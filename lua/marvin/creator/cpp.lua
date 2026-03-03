-- lua/marvin/creator/cpp.lua
-- Interactive C/C++ file creation wizard.
-- Handles: class (header + source), header-only, interface (abstract base),
--          struct, enum, test file, main file, and Makefile regeneration.
-- Now includes: auto-link detection (scans includes/CMakeLists for known libs
--               and injects LDFLAGS / target_link_libraries suggestions).

local M = {}

local function ui() return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function plain(it) return it.label end

-- ── Auto-link detection ───────────────────────────────────────────────────────
-- Maps well-known #include patterns → { lib, cmake_target, pkg_config }
-- lib          = -l flag for LDFLAGS
-- cmake_target = CMake target_link_libraries() name
-- pkg_config   = pkg-config name (for Makefile)
-- system       = true → no separate -l needed (standard library)

local KNOWN_LIBS = {
  -- Threading
  { include = 'pthread',               lib = '-lpthread',                         cmake = 'Threads::Threads',             pkg = 'threads' },
  { include = 'thread',                lib = '-lpthread',                         cmake = 'Threads::Threads',             pkg = 'threads' },
  -- Networking / TLS
  { include = 'openssl',               lib = '-lssl -lcrypto',                    cmake = 'OpenSSL::SSL OpenSSL::Crypto', pkg = 'openssl' },
  { include = 'ssl',                   lib = '-lssl -lcrypto',                    cmake = 'OpenSSL::SSL OpenSSL::Crypto', pkg = 'openssl' },
  { include = 'curl',                  lib = '-lcurl',                            cmake = 'CURL::libcurl',                pkg = 'libcurl' },
  -- Math
  { include = 'cmath',                 lib = '-lm',                               cmake = 'm',                            system = true },
  { include = 'math.h',                lib = '-lm',                               cmake = 'm',                            system = true },
  { include = 'complex',               lib = '-lm',                               cmake = 'm',                            system = true },
  -- Boost
  { include = 'boost/filesystem',      lib = '-lboost_filesystem -lboost_system', cmake = 'Boost::filesystem',            pkg = 'boost_filesystem' },
  { include = 'boost/regex',           lib = '-lboost_regex',                     cmake = 'Boost::regex',                 pkg = 'boost_regex' },
  { include = 'boost/thread',          lib = '-lboost_thread',                    cmake = 'Boost::thread',                pkg = 'boost_thread' },
  { include = 'boost/program_options', lib = '-lboost_program_options',           cmake = 'Boost::program_options',       pkg = 'boost_program_options' },
  { include = 'boost/asio',            lib = '-lpthread',                         cmake = 'Boost::asio Threads::Threads', pkg = nil },
  -- fmt
  { include = 'fmt/',                  lib = '-lfmt',                             cmake = 'fmt::fmt',                     pkg = 'fmt' },
  -- spdlog
  { include = 'spdlog/',               lib = '-lfmt',                             cmake = 'spdlog::spdlog',               pkg = 'spdlog' },
  -- SQLite
  { include = 'sqlite3',               lib = '-lsqlite3',                         cmake = 'SQLite::SQLite3',              pkg = 'sqlite3' },
  -- zlib
  { include = 'zlib',                  lib = '-lz',                               cmake = 'ZLIB::ZLIB',                   pkg = 'zlib' },
  { include = 'zconf',                 lib = '-lz',                               cmake = 'ZLIB::ZLIB',                   pkg = 'zlib' },
  -- ncurses / readline
  { include = 'ncurses',               lib = '-lncurses',                         cmake = 'Curses::Curses',               pkg = 'ncurses' },
  { include = 'readline',              readline = true,                           lib = '-lreadline',                     cmake = 'readline',           pkg = 'readline' },
  -- Graphics / windowing
  { include = 'GLFW',                  lib = '-lglfw',                            cmake = 'glfw',                         pkg = 'glfw3' },
  { include = 'GL/',                   lib = '-lGL',                              cmake = 'OpenGL::GL',                   pkg = 'gl' },
  { include = 'GLES',                  lib = '-lGLES',                            cmake = 'OpenGL::GLES',                 pkg = nil },
  { include = 'vulkan',                lib = '-lvulkan',                          cmake = 'Vulkan::Vulkan',               pkg = 'vulkan' },
  { include = 'SDL2',                  lib = '-lSDL2',                            cmake = 'SDL2::SDL2',                   pkg = 'sdl2' },
  -- Testing (header-only; no link needed for catch2 amalgam)
  { include = 'gtest',                 lib = '-lgtest -lgtest_main -lpthread',    cmake = 'GTest::gtest_main',            pkg = 'gtest' },
  { include = 'gmock',                 lib = '-lgmock -lgtest -lpthread',         cmake = 'GTest::gmock',                 pkg = nil },
  -- JSON
  { include = 'nlohmann/json',         lib = nil,                                 cmake = 'nlohmann_json::nlohmann_json', pkg = nil,                    header_only = true },
  { include = 'rapidjson',             lib = nil,                                 cmake = nil,                            pkg = nil,                    header_only = true },
  -- YAML
  { include = 'yaml-cpp',              lib = '-lyaml-cpp',                        cmake = 'yaml-cpp::yaml-cpp',           pkg = 'yaml-cpp' },
  -- Protocol Buffers / gRPC
  { include = 'google/protobuf',       lib = '-lprotobuf',                        cmake = 'protobuf::libprotobuf',        pkg = 'protobuf' },
  { include = 'grpc',                  lib = '-lgrpc++ -lgrpc',                   cmake = 'gRPC::grpc++',                 pkg = 'grpc++' },
  -- Compression
  { include = 'lz4',                   lib = '-llz4',                             cmake = 'lz4::lz4',                     pkg = 'liblz4' },
  { include = 'zstd',                  lib = '-lzstd',                            cmake = 'zstd::libzstd',                pkg = 'libzstd' },
  -- FFmpeg
  { include = 'libavcodec',            lib = '-lavcodec -lavutil',                cmake = nil,                            pkg = 'libavcodec libavutil' },
}

-- Scan a list of #include lines and return detected library entries (deduplicated)
local function detect_includes_from_lines(lines)
  local found, seen = {}, {}
  for _, line in ipairs(lines) do
    -- Match both <> and "" includes
    local inc = line:match('#%s*include%s*[<"]([^>"]+)[>"]')
    if inc then
      for _, entry in ipairs(KNOWN_LIBS) do
        if not seen[entry.include] and inc:find(entry.include, 1, true) then
          seen[entry.include] = true
          found[#found + 1] = entry
        end
      end
    end
  end
  return found
end

-- Scan all .h/.hpp/.cpp/.c files under root for includes
local function scan_project_includes(root)
  local all_lines = {}
  local patterns  = { '*.h', '*.hpp', '*.cpp', '*.c', '*.hxx', '*.cxx' }
  for _, pat in ipairs(patterns) do
    local files = vim.fn.globpath(root, '**/' .. pat, false, true)
    for _, f in ipairs(files) do
      local ok, content = pcall(vim.fn.readfile, f)
      if ok then
        for _, l in ipairs(content) do
          all_lines[#all_lines + 1] = l
        end
      end
    end
  end
  return detect_includes_from_lines(all_lines)
end

-- Scan CMakeLists.txt for target_link_libraries entries
local function scan_cmake_links(root)
  local cmake_path = root .. '/CMakeLists.txt'
  if vim.fn.filereadable(cmake_path) == 0 then return {} end
  local content = vim.fn.readfile(cmake_path)
  local linked  = {}
  for _, line in ipairs(content) do
    -- e.g. target_link_libraries(myapp PRIVATE pthread ssl)
    local libs_str = line:match('target_link_libraries%s*%([^%)]+%)')
    if libs_str then
      for lib in libs_str:gmatch('(%S+)') do
        if lib ~= 'target_link_libraries(' and lib ~= 'PRIVATE'
            and lib ~= 'PUBLIC' and lib ~= 'INTERFACE' and not lib:match('%($') then
          linked[lib] = true
        end
      end
    end
  end
  return linked
end

-- Build a deduplicated LDFLAGS string and cmake targets list
-- from a list of KNOWN_LIBS entries, excluding already-linked ones
local function build_link_suggestions(detected, already_linked)
  already_linked = already_linked or {}
  local ldflags_parts, cmake_parts, pkg_parts = {}, {}, {}
  local seen = {}

  for _, entry in ipairs(detected) do
    if entry.header_only then goto continue end
    local key = entry.include
    if seen[key] then goto continue end
    seen[key] = true

    -- Check if cmake target already present
    if entry.cmake then
      local skip = false
      for _, ct in ipairs(vim.split(entry.cmake, ' ')) do
        if already_linked[ct] then
          skip = true; break
        end
      end
      if skip then goto continue end
      for _, ct in ipairs(vim.split(entry.cmake, ' ')) do
        cmake_parts[#cmake_parts + 1] = ct
      end
    end

    if entry.lib and not entry.system then
      ldflags_parts[#ldflags_parts + 1] = entry.lib
    end
    if entry.pkg then
      pkg_parts[#pkg_parts + 1] = entry.pkg
    end

    ::continue::
  end

  return {
    ldflags    = table.concat(ldflags_parts, ' '),
    cmake      = cmake_parts,
    pkg_config = pkg_parts,
  }
end

-- Public: detect links for a project, return suggestion table
function M.detect_links(p)
  local detected       = scan_project_includes(p.root)
  local already_linked = p.type == 'cmake' and scan_cmake_links(p.root) or {}
  return build_link_suggestions(detected, already_linked)
end

-- Public: detect links for a specific set of include lines (for new file wizard)
function M.detect_links_for_includes(includes_list, p)
  local lines = {}
  for _, inc in ipairs(includes_list) do
    lines[#lines + 1] = '#include ' .. inc
  end
  local detected       = detect_includes_from_lines(lines)
  local already_linked = p and p.type == 'cmake' and scan_cmake_links(p.root) or {}
  return build_link_suggestions(detected, already_linked)
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function write(path, lines, label)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local f = io.open(path, 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. path, vim.log.levels.ERROR); return false
  end
  for _, l in ipairs(lines) do f:write(l .. '\n') end
  f:close()
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.notify('[Marvin] Created ' .. label .. ': ' .. vim.fn.fnamemodify(path, ':t'), vim.log.levels.INFO)
  return true
end

local function guard(name)
  return name:upper():gsub('[^A-Z0-9]', '_') .. '_H'
end

local function cfg()
  return require('marvin').config.cpp
end

-- Notify with link suggestions after file creation
local function notify_link_suggestions(links, p)
  if not links then return end
  local parts = {}
  if links.ldflags and links.ldflags ~= '' then
    parts[#parts + 1] = 'LDFLAGS: ' .. links.ldflags
  end
  if links.cmake and #links.cmake > 0 then
    parts[#parts + 1] = 'CMake:   target_link_libraries(<target> ' .. table.concat(links.cmake, ' ') .. ')'
  end
  if links.pkg_config and #links.pkg_config > 0 then
    parts[#parts + 1] = 'pkg-cfg: ' .. table.concat(links.pkg_config, ' ')
  end
  if #parts > 0 then
    vim.notify('[Marvin] Detected linker flags for new file:\n' .. table.concat(parts, '\n'),
      vim.log.levels.INFO)
  end
end

-- ── Templates ─────────────────────────────────────────────────────────────────

local function class_header(name, opts)
  local g     = guard(name)
  local ns    = opts.ns
  local lines = {
    '#pragma once',
    '#ifndef ' .. g,
    '#define ' .. g,
    '',
  }
  if opts.includes and #opts.includes > 0 then
    for _, inc in ipairs(opts.includes) do
      lines[#lines + 1] = '#include ' .. inc
    end
    lines[#lines + 1] = ''
  end
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = 'class ' .. name .. (opts.base and (' : public ' .. opts.base) or '') .. ' {'
  lines[#lines + 1] = 'public:'
  lines[#lines + 1] = '    ' .. name .. '();'
  lines[#lines + 1] = '    ~' .. name .. (opts.base and '() override;' or '();')
  if opts.copy then
    lines[#lines + 1] = '    ' .. name .. '(const ' .. name .. '&) = default;'
    lines[#lines + 1] = '    ' .. name .. '& operator=(const ' .. name .. '&) = default;'
  end
  if opts.move then
    lines[#lines + 1] = '    ' .. name .. '(' .. name .. '&&) noexcept = default;'
    lines[#lines + 1] = '    ' .. name .. '& operator=(' .. name .. '&&) noexcept = default;'
  end
  if opts.methods and #opts.methods > 0 then
    lines[#lines + 1] = ''
    for _, m in ipairs(opts.methods) do
      lines[#lines + 1] = '    ' .. m .. ';'
    end
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = 'private:'
  if opts.fields and #opts.fields > 0 then
    for _, f in ipairs(opts.fields) do
      lines[#lines + 1] = '    ' .. f.typ .. ' ' .. f.name .. ';'
    end
  else
    lines[#lines + 1] = '    // TODO: add members'
  end
  lines[#lines + 1] = '};'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '#endif // ' .. g
  return lines
end

local function class_source(name, opts)
  local inc_path = opts.inc_dir and (opts.inc_dir .. '/' .. name .. '.h') or (name .. '.h')
  local ns       = opts.ns
  local lines    = {
    '#include "' .. inc_path .. '"',
    '',
  }
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = name .. '::' .. name .. '() {'
  lines[#lines + 1] = '    // TODO: constructor'
  lines[#lines + 1] = '}'
  lines[#lines + 1] = ''
  lines[#lines + 1] = name .. '::~' .. name .. '() {'
  lines[#lines + 1] = '    // TODO: destructor'
  lines[#lines + 1] = '}'
  -- Stub out any method definitions
  if opts.methods and #opts.methods > 0 then
    for _, m in ipairs(opts.methods) do
      -- Strip parameter names, just get signature
      lines[#lines + 1] = ''
      lines[#lines + 1] = '// ' .. m
      local ret, rest = m:match('^(%S+)%s+(.+)')
      if ret and rest then
        lines[#lines + 1] = ret .. ' ' .. name .. '::' .. rest .. ' {'
      else
        lines[#lines + 1] = name .. '::' .. m .. ' {'
      end
      lines[#lines + 1] = '    // TODO: implement'
      lines[#lines + 1] = '}'
    end
  end
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  return lines
end

local function abstract_header(name, opts)
  local g     = guard(name)
  local ns    = opts.ns
  local lines = {
    '#pragma once',
    '#ifndef ' .. g,
    '#define ' .. g,
    '',
  }
  if opts.includes and #opts.includes > 0 then
    for _, inc in ipairs(opts.includes) do
      lines[#lines + 1] = '#include ' .. inc
    end
    lines[#lines + 1] = ''
  end
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = 'class ' .. name .. ' {'
  lines[#lines + 1] = 'public:'
  lines[#lines + 1] = '    virtual ~' .. name .. '() = default;'
  lines[#lines + 1] = ''
  if opts.methods and #opts.methods > 0 then
    for _, m in ipairs(opts.methods) do
      lines[#lines + 1] = '    virtual ' .. m .. ' = 0;'
    end
  else
    lines[#lines + 1] = '    // TODO: add pure virtual methods'
    lines[#lines + 1] = '    // virtual void doSomething() = 0;'
  end
  lines[#lines + 1] = '};'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '#endif // ' .. g
  return lines
end

local function struct_header(name, opts)
  local g     = guard(name)
  local ns    = opts.ns
  local lines = {
    '#pragma once',
    '#ifndef ' .. g,
    '#define ' .. g,
    '',
  }
  if opts.includes and #opts.includes > 0 then
    for _, inc in ipairs(opts.includes) do
      lines[#lines + 1] = '#include ' .. inc
    end
    lines[#lines + 1] = ''
  end
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = 'struct ' .. name .. ' {'
  if opts.fields and #opts.fields > 0 then
    for _, f in ipairs(opts.fields) do
      lines[#lines + 1] = '    ' .. f.typ .. ' ' .. f.name .. ';'
    end
  else
    lines[#lines + 1] = '    // TODO: add fields'
  end
  lines[#lines + 1] = '};'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '#endif // ' .. g
  return lines
end

local function enum_header(name, opts)
  local g         = guard(name)
  local ns        = opts.ns
  local use_class = opts.scoped ~= false -- default to enum class
  local lines     = {
    '#pragma once',
    '#ifndef ' .. g,
    '#define ' .. g,
    '',
  }
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = (use_class and 'enum class ' or 'enum ') .. name .. ' {'
  if opts.values and #opts.values > 0 then
    for i, v in ipairs(opts.values) do
      local comma = i < #opts.values and ',' or ''
      lines[#lines + 1] = '    ' .. v .. comma
    end
  else
    lines[#lines + 1] = '    // TODO: add values'
  end
  lines[#lines + 1] = '};'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '#endif // ' .. g
  return lines
end

local function test_file(name, opts)
  local subject = opts.subject or name
  if opts.framework == 'catch2' then
    return {
      '#include <catch2/catch_test_macros.hpp>',
      '',
      '// TODO: #include "' .. subject .. '.h"',
      '',
      'TEST_CASE("' .. subject .. ' basic", "[' .. subject .. ']") {',
      '    SECTION("placeholder") {',
      '        REQUIRE(true);',
      '    }',
      '}',
    }
  else -- gtest default
    return {
      '#include <gtest/gtest.h>',
      '',
      '// TODO: #include "' .. subject .. '.h"',
      '',
      'TEST(' .. subject .. 'Test, BasicAssertion) {',
      '    EXPECT_TRUE(true);',
      '}',
      '',
      'int main(int argc, char** argv) {',
      '    ::testing::InitGoogleTest(&argc, argv);',
      '    return RUN_ALL_TESTS();',
      '}',
    }
  end
end

-- ── Prompt helpers ────────────────────────────────────────────────────────────
local function prompt_ns(cb)
  ui().select({
    { id = '__none__', label = '(no namespace)' },
    { id = '__custom__', label = '󰏫 Enter namespace…' },
  }, { prompt = 'Namespace', format_item = plain }, function(choice)
    if not choice or choice.id == '__none__' then
      cb(nil); return
    end
    ui().input({ prompt = 'Namespace name' }, function(ns)
      cb(ns ~= '' and ns or nil)
    end)
  end)
end

local function prompt_fields(cb)
  ui().input({
    prompt  = 'Fields (type:name, …) e.g. int:age,std::string:name',
    default = '',
  }, function(input)
    if not input or input == '' then
      cb({}); return
    end
    local fields = {}
    for pair in input:gmatch('[^,]+') do
      local typ, nm = pair:match('%s*([^:]+):([^:]+)%s*')
      if typ and nm then
        fields[#fields + 1] = { typ = vim.trim(typ), name = vim.trim(nm) }
      end
    end
    cb(fields)
  end)
end

local function prompt_methods(cb)
  ui().input({
    prompt  = 'Method signatures (semicolon-separated)',
    default = 'void doSomething()',
  }, function(input)
    if not input or input == '' then
      cb({}); return
    end
    local methods = {}
    for m in input:gmatch('[^;]+') do
      local t = vim.trim(m); if t ~= '' then methods[#methods + 1] = t end
    end
    cb(methods)
  end)
end

-- Ask user to pick extra includes for a new file, show lib detection results
local function prompt_includes(cb)
  ui().select({
    { id = '__none__', label = '(no extra includes)' },
    { id = '__custom__', label = '󰏫 Add includes…', desc = 'e.g. <thread>,<openssl/ssl.h>' },
  }, { prompt = 'Extra #includes (for auto-link detection)', format_item = plain }, function(choice)
    if not choice or choice.id == '__none__' then
      cb({}); return
    end
    ui().input({ prompt = 'Includes (comma-separated)', default = '' }, function(raw)
      if not raw or raw == '' then
        cb({}); return
      end
      local includes = {}
      for inc in raw:gmatch('[^,]+') do
        local t = vim.trim(inc)
        -- Wrap bare names in <> if missing delimiters
        if t ~= '' then
          if not t:match('^[<"]') then t = '<' .. t .. '>' end
          includes[#includes + 1] = t
        end
      end
      cb(includes)
    end)
  end)
end

-- ── Resolve source/include dirs from project ─────────────────────────────────
local function resolve_dirs(p)
  local src = vim.fn.isdirectory(p.root .. '/src') == 1 and 'src' or ''
  local inc = vim.fn.isdirectory(p.root .. '/include') == 1 and 'include' or src
  return src, inc
end

-- ── Entry points ──────────────────────────────────────────────────────────────

function M.create_class(on_back)
  local p = det().get()
  if not p then return end
  local src_dir, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰙲 Class name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_ns(function(ns)
        ui().select({
          { id = 'default',   label = 'Default (constructor + destructor)' },
          { id = 'copy',      label = '+ Copy semantics' },
          { id = 'move',      label = '+ Move semantics' },
          { id = 'rule_of_5', label = '+ Rule of 5 (copy + move)' },
        }, { prompt = 'Class type', format_item = plain }, function(kind)
          -- Optionally prompt for methods
          ui().select({
            { id = 'yes', label = 'Yes — declare methods now' },
            { id = 'no', label = 'No — just constructor/destructor' },
          }, { prompt = 'Add method signatures?', format_item = plain }, function(do_methods)
            local function after_methods(methods)
              prompt_fields(function(fields)
                prompt_includes(function(includes)
                  local links  = M.detect_links_for_includes(includes, p)
                  local opts   = {
                    ns       = ns,
                    inc_dir  = inc_dir ~= '' and inc_dir or nil,
                    copy     = kind and (kind.id == 'copy' or kind.id == 'rule_of_5'),
                    move     = kind and (kind.id == 'move' or kind.id == 'rule_of_5'),
                    methods  = methods,
                    fields   = fields,
                    includes = includes,
                  }
                  local h_path = p.root
                      .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
                      .. '/' .. name .. '.h'
                  local c_path = p.root
                      .. (src_dir ~= '' and ('/' .. src_dir) or '')
                      .. '/' .. name .. '.cpp'
                  write(h_path, class_header(name, opts), 'Header')
                  write(c_path, class_source(name, opts), 'Source')
                  notify_link_suggestions(links, p)
                end)
              end)
            end
            if do_methods and do_methods.id == 'yes' then
              prompt_methods(function(methods)
                vim.schedule(function() after_methods(methods) end)
              end)
            else
              after_methods({})
            end
          end)
        end)
      end)
    end)
  end)
end

function M.create_abstract(on_back)
  local p = det().get()
  if not p then return end
  local _, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰙲 Abstract class / interface name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_ns(function(ns)
        prompt_methods(function(methods)
          prompt_includes(function(includes)
            local links = M.detect_links_for_includes(includes, p)
            local opts  = { ns = ns, methods = methods, includes = includes }
            local path  = p.root
                .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
                .. '/' .. name .. '.h'
            write(path, abstract_header(name, opts), 'Abstract Class')
            notify_link_suggestions(links, p)
          end)
        end)
      end)
    end)
  end)
end

function M.create_struct(on_back)
  local p = det().get()
  if not p then return end
  local _, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰙲 Struct name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_ns(function(ns)
        prompt_fields(function(fields)
          prompt_includes(function(includes)
            local links = M.detect_links_for_includes(includes, p)
            local opts  = { ns = ns, fields = fields, includes = includes }
            local path  = p.root
                .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
                .. '/' .. name .. '.h'
            write(path, struct_header(name, opts), 'Struct')
            notify_link_suggestions(links, p)
          end)
        end)
      end)
    end)
  end)
end

function M.create_enum(on_back)
  local p = det().get()
  if not p then return end
  local _, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰒻 Enum name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      ui().input({ prompt = 'Values (comma-separated)', default = 'ValueA, ValueB, ValueC' }, function(raw)
        local values = {}
        for v in (raw or ''):gmatch('[^,]+') do
          values[#values + 1] = vim.trim(v)
        end
        prompt_ns(function(ns)
          local opts = { ns = ns, values = values }
          local path = p.root
              .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
              .. '/' .. name .. '.h'
          write(path, enum_header(name, opts), 'Enum')
        end)
      end)
    end)
  end)
end

function M.create_header_only(on_back)
  local p = det().get()
  if not p then return end
  local _, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰈙 Header-only file name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_ns(function(ns)
        prompt_includes(function(includes)
          local links = M.detect_links_for_includes(includes, p)
          local g     = guard(name)
          local lines = {
            '#pragma once',
            '#ifndef ' .. g,
            '#define ' .. g,
            '',
          }
          if #includes > 0 then
            for _, inc in ipairs(includes) do
              lines[#lines + 1] = '#include ' .. inc
            end
            lines[#lines + 1] = ''
          end
          if ns then
            lines[#lines + 1] = 'namespace ' .. ns .. ' {'
            lines[#lines + 1] = ''
          end
          lines[#lines + 1] = '// TODO: implement ' .. name
          if ns then
            lines[#lines + 1] = ''
            lines[#lines + 1] = '} // namespace ' .. ns
          end
          lines[#lines + 1] = ''
          lines[#lines + 1] = '#endif // ' .. g
          local path = p.root
              .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
              .. '/' .. name .. '.hpp'
          write(path, lines, 'Header-only')
          notify_link_suggestions(links, p)
        end)
      end)
    end)
  end)
end

function M.create_test(on_back)
  local p = det().get()
  if not p then return end

  ui().input({ prompt = '󰙨 Subject / class under test' }, function(subject)
    if not subject or subject == '' then return end
    vim.schedule(function()
      ui().select({
        { id = 'gtest',  label = 'GoogleTest (gtest)' },
        { id = 'catch2', label = 'Catch2' },
      }, { prompt = 'Test framework', format_item = plain }, function(fw)
        local framework = fw and fw.id or 'gtest'
        local lines     = test_file(subject, { framework = framework, subject = subject })
        -- Auto-detect links for the chosen framework
        local fw_inc    = framework == 'catch2'
            and { '<catch2/catch_test_macros.hpp>' }
            or { '<gtest/gtest.h>' }
        local links     = M.detect_links_for_includes(fw_inc, p)
        local test_dir  = vim.fn.isdirectory(p.root .. '/tests') == 1 and 'tests'
            or (vim.fn.isdirectory(p.root .. '/test') == 1 and 'test' or 'tests')
        local path      = p.root .. '/' .. test_dir .. '/' .. subject .. '_test.cpp'
        write(path, lines, 'Test')
        notify_link_suggestions(links, p)
      end)
    end)
  end)
end

function M.create_main(on_back)
  local p = det().get()
  if not p then return end
  local src_dir, _ = resolve_dirs(p)
  local c          = cfg()

  local is_cpp     = (c.compiler == 'g++' or c.compiler == 'clang++')
  local ext        = is_cpp and '.cpp' or '.c'

  prompt_includes(function(includes)
    local links = M.detect_links_for_includes(includes, p)
    local lines = {}
    if is_cpp then
      lines[#lines + 1] = '#include <iostream>'
    else
      lines[#lines + 1] = '#include <stdio.h>'
    end
    for _, inc in ipairs(includes) do
      lines[#lines + 1] = '#include ' .. inc
    end
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'int main(int argc, char* argv[]) {'
    if is_cpp then
      lines[#lines + 1] = '    std::cout << "Hello, World!" << std::endl;'
    else
      lines[#lines + 1] = '    printf("Hello, World!\\n");'
    end
    lines[#lines + 1] = '    return 0;'
    lines[#lines + 1] = '}'

    local path = p.root
        .. (src_dir ~= '' and ('/' .. src_dir) or '')
        .. '/main' .. ext
    write(path, lines, 'main' .. ext)
    notify_link_suggestions(links, p)
  end)
end

-- ── Scan project and show full link report ────────────────────────────────────
function M.show_link_report()
  local p = det().get()
  if not p then
    vim.notify('[Marvin] No C/C++ project detected', vim.log.levels.WARN); return
  end
  local detected = scan_project_includes(p.root)
  if #detected == 0 then
    vim.notify('[Marvin] No known library includes detected in project', vim.log.levels.INFO)
    return
  end
  local already = p.type == 'cmake' and scan_cmake_links(p.root) or {}
  local links   = build_link_suggestions(detected, already)

  local lines   = { '', '  Detected Library Dependencies', '  ' .. string.rep('─', 40), '' }
  for _, entry in ipairs(detected) do
    local note = entry.header_only and '(header-only)' or (entry.lib or '')
    lines[#lines + 1] = string.format('  %-28s %s', entry.include, note)
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '  Suggested Link Flags'
  lines[#lines + 1] = '  ' .. string.rep('─', 40)
  if links.ldflags ~= '' then
    lines[#lines + 1] = '  LDFLAGS:  ' .. links.ldflags
  end
  if #links.cmake > 0 then
    lines[#lines + 1] = '  CMake:    target_link_libraries(<target> '
        .. table.concat(links.cmake, ' ') .. ')'
  end
  if #links.pkg_config > 0 then
    lines[#lines + 1] = '  pkg-cfg:  ' .. table.concat(links.pkg_config, ' ')
  end
  lines[#lines + 1] = ''
  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items()
  local items = {}
  local function sep(l) items[#items + 1] = { label = l, is_separator = true } end
  local function it(id, icon, label, desc)
    items[#items + 1] = { id = id, label = icon .. ' ' .. label, desc = desc }
  end

  sep('Create')
  it('cr_class', '󰙲', 'New Class', 'Header + source pair, auto-link detection')
  it('cr_abstract', '󰦊', 'New Abstract Class', 'Pure virtual interface header')
  it('cr_struct', '󰙲', 'New Struct', 'POD struct header')
  it('cr_enum', '󰒻', 'New Enum', 'enum class header')
  it('cr_header_only', '󰈙', 'New Header-only', 'Single .hpp file')
  it('cr_test', '󰙨', 'New Test File', 'GoogleTest or Catch2 scaffold + link hints')
  it('cr_main', '󰐊', 'New main.cpp', 'Entry point + include-based link detection')

  sep('Analysis')
  it('cr_link_report', '󰘦', 'Link Report', 'Scan project includes → suggest LDFLAGS')
  it('cr_makefile', '󰈙', 'New/Regenerate Makefile', 'Interactive Makefile wizard')
  return items
end

function M.handle(id, on_back)
  if id == 'cr_class' then
    M.create_class(on_back)
  elseif id == 'cr_abstract' then
    M.create_abstract(on_back)
  elseif id == 'cr_struct' then
    M.create_struct(on_back)
  elseif id == 'cr_enum' then
    M.create_enum(on_back)
  elseif id == 'cr_header_only' then
    M.create_header_only(on_back)
  elseif id == 'cr_test' then
    M.create_test(on_back)
  elseif id == 'cr_main' then
    M.create_main(on_back)
  elseif id == 'cr_link_report' then
    M.show_link_report()
  elseif id == 'cr_makefile' then
    local p = det().get()
    require('marvin.makefile_creator').create(p and p.root or vim.fn.getcwd(), on_back)
  else
    return false
  end
  return true
end

return M
