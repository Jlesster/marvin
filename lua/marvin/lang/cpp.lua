-- lua/marvin/lang/cpp.lua
-- C/C++ language module for the Marvin unified dashboard.

local M = {}

local function plain(it) return it.label end
local function ui() return require('marvin.ui') end
local function cr() return require('marvin.creator.cpp') end
local function det() return require('marvin.detector') end
local function local_libs() return require('marvin.local_libs') end

local function sep(l) return { label = l, is_separator = true } end
local function item(id, i, l, d) return { id = id, _icon = i, label = l, desc = d } end

-- ── Project header ────────────────────────────────────────────────────────────
function M.prompt_header(p)
  local info = p.info or {}
  local kind = p.type == 'cmake' and '[CMake]'
      or p.type == 'meson' and '[Meson]'
      or '[Makefile]'
  return string.format('%s  %s', info.name or p.name, kind)
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end

  for _, ci in ipairs(cr().menu_items()) do add(ci) end

  add(sep('Build'))
  local tool = p.type == 'cmake' and 'CMake'
      or p.type == 'meson' and 'Meson'
      or 'Make'
  add(item('build_menu', '󰑕', tool .. '…', 'Configure, build, test, install, clean'))

  add(sep('Libraries'))
  add(item('libs_link', '󰘦', 'Link Libraries…', 'Pick local .a/.so libs to link'))
  add(item('libs_build', '󰑕', 'Build Static Library…', 'Compile sources → .a archive'))
  add(item('libs_paths', '󰉿', 'Manage Library Paths…', 'Register / remove search dirs'))
  add(item('libs_report', '󰙅', 'Library Report', 'Show discovered libs + active flags'))

  add(sep('Project Files'))
  add(item('proj_files_menu', '󰈙', 'Build System…',
    'Makefile, CMakeLists.txt, meson.build, compile_commands.json'))

  return items
end

-- ── Submenu: Build ────────────────────────────────────────────────────────────
function M.show_build_menu(p, back)
  local items = {}
  if p.type == 'cmake' then
    items = {
      { id = 'cmake_cfg', label = '󰒓 Configure', desc = 'cmake -B build -S .' },
      { id = 'cmake_build', label = '󰑕 Build', desc = 'cmake --build build' },
      { id = 'cmake_test', label = '󰙨 Test', desc = 'ctest --test-dir build' },
      { id = 'cmake_install', label = '󰇚 Install', desc = 'cmake --install build' },
      { id = 'cmake_clean', label = '󰃢 Clean', desc = 'cmake --build build --target clean' },
    }
  elseif p.type == 'meson' then
    local configured = vim.fn.isdirectory(p.root .. '/builddir') == 1
        or vim.fn.isdirectory(p.root .. '/build') == 1
    items = {
      {
        id    = 'meson_setup',
        label = configured and '󰒓 Re-configure' or '󰒓 Setup (meson setup builddir)',
        desc  = configured and 'meson setup --reconfigure builddir' or 'meson setup builddir',
      },
      { id = 'meson_build', label = '󰑕 Build', desc = 'meson compile -C builddir' },
      { id = 'meson_test', label = '󰙨 Test', desc = 'meson test -C builddir' },
      { id = 'meson_install', label = '󰇚 Install', desc = 'meson install -C builddir' },
      { id = 'meson_clean', label = '󰃢 Clean', desc = 'rm -rf builddir' },
      { id = 'meson_introspect', label = '󰙅 Introspect…', desc = 'meson introspect subcommands' },
    }
  else
    items = {
      { id = 'make_build', label = '󰑕 Build', desc = 'make' },
      { id = 'make_test', label = '󰙨 Test', desc = 'make test' },
      { id = 'make_install', label = '󰇚 Install', desc = 'make install' },
      { id = 'make_clean', label = '󰃢 Clean', desc = 'make clean' },
    }
  end
  ui().select(items, { prompt = 'Build', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Meson introspect ─────────────────────────────────────────────────
function M.show_meson_introspect_menu(p, back)
  local root  = p and p.root or vim.fn.getcwd()
  local items = {
    { id = 'mi_targets', label = '󰙅 Targets', desc = 'meson introspect --targets' },
    { id = 'mi_deps', label = '󰘦 Dependencies', desc = 'meson introspect --dependencies' },
    { id = 'mi_buildopts', label = '󰒓 Build Options', desc = 'meson introspect --buildoptions' },
    { id = 'mi_tests', label = '󰙨 Tests', desc = 'meson introspect --tests' },
    { id = 'mi_compilers', label = '󰙲 Compilers', desc = 'meson introspect --compilers' },
    { id = 'mi_installed', label = '󰇚 Installed Files', desc = 'meson introspect --installed' },
  }
  ui().select(items, { prompt = 'Meson Introspect', on_back = back, format_item = plain },
    function(ch)
      if not ch then return end
      local subcmds = {
        mi_targets   = '--targets',
        mi_deps      = '--dependencies',
        mi_buildopts = '--buildoptions',
        mi_tests     = '--tests',
        mi_compilers = '--compilers',
        mi_installed = '--installed',
      }
      local flag = subcmds[ch.id]
      if flag then
        local bdir = vim.fn.isdirectory(root .. '/builddir') == 1 and 'builddir' or 'build'
        require('core.runner').execute({
          cmd      = 'meson introspect ' .. bdir .. ' ' .. flag,
          cwd      = root,
          title    = 'Meson Introspect ' .. flag,
          term_cfg = require('marvin').config.terminal,
          plugin   = 'marvin',
        })
      end
    end)
end

-- ── Submenu: Project Files ────────────────────────────────────────────────────
function M.show_proj_files_menu(p, back)
  local items = {
    {
      id    = 'gen_makefile',
      label = '󰈙 New/Regenerate Makefile',
      desc  = 'Interactive Makefile wizard',
    },
    {
      id    = 'gen_cmake',
      label = '󰒓 New/Regenerate CMakeLists.txt',
      desc  = 'Interactive CMake wizard with auto-link detection',
    },
    {
      id    = 'gen_meson',
      label = '󰒓 New/Regenerate meson.build',
      desc  = 'Interactive Meson wizard with auto-link detection',
    },
    {
      id    = 'gen_compile_commands',
      label = '󰘦 Generate compile_commands.json',
      desc  = 'For clangd — build then rewrite to project root',
    },
    {
      id    = 'rewrite_compile_commands',
      label = '󰑕 Rewrite & Restart clangd',
      desc  = 'Re-run path rewriter on existing compile_commands.json',
    },
  }
  ui().select(items, { prompt = 'Build System', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- compile_commands.json rewriter
--
-- Meson writes compile_commands.json inside builddir/ with:
--   • relative -I flags (e.g. -I.. -I../include -ITrixie.p)
--   • relative "file" paths (e.g. "../src/anim.c")
--   • NO reference to builddir itself (where generated protocol headers live)
--
-- This rewriter produces a file at the PROJECT ROOT with:
--   1. Every -I flag resolved to an absolute path
--   2. -I<builddir> injected → clangd finds wlr-*-protocol.h, xdg-*-protocol.h
--   3. -I<builddir>/<target>.p/ injected → meson per-target private dir headers
--   4. Every "file" field resolved to an absolute path
--   5. "directory" set to the project root (not builddir)
-- ══════════════════════════════════════════════════════════════════════════════

local REWRITE_PY = [[
import json, os, subprocess, sys

root  = sys.argv[1]   # project root  e.g. /home/user/Code/Trixie
bdir  = sys.argv[2]   # builddir      e.g. /home/user/Code/Trixie/builddir
src   = sys.argv[3]   # input         bdir/compile_commands.json
dst   = sys.argv[4]   # output        root/compile_commands.json

# ── pkg-config header → package map ──────────────────────────────────────────
# We scan every source file referenced in compile_commands.json for #include
# patterns, map them to pkg-config packages, then inject --cflags so clangd
# can find headers like <wlr/backend.h> that live outside standard paths.
PKG_MAP = [
    ('wlr/',               'wlroots'),
    ('wayland-server',     'wayland-server'),
    ('wayland-client',     'wayland-client'),
    ('xkbcommon',          'xkbcommon'),
    ('libinput',           'libinput'),
    ('libudev',            'libudev'),
    ('pixman',             'pixman-1'),
    ('drm',                'libdrm'),
    ('gbm',                'gbm'),
    ('EGL/egl',            'egl'),
    ('GLES',               'glesv2'),
    ('cairo',              'cairo'),
    ('pango',              'pango'),
    ('gdk-pixbuf',         'gdk-pixbuf-2.0'),
    ('gtk/gtk',            'gtk+-3.0'),
    ('glib',               'glib-2.0'),
    ('gio/',               'gio-2.0'),
    ('libavcodec',         'libavcodec'),
    ('libavformat',        'libavformat'),
    ('pulse',              'libpulse'),
    ('alsa',               'alsa'),
    ('openssl',            'openssl'),
    ('curl',               'libcurl'),
    ('dbus',               'dbus-1'),
    ('systemd',            'libsystemd'),
    ('json-c',             'json-c'),
    ('libxml2',            'libxml-2.0'),
    ('libpng',             'libpng'),
    ('freetype',           'freetype2'),
    ('fontconfig',         'fontconfig'),
    ('zlib',               'zlib'),
    ('lua',                'lua'),
    ('ffi',                'libffi'),
]

def resolve_pkg(base):
    """Resolve base pkg name to actual installed name, handling versioned packages.

    e.g. 'wlroots' -> 'wlroots-0.18' when only the versioned form is installed.
    Returns the resolved name string, or None if not found at all.
    """
    # 1. Try exact name first
    if subprocess.call(['pkg-config', '--exists', base],
                       stderr=subprocess.DEVNULL) == 0:
        return base
    # 2. Search for versioned variant via pkg-config --list-all
    try:
        all_pkgs = subprocess.check_output(
            ['pkg-config', '--list-all'],
            stderr=subprocess.DEVNULL).decode()
        for line in all_pkgs.splitlines():
            pkg_name = line.split()[0] if line.split() else ''
            # Match 'wlroots-0.18', 'wlroots-0.17', etc.
            if pkg_name == base or pkg_name.startswith(base + '-') or pkg_name.startswith(base + '.'):
                if subprocess.call(['pkg-config', '--exists', pkg_name],
                                   stderr=subprocess.DEVNULL) == 0:
                    return pkg_name
    except Exception:
        pass
    return None

def pkg_exists(name):
    return resolve_pkg(name) is not None

def pkg_cflags(names):
    """Return list of flag tokens from pkg-config --cflags for all names.
    Names should already be resolved (i.e. 'wlroots-0.18' not 'wlroots').
    """
    if not names:
        return []
    try:
        out = subprocess.check_output(
            ['pkg-config', '--cflags'] + names,
            stderr=subprocess.DEVNULL).decode().strip()
        return out.split() if out else []
    except Exception:
        return []

def scan_file_for_pkgs(path, found, ordered):
    """Scan a single source/header file for #include patterns."""
    try:
        with open(path, errors='replace') as f:
            for line in f:
                line = line.strip()
                if not line.startswith('#'):
                    continue
                if 'include' not in line:
                    continue
                start = line.find('<')
                if start == -1:
                    start = line.find('"')
                    end   = line.rfind('"')
                else:
                    end = line.find('>')
                if start == -1 or end <= start:
                    continue
                inc = line[start+1:end]
                for pat, pkg in PKG_MAP:
                    if pkg not in found and pat in inc:
                        # resolve handles versioned names: wlroots -> wlroots-0.18
                        resolved = resolve_pkg(pkg)
                        if resolved:
                            found.add(pkg)        # key on base to avoid duplicates
                            ordered.append(resolved)  # use actual installed name
    except OSError:
        pass

with open(src) as f:
    entries = json.load(f)

# ── collect all source files referenced in compile_commands ──────────────────
all_source_files = set()
for e in entries:
    fpath = e.get('file', '')
    if fpath and not fpath.startswith('/'):
        fpath = os.path.normpath(os.path.join(bdir, fpath))
    if fpath:
        all_source_files.add(fpath)
    # also scan headers alongside each source
    d = os.path.dirname(fpath)
    if os.path.isdir(d):
        for name in os.listdir(d):
            if name.endswith(('.h', '.hpp', '.hxx')):
                all_source_files.add(os.path.join(d, name))

# also scan include/ and src/ at project root
for subdir in ('include', 'src', '.'):
    dp = os.path.join(root, subdir)
    if os.path.isdir(dp):
        for dirpath, _, filenames in os.walk(dp):
            for name in filenames:
                if name.endswith(('.c', '.cpp', '.h', '.hpp', '.cxx', '.hxx')):
                    all_source_files.add(os.path.join(dirpath, name))

found_pkgs   = set()
ordered_pkgs = []
for fpath in all_source_files:
    scan_file_for_pkgs(fpath, found_pkgs, ordered_pkgs)

pkg_cflags_tokens = pkg_cflags(ordered_pkgs)
needs_wlr_unstable = any(p.startswith('wlroots') for p in ordered_pkgs)

if ordered_pkgs:
    print('pkg-config deps detected: ' + ' '.join(ordered_pkgs))
    print('injecting cflags: ' + ' '.join(pkg_cflags_tokens))

# ── rewrite every compile_commands entry ─────────────────────────────────────
for e in entries:
    parts = e.get('command', '').split()
    fixed = []
    seen  = set()

    for p in parts:
        if p.startswith('-I') and not p.startswith('-I/'):
            # resolve relative include path against builddir
            abs_inc = os.path.normpath(os.path.join(bdir, p[2:]))
            flag    = '-I' + abs_inc
        else:
            flag = p

        if flag not in seen:
            seen.add(flag)
            fixed.append(flag)

    # inject builddir itself → clangd finds generated protocol headers
    # (wlr-layer-shell-unstable-v1-protocol.h, xdg-shell-protocol.h, etc.)
    bdir_flag = '-I' + bdir
    if bdir_flag not in seen:
        seen.add(bdir_flag)
        fixed.append(bdir_flag)

    # inject every *.p/ subdir inside builddir (meson per-target private dirs)
    try:
        for entry in os.scandir(bdir):
            if entry.is_dir() and entry.name.endswith('.p'):
                flag = '-I' + entry.path
                if flag not in seen:
                    seen.add(flag)
                    fixed.append(flag)
    except OSError:
        pass

    # inject project root and include/protocols/ so generated protocol headers
    # are found regardless of whether they're in root or include/protocols/
    for extra_inc in [root, os.path.join(root, 'include', 'protocols')]:
        flag = '-I' + extra_inc
        if flag not in seen and os.path.isdir(extra_inc):
            seen.add(flag)
            fixed.append(flag)

    # inject every directory under the project root that contains a
    # *-protocol.h file (covers hand-committed or subdir-placed headers)
    try:
        for dirpath, dirnames, filenames in os.walk(root):
            # skip build dirs and hidden dirs
            dirnames[:] = [d for d in dirnames
                           if d not in ('builddir', 'build', '.git', '.marvin-obj')
                           and not d.startswith('.')]
            if any(f.endswith('-protocol.h') or f.endswith('_protocol.h')
                   for f in filenames):
                flag = '-I' + dirpath
                if flag not in seen:
                    seen.add(flag)
                    fixed.append(flag)
    except OSError:
        pass

    # inject pkg-config --cflags tokens (the key fix for wlr/backend.h etc.)
    for token in pkg_cflags_tokens:
        if token not in seen:
            seen.add(token)
            fixed.append(token)

    # wlroots requires this define or headers refuse to compile
    if needs_wlr_unstable and '-DWLR_USE_UNSTABLE' not in seen:
        seen.add('-DWLR_USE_UNSTABLE')
        fixed.append('-DWLR_USE_UNSTABLE')

    e['command']   = ' '.join(fixed)
    e['directory'] = root   # set directory to project root, not builddir

    # fix relative file path
    if not e.get('file', '').startswith('/'):
        e['file'] = os.path.normpath(os.path.join(bdir, e['file']))

    # fix relative output path if present
    if 'output' in e and not e['output'].startswith('/'):
        e['output'] = os.path.normpath(os.path.join(bdir, e['output']))

with open(dst, 'w') as f:
    json.dump(entries, f, indent=2)

print('ok: wrote ' + dst)
]]

local function rewrite_compile_commands(root, on_done)
  -- find builddir
  local bdir = nil
  for _, c in ipairs({ 'builddir', 'build' }) do
    if vim.fn.filereadable(root .. '/' .. c .. '/compile_commands.json') == 1 then
      bdir = root .. '/' .. c
      break
    end
  end

  if not bdir then
    vim.notify(
      '[Marvin] compile_commands.json not found in builddir/ or build/.\n'
      .. '  Run Meson Setup first to generate it.',
      vim.log.levels.WARN)
    return
  end

  local src         = bdir .. '/compile_commands.json'
  local dst         = root .. '/compile_commands.json'
  local script_path = vim.fn.tempname() .. '_marvin_rewrite.py'

  local sf          = io.open(script_path, 'w')
  if not sf then
    vim.notify('[Marvin] Cannot write temp script: ' .. script_path, vim.log.levels.ERROR)
    return
  end
  sf:write(REWRITE_PY)
  sf:close()

  vim.fn.jobstart({ 'python3', script_path, root, bdir, src, dst }, {
    on_stdout = function(_, data)
      local msg = table.concat(data or {}, '\n'):gsub('^%s+', ''):gsub('%s+$', '')
      if msg ~= '' then vim.notify('[Marvin] ' .. msg, vim.log.levels.INFO) end
    end,
    on_stderr = function(_, data)
      local msg = table.concat(data or {}, '\n'):gsub('^%s+', ''):gsub('%s+$', '')
      if msg ~= '' then vim.notify('[Marvin] rewrite error: ' .. msg, vim.log.levels.ERROR) end
    end,
    on_exit = function(_, code)
      os.remove(script_path)
      if code ~= 0 then
        vim.notify('[Marvin] compile_commands rewrite failed (exit ' .. code .. ')', vim.log.levels.ERROR)
        return
      end
      if on_done then vim.schedule(on_done) end
    end,
  })
end

-- ── clangd restart ────────────────────────────────────────────────────────────
local function restart_clangd()
  local cache = vim.fn.expand('~/.cache/clangd')
  if vim.fn.isdirectory(cache) == 1 then
    vim.fn.system('rm -rf ' .. vim.fn.shellescape(cache))
  end
  vim.lsp.stop_client(vim.lsp.get_clients({ name = 'clangd' }))
  vim.defer_fn(function() vim.cmd('edit') end, 300)
end

-- ── compile_commands generator (entry point) ─────────────────────────────────
function M.generate_compile_commands(p, back)
  local root          = p and p.root or vim.fn.getcwd()
  local has_meson     = vim.fn.filereadable(root .. '/meson.build') == 1
  local has_cmake     = vim.fn.filereadable(root .. '/CMakeLists.txt') == 1
  local has_make      = vim.fn.filereadable(root .. '/Makefile') == 1
  local has_bear      = vim.fn.executable('bear') == 1
  local has_compdb    = vim.fn.executable('compiledb') == 1
  local has_cmake_bin = vim.fn.executable('cmake') == 1
  local has_meson_bin = vim.fn.executable('meson') == 1

  -- Meson: always go through meson_setup so rewrite runs automatically
  if has_meson and has_meson_bin then
    M.handle('meson_setup', p, back)
    return
  end

  local items = {}
  local function add(t) items[#items + 1] = t end

  if has_cmake and has_cmake_bin then
    add({
      id = 'ccmd_cmake',
      label = '󰒓 CMake (recommended)',
      desc = 'cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -S .'
    })
  end
  if has_bear then
    if has_make then
      add({ id = 'ccmd_bear_make', label = '󰈙 bear + make', desc = 'bear -- make' })
    end
    add({ id = 'ccmd_bear_custom', label = '󰈙 bear + custom command…', desc = 'bear -- <cmd>' })
  end
  if has_compdb and has_make then
    add({ id = 'ccmd_compiledb', label = '󰘦 compiledb', desc = 'compiledb make' })
  end
  add({
    id = 'ccmd_clangd_file',
    label = '󰄬 .clangd config (no build needed)',
    desc = 'Write .clangd with -Iinclude flags'
  })
  if #items == 1 then
    add({ id = 'ccmd_install_hint', label = '󰋖 How to install bear / compiledb', desc = '' })
  end

  ui().select(items, { prompt = 'Generate compile_commands.json', on_back = back, format_item = plain },
    function(ch)
      if not ch then return end

      local function run(cmd, title, on_exit_cb)
        require('core.runner').execute({
          cmd = cmd,
          cwd = root,
          title = title,
          term_cfg = require('marvin').config.terminal,
          plugin = 'marvin',
          on_exit = on_exit_cb,
        })
      end

      if ch.id == 'ccmd_cmake' then
        run('cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
          'Generate compile_commands.json',
          function(ok)
            if not ok then return end
            vim.defer_fn(function()
              local s = root .. '/build/compile_commands.json'
              local d = root .. '/compile_commands.json'
              if vim.fn.filereadable(s) == 1 then
                vim.fn.system('ln -sf ' .. vim.fn.shellescape(s) .. ' ' .. vim.fn.shellescape(d))
                restart_clangd()
              end
            end, 500)
          end)
      elseif ch.id == 'ccmd_bear_make' then
        run('bear -- make', 'bear + make', function(ok)
          if ok then restart_clangd() end
        end)
      elseif ch.id == 'ccmd_bear_custom' then
        ui().input({ prompt = 'Build command for bear', default = 'make' }, function(cmd)
          if cmd and cmd ~= '' then
            run('bear -- ' .. cmd, 'bear + ' .. cmd, function(ok)
              if ok then restart_clangd() end
            end)
          end
        end)
      elseif ch.id == 'ccmd_compiledb' then
        run('compiledb make', 'compiledb', function(ok)
          if ok then restart_clangd() end
        end)
      elseif ch.id == 'ccmd_clangd_file' then
        local inc_flags = {}
        for _, d in ipairs({ 'include', 'src', '.' }) do
          if vim.fn.isdirectory(root .. '/' .. d) == 1 then
            inc_flags[#inc_flags + 1] = '-I' .. root .. '/' .. d
          end
        end
        local ok_ll, ll = pcall(require, 'marvin.local_libs')
        if ok_ll then
          local lf = ll.build_flags(root)
          if lf.iflags ~= '' then
            for _, f in ipairs(vim.split(lf.iflags, '%s+')) do
              if f ~= '' then inc_flags[#inc_flags + 1] = f end
            end
          end
        end
        local cfg         = require('marvin').config.cpp or {}
        local std         = cfg.standard or 'c11'
        local clang_lang  = (cfg.compiler == 'g++' or cfg.compiler == 'clang++') and 'c++' or 'c'
        local flags       = vim.deepcopy(inc_flags)

        local ok_b, build = pcall(require, 'marvin.build')
        if ok_b and build.cpp then
          -- POSIX define
          if build.cpp.needs_posix_define and build.cpp.needs_posix_define(root) then
            flags[#flags + 1] = '-D_POSIX_C_SOURCE=200809L'
          end
          -- pkg-config --cflags: resolves -I/usr/include/wlroots-0.17,
          -- -DWLR_USE_UNSTABLE, and flags for every other detected library.
          if build.cpp.pkg_config_flags then
            local pkg = build.cpp.pkg_config_flags(root)
            for _, f in ipairs(pkg.iflags) do flags[#flags + 1] = f end
            if #pkg.pkg_names > 0 then
              vim.notify('[Marvin] .clangd: injecting pkg-config flags for: '
                .. table.concat(pkg.pkg_names, ' '), vim.log.levels.INFO)
            end
          end
        end


        -- inject project root and include/protocols/ for generated protocol headers
        flags[#flags + 1] = '-I' .. root
        if vim.fn.isdirectory(root .. '/include/protocols') == 1 then
          flags[#flags + 1] = '-I' .. root .. '/include/protocols'
        end

        -- scan every subdir for *-protocol.h files and inject those dirs too
        -- (covers wlr-layer-shell-unstable-v1-protocol.h committed to the repo)
        local _skip = { build = true, builddir = true, ['.git'] = true, ['.marvin-obj'] = true }
        local function scan_proto_dirs(dir)
          for _, sub in ipairs(vim.fn.globpath(dir, '*', false, true)) do
            if vim.fn.isdirectory(sub) == 1 then
              local bn = vim.fn.fnamemodify(sub, ':t')
              if not _skip[bn] and not bn:match('^%.') then
                local ph = vim.fn.globpath(sub, '*-protocol.h', false, true)
                if #ph == 0 then ph = vim.fn.globpath(sub, '*_protocol.h', false, true) end
                if #ph > 0 then flags[#flags + 1] = '-I' .. sub end
                scan_proto_dirs(sub)
              end
            end
          end
        end
        scan_proto_dirs(root)

        flags[#flags + 1] = '-std=' .. std
        flags[#flags + 1] = '-x'
        flags[#flags + 1] = clang_lang
        local flag_lines = {}
        for _, f in ipairs(flags) do flag_lines[#flag_lines + 1] = '    - ' .. f end
        local clangd_content = 'CompileFlags:\n  Add:\n' .. table.concat(flag_lines, '\n') .. '\n'
        local clangd_path    = root .. '/.clangd'
        if vim.fn.filereadable(clangd_path) == 1 then
          ui().select({
              { id = 'overwrite', label = 'Overwrite existing .clangd' },
              { id = 'cancel',    label = 'Cancel' },
            }, { prompt = '.clangd already exists', format_item = plain },
            function(ow)
              if ow and ow.id == 'overwrite' then
                local f = io.open(clangd_path, 'w')
                if f then
                  f:write(clangd_content); f:close(); restart_clangd()
                end
              end
            end)
        else
          local f = io.open(clangd_path, 'w')
          if f then
            f:write(clangd_content); f:close(); restart_clangd()
          end
        end
      elseif ch.id == 'ccmd_install_hint' then
        vim.api.nvim_echo({ { table.concat({
          '', '  Install bear:', '    Arch: sudo pacman -S bear',
          '    Ubuntu: sudo apt install bear', '    macOS: brew install bear', '',
          '  Install compiledb:  pip install compiledb', '',
          '  Meson: meson setup builddir  (generates automatically)', '',
          '  CMake: cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON', '',
        }, '\n'), 'Normal' } }, true, {})
      end
    end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle(id, p, back)
  if cr().handle(id, back) then return end

  if id:match('^libs_') then
    local ll   = local_libs()
    local root = p and p.root or vim.fn.getcwd()
    ll.handle(id, root, back)
    return
  end

  if id == 'build_menu' then
    M.show_build_menu(p, back)
  elseif id == 'proj_files_menu' then
    M.show_proj_files_menu(p, back)
  elseif id == 'gen_makefile' then
    require('marvin.makefile_creator').create(p and p.root or vim.fn.getcwd(), back)
  elseif id == 'gen_cmake' then
    require('marvin.cmake_creator').create(p and p.root or vim.fn.getcwd(), back)
  elseif id == 'gen_meson' then
    require('marvin.meson_creator').create(p and p.root or vim.fn.getcwd(), back)
  elseif id == 'gen_compile_commands' then
    M.generate_compile_commands(p, back)
  elseif id == 'rewrite_compile_commands' then
    local root = p and p.root or vim.fn.getcwd()
    rewrite_compile_commands(root, function()
      restart_clangd()
      vim.notify('[Marvin] compile_commands.json rewritten + clangd restarted', vim.log.levels.INFO)
    end)

    -- ── CMake ───────────────────────────────────────────────────────────────────
  elseif id == 'cmake_cfg' then
    require('core.runner').execute({
      cmd = 'cmake -B build -S .',
      cwd = p.root,
      title = 'CMake Configure',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'cmake_build' then
    require('core.runner').execute({
      cmd = 'cmake --build build',
      cwd = p.root,
      title = 'CMake Build',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'cmake_test' then
    require('core.runner').execute({
      cmd = 'ctest --test-dir build',
      cwd = p.root,
      title = 'CTest',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'cmake_clean' then
    require('core.runner').execute({
      cmd = 'cmake --build build --target clean',
      cwd = p.root,
      title = 'CMake Clean',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'cmake_install' then
    require('core.runner').execute({
      cmd = 'cmake --install build',
      cwd = p.root,
      title = 'CMake Install',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })

    -- ── Meson ───────────────────────────────────────────────────────────────────
  elseif id == 'meson_setup' then
    local root       = p.root
    local configured = vim.fn.isdirectory(root .. '/builddir') == 1
        or vim.fn.isdirectory(root .. '/build') == 1
    require('core.runner').execute({
      cmd      = (configured
            and 'meson setup --reconfigure builddir'
            or 'meson setup builddir')
          .. ' && ninja -C builddir; true',
      cwd      = root,
      title    = 'Meson Setup + Build',
      term_cfg = require('marvin').config.terminal,
      plugin   = 'marvin',
      on_exit  = function(_)
        rewrite_compile_commands(root, function()
          restart_clangd()
          vim.notify(
            '[Marvin] Meson setup complete.\n'
            .. '  compile_commands.json → project root (absolute paths)\n'
            .. '  clangd cache cleared + restarted',
            vim.log.levels.INFO)
        end)
      end,
    })
  elseif id == 'meson_build' then
    require('core.runner').execute({
      cmd      = 'meson compile -C builddir',
      cwd      = p.root,
      title    = 'Meson Build',
      term_cfg = require('marvin').config.terminal,
      plugin   = 'marvin',
      on_exit  = function(_)
        rewrite_compile_commands(p.root, function()
          restart_clangd()
        end)
      end,
    })
  elseif id == 'meson_test' then
    require('core.runner').execute({
      cmd = 'meson test -C builddir',
      cwd = p.root,
      title = 'Meson Test',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'meson_install' then
    require('core.runner').execute({
      cmd = 'meson install -C builddir',
      cwd = p.root,
      title = 'Meson Install',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'meson_clean' then
    require('core.runner').execute({
      cmd = 'rm -rf builddir',
      cwd = p.root,
      title = 'Meson Clean',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'meson_introspect' then
    M.show_meson_introspect_menu(p, back)

    -- ── Make ────────────────────────────────────────────────────────────────────
  elseif id == 'make_build' then
    require('core.runner').execute({
      cmd = 'make',
      cwd = p.root,
      title = 'Make',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'make_test' then
    require('core.runner').execute({
      cmd = 'make test',
      cwd = p.root,
      title = 'Make Test',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'make_clean' then
    require('core.runner').execute({
      cmd = 'make clean',
      cwd = p.root,
      title = 'Make Clean',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'make_install' then
    require('core.runner').execute({
      cmd = 'make install',
      cwd = p.root,
      title = 'Make Install',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  end
end

return M
