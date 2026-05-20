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
--
-- Protocol XML strategy:
--   wayland-protocols XMLs  → referenced via wp_dir / 'subpath' (never copied)
--   wlroots protocol XMLs   → referenced via wlr_proto_dir / 'subpath' if installed,
--                             else vendored into include/protocols/ as fallback
--   No .h/.c files are pre-generated — Meson's custom_target() does that at build time.

local M = {}

-- Exposed functions for use by other modules
M.exposed = {}

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
    local h = io.popen(
        'grep -rl --include="*.c" --include="*.cpp" --include="*.h" --include="*.hpp"'
        .. ' --include="*.cxx" --include="*.hxx"'
        .. ' -E ' .. vim.fn.shellescape([=[#\s*include\s*[<"]wlr/|WLR_USE_UNSTABLE]=])
        .. ' ' .. vim.fn.shellescape(root)
        .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
        .. ' 2>/dev/null | head -1')
    if not h then return false end
    local found = h:read('*l'); h:close()
    return found ~= nil and found ~= ''
end

-- ── pkg-config dependency resolution ──────────────────────────────────────────
--
-- On-demand: derive candidate package names from the include path and verify
-- against the cached pkg-config package list. No bulk header scanning needed.

local function include_to_pkg(inc)
    local function try_candidate(name)
        if not name or name == '' then return nil end
        local resolved = resolve_pkg(name)
        if resolved then return resolved end
        local lower = name:lower()
        if lower ~= name then
            resolved = resolve_pkg(lower)
            if resolved then return resolved end
        end
        return nil
    end

    -- Try first path component
    local first = inc:match('^([^/]+)')
    local pkg = try_candidate(first)
    if pkg then return pkg end

    -- Try filename without extension (handle paths with /)
    local fname = inc:match('([^/]+)%.h$')
    if not fname then
        -- Try to extract filename from path (e.g., "path/to/file.h" -> "file")
        local basename = inc:match('[^/]+$')
        if basename then
            fname = basename:match('(.+)%.h$')
        end
    end
    if fname then
        pkg = try_candidate(fname)
        if pkg then return pkg end
    end

    -- Try common variations: remove common prefixes/suffixes
    if first then
        -- Remove common prefixes like 'lib'
        local no_prefix = first:match('^lib(.+)' )
        if no_prefix then
            pkg = try_candidate(no_prefix)
            if pkg then return pkg end
        end
        -- Remove common suffixes
        local no_suffix = first:match('^(.+)%-[^-]+$')
        if no_suffix and no_suffix ~= first then
            pkg = try_candidate(no_suffix)
            if pkg then return pkg end
        end
    end

    -- Try additional common patterns for library naming
    if first then
        -- Try with common version suffixes removed (e.g., glib-2.0 -> glib)
        local base_no_version = first:match('^(.+)%-%d+%.%d+')
        if base_no_version then
            pkg = try_candidate(base_no_version)
            if pkg then return pkg end
        end

        -- Try removing trailing numbers or version-like patterns
        local base_no_trailing_num = first:match('^(.+)%d+$')
        if base_no_trailing_num then
            pkg = try_candidate(base_no_trailing_num)
            if pkg then return pkg end
        end

        -- Try converting underscores to hyphens (common in some libraries)
        local with_hyphens = first:gsub('_', '-')
        if with_hyphens ~= first then
            pkg = try_candidate(with_hyphens)
            if pkg then return pkg end
        end

        -- Try converting hyphens to underscores
        local with_underscores = first:gsub('-', '_')
        if with_underscores ~= first then
            pkg = try_candidate(with_underscores)
            if pkg then return pkg end
        end

        -- Try removing common suffixes like -dev, -libs, etc.
        local no_dev_suffix = first:match('^(.+)%-dev$')
        if no_dev_suffix then
            pkg = try_candidate(no_dev_suffix)
            if pkg then return pkg end
        end
        local no_libs_suffix = first:match('^(.+)%-libs$')
        if no_libs_suffix then
            pkg = try_candidate(no_libs_suffix)
            if pkg then return pkg end
        end

        -- Try removing version numbers at the end (e.g., gtk3 -> gtk)
        local no_version_num = first:match('^(.+)%d+$')
        if no_version_num then
            pkg = try_candidate(no_version_num)
            if pkg then return pkg end
        end

        -- Try adding common prefixes for libraries that don't include them in the path
        -- but do in their package names
        if not first:match('^lib') then
            local with_lib = 'lib' .. first
            pkg = try_candidate(with_lib)
            if pkg then return pkg end
        end

        -- Try handling cases where the include path has subdirectories
        -- but the package name doesn't (e.g., gtk/gtk.h -> gtk)
        if inc:match('/') then
            -- Extract the last path component before the filename
            local path_part = inc:match('^(.*)/[^/]+$')
            if path_part then
                -- Try the path part as a package name
                pkg = try_candidate(path_part)
                if pkg then return pkg end
            end
        end
    end

    return nil
end

-- Resolve a pkg name to its actual installed versioned name.
-- Uses a single pre-built lookup table from pkg-config --list-all instead of
-- spawning one process per package.
local _pkg_list_cache = nil
local function get_pkg_list()
    if _pkg_list_cache then return _pkg_list_cache end
    local set = {}
    local h = io.popen('pkg-config --list-all 2>/dev/null')
    if not h then
        -- If pkg-config is not available, return empty set
        _pkg_list_cache = set
        return set
    end
    for line in h:lines() do
        local name = line:match('^(%S+)')
        if name then set[name] = true end
    end
    h:close()
    _pkg_list_cache = set
    return set
end

local _pkg_resolve_cache = {}
local function resolve_pkg(base)
    if _pkg_resolve_cache[base] ~= nil then return _pkg_resolve_cache[base] or nil end
    local all = get_pkg_list()
    -- Handle empty package list
    if not all or next(all) == nil then
        _pkg_resolve_cache[base] = false; return nil
    end
    -- exact match
    if all[base] then
        _pkg_resolve_cache[base] = base; return base
    end
    -- versioned variant: find first entry that starts with base + common separator
    for _, sep in ipairs({ '-', '+' }) do
        local prefix = base .. sep
        for name in pairs(all) do
            if name:sub(1, #prefix) == prefix then
                _pkg_resolve_cache[base] = name; return name
            end
        end
    end
    -- Try with common prefixes removed
    if base:find('^lib') then
        local no_lib = base:sub(4)
        if all[no_lib] then
            _pkg_resolve_cache[base] = no_lib; return no_lib
        end
        for _, sep in ipairs({ '-', '+' }) do
            local prefix = no_lib .. sep
            for name in pairs(all) do
                if name:sub(1, #prefix) == prefix then
                    _pkg_resolve_cache[base] = name; return name
                end
            end
        end
    end
    -- Try adding common prefixes
    local with_lib = 'lib' .. base
    if all[with_lib] then
        _pkg_resolve_cache[base] = with_lib; return with_lib
    end
    for _, sep in ipairs({ '-', '+' }) do
        local prefix = with_lib .. sep
        for name in pairs(all) do
            if name:sub(1, #prefix) == prefix then
                _pkg_resolve_cache[base] = name; return name
            end
        end
    end
    -- Try with common suffixes removed
    if base:match('%-[^-]+$') then
        local no_suffix = base:match('^(.+)%-[^-]+$')
        if no_suffix and no_suffix ~= base then
            if all[no_suffix] then
                _pkg_resolve_cache[base] = no_suffix; return no_suffix
            end
            for _, sep in ipairs({ '-', '+' }) do
                local prefix = no_suffix .. sep
                for name in pairs(all) do
                    if name:sub(1, #prefix) == prefix then
                        _pkg_resolve_cache[base] = name; return name
                    end
                end
            end
        end
    end
    _pkg_resolve_cache[base] = false; return nil
end

-- Collect all #include lines from the project in one grep, then map them.
local function detect_pkg_deps(root)
    local found    = {}
    local ordered  = {}

    -- One grep across the whole tree is vastly faster than Lua globpath + readfile
    local grep_cmd = 'grep -rh'
        .. ' --include="*.c" --include="*.cpp" --include="*.cxx"'
        .. ' --include="*.h" --include="*.hpp" --include="*.hxx"'
        .. ' -E ' .. vim.fn.shellescape([=[^\s*#\s*include\s*[<"][^>"]+[>"]]=])
        .. ' ' .. vim.fn.shellescape(root)
        .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
        .. ' 2>/dev/null'

    local h        = io.popen(grep_cmd)
    if not h then return ordered end

    for line in h:lines() do
        local inc = line:match('#%s*include%s*[<\"]([^>\"]+)[>\"]')
        if inc then
            local pkg = include_to_pkg(inc)
            if pkg and not found[pkg] then
                found[pkg]            = true
                ordered[#ordered + 1] = pkg
            end
        end
    end
    h:close()
    return ordered
end

-- ── meson variable name sanitiser ─────────────────────────────────────────────

local function var(pkg) return pkg:gsub('[%-.]', '_') end

-- ── grep helper ───────────────────────────────────────────────────────────────

local function grep_any(root, pattern)
    local h = io.popen(
        'grep -rl --include="*.c" --include="*.cpp" --include="*.cxx"'
        .. ' --include="*.h" --include="*.hpp" --include="*.hxx"'
        .. ' -E ' .. vim.fn.shellescape(pattern)
        .. ' ' .. vim.fn.shellescape(root)
        .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
        .. ' 2>/dev/null | head -1')
    if not h then return false end
    local found = h:read('*l'); h:close()
    return found ~= nil and found ~= ''
end

-- ── find_library() dependency detection ──────────────────────────────────────

local FIND_LIBRARY_RULES = {
    {
        header_pat = [=[math\.h|complex\.h|fenv\.h|tgmath\.h]=],
        symbol_pat =
        [=[roundf?\s*\(|floorf?\s*\(|ceilf?\s*\(|sqrtf?\s*\(|powf?\s*\(|fabsf?\s*\(|logf?\s*\(|expf?\s*\(|sinf?\s*\(|cosf?\s*\(|fmaf?\s*\(|hypotf?\s*\(|truncf?\s*\(|nanf?\s*\(|isinf\s*\(|isnan\s*\(]=],
        lib = 'm',
        vname = 'm',
    },
    {
        header_pat = [=[time\.h|aio\.h|mqueue\.h]=],
        symbol_pat =
        [=[clock_gettime\s*\(|clock_nanosleep\s*\(|timer_create\s*\(|shm_open\s*\(|mq_open\s*\(|aio_read\s*\(]=],
        lib = 'rt',
        vname = 'rt',
    },
    {
        header_pat = [=[dlfcn\.h]=],
        symbol_pat = [=[dlopen\s*\(|dlsym\s*\(|dlclose\s*\(|dlerror\s*\(]=],
        lib = 'dl',
        vname = 'dl',
    },
    {
        header_pat = [=[pthread\.h|semaphore\.h]=],
        symbol_pat = [=[pthread_create\s*\(|pthread_mutex_lock\s*\(|pthread_cond_wait\s*\(|sem_init\s*\(]=],
        lib = 'pthread',
        vname = 'pthread',
    },
}

local function detect_find_library_deps(root)
    local result = {}
    for _, rule in ipairs(FIND_LIBRARY_RULES) do
        if grep_any(root, rule.header_pat) and grep_any(root, rule.symbol_pat) then
            result[#result + 1] = { lib = rule.lib, vname = rule.vname }
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
    local syms = table.concat(WL_SERVER_SYMBOLS, '|')
    local h = io.popen(
        'grep -rl --include="*.c" --include="*.cpp" --include="*.h" --include="*.hpp"'
        .. ' -E ' .. vim.fn.shellescape(syms)
        .. ' ' .. vim.fn.shellescape(root)
        .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
        .. ' 2>/dev/null | head -1')
    if not h then return false end
    local found = h:read('*l'); h:close()
    return found ~= nil and found ~= ''
end

-- ── xkbcommon detection ───────────────────────────────────────────────────────

local function detect_needs_xkbcommon(root)
    local h = io.popen(
        'grep -rl --include="*.c" --include="*.cpp" --include="*.h" --include="*.hpp"'
        .. ' -E ' ..
        vim.fn.shellescape([=[#\s*include\s*[<"]xkbcommon/|xkb_context_new|xkb_keymap_|xkb_keysym_|xkb_state_]=])
        .. ' ' .. vim.fn.shellescape(root)
        .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
        .. ' 2>/dev/null | head -1')
    if not h then return false end
    local found = h:read('*l'); h:close()
    return found ~= nil and found ~= ''
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
                                base = vim.fn.fnamemodify(f, ':t:r'), -- filename without ext
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

local POSIX_PATTERN = '_POSIX_C_SOURCE|_XOPEN_SOURCE|getaddrinfo|getnameinfo'
    .. '|setenv|unsetenv|strndup|strsignal|sigaction|strptime'
    .. '|opendir|readdir|scandir|nftw|pthread_|sem_init|mmap|munmap'
    .. '|clock_gettime|nanosleep|usleep|mkstemp|realpath|readlink'

local function detect_needs_posix(root)
    return grep_any(root, POSIX_PATTERN)
end

-- ── multi-main detection ──────────────────────────────────────────────────────
--
-- grep prints "filename:line" for each match. We collect unique filenames
-- that contain a main() definition to detect split-executable projects.

local function detect_main_files(root, lang)
    local include_pat = lang == 'cpp'
        and [=[\.(cpp|cxx|cc)$]=]
        or [=[\.c$]=]

    -- grep -rn prints "file:linenum:content" — we want files containing a main def
    local main_pat    = [=[^\s*int\s+main\s*\(]=]
    local cmd         = 'grep -rn'
        .. ' --include="*.c" --include="*.cpp" --include="*.cxx" --include="*.cc"'
        .. ' -E ' .. vim.fn.shellescape(main_pat)
        .. ' ' .. vim.fn.shellescape(root)
        .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
        .. ' 2>/dev/null'

    local mains       = {}
    local seen        = {}
    local h           = io.popen(cmd)
    if h then
        for line in h:lines() do
            local fpath = line:match('^([^:]+):')
            if fpath and not seen[fpath] and fpath:match(include_pat) then
                seen[fpath] = true
                local rel = fpath:sub(#root + 2)
                mains[#mains + 1] = {
                    path = rel,
                    base = vim.fn.fnamemodify(fpath, ':t:r'),
                }
            end
        end
        h:close()
    end
    return mains
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
    -- Only inject include/protocols/ if we have vendored XMLs in the project tree.
    -- System-referenced protocols generate their headers into the Meson build dir,
    -- which is already on the include path automatically.
    l('# ── Include directories ──────────────────────────────────────────────────────')
    local inc_decl     = opts.inc_decl
    local has_vendored = false
    for _, p in ipairs(opts.protocol_entries or {}) do
        if p.in_root then
            has_vendored = true; break
        end
    end
    if has_vendored then
        if inc_decl:find("'include/protocols'") == nil then
            inc_decl = inc_decl:gsub('%)', ",\n  'include/protocols'\n)", 1)
        end
    end
    l('inc = ' .. inc_decl)
    l()

    -- dependencies: find_library() first (cc must be declared first)
    local dep_names     = opts.dep_names or {}
    local find_lib_deps = opts.find_lib_deps or {}
    local dep_entries   = {}

    -- Determine whether we need wayland-protocols as an explicit dep
    -- (needed when we reference system XMLs via wp_dir variable in Meson)
    local needs_wp_dep  = false
    local needs_wlr_dep = false
    for _, p in ipairs(opts.protocol_entries or {}) do
        if p.xml_ref == 'system_wp' then needs_wp_dep = true end
        if p.xml_ref == 'system_wlr' then needs_wlr_dep = true end
    end

    l('# ── Dependencies ─────────────────────────────────────────────────────────────')

    -- find_library() deps need the compiler object
    if #find_lib_deps > 0 then
        l('cc = meson.get_compiler(\'' .. lang_str .. '\')')
        for _, fd in ipairs(find_lib_deps) do
            dep_entries[#dep_entries + 1] = "  cc.find_library('" .. fd.lib .. "', required : true)"
        end
    end

    -- wayland-protocols system dep (for wp_dir variable)
    if needs_wp_dep then
        l("wayland_protocols_dep = dependency('wayland-protocols', required : true)")
        l("wp_dir = wayland_protocols_dep.get_variable('pkgdatadir')")
    end

    -- wlroots dep for its protocol pkgdatadir (if we reference system wlr XMLs)
    -- Note: wlroots_dep is already in dep_names from pkg-config scan, so we just
    -- capture its pkgdatadir here for the protocol paths.
    if needs_wlr_dep then
        local wlr_varname = nil
        for _, d in ipairs(dep_names) do
            if d:match('^wlroots') then
                wlr_varname = var(d); break
            end
        end
        if wlr_varname then
            l("wlr_proto_dir = " .. wlr_varname .. "_dep.get_variable('pkgdatadir') / 'protocols'")
        else
            l("_wlr_dep_proto = dependency('wlroots-0.18', required : true)")
            l("wlr_proto_dir  = _wlr_dep_proto.get_variable('pkgdatadir') / 'protocols'")
        end
    end

    -- pkg-config deps
    for _, dep in ipairs(dep_names) do
        if dep == 'threads' then
            dep_entries[#dep_entries + 1] = "  dependency('threads')"
        else
            dep_entries[#dep_entries + 1] = "  dependency('" .. dep .. "', required : true)"
        end
    end

    -- emit single deps array (or empty fallback)
    if #dep_entries > 0 then
        l('deps = [')
        l(table.concat(dep_entries, ',\n'))
        l(']')
    else
        l('deps = []')
    end
    l()

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
    -- Each entry carries xml_ref: 'system_wp' | 'system_wlr' | 'vendored'
    -- which determines how we express the XML path in Meson.
    local protocol_entries = opts.protocol_entries or {}
    if #protocol_entries > 0 then
        l('# ── Wayland protocol generation ──────────────────────────────────────────────')
        l("wayland_scanner = find_program('wayland-scanner')")
        l()
        l('protocol_src = []')
        for _, entry in ipairs(protocol_entries) do
            local stem    = entry.xml:gsub('%.xml$', '')
            local varname = stem:gsub('%-', '_')

            -- Build the Meson XML reference expression
            local xml_meson
            if entry.xml_ref == 'system_wp' then
                -- e.g. wp_dir / 'stable/xdg-shell/xdg-shell.xml'
                xml_meson = "wp_dir / '" .. entry.xml_subpath .. "'"
            elseif entry.xml_ref == 'system_wlr' then
                -- e.g. wlr_proto_dir / 'wlr-layer-shell-unstable-v1.xml'
                xml_meson = "wlr_proto_dir / '" .. entry.xml_subpath .. "'"
            else
                -- vendored into include/protocols/
                xml_meson = "files('include/protocols/" .. entry.xml .. "')"
            end

            l(varname .. '_h = custom_target(')
            l("  '" .. stem .. "-client-header',")
            l("  input   : " .. xml_meson .. ",")
            l("  output  : '" .. stem .. "-protocol.h',")
            l("  command : [wayland_scanner, 'client-header', '@INPUT@', '@OUTPUT@'],")
            l(')')
            l(varname .. '_c = custom_target(')
            l("  '" .. stem .. "-private-code',")
            l("  input   : " .. xml_meson .. ",")
            l("  output  : '" .. stem .. "-protocol.c',")
            l("  command : [wayland_scanner, 'private-code', '@INPUT@', '@OUTPUT@'],")
            l(')')
            l('protocol_src += [' .. varname .. '_h, ' .. varname .. '_c]')
            l()
        end
    end

    -- executable(s)
    l('# ── Executable ───────────────────────────────────────────────────────────────')

    local c_args_str = ''
    if #c_args > 0 then
        local quoted = vim.tbl_map(function(a) return "'" .. a .. "'" end, c_args)
        c_args_str = table.concat(quoted, ', ')
    end

    local function write_exe(exename, src_expr)
        l("exe = executable('" .. exename .. "',")
        l('  ' .. src_expr .. ',')
        l('  include_directories : inc,')
        l('  dependencies        : deps,')
        if c_args_str ~= '' then
            l('  c_args              : [' .. c_args_str .. '],')
        end
        l("  link_args           : ['-Wl,--as-needed'],")
        l('  install             : false,')
        l(')')
    end

    if multi_exe then
        -- One executable per main() file, sharing common sources
        local proto_suffix = #protocol_entries > 0 and ' + protocol_src' or ''
        for _, m in ipairs(opts.multi_exe) do
            write_exe(m.base, "shared_src + files('" .. m.path .. "')" .. proto_suffix)
            l()
        end
    else
        local proto_suffix = #protocol_entries > 0 and 'src + protocol_src' or 'src'
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
                                                notices[#notices + 1] = 'pkg-config deps: ' ..
                                                    table.concat(detected.pkg_deps, ' ')
                                            end
                                            if #detected.find_lib_deps > 0 then
                                                local names = vim.tbl_map(function(d) return d.lib end,
                                                    detected.find_lib_deps)
                                                notices[#notices + 1] = 'find_library() deps: ' ..
                                                    table.concat(names, ' ')
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
                                                vim.notify(
                                                    '[Marvin] Auto-injecting:\n  ' .. table.concat(notices, '\n  '),
                                                    vim.log.levels.INFO)
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
                                                vim.notify(
                                                    '[Marvin] Include dirs:\n  ' .. table.concat(inc_dirs, '\n  '),
                                                    vim.log.levels.INFO)
                                            end

                                            local ok_wp, wl_proto = pcall(require, 'marvin.wayland_protocols')
                                            if not ok_wp then
                                                vim.notify(
                                                    '[Marvin] wayland_protocols module error: ' .. tostring(wl_proto),
                                                    vim.log.levels
                                                    .WARN)
                                                wl_proto = nil
                                            end
                                            local protocol_entries = {}
                                            if wl_proto then
                                                local ok_r, proto_results = pcall(wl_proto.resolve, root)
                                                if ok_r then
                                                    protocol_entries = proto_results
                                                    -- Notify which protocols were resolved and how
                                                    local sys_wp, sys_wlr, vendored_list = {}, {}, {}
                                                    for _, e in ipairs(protocol_entries) do
                                                        if e.xml_ref == 'system_wp' then
                                                            sys_wp[#sys_wp + 1] = e.xml
                                                        elseif e.xml_ref == 'system_wlr' then
                                                            sys_wlr[#sys_wlr + 1] = e.xml
                                                        else
                                                            vendored_list[#vendored_list + 1] = e.xml
                                                        end
                                                    end
                                                    if #sys_wp > 0 then
                                                        notices[#notices + 1] = 'wayland-protocols (system): ' ..
                                                            #sys_wp .. ' XMLs via wp_dir'
                                                    end
                                                    if #sys_wlr > 0 then
                                                        notices[#notices + 1] = 'wlroots protocols (system): ' ..
                                                            #sys_wlr .. ' XMLs via wlr_proto_dir'
                                                    end
                                                    if #vendored_list > 0 then
                                                        notices[#notices + 1] = 'vendored protocols (fallback): ' ..
                                                            table.concat(vendored_list, ', ')
                                                    end
                                                else
                                                    vim.notify(
                                                        '[Marvin] Protocol scan error: ' .. tostring(proto_results),
                                                        vim.log.levels.WARN)
                                                end
                                            end

                                            local opts = {
                                                name             = name,
                                                version          = '0.1.0',
                                                lang             = lang,
                                                std              = std_ch.id,
                                                sanitizer        = san_ch and san_ch.id or 'none',
                                                testing          = test_ch and test_ch.id ~= 'none',
                                                test_framework   = test_ch and test_ch.id or 'none',
                                                install          = inst_ch and inst_ch.id == 'yes',
                                                dep_names        = detected.pkg_deps,
                                                find_lib_deps    = detected.find_lib_deps,
                                                needs_posix      = detected.needs_posix,
                                                wlr_guard        = detected.wlr_guard,
                                                extra_cargs      = detected.extra_cargs,
                                                src_decl         = src_decl,
                                                shared_src_decl  = shared_src_decl,
                                                test_src_decl    = test_src_decl,
                                                inc_decl         = inc_decl,
                                                inc_dirs         = inc_dirs,
                                                protocol_entries = protocol_entries,
                                                multi_exe        = multi_exe,
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

-- Expose functions for use by other modules (e.g., Jason dashboard sync)
M.exposed.infer_lang = infer_lang
M.exposed.collect_sources = collect_sources
M.exposed.collect_include_dirs = collect_include_dirs
M.exposed.detect_pkg_deps = detect_pkg_deps
M.exposed.detect_find_library_deps = detect_find_library_deps
M.exposed.auto_detect = auto_detect
M.exposed.meson_template = meson_template
M.exposed.detect_main_files = detect_main_files -- the grep-based one at line 399
M.exposed.scan_needs_wlr_unstable = scan_needs_wlr_unstable
M.exposed.detect_needs_posix = detect_needs_posix
M.exposed.detect_needs_wayland_server = detect_needs_wayland_server
M.exposed.detect_needs_xkbcommon = detect_needs_xkbcommon
M.exposed.include_to_pkg = include_to_pkg
M.exposed.resolve_pkg = resolve_pkg
M.exposed.get_pkg_list = get_pkg_list
M.exposed.grep_any = grep_any
M.exposed.var = var

return M
