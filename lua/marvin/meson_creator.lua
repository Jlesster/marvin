-- lua/marvin/meson_creator.lua
-- Interactive meson.build wizard.
--
-- Detection pipeline:
--   • pkg-config deps         → header scan against dynamic PKG_CONFIG_MAP
--   • find_library() deps     → symbol scan against SYMBOL_LIB_MAP (libm, librt, etc.)
--   • multi-executable guard  → detects multiple main() → splits executables
--   • POSIX define            → source scan for POSIX symbols
--   • wlroots guard           → header scan for #include <wlr/...>
--   • wayland-server guard    → symbol scan for wl_display_* usage
--   • xkbcommon guard         → header scan for <xkbcommon/...>
--   • include dirs            → filesystem walk
--   • sources                 → filesystem walk (explicit files(), no globs)
--   • linker symbol audit     → post-collection ldd cross-check (optional)

local M = {}

local function ui() return require('marvin.ui') end
local function plain(it) return it.label end

-- ── write helpers ─────────────────────────────────────────────────────────────

local function write(path, content, name)
  local f = io.open(path, 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. path, vim.log.levels.ERROR)
    return false
  end
  f:write(content); f:close()
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.notify('[Marvin] meson.build created for: ' .. name, vim.log.levels.INFO)
  return true
end

local function check_existing(path, content, name)
  if vim.fn.filereadable(path) == 1 then
    ui().select({
        { id = 'overwrite', label = 'Overwrite', desc = 'Replace existing meson.build' },
        { id = 'cancel',    label = 'Cancel',    desc = 'Keep existing file' },
      }, { prompt = 'meson.build already exists', format_item = plain },
      function(ch)
        if ch and ch.id == 'overwrite' then write(path, content, name) end
      end)
    return
  end
  write(path, content, name)
end

-- ── language detection ────────────────────────────────────────────────────────

local function infer_lang(root)
  if #vim.fn.globpath(root, '**/*.cpp', false, true) > 0 then return 'cpp' end
  if #vim.fn.globpath(root, '**/*.cxx', false, true) > 0 then return 'cpp' end
  if #vim.fn.globpath(root, '**/*.c', false, true) > 0 then return 'c' end
  return nil
end

-- ── source collection ─────────────────────────────────────────────────────────

local SKIP = { '/builddir/', '/build/', '/.marvin%-obj/', '/%.git/' }
local function skip(p)
  for _, pat in ipairs(SKIP) do if p:find(pat, 1, false) then return true end end
  return false
end

local function collect_sources(dir, lang)
  local exts = lang == 'cpp'
      and { '**/*.cpp', '**/*.cxx', '**/*.cc' }
      or { '**/*.c' }
  local seen, rel = {}, {}
  for _, pat in ipairs(exts) do
    for _, f in ipairs(vim.fn.globpath(dir, pat, false, true)) do
      if not skip(f) then
        local r = f:sub(#dir + 2)
        if r ~= '' and not seen[r] then
          seen[r] = true; rel[#rel + 1] = "  '" .. r .. "'"
        end
      end
    end
  end
  if #rel == 0 then return 'files()' end
  table.sort(rel)
  return 'files(\n' .. table.concat(rel, ',\n') .. '\n)'
end

-- ── include directory collection ──────────────────────────────────────────────

local function collect_include_dirs(root)
  local seen, dirs = {}, {}
  for _, pat in ipairs({ '**/*.h', '**/*.hpp', '**/*.hxx' }) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
      if not skip(f) then
        local dir = vim.fn.fnamemodify(f, ':h')
        local rel = dir:sub(#root + 2)
        if rel == '' then rel = '.' end
        if not seen[rel] then
          seen[rel] = true; dirs[#dirs + 1] = rel
        end
      end
    end
  end
  if #dirs == 0 then
    return "include_directories('include')", { 'include' }
  end
  table.sort(dirs)
  local quoted = {}
  for _, d in ipairs(dirs) do quoted[#quoted + 1] = "  '" .. d .. "'" end
  return 'include_directories(\n' .. table.concat(quoted, ',\n') .. '\n)', dirs
end

-- ── wlroots guard ─────────────────────────────────────────────────────────────

local function scan_needs_wlr_unstable(root)
  for _, pat in ipairs({ '**/*.c', '**/*.cpp', '**/*.cxx', '**/*.h', '**/*.hpp', '**/*.hxx' }) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
      if not skip(f) then
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

-- ── pkg-config scan ───────────────────────────────────────────────────────────

local _hdr_pkg_map_cache = nil
local function get_hdr_pkg_map()
  if _hdr_pkg_map_cache then return _hdr_pkg_map_cache end
  local map = {}

  local h = io.popen('pkg-config --list-all 2>/dev/null')
  if not h then
    _hdr_pkg_map_cache = map; return map
  end
  local pkgs = {}
  for line in h:lines() do
    local name = line:match('^(%S+)')
    if name then pkgs[#pkgs + 1] = name end
  end
  h:close()

  local scanned = {}
  for _, pkg in ipairs(pkgs) do
    local dirs = {}
    local ch = io.popen('pkg-config --cflags-only-I ' .. pkg .. ' 2>/dev/null')
    if ch then
      local out = ch:read('*a'); ch:close()
      for token in out:gmatch('%S+') do
        if token:sub(1, 2) == '-I' then dirs[#dirs + 1] = token:sub(3) end
      end
    end
    local ih = io.popen('pkg-config --variable=includedir ' .. pkg .. ' 2>/dev/null')
    if ih then
      local d = vim.trim(ih:read('*l') or ''); ih:close()
      if d ~= '' then dirs[#dirs + 1] = d end
    end
    local stem = pkg:match('^([%a%d]+)')
    if stem then
      for _, base in ipairs({ '/usr/include', '/usr/local/include' }) do
        if vim.fn.isdirectory(base .. '/' .. stem) == 1 then
          dirs[#dirs + 1] = base
          dirs[#dirs + 1] = base .. '/' .. stem
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
              local sh = io.popen('ls ' .. vim.fn.shellescape(dir .. '/' .. entry) .. ' 2>/dev/null')
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
local _pkg_resolve_cache = {}
local function resolve_pkg(base)
  if _pkg_resolve_cache[base] ~= nil then return _pkg_resolve_cache[base] or nil end
  if os.execute('pkg-config --exists ' .. base .. ' 2>/dev/null') == 0 then
    _pkg_resolve_cache[base] = base; return base
  end
  local h = io.popen(
    "pkg-config --list-all 2>/dev/null | grep -E '^" .. base .. "[-[:space:]]' | head -1 | awk '{print $1}'")
  if h then
    local found = vim.trim(h:read('*l') or ''); h:close()
    if found ~= '' then
      _pkg_resolve_cache[base] = found; return found
    end
  end
  _pkg_resolve_cache[base] = false; return nil
end

local function detect_pkg_deps(root)
  local patterns = { '*.c', '*.cpp', '*.h', '*.hpp', '*.cxx', '*.hxx' }
  local found    = {}
  local ordered  = {}

  for _, pat in ipairs(patterns) do
    for _, f in ipairs(vim.fn.globpath(root, '**/' .. pat, false, true)) do
      if not skip(f) then
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

-- ── meson variable name sanitiser ─────────────────────────────────────────────

local function var(pkg) return pkg:gsub('[%-.]', '_') end

-- ── find_library() dependency detection ──────────────────────────────────────
--
-- Libraries that are NOT exposed via pkg-config but are needed at link time.
-- We detect them by scanning for:
--   1. Known headers that map to find_library() deps
--   2. Known C function calls / symbols that imply a library
--   3. Known #include patterns that pkg-config misses
--
-- Each entry: { header_patterns, symbol_patterns, lib_name, var_name }
-- lib_name is what you pass to find_library('lib_name')

local FIND_LIBRARY_RULES = {
  -- libm: math.h usage + any of the common math functions
  {
    headers = { 'math%.h', 'complex%.h', 'fenv%.h', 'tgmath%.h' },
    symbols = {
      'roundf?%s*%(', 'floorf?%s*%(', 'ceilf?%s*%(', 'sqrtf?%s*%(',
      'powf?%s*%(', 'fabsf?%s*%(', 'logf?%s*%(', 'expf?%s*%(',
      'sinf?%s*%(', 'cosf?%s*%(', 'tanf?%s*%(', 'atan2f?%s*%(',
      'fmaf?%s*%(', 'hypotf?%s*%(', 'truncf?%s*%(', 'fmodf?%s*%(',
      'remainderf?%s*%(', 'nanf?%s*%(', 'isinf%s*%(', 'isnan%s*%(',
    },
    lib     = 'm',
    vname   = 'm',
  },
  -- librt: POSIX realtime extensions
  {
    headers = { 'time%.h', 'aio%.h', 'mqueue%.h' },
    symbols = {
      'clock_gettime%s*%(', 'clock_nanosleep%s*%(', 'timer_create%s*%(',
      'shm_open%s*%(', 'mq_open%s*%(', 'aio_read%s*%(',
    },
    lib     = 'rt',
    vname   = 'rt',
  },
  -- libdl: dynamic loading
  {
    headers = { 'dlfcn%.h' },
    symbols = { 'dlopen%s*%(', 'dlsym%s*%(', 'dlclose%s*%(', 'dlerror%s*%(' },
    lib     = 'dl',
    vname   = 'dl',
  },
  -- libpthread: POSIX threads (when not using dependency('threads'))
  {
    headers = { 'pthread%.h', 'semaphore%.h' },
    symbols = {
      'pthread_create%s*%(', 'pthread_mutex_lock%s*%(',
      'pthread_cond_wait%s*%(', 'sem_init%s*%(',
    },
    lib     = 'pthread',
    vname   = 'pthread',
  },
}

-- Scan all source+header files; return list of find_library() deps needed.
local function detect_find_library_deps(root)
  -- Collect all file content once
  local all_lines = {}
  for _, pat in ipairs({ '**/*.c', '**/*.cpp', '**/*.cxx', '**/*.h', '**/*.hpp', '**/*.hxx' }) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
      if not skip(f) then
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            all_lines[#all_lines + 1] = line
          end
        end
      end
    end
  end

  local result = {}
  for _, rule in ipairs(FIND_LIBRARY_RULES) do
    local matched = false

    -- 1. Header match
    for _, line in ipairs(all_lines) do
      local inc = line:match('#%s*include%s*[<\"]([^>\"]+)[>\"]')
      if inc then
        for _, hpat in ipairs(rule.headers) do
          if inc:match(hpat) then
            matched = true; break
          end
        end
      end
      if matched then break end
    end

    -- 2. Symbol match (only scan if header matched to avoid false positives)
    if matched then
      local sym_matched = false
      for _, line in ipairs(all_lines) do
        for _, spat in ipairs(rule.symbols) do
          if line:match(spat) then
            sym_matched = true; break
          end
        end
        if sym_matched then break end
      end
      -- Require BOTH header AND at least one symbol call to be confident
      if sym_matched then
        result[#result + 1] = { lib = rule.lib, vname = rule.vname }
      end
    end
  end
  return result
end

-- ── wayland-server detection ──────────────────────────────────────────────────
--
-- wlroots wraps wayland-server but --as-needed means we must link it explicitly
-- if we call wl_* functions directly. Detect direct wl_display / wl_event_loop
-- usage in source files.

local WL_SERVER_SYMBOLS = {
  'wl_display_create', 'wl_display_run', 'wl_display_destroy',
  'wl_display_add_socket', 'wl_display_get_event_loop',
  'wl_event_loop_add_fd', 'wl_event_loop_add_timer',
  'wl_event_source_remove', 'wl_global_create',
  'wl_resource_create', 'wl_resource_post_event',
  'wl_list_init', 'wl_list_insert', 'wl_list_remove',
  'wl_signal_init', 'wl_signal_add', 'wl_signal_emit',
}

local function detect_needs_wayland_server(root)
  for _, pat in ipairs({ '**/*.c', '**/*.cpp', '**/*.h', '**/*.hpp' }) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
      if not skip(f) then
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            for _, sym in ipairs(WL_SERVER_SYMBOLS) do
              if line:match(sym) then return true end
            end
          end
        end
      end
    end
  end
  return false
end

-- ── xkbcommon detection ───────────────────────────────────────────────────────

local function detect_needs_xkbcommon(root)
  for _, pat in ipairs({ '**/*.c', '**/*.cpp', '**/*.h', '**/*.hpp' }) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
      if not skip(f) then
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            if line:match('#%s*include%s*[<\"]xkbcommon/') then return true end
            if line:match('xkb_context_new') or line:match('xkb_keymap_') or
                line:match('xkb_keysym_') or line:match('xkb_state_') then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

-- ── multi-main detection ──────────────────────────────────────────────────────
--
-- If multiple .c files each define main(), they cannot be linked into a single
-- executable. We detect this and split them into separate executable() blocks.

local function detect_main_files(root, lang)
  local ext_pats = lang == 'cpp'
      and { '**/*.cpp', '**/*.cxx', '**/*.cc' }
      or { '**/*.c' }

  -- Regex patterns that match a main() definition (not a call or declaration)
  local MAIN_PATS = {
    '^%s*int%s+main%s*%(',
    '^%s*int%s+main%s*%(%s*void%s*%)',
    '^%s*int%s+main%s*%(%s*int%s+argc',
  }

  local mains = {} -- { path = rel_path, file = basename }
  for _, pat in ipairs(ext_pats) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
      if not skip(f) then
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            local found = false
            for _, mp in ipairs(MAIN_PATS) do
              if line:match(mp) then
                found = true; break
              end
            end
            if found then
              local rel = f:sub(#root + 2)
              mains[#mains + 1] = {
                path = rel,
                base = vim.fn.fnamemodify(f, ':t:r'),  -- filename without ext
              }
              break
            end
          end
        end
      end
    end
  end
  return mains
end

-- ── POSIX detection ───────────────────────────────────────────────────────────

local POSIX_SYMBOLS = {
  'getaddrinfo', 'getnameinfo', 'setenv', 'unsetenv',
  'strndup', 'strsignal', 'sigaction', 'strptime',
  'opendir', 'readdir', 'scandir', 'nftw',
  'pthread_', 'sem_init', 'mmap', 'munmap',
  'clock_gettime', 'nanosleep', 'usleep',
  'mkstemp', 'realpath', 'readlink',
}

local function detect_needs_posix(root)
  for _, pat in ipairs({ '**/*.c', '**/*.cpp', '**/*.h', '**/*.hpp' }) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
      if not skip(f) then
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            if line:match('_POSIX_C_SOURCE') or line:match('_XOPEN_SOURCE') then
              return true
            end
            for _, sym in ipairs(POSIX_SYMBOLS) do
              if line:match(sym) then return true end
            end
          end
        end
      end
    end
  end
  return false
end

-- ── canonical auto-detection ──────────────────────────────────────────────────

local function auto_detect(root, lang)
  local extra_cargs = {}
  local needs_posix = false
  local wlr_guard   = false
  local pkg_deps    = {}

  -- 1. Try the marvin build module first (existing behaviour)
  local ok_b, build = pcall(require, 'marvin.build')
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

  -- 2. Fallback: run our own pkg-config header scan
  if #pkg_deps == 0 then
    pkg_deps = detect_pkg_deps(root)
  end

  -- 3. wlroots guard (own scan, more reliable than build module)
  if not wlr_guard then
    wlr_guard = scan_needs_wlr_unstable(root)
  end

  -- 4. POSIX detection
  if not needs_posix then
    needs_posix = detect_needs_posix(root)
  end

  -- 5. wayland-server: add if not already picked up by pkg-config scan
  local has_wayland_server = false
  for _, d in ipairs(pkg_deps) do
    if d:match('wayland%-server') then
      has_wayland_server = true; break
    end
  end
  if not has_wayland_server and detect_needs_wayland_server(root) then
    pkg_deps[#pkg_deps + 1] = 'wayland-server'
  end

  -- 6. xkbcommon: same pattern
  local has_xkb = false
  for _, d in ipairs(pkg_deps) do
    if d:match('xkbcommon') then
      has_xkb = true; break
    end
  end
  if not has_xkb and detect_needs_xkbcommon(root) then
    pkg_deps[#pkg_deps + 1] = 'xkbcommon'
  end

  -- 7. find_library() deps (libm, librt, libdl, libpthread)
  local find_lib_deps = detect_find_library_deps(root)

  if wlr_guard then
    extra_cargs[#extra_cargs + 1] = '-DWLR_USE_UNSTABLE'
  end

  return {
    pkg_deps      = pkg_deps,
    find_lib_deps = find_lib_deps,
    needs_posix   = needs_posix,
    wlr_guard     = wlr_guard,
    extra_cargs   = extra_cargs,
  }
end

-- ── template ──────────────────────────────────────────────────────────────────

local function meson_template(opts)
  local lines = {}
  local function l(s) lines[#lines + 1] = (s or '') end

  local lang_str = opts.lang == 'cpp' and 'cpp' or 'c'
  local std_key  = opts.lang == 'cpp' and 'cpp_std' or 'c_std'

  -- project()
  l("project('" .. opts.name .. "',")
  l("  '" .. lang_str .. "',")
  l("  version : '" .. (opts.version or '0.1.0') .. "',")
  l("  default_options : [")
  l("    'warning_level=3',")
  l("    '" .. std_key .. '=' .. opts.std .. "',")
  l("    'buildtype=debugoptimized',")
  l("  ]")
  l(')')
  l()

  -- sources
  l('# ── Sources ──────────────────────────────────────────────────────────────────')
  -- If multiple mains were detected, we'll use shared_src for the common files
  local multi_exe = opts.multi_exe and #opts.multi_exe > 1
  if multi_exe then
    l('# Shared sources (no main)')
    l('shared_src = ' .. opts.shared_src_decl)
  else
    l('src = ' .. opts.src_decl)
  end
  l()

  -- include directories
  l('# ── Include directories ──────────────────────────────────────────────────────')
  local inc_decl = opts.inc_decl
  if opts.protocol_xmls and #opts.protocol_xmls > 0 then
    if inc_decl:find("'include/protocols'") == nil then
      inc_decl = inc_decl:gsub('%)', ",\n  'include/protocols'\n)", 1)
    end
  end
  l('inc = ' .. inc_decl)
  l()

  -- dependencies: find_library() first (cc must be declared first)
  local dep_names     = opts.dep_names or {}
  local find_lib_deps = opts.find_lib_deps or {}
  local all_dep_refs  = {}

  if #find_lib_deps > 0 or #dep_names > 0 then
    l('# ── Dependencies ─────────────────────────────────────────────────────────────')

    -- find_library() deps need the compiler object
    if #find_lib_deps > 0 then
      l('cc = meson.get_compiler(\'' .. lang_str .. '\')')
      for _, fd in ipairs(find_lib_deps) do
        l(fd.vname .. "_dep = cc.find_library('" .. fd.lib .. "', required : true)")
        all_dep_refs[#all_dep_refs + 1] = fd.vname .. '_dep'
      end
    end

    -- pkg-config deps
    for _, dep in ipairs(dep_names) do
      if dep == 'threads' then
        l(var(dep) .. "_dep = dependency('threads')")
      else
        l(var(dep) .. "_dep = dependency('" .. dep .. "', required : true)")
      end
      all_dep_refs[#all_dep_refs + 1] = var(dep) .. '_dep'
    end
    l()
  end

  -- c_args
  local c_args = vim.deepcopy(opts.extra_cargs or {})
  if opts.needs_posix then
    local has = false
    for _, a in ipairs(c_args) do
      if a == '-D_POSIX_C_SOURCE=200809L' then
        has = true; break
      end
    end
    if not has then c_args[#c_args + 1] = '-D_POSIX_C_SOURCE=200809L' end
  end
  if opts.sanitizer and opts.sanitizer ~= 'none' then
    local sflag = opts.sanitizer == 'asan' and 'address'
        or opts.sanitizer == 'tsan' and 'thread'
        or 'undefined'
    c_args[#c_args + 1] = '-fsanitize=' .. sflag
    c_args[#c_args + 1] = '-fno-omit-frame-pointer'
  end

  -- Wayland protocol generation
  local protocol_xmls = opts.protocol_xmls or {}
  if #protocol_xmls > 0 then
    l('# ── Wayland protocol generation ──────────────────────────────────────────────')
    l("wayland_scanner = find_program('wayland-scanner')")
    l()
    l('protocol_src = []')
    for _, xml in ipairs(protocol_xmls) do
      local stem    = xml:gsub('%.xml$', '')
      local varname = stem:gsub('%-', '_')
      local xml_ref = "files('include/protocols/" .. xml .. "')"
      l(varname .. '_h = custom_target(')
      l("  '" .. stem .. "-client-header',")
      l("  input  : " .. xml_ref .. ",")
      l("  output : '" .. stem .. "-protocol.h',")
      l("  command: [wayland_scanner, 'client-header', '@INPUT@', '@OUTPUT@'],")
      l(')')
      l(varname .. '_c = custom_target(')
      l("  '" .. stem .. "-private-code',")
      l("  input  : " .. xml_ref .. ",")
      l("  output : '" .. stem .. "-protocol.c',")
      l("  command: [wayland_scanner, 'private-code', '@INPUT@', '@OUTPUT@'],")
      l(')')
      l('protocol_src += [' .. varname .. '_h, ' .. varname .. '_c]')
      l()
    end
  end

  -- executable(s)
  l('# ── Executable ───────────────────────────────────────────────────────────────')

  local deps_str = ''
  if #all_dep_refs > 0 then
    deps_str = table.concat(all_dep_refs, ', ')
  end
  local c_args_str = ''
  if #c_args > 0 then
    local quoted = vim.tbl_map(function(a) return "'" .. a .. "'" end, c_args)
    c_args_str = table.concat(quoted, ', ')
  end

  local function write_exe(exename, src_expr)
    l("exe = executable('" .. exename .. "',")
    l('  ' .. src_expr .. ',')
    l('  include_directories : inc,')
    if deps_str ~= '' then
      l('  dependencies        : [' .. deps_str .. '],')
    end
    if c_args_str ~= '' then
      l('  c_args              : [' .. c_args_str .. '],')
    end
    l("  link_args           : ['-Wl,--as-needed'],")
    l('  install             : false,')
    l(')')
  end

  if multi_exe then
    -- One executable per main() file, sharing common sources
    local proto_suffix = #protocol_xmls > 0 and ' + protocol_src' or ''
    for _, m in ipairs(opts.multi_exe) do
      write_exe(m.base, "shared_src + files('" .. m.path .. "')" .. proto_suffix)
      l()
    end
  else
    local proto_suffix = #protocol_xmls > 0 and 'src + protocol_src' or 'src'
    write_exe(opts.name, proto_suffix)
    l()
  end

  -- optional: tests
  if opts.testing and opts.test_framework ~= 'none' then
    l('# ── Tests ────────────────────────────────────────────────────────────────────')
    if opts.test_framework == 'gtest' then
      l("gtest_dep = dependency('gtest', main : true, required : true)")
      l('test_src = ' .. opts.test_src_decl)
      l("test_exe = executable('" .. opts.name .. "_tests',")
      l('  test_src,')
      l('  include_directories : inc,')
      l('  dependencies        : [gtest_dep],')
      l(')')
      l("test('" .. opts.name .. " unit tests', test_exe)")
    elseif opts.test_framework == 'catch2' then
      l("catch2_dep = dependency('catch2-with-main', required : true)")
      l('test_src = ' .. opts.test_src_decl)
      l("test_exe = executable('" .. opts.name .. "_tests',")
      l('  test_src,')
      l('  include_directories : inc,')
      l('  dependencies        : [catch2_dep],')
      l(')')
      l("test('" .. opts.name .. " unit tests', test_exe)")
    else
      l("# test_exe = executable('" .. opts.name .. "_tests', ...)")
      l("# test('" .. opts.name .. " tests', test_exe)")
    end
    l()
  end

  -- optional: install
  if opts.install then
    local inc_dir = (opts.inc_dirs and #opts.inc_dirs > 0) and opts.inc_dirs[1] or 'include'
    l('# ── Install ──────────────────────────────────────────────────────────────────')
    l("install_subdir('" .. inc_dir .. "',")
    l("  install_dir : get_option('includedir') / '" .. opts.name .. "'")
    l(')')
    l()
  end

  return table.concat(lines, '\n') .. '\n'
end

-- ── wizard ────────────────────────────────────────────────────────────────────

function M.create(root, on_back)
  root                = root or vim.fn.getcwd()
  local default_name  = vim.fn.fnamemodify(root, ':t')
  local detected_lang = infer_lang(root)

  ui().input({ prompt = '󰬷 Project name', default = default_name }, function(name)
    if not name or name == '' then return end

    local lang_items = {
      { id = 'cpp', label = 'C++', desc = 'cpp, .cpp sources' },
      { id = 'c',   label = 'C',   desc = 'c, .c sources' },
    }
    local lang_prompt = 'Language'
    if detected_lang then
      lang_prompt = 'Language  (detected: ' .. detected_lang .. ')'
      for i, it in ipairs(lang_items) do
        if it.id == detected_lang then
          table.remove(lang_items, i)
          table.insert(lang_items, 1, vim.tbl_extend('force', it, {
            label = it.label .. '  ✓ detected',
          }))
          break
        end
      end
    end

    ui().select(lang_items, {
      prompt      = lang_prompt,
      on_back     = on_back,
      format_item = plain,
    }, function(lang_ch)
      if not lang_ch then return end
      local lang = lang_ch.id

      local stds = lang == 'c'
          and {
            { id = 'c11', label = 'C11', desc = 'Recommended' },
            { id = 'c17', label = 'C17', desc = 'Latest stable' },
            { id = 'c99', label = 'C99', desc = 'Wide compat' },
          }
          or {
            { id = 'c++17', label = 'C++17', desc = 'Recommended' },
            { id = 'c++20', label = 'C++20', desc = 'Concepts, ranges' },
            { id = 'c++23', label = 'C++23', desc = 'Latest' },
            { id = 'c++14', label = 'C++14', desc = 'Lambdas, auto' },
          }

      ui().select(stds, { prompt = 'Language standard', format_item = plain },
        function(std_ch)
          if not std_ch then return end

          ui().select({
              { id = 'none',  label = 'None' },
              { id = 'asan',  label = 'AddressSanitizer', desc = '-fsanitize=address' },
              { id = 'tsan',  label = 'ThreadSanitizer',  desc = '-fsanitize=thread' },
              { id = 'ubsan', label = 'UBSanitizer',      desc = '-fsanitize=undefined' },
            }, { prompt = 'Sanitizer (optional)', format_item = plain },
            function(san_ch)
              ui().select({
                  { id = 'none',   label = 'No tests' },
                  { id = 'gtest',  label = 'GoogleTest',  desc = "dependency('gtest')" },
                  { id = 'catch2', label = 'Catch2',      desc = "dependency('catch2-with-main')" },
                  { id = 'custom', label = 'Custom stub', desc = 'Placeholder comments only' },
                }, { prompt = 'Test framework', format_item = plain },
                function(test_ch)
                  ui().select({
                      { id = 'no', label = 'No' },
                      { id = 'yes', label = 'Yes — add install_subdir()', desc = 'install_subdir() rule' },
                    }, { prompt = 'Add install rules?', format_item = plain },
                    function(inst_ch)
                      -- Run full detection pipeline
                      local detected   = auto_detect(root, lang)

                      -- Detect multiple main() files
                      local main_files = detect_main_files(root, lang)
                      local multi_exe  = #main_files > 1 and main_files or nil

                      -- Notify what was injected
                      local notices    = {}
                      if #detected.pkg_deps > 0 then
                        notices[#notices + 1] = 'pkg-config deps: ' .. table.concat(detected.pkg_deps, ' ')
                      end
                      if #detected.find_lib_deps > 0 then
                        local names = vim.tbl_map(function(d) return d.lib end, detected.find_lib_deps)
                        notices[#notices + 1] = 'find_library() deps: ' .. table.concat(names, ' ')
                      end
                      if detected.wlr_guard then
                        notices[#notices + 1] = 'wlroots headers → c_args: -DWLR_USE_UNSTABLE'
                      end
                      if detected.needs_posix then
                        notices[#notices + 1] = 'POSIX usage → c_args: -D_POSIX_C_SOURCE=200809L'
                      end
                      if multi_exe then
                        local bnames = vim.tbl_map(function(m) return m.base end, multi_exe)
                        notices[#notices + 1] = 'Multiple main() found → splitting executables: ' ..
                        table.concat(bnames, ', ')
                      end
                      if #notices > 0 then
                        vim.notify('[Marvin] Auto-injecting:\n  ' .. table.concat(notices, '\n  '), vim.log.levels.INFO)
                      end

                      local src_decl           = collect_sources(root, lang)
                      local test_src_decl      = collect_sources(root .. '/tests', lang)
                      local inc_decl, inc_dirs = collect_include_dirs(root)

                      -- For multi-exe: build shared_src by excluding the main() files
                      local shared_src_decl    = src_decl
                      if multi_exe then
                        local main_paths = {}
                        for _, m in ipairs(multi_exe) do main_paths[m.path] = true end
                        local shared = {}
                        for _, pat in ipairs({ '**/*.c', '**/*.cpp', '**/*.cxx' }) do
                          for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
                            if not skip(f) then
                              local rel = f:sub(#root + 2)
                              if rel ~= '' and not main_paths[rel] then
                                shared[#shared + 1] = "  '" .. rel .. "'"
                              end
                            end
                          end
                        end
                        table.sort(shared)
                        shared_src_decl = #shared > 0
                            and 'files(\n' .. table.concat(shared, ',\n') .. '\n)'
                            or 'files()'
                      end

                      if #inc_dirs > 0 then
                        vim.notify('[Marvin] Include dirs:\n  ' .. table.concat(inc_dirs, '\n  '), vim.log.levels.INFO)
                      end

                      local ok_wp, wl_proto = pcall(require, 'marvin.wayland_protocols')
                      if not ok_wp then
                        vim.notify('[Marvin] wayland_protocols module error: ' .. tostring(wl_proto), vim.log.levels
                        .WARN)
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
                        name            = name,
                        version         = '0.1.0',
                        lang            = lang,
                        std             = std_ch.id,
                        sanitizer       = san_ch and san_ch.id or 'none',
                        testing         = test_ch and test_ch.id ~= 'none',
                        test_framework  = test_ch and test_ch.id or 'none',
                        install         = inst_ch and inst_ch.id == 'yes',
                        dep_names       = detected.pkg_deps,
                        find_lib_deps   = detected.find_lib_deps,
                        needs_posix     = detected.needs_posix,
                        wlr_guard       = detected.wlr_guard,
                        extra_cargs     = detected.extra_cargs,
                        src_decl        = src_decl,
                        shared_src_decl = shared_src_decl,
                        test_src_decl   = test_src_decl,
                        inc_decl        = inc_decl,
                        inc_dirs        = inc_dirs,
                        protocol_xmls   = protocol_xmls,
                        multi_exe       = multi_exe,
                      }

                      local content = meson_template(opts)
                      check_existing(root .. '/meson.build', content, name)
                    end)
                end)
            end)
        end)
    end)
  end)
end

return M
