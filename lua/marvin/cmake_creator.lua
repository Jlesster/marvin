-- lua/marvin/cmake_creator.lua
-- Interactive CMakeLists.txt wizard.
-- Generates a well-structured CMakeLists.txt for C or C++ projects,
-- with optional auto-link detection, pkg-config detection, test target
-- (CTest + gtest/catch2), and install rules.

local M = {}

local function ui() return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function plain(it) return it.label end

-- ── pkg-config header → package name map ──────────────────────────────────────
-- Mirrors the map in makefile_creator.lua exactly.

-- ── pkg-config scan ───────────────────────────────────────────────────────────
-- ── Dynamic pkg-config dependency detection ──────────────────────────────────
-- Builds a header→package reverse map from whatever is installed on this system.
-- No hardcoded list needed — works for any library with a .pc file.

local _hdr_pkg_map_cache = nil
local function get_hdr_pkg_map()
  if _hdr_pkg_map_cache then return _hdr_pkg_map_cache end
  local map = {}

  local h = io.popen('pkg-config --list-all 2>/dev/null')
  if not h then _hdr_pkg_map_cache = map; return map end
  local pkgs = {}
  for line in h:lines() do
    local name = line:match('^(%S+)')
    if name then pkgs[#pkgs + 1] = name end
  end
  h:close()

  local scanned = {}
  for _, pkg in ipairs(pkgs) do
    local dirs = {}
    -- explicit -I flags
    local ch = io.popen('pkg-config --cflags-only-I ' .. pkg .. ' 2>/dev/null')
    if ch then
      local out = ch:read('*a'); ch:close()
      for token in out:gmatch('%S+') do
        if token:sub(1,2) == '-I' then dirs[#dirs+1] = token:sub(3) end
      end
    end
    -- includedir variable
    local ih = io.popen('pkg-config --variable=includedir ' .. pkg .. ' 2>/dev/null')
    if ih then
      local d = vim.trim(ih:read('*l') or ''); ih:close()
      if d ~= '' then dirs[#dirs+1] = d end
    end
    -- guess <includedir>/<stem> for packages like harfbuzz in /usr/include/harfbuzz/
    local stem = pkg:match('^([%a%d]+)')
    if stem then
      for _, base in ipairs({'/usr/include', '/usr/local/include'}) do
        if vim.fn.isdirectory(base .. '/' .. stem) == 1 then
          dirs[#dirs+1] = base
          dirs[#dirs+1] = base .. '/' .. stem
        end
      end
    end
    for _, dir in ipairs(dirs) do
      if not scanned[dir] and vim.fn.isdirectory(dir) == 1 then
        scanned[dir] = true
        local fh = io.popen('ls ' .. vim.fn.shellescape(dir) .. ' 2>/dev/null')
        if fh then
          for entry in fh:lines() do
            if entry:match('%.h$') then
              if not map[entry] then map[entry] = pkg end
            elseif vim.fn.isdirectory(dir .. '/' .. entry) == 1 then
              local sh = io.popen('ls ' .. vim.fn.shellescape(dir..'/'..entry) .. ' 2>/dev/null')
              if sh then
                for hdr in sh:lines() do
                  if hdr:match('%.h$') then
                    local key = entry .. '/' .. hdr
                    if not map[key] then map[key] = pkg end
                  end
                end
                sh:close()
              end
            end
          end
          fh:close()
        end
      end
    end
  end
  _hdr_pkg_map_cache = map
  return map
end

local function include_to_pkg(inc)
  local map = get_hdr_pkg_map()
  if map[inc] then return map[inc] end
  local fname = inc:match('([^/]+)$')
  return fname and map[fname] or nil
end


-- Resolve a base pkg-config name to the actual installed name.
-- Handles versioned packages: 'wlroots' → 'wlroots-0.18' etc.
local _pkg_resolve_cache = {}
local function resolve_pkg(base)
  if _pkg_resolve_cache[base] ~= nil then return _pkg_resolve_cache[base] or nil end
  -- 1. Exact name
  if os.execute('pkg-config --exists ' .. base .. ' 2>/dev/null') == 0 then
    _pkg_resolve_cache[base] = base; return base
  end
  -- 2. Versioned variant: e.g. wlroots-0.18
  local h = io.popen(
    "pkg-config --list-all 2>/dev/null | grep -E '^" .. base .. "[-[:space:]]' | head -1 | awk '{print $1}'")
  if h then
    local found = vim.trim(h:read('*l') or ''); h:close()
    if found ~= '' then _pkg_resolve_cache[base] = found; return found end
  end
  _pkg_resolve_cache[base] = false; return nil
end

local function detect_pkg_deps(root)
  local patterns = { '*.c', '*.cpp', '*.h', '*.hpp', '*.cxx', '*.hxx' }
  local found    = {}
  local ordered  = {}

  for _, pat in ipairs(patterns) do
    for _, f in ipairs(vim.fn.globpath(root, '**/' .. pat, false, true)) do
      if not f:find('/build', 1, true) and not f:find('/builddir', 1, true) then
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            local inc = line:match('#%s*include%s*[<\"]([^>\"]+)[>\"]')
            if inc then
              local pkg = include_to_pkg(inc)
              if pkg and not found[pkg] then
                local resolved = resolve_pkg(pkg)
                if resolved then
                  found[pkg]            = true
                  ordered[#ordered + 1] = resolved
                end
              end
            end
          end
        end
      end
    end
  end
  return ordered
end
-- ── wlroots unstable guard ────────────────────────────────────────────────────
local function scan_needs_wlr_unstable(root)
  for _, pat in ipairs({ '**/*.c', '**/*.cpp', '**/*.cxx', '**/*.h', '**/*.hpp' }) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
      if not f:find('/build', 1, true) and not f:find('/builddir', 1, true) then
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            if line:match('#%s*include%s*[<\"]wlr/') then return true end
            if line:match('WLR_USE_UNSTABLE') then return true end
          end
        end
      end
    end
  end
  return false
end

-- ── Auto-link integration ─────────────────────────────────────────────────────
-- Returns cmake_targets (e.g. Threads::Threads) from the existing creator/cpp
-- detection, plus pkg_deps list from our header scan.
local function auto_detect_cmake_targets(root)
  local cmake_targets = {}
  local ok_cr, cr   = pcall(require, 'marvin.creator.cpp')
  local ok_det, det2 = pcall(require, 'marvin.detector')
  if ok_cr and ok_det then
    local p = det2.get()
    if p then
      local links = cr.detect_links(p)
      cmake_targets = (links and links.cmake) or {}
    end
  end
  return cmake_targets
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function write(path, content, name)
  local f = io.open(path, 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. path, vim.log.levels.ERROR); return false
  end
  f:write(content); f:close()
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.notify('[Marvin] CMakeLists.txt created for: ' .. name, vim.log.levels.INFO)
  return true
end

local function check_existing(path, content, name)
  if vim.fn.filereadable(path) == 1 then
    ui().select({
        { id = 'overwrite', label = 'Overwrite', desc = 'Replace existing CMakeLists.txt' },
        { id = 'cancel',    label = 'Cancel',    desc = 'Keep existing file' },
      }, { prompt = 'CMakeLists.txt already exists', format_item = plain },
      function(ch)
        if ch and ch.id == 'overwrite' then write(path, content, name) end
      end)
    return
  end
  write(path, content, name)
end

-- ── Template ──────────────────────────────────────────────────────────────────


local function cmake_template(opts)
  local lines = {}
  local function l(s) lines[#lines + 1] = (s or '') end

  local lang     = opts.lang == 'c' and 'C' or 'CXX'
  local std_var  = opts.lang == 'c' and 'CMAKE_C_STANDARD' or 'CMAKE_CXX_STANDARD'
  local std_req  = opts.lang == 'c' and 'CMAKE_C_STANDARD_REQUIRED' or 'CMAKE_CXX_STANDARD_REQUIRED'
  local std_ext  = opts.lang == 'c' and 'CMAKE_C_EXTENSIONS' or 'CMAKE_CXX_EXTENSIONS'
  local src_glob = opts.lang == 'c' and '*.c' or '*.cpp'
  local std_val  = opts.std or (opts.lang == 'c' and '11' or '17')

  -- Header
  l('# ' .. opts.name .. ' — generated by Marvin')
  l('# CMake ' .. (opts.cmake_min or '3.20') .. '+')
  l()
  l('cmake_minimum_required(VERSION ' .. (opts.cmake_min or '3.20') .. ')')
  l('project(' .. opts.name .. ' LANGUAGES ' .. lang .. ')')
  l()

  -- Language standard
  l('# ── Language standard ────────────────────────────────────────────────────')
  l('set(' .. std_var .. ' ' .. std_val .. ')')
  l('set(' .. std_req .. ' ON)')
  l('set(' .. std_ext .. ' OFF)')
  l()

  -- Source glob
  l('# ── Sources ──────────────────────────────────────────────────────────────')
  l('file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS')
  l('    "${CMAKE_CURRENT_SOURCE_DIR}/src/' .. src_glob .. '"')
  l(')')
  l()

  -- Executable
  l('# ── Target ───────────────────────────────────────────────────────────────')
  l('add_executable(' .. opts.name .. ' ${SOURCES})')
  l()

  -- Include dirs
  l('target_include_directories(' .. opts.name .. ' PRIVATE')
  l('    "${CMAKE_CURRENT_SOURCE_DIR}/include"')
  l(')')
  l()

  -- Compiler warnings + defines
  l('# ── Compiler options ─────────────────────────────────────────────────────')
  l('target_compile_options(' .. opts.name .. ' PRIVATE')
  if opts.lang == 'c' then
    l('    -Wall -Wextra -Wpedantic')
  else
    l('    -Wall -Wextra -Wpedantic -Wno-unused-parameter')
  end
  if opts.sanitizer and opts.sanitizer ~= 'none' then
    local sflag = opts.sanitizer == 'asan' and 'address'
        or opts.sanitizer == 'tsan' and 'thread'
        or 'undefined'
    l('    -fsanitize=' .. sflag .. ' -fno-omit-frame-pointer')
  end
  l(')')
  l()

  -- Compile definitions
  local defs = {}
  if opts.wlr_guard   then defs[#defs + 1] = 'WLR_USE_UNSTABLE' end
  if opts.needs_posix then defs[#defs + 1] = '_POSIX_C_SOURCE=200809L' end
  if #defs > 0 then
    l('target_compile_definitions(' .. opts.name .. ' PRIVATE')
    for _, d in ipairs(defs) do l('    ' .. d) end
    l(')')
    l()
  end

  if opts.sanitizer and opts.sanitizer ~= 'none' then
    local sflag = opts.sanitizer == 'asan' and 'address'
        or opts.sanitizer == 'tsan' and 'thread'
        or 'undefined'
    l('target_link_options(' .. opts.name .. ' PRIVATE -fsanitize=' .. sflag .. ')')
    l()
  end

  -- pkg-config dependencies
  local pkg_deps = opts.pkg_deps or {}
  if #pkg_deps > 0 then
    l('# ── pkg-config dependencies ───────────────────────────────────────────────')
    l('find_package(PkgConfig REQUIRED)')
    for _, pkg in ipairs(pkg_deps) do
      local varname = pkg:gsub('[%-.]', '_'):upper()
      l('pkg_check_modules(' .. varname .. ' REQUIRED IMPORTED_TARGET ' .. pkg .. ')')
    end
    l()
  end

  -- Auto-detected cmake targets + user extra libs
  local all_targets = {}
  if opts.cmake_targets then
    for _, t in ipairs(opts.cmake_targets) do all_targets[#all_targets + 1] = t end
  end
  -- pkg-config targets as PkgConfig::VARNAME
  for _, pkg in ipairs(pkg_deps) do
    local varname = pkg:gsub('[%-.]', '_'):upper()
    all_targets[#all_targets + 1] = 'PkgConfig::' .. varname
  end
  if opts.extra_libs and opts.extra_libs ~= '' then
    all_targets[#all_targets + 1] = opts.extra_libs
  end
  if #all_targets > 0 then
    l('# ── Link libraries ───────────────────────────────────────────────────────')
    local needs_threads = false
    for _, t in ipairs(all_targets) do
      if t:match('Threads') then needs_threads = true end
    end
    if needs_threads then l('find_package(Threads REQUIRED)') end
    l('target_link_libraries(' .. opts.name .. ' PRIVATE')
    for _, t in ipairs(all_targets) do l('    ' .. t) end
    l(')')
    l()
  end

  -- Wayland protocol generation
  local protocol_xmls = opts.protocol_xmls or {}
  if #protocol_xmls > 0 then
    l('# ── Wayland protocol generation ──────────────────────────────────────────────')
    l('find_program(WAYLAND_SCANNER wayland-scanner REQUIRED)')
    l()
    l('set(PROTOCOL_SOURCES)')
    for _, xml in ipairs(protocol_xmls) do
      local stem = xml:gsub('%.xml$', '')
      l('# ' .. xml)
      l('execute_process(')
      l('    COMMAND ${WAYLAND_SCANNER} client-header')
      l('        ${CMAKE_CURRENT_SOURCE_DIR}/include/protocols/' .. xml)
      l('        ${CMAKE_CURRENT_SOURCE_DIR}/include/protocols/' .. stem .. '-protocol.h')
      l(')')
      l('execute_process(')
      l('    COMMAND ${WAYLAND_SCANNER} private-code')
      l('        ${CMAKE_CURRENT_SOURCE_DIR}/include/protocols/' .. xml)
      l('        ${CMAKE_CURRENT_SOURCE_DIR}/include/protocols/' .. stem .. '-protocol.c')
      l(')')
      l('list(APPEND PROTOCOL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/include/protocols/' .. stem .. '-protocol.c)')
      l()
    end
    l('target_sources(' .. opts.name .. ' PRIVATE ${PROTOCOL_SOURCES})')
    l('target_include_directories(' .. opts.name .. ' PRIVATE ${CMAKE_CURRENT_BINARY_DIR})')
    l('target_include_directories(' .. opts.name .. " PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include/protocols)')
    l()
  end

  -- compile_commands.json
  l('# ── compile_commands.json (for clangd) ───────────────────────────────────')
  l('set(CMAKE_EXPORT_COMPILE_COMMANDS ON)')
  l()

  -- Optional: testing
  if opts.testing then
    l('# ── Tests ────────────────────────────────────────────────────────────────')
    l('enable_testing()')
    l()
    if opts.test_framework == 'gtest' then
      l('find_package(GTest REQUIRED)')
      l('file(GLOB_RECURSE TEST_SOURCES CONFIGURE_DEPENDS')
      l('    "${CMAKE_CURRENT_SOURCE_DIR}/tests/' .. src_glob .. '"')
      l(')')
      l('add_executable(' .. opts.name .. '_tests ${TEST_SOURCES})')
      l('target_include_directories(' .. opts.name .. '_tests PRIVATE')
      l('    "${CMAKE_CURRENT_SOURCE_DIR}/include"')
      l(')')
      l('target_link_libraries(' .. opts.name .. '_tests PRIVATE GTest::gtest_main)')
      l('include(GoogleTest)')
      l('gtest_discover_tests(' .. opts.name .. '_tests)')
    elseif opts.test_framework == 'catch2' then
      l('find_package(Catch2 3 REQUIRED)')
      l('file(GLOB_RECURSE TEST_SOURCES CONFIGURE_DEPENDS')
      l('    "${CMAKE_CURRENT_SOURCE_DIR}/tests/' .. src_glob .. '"')
      l(')')
      l('add_executable(' .. opts.name .. '_tests ${TEST_SOURCES})')
      l('target_include_directories(' .. opts.name .. '_tests PRIVATE')
      l('    "${CMAKE_CURRENT_SOURCE_DIR}/include"')
      l(')')
      l('target_link_libraries(' .. opts.name .. '_tests PRIVATE Catch2::Catch2WithMain)')
      l('include(CTest)')
      l('include(Catch)')
      l('catch_discover_tests(' .. opts.name .. '_tests)')
    else
      l('# add_subdirectory(tests)')
    end
    l()
  end

  -- Optional: install rules
  if opts.install then
    l('# ── Install ──────────────────────────────────────────────────────────────')
    l('install(TARGETS ' .. opts.name .. ' DESTINATION bin)')
    l('install(DIRECTORY include/ DESTINATION include)')
    l()
  end

  return table.concat(lines, '\n')
end

-- ── Wizard ────────────────────────────────────────────────────────────────────
function M.create(root, on_back)
  root = root or vim.fn.getcwd()
  local default_name = vim.fn.fnamemodify(root, ':t')

  -- Step 1: project name
  ui().input({ prompt = '󰬷 Project name', default = default_name }, function(name)
    if not name or name == '' then return end

    -- Step 2: language
    ui().select({
        { id = 'cpp', label = 'C++', desc = 'CXX language, .cpp sources' },
        { id = 'c',   label = 'C',   desc = 'C language, .c sources' },
      }, { prompt = 'Language', on_back = on_back, format_item = plain },
      function(lang_ch)
        if not lang_ch then return end
        local lang = lang_ch.id

        -- Step 3: standard
        local stds = lang == 'c'
            and {
              { id = '11', label = 'C11', desc = 'Recommended' },
              { id = '17', label = 'C17', desc = 'Latest stable' },
              { id = '99', label = 'C99', desc = 'Wide compat' },
            }
            or {
              { id = '17', label = 'C++17', desc = 'Recommended' },
              { id = '20', label = 'C++20', desc = 'Concepts, ranges' },
              { id = '23', label = 'C++23', desc = 'Latest' },
              { id = '14', label = 'C++14', desc = 'Lambdas, auto' },
            }
        ui().select(stds, { prompt = 'Standard', format_item = plain },
          function(std_ch)
            if not std_ch then return end

            -- Step 4: cmake minimum version
            ui().select({
                { id = '3.20', label = 'CMake 3.20', desc = 'Recommended minimum' },
                { id = '3.25', label = 'CMake 3.25', desc = 'Latest LTS features' },
                { id = '3.16', label = 'CMake 3.16', desc = 'Wide compatibility' },
              }, { prompt = 'CMake minimum version', format_item = plain },
              function(cmake_ch)
                if not cmake_ch then return end

                -- Step 5: sanitizer
                ui().select({
                    { id = 'none',  label = 'None' },
                    { id = 'asan',  label = 'AddressSanitizer', desc = '-fsanitize=address' },
                    { id = 'tsan',  label = 'ThreadSanitizer',  desc = '-fsanitize=thread' },
                    { id = 'ubsan', label = 'UBSanitizer',      desc = '-fsanitize=undefined' },
                  }, { prompt = 'Sanitizer (optional)', format_item = plain },
                  function(san_ch)
                    -- Step 6: testing
                    ui().select({
                        { id = 'none',   label = 'No tests' },
                        { id = 'gtest',  label = 'GoogleTest', desc = 'find_package(GTest)' },
                        { id = 'catch2', label = 'Catch2',     desc = 'find_package(Catch2 3)' },
                      }, { prompt = 'Test framework', format_item = plain },
                      function(test_ch)
                        -- Step 7: install rules
                        ui().select({
                            { id = 'yes', label = 'Yes — add install() rules' },
                            { id = 'no',  label = 'No' },
                          }, { prompt = 'Add install rules?', format_item = plain },
                          function(inst_ch)
                            -- Run full detection pipeline
                            local cmake_targets = auto_detect_cmake_targets(root)
                            local wlr_guard     = false
                            local needs_posix   = false
                            local pkg_deps      = {}
                            local ok_b, build   = pcall(require, 'marvin.build')
                            if ok_b and build.cpp then
                              if build.cpp.pkg_config_flags then
                                local ok_f, flags = pcall(build.cpp.pkg_config_flags, root)
                                if ok_f then
                                  pkg_deps = flags.pkg_names or {}
                                  for _, f in ipairs(flags.iflags or {}) do
                                    if f == '-DWLR_USE_UNSTABLE' then wlr_guard = true end
                                  end
                                end
                              end
                              if build.cpp.needs_posix_define then
                                local ok_p, res = pcall(build.cpp.needs_posix_define, root)
                                if ok_p then needs_posix = res end
                              end
                            end
                            if not wlr_guard then wlr_guard = scan_needs_wlr_unstable(root) end

                            -- Notify what was injected
                            local notices = {}
                            if #pkg_deps > 0 then
                              notices[#notices + 1] = 'pkg-config deps: ' .. table.concat(pkg_deps, ' ')
                              notices[#notices + 1] = '  → find_package(PkgConfig) + pkg_check_modules()'
                            end
                            if wlr_guard   then notices[#notices + 1] = 'wlroots → WLR_USE_UNSTABLE defined' end
                            if needs_posix then notices[#notices + 1] = 'POSIX   → _POSIX_C_SOURCE=200809L defined' end
                            if #cmake_targets > 0 then
                              notices[#notices + 1] = 'CMake targets: ' .. table.concat(cmake_targets, ' ')
                            end
                            if #notices > 0 then
                              vim.notify(
                                '[Marvin] Auto-detected:\n  ' .. table.concat(notices, '\n  '),
                                vim.log.levels.INFO)
                            end

                            -- Optional extra libs
                            ui().input({
                              prompt  = 'Extra link targets (space-separated, optional)',
                              default = '',
                            }, function(extra)
                              local ok_wp, wl_proto = pcall(require, 'marvin.wayland_protocols')
                              if not ok_wp then
                                vim.notify('[Marvin] wayland_protocols module error: ' .. tostring(wl_proto), vim.log.levels.WARN)
                                wl_proto = nil
                              end
                              local protocol_xmls = {}
                              if wl_proto then
                                local ok_r, proto_entries = pcall(wl_proto.resolve, root)
                                if ok_r then
                                  for _, e in ipairs(proto_entries) do
                                    if e.in_root then
                                      protocol_xmls[#protocol_xmls + 1] = e.xml
                                    end
                                  end
                                else
                                  vim.notify('[Marvin] Protocol scan error: ' .. tostring(proto_entries), vim.log.levels.WARN)
                                end
                              end

                              local opts = {
                                name           = name,
                                lang           = lang,
                                std            = std_ch.id,
                                cmake_min      = cmake_ch.id,
                                sanitizer      = san_ch and san_ch.id or 'none',
                                testing        = test_ch and test_ch.id ~= 'none',
                                test_framework = test_ch and test_ch.id or nil,
                                install        = inst_ch and inst_ch.id == 'yes',
                                cmake_targets  = cmake_targets,
                                pkg_deps       = pkg_deps,
                                wlr_guard      = wlr_guard,
                                needs_posix    = needs_posix,
                                extra_libs     = extra and extra ~= '' and extra or nil,
                                protocol_xmls  = protocol_xmls,
                              }
                              local content = cmake_template(opts)
                              check_existing(root .. '/CMakeLists.txt', content, name)
                            end)
                          end)
                      end)
                  end)
              end)
          end)
      end)
  end)
end

return M
