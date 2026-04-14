-- lua/marvin/jason_dashboard.lua
-- Jason task-runner dashboard. Purely focused on build/run/test/package operations.
-- Project management (deps, file creation, settings) lives in marvin.dashboard.
-- Accessed via :Jason, <leader>j, or from within Marvin dashboard.

local M = {}

local function plain(it) return it.label end
local function sep(l) return { label = l, is_separator = true } end
local function item(id, icon, label, desc)
  return { id = id, _icon = icon, label = label, desc = desc }
end

local function ui() return require('marvin.ui') end
local function bld() return require('marvin.build') end
local function det() return require('marvin.detector') end

-- ── Language/tool metadata ────────────────────────────────────────────────────
local META = {
  maven = {
    label = 'Maven',
    lang = 'Java',
    icon = '󰬷',
    has = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, test_filter = 1 },
  },
  gradle = {
    label = 'Gradle',
    lang = 'Java',
    icon = '󰏗',
    has = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, test_filter = 1 },
  },
  cargo = {
    label = 'Cargo',
    lang = 'Rust',
    icon = '󱘗',
    has = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, fmt = 1, lint = 1, test_filter = 1 },
  },
  go_mod = {
    label = 'Go',
    lang = 'Go',
    icon = '󰟓',
    has = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, fmt = 1, lint = 1, test_filter = 1 },
  },
  cmake = {
    label = 'CMake',
    lang = 'C/C++',
    icon = '󰙲',
    has = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, fmt = 1, lint = 1, build_system = 1, package_lib = 1 },
  },
  meson = {
    label = 'Meson',
    lang  = 'C/C++',
    icon  = '󰒓',
    has   = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, fmt = 1, lint = 1, build_system = 1, package_lib = 1 },
  },
  makefile = {
    label = 'Make',
    lang = 'C/C++',
    icon = '󰙱',
    has = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, fmt = 1, lint = 1, build_system = 1, package_lib = 1 },
  },
  single_file = {
    label = 'Single File',
    lang = nil,
    icon = '󰈙',
    has = { build = 1, run = 1, clean = 1, build_run = 1 },
  },
}

-- ── Language-specific extras ──────────────────────────────────────────────────
-- Replace the bottom of the EXTRAS block (the gradle line) with this.
-- Pull the shared logic out as a named local before the table is constructed.

local function graalvm_extras(_p)
  return {
    sep('GraalVM'),
    item('j_graal_build', '󰂮', 'Build Native Image', 'Compile to native binary'),
    item('j_graal_run', '󰐊', 'Run Native Binary', 'Execute native build'),
    item('j_graal_agent', '󰋊', 'Run with Agent', 'Collect reflection config'),
    item('j_graal_info', '󰙅', 'GraalVM Info', 'Status / install guide'),
  }
end

local EXTRAS = {
  cargo    = function(_p)
    local profile = require('marvin').config.rust.profile
    return {
      sep('Rust'),
      item('j_rust_profile', '󰒓',
        'Toggle Profile (' .. profile .. ')',
        'Currently: ' .. profile .. ' → switch to ' .. (profile == 'release' and 'dev' or 'release')),
      item('j_clippy', '󰅾', 'Clippy', 'cargo clippy — lint'),
      item('j_bench', '󰙨', 'Benchmark', 'cargo bench'),
      item('j_doc', '󰈙', 'Doc', 'cargo doc --open'),
    }
  end,
  go_mod   = function(_p)
    return {
      sep('Go'),
      item('j_go_race', '󰍉', 'Test (race)', 'go test -race ./...'),
      item('j_go_cover', '󰙨', 'Test + Coverage', 'go test -cover ./...'),
      item('j_go_vet', '󰅾', 'Vet', 'go vet ./...'),
      item('j_go_doc', '󰈙', 'godoc', 'godoc -http=:6060'),
    }
  end,
  cmake    = function(p)
    local configured = vim.fn.isdirectory(p.root .. '/build') == 1
    return {
      sep('CMake'),
      item('j_cmake_cfg', '󰒓', configured and 'Re-configure' or 'Configure', 'cmake -B build -S .'),
      item('j_cpp_info', '󰙅', 'C/C++ Project Info', 'Auto-detected binary, flags, links'),
      item('j_build_file', '󰐊', 'Build Current File', 'Compile active buffer with auto-flags'),
    }
  end,
  meson    = function(p)
    local configured = vim.fn.isdirectory(p.root .. '/builddir') == 1
        or vim.fn.isdirectory(p.root .. '/build') == 1
    return {
      sep('Meson'),
      item('j_meson_setup', '󰒓',
        configured and 'Re-configure (--reconfigure)' or 'Setup builddir',
        configured and 'meson setup --reconfigure builddir' or 'meson setup builddir'),
      item('j_cpp_info', '󰙅', 'C/C++ Project Info', 'Auto-detected binary, flags, links'),
      item('j_build_file', '󰐊', 'Build Current File', 'Compile active buffer with auto-flags'),
      item('j_meson_introspect', '󰙅', 'Introspect…', 'meson introspect subcommands'),
    }
  end,
  makefile = function(_p)
    return {
      sep('C/C++'),
      item('j_cpp_info', '󰙅', 'C/C++ Project Info', 'Auto-detected binary, flags, links'),
      item('j_build_file', '󰐊', 'Build Current File', 'Compile active buffer with auto-flags'),
    }
  end,
  -- Both maven and gradle share the GraalVM extras.
  -- They now reference `graalvm_extras` (a plain local), not each other,
  -- which avoids the self-referential table construction crash.
  maven    = graalvm_extras,
  gradle   = graalvm_extras,
}

-- ── Dashboard ─────────────────────────────────────────────────────────────────
function M.show()
  local p         = det().get()
  local meta      = p and META[p.type]
  local has       = (meta and meta.has) or {}
  local tool      = meta and meta.label or 'No Project'
  local lang      = meta and (meta.lang or (p and p.lang) or '') or ''
  local pname     = p and p.name or '(no project)'
  local icon      = meta and meta.icon or '󰙅'

  local is_single = p and p.type == 'single_file'
  local prompt    = is_single
      and string.format('Jason  %s %s  %s  [%s]  — use Build System to create meson/cmake/make',
        icon, tool, pname, lang)
      or string.format('Jason  %s %s  %s  [%s]', icon, tool, pname, lang)
  local items     = M._build_items(p, meta, has)

  ui().select(items, {
    prompt        = prompt,
    enable_search = true,
    format_item   = function(it)
      if it.is_separator then return it.label end
      return (it._icon and (it._icon .. ' ') or '') .. it.label
    end,
  }, function(choice)
    if choice then M._handle(choice.id, p, meta) end
  end)
end

-- ── Item builder ──────────────────────────────────────────────────────────────
function M._build_items(p, meta, has)
  local items = {}
  local function add(t) items[#items + 1] = t end
  local function addall(t) for _, v in ipairs(t) do add(v) end end

  local tool = meta and meta.label or 'Actions'

  -- Core actions
  add(sep(tool .. ' Actions'))
  if has.build_run then add(item('j_build_run', '󰑓', 'Build & Run', 'Compile then run')) end
  if has.build then add(item('j_build', '󰑕', 'Build', 'Compile')) end
  if has.run then add(item('j_run', '󰐊', 'Run', 'Run')) end
  if has.test then add(item('j_test', '󰙨', 'Test', 'Run tests')) end
  if has.clean then add(item('j_clean', '󰃢', 'Clean', 'Remove artifacts')) end

  -- With options
  if has.build or has.run or has.test_filter then
    add(sep('With Options'))
    if has.build then add(item('j_build_args', '󰒓', 'Build (args…)', 'Extra build flags')) end
    if has.run then add(item('j_run_args', '󰒓', 'Run (args…)', 'Runtime arguments')) end
    if has.test_filter then add(item('j_test_filter', '󰍉', 'Test (filter…)', 'Specific test name')) end
  end

  -- Extras
  if has.fmt or has.lint or has.package or has.install then
    add(sep('Extras'))
    if has.fmt then add(item('j_fmt', '󰉣', 'Format', 'Auto-format')) end
    if has.lint then add(item('j_lint', '󰅾', 'Lint', 'Run linter')) end
    if has.package then add(item('j_package', '󰏗', 'Package', 'Create distributable')) end
    if has.install then add(item('j_install', '󰇚', 'Install', 'Install to local registry')) end
  end

  -- Package as Library (C/C++ only)
  if has.package_lib then
    add(sep('Library'))
    add(item('j_package_lib', '󰘦', 'Package as Library…',
      'Build .a + copy headers → lib/ for use as #include'))
  end

  -- Language-specific extras
  if p then
    local extras_fn = EXTRAS[p.type]
    if extras_fn then addall(extras_fn(p)) end
  end

  -- Build System submenu (C/C++ + no-project fallback)
  if has.build_system or not p or (p and p.type == 'single_file') then
    add(sep('Build System'))
    add(item('j_build_system_menu', '󰈙', 'Build System…',
      'Makefile, CMakeLists.txt, meson.build, compile_commands.json'))
  end

  -- Custom .jason.lua tasks
  if p then
    local ok, tasks_m = pcall(require, 'marvin.tasks')
    if ok then
      local tasks = tasks_m.load(p.root)
      if tasks and #tasks > 0 then
        add(sep('Tasks (.jason.lua)'))
        for _, t in ipairs(tasks_m.to_menu_items(tasks)) do
          items[#items + 1] = vim.tbl_extend('force', t, { _icon = t.icon })
        end
      end
    end
  end

  -- Monorepo
  if p then
    local subs = det().detect_sub_projects(vim.fn.getcwd())
    if subs and #subs > 1 then
      add(sep('Monorepo'))
      add(item('j_switch', '󰙅', 'Switch Sub-project…', #subs .. ' projects found'))
    end
  end

  add(sep('Console'))
  add(item('j_console', '󰋚', 'Task Console', 'View output history'))

  return items
end

-- ── Build System submenu ──────────────────────────────────────────────────────
function M.show_build_system_menu(p)
  local root         = p and p.root or vim.fn.getcwd()
  local has_makefile = vim.fn.filereadable(root .. '/Makefile') == 1
  local has_cmake    = vim.fn.filereadable(root .. '/CMakeLists.txt') == 1
  local has_meson    = vim.fn.filereadable(root .. '/meson.build') == 1
  local has_ccmd     = vim.fn.filereadable(root .. '/compile_commands.json') == 1

  local function exists_tag(flag) return flag and '  (exists)' or '' end

  local items = {
    {
      id    = 'j_new_makefile',
      label = '󰈙 ' .. (has_makefile and 'Regenerate' or 'New') .. ' Makefile' .. exists_tag(has_makefile),
      desc  = 'Interactive wizard — C, C++, Go, Rust, Generic',
    },
    {
      id    = 'j_new_cmake',
      label = '󰒓 ' .. (has_cmake and 'Regenerate' or 'New') .. ' CMakeLists.txt' .. exists_tag(has_cmake),
      desc  = 'Interactive CMake wizard with auto-link detection',
    },
    {
      id    = 'j_new_meson',
      label = '󰒓 ' .. (has_meson and 'Regenerate' or 'New') .. ' meson.build' .. exists_tag(has_meson),
      desc  = 'Interactive Meson wizard with auto-link detection',
    },
    {
      id    = 'j_gen_compile_commands',
      label = '󰘦 Generate compile_commands.json' .. exists_tag(has_ccmd),
      desc  = 'For clangd — via cmake, meson, bear, or compiledb',
    },
  }

  ui().select(items, {
    prompt      = 'Build System',
    on_back     = M.show,
    format_item = plain,
  }, function(ch)
    if ch then M._handle(ch.id, p, nil) end
  end)
end

-- ── compile_commands generator ────────────────────────────────────────────────
function M.show_compile_commands_menu(p)
  local root           = p and p.root or vim.fn.getcwd()
  local has_cmake_file = vim.fn.filereadable(root .. '/CMakeLists.txt') == 1
  local has_meson_file = vim.fn.filereadable(root .. '/meson.build') == 1
  local has_make_file  = vim.fn.filereadable(root .. '/Makefile') == 1
  local has_bear       = vim.fn.executable('bear') == 1
  local has_compdb     = vim.fn.executable('compiledb') == 1
  local has_cmake_bin  = vim.fn.executable('cmake') == 1
  local has_meson_bin  = vim.fn.executable('meson') == 1

  local items          = {}
  local function add(t) items[#items + 1] = t end

  if has_meson_file and has_meson_bin then
    add({
      id = 'ccmd_meson',
      label = '󰒓 Meson  (recommended for Meson projects)',
      desc =
      'meson setup builddir — compile_commands.json generated automatically'
    })
  end
  if has_cmake_file and has_cmake_bin then
    add({
      id = 'ccmd_cmake',
      label = '󰒓 CMake  (recommended)',
      desc =
      'cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -S .'
    })
  end
  if has_bear then
    if has_make_file then
      add({ id = 'ccmd_bear_make', label = '󰈙 bear + make', desc = 'bear -- make' })
    end
    add({ id = 'ccmd_bear_custom', label = '󰈙 bear + custom command…', desc = 'bear -- <cmd>' })
  end
  if has_compdb and has_make_file then
    add({ id = 'ccmd_compiledb', label = '󰘦 compiledb', desc = 'compiledb make' })
  end
  add({
    id = 'ccmd_clangd_file',
    label = '󰄬 Write .clangd config',
    desc =
    'No build needed — adds -Iinclude flags for clangd'
  })
  if #items == 1 then
    add({ id = 'ccmd_install_hint', label = '󰋖 How to install bear / compiledb', desc = 'Show installation instructions' })
  end

  ui().select(items, {
    prompt      = 'Generate compile_commands.json',
    on_back     = function() M.show_build_system_menu(p) end,
    format_item = plain,
  }, function(ch)
    if ch then M._handle(ch.id, p, nil) end
  end)
end

-- ── Meson introspect submenu ──────────────────────────────────────────────────
function M.show_meson_introspect_menu(p)
  local root  = p and p.root or vim.fn.getcwd()
  local items = {
    { id = 'mi_targets', label = '󰙅 Targets', desc = 'meson introspect --targets' },
    { id = 'mi_deps', label = '󰘦 Dependencies', desc = 'meson introspect --dependencies' },
    { id = 'mi_buildopts', label = '󰒓 Build Options', desc = 'meson introspect --buildoptions' },
    { id = 'mi_tests', label = '󰙨 Tests', desc = 'meson introspect --tests' },
    { id = 'mi_compilers', label = '󰙲 Compilers', desc = 'meson introspect --compilers' },
    { id = 'mi_installed', label = '󰇚 Installed Files', desc = 'meson introspect --installed' },
  }

  ui().select(items, {
    prompt      = 'Meson Introspect',
    on_back     = function() M.show() end,
    format_item = plain,
  }, function(ch)
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

-- ══════════════════════════════════════════════════════════════════════════════
-- PACKAGE AS LIBRARY WIZARD
-- ══════════════════════════════════════════════════════════════════════════════

function M.show_package_lib_wizard(p)
  local root         = p and p.root or vim.fn.getcwd()
  local default_name = vim.fn.fnamemodify(root, ':t'):gsub('-', '_')

  ui().input({ prompt = '󰘦 Library name', default = default_name }, function(name)
    if not name or name == '' then return end
    name = name:gsub('^lib', '')

    ui().select({
      { id = 'include', label = 'include/', desc = root .. '/include  (recommended)' },
      { id = 'src', label = 'src/  (*.h only)', desc = 'Headers alongside sources' },
      { id = 'root', label = '. (root *.h)', desc = 'Headers at project root' },
      { id = 'custom', label = '󰏫 Custom…', desc = 'Enter header directory path' },
    }, { prompt = 'Public header directory', format_item = plain }, function(hdr_ch)
      if not hdr_ch then return end

      local function after_hdr(hdr_dir)
        ui().select({
          { id = 'lib', label = 'lib/  (project-local)', desc = root .. '/lib/lib' .. name .. '.a' },
          { id = 'home_lib', label = '~/.local/lib', desc = vim.fn.expand('~/.local/lib') },
          { id = 'custom', label = '󰏫 Custom…', desc = 'Enter destination root' },
        }, { prompt = 'Export destination', format_item = plain }, function(dest_ch)
          if not dest_ch then return end

          local function after_dest(dest_root)
            ui().select({
              { id = 'c11',   label = 'C11' },
              { id = 'c17',   label = 'C17' },
              { id = 'c++17', label = 'C++17' },
              { id = 'c++20', label = 'C++20' },
            }, { prompt = 'Language standard', format_item = plain }, function(std_ch)
              local std = std_ch and std_ch.id or 'c11'

              ui().input({
                prompt  = 'Extra CFLAGS (optional)',
                default = '-Wall -Wextra -O2',
              }, function(cflags)
                M._do_package_lib({
                  name      = name,
                  root      = root,
                  hdr_dir   = hdr_dir,
                  dest_root = dest_root,
                  std       = std,
                  cflags    = cflags or '-Wall -Wextra -O2',
                })
              end)
            end)
          end

          if dest_ch.id == 'lib' then
            after_dest(root .. '/lib')
          elseif dest_ch.id == 'home_lib' then
            after_dest(vim.fn.expand('~/.local/lib'))
          else
            ui().input({ prompt = 'Destination directory', default = root .. '/lib' }, function(d)
              if d and d ~= '' then after_dest(d) end
            end)
          end
        end)
      end

      if hdr_ch.id == 'custom' then
        ui().input({ prompt = 'Header directory', default = root .. '/include' }, function(d)
          if d and d ~= '' then after_hdr(d) end
        end)
      elseif hdr_ch.id == 'src' then
        after_hdr(root .. '/src')
      elseif hdr_ch.id == 'root' then
        after_hdr(root)
      else
        after_hdr(root .. '/include')
      end
    end)
  end)
end

function M._do_package_lib(opts)
  local name      = opts.name
  local root      = opts.root
  local hdr_dir   = opts.hdr_dir
  local dest_root = opts.dest_root
  local std       = opts.std or 'c11'
  local cflags    = opts.cflags or '-Wall -Wextra -O2'

  local has_cpp   = std:find('+') ~= nil
  local cc        = has_cpp and 'g++' or 'gcc'
  local std_flag  = '-std=' .. std

  local src_ext   = has_cpp and [[-name '*.cpp' -o -name '*.cxx' -o -name '*.cc']] or [[-name '*.c']]
  local src_cmd   = string.format(
    "find '%s' \\( %s \\) -not -path '*/.marvin-obj/*' -not -path '*/lib/*' -type f 2>/dev/null | sort",
    root:gsub("'", "'\\''"), src_ext)

  local sources   = {}
  local h         = io.popen(src_cmd)
  if h then
    for line in h:lines() do
      local t = vim.trim(line)
      if t ~= '' then sources[#sources + 1] = t end
    end
    h:close()
  end

  if #sources == 0 then
    vim.notify('[Marvin] No sources found in ' .. root .. ' for packaging.', vim.log.levels.ERROR)
    return
  end

  local obj_dir   = root .. '/.marvin-obj-lib-' .. name
  local archive   = dest_root .. '/lib' .. name .. '.a'
  local inc_dest  = dest_root .. '/include/' .. name

  local inc_flags = {}
  for _, d in ipairs({ root .. '/include', root .. '/src', root }) do
    if vim.fn.isdirectory(d) == 1 then
      inc_flags[#inc_flags + 1] = '-I' .. d
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
  local inc_str = table.concat(inc_flags, ' ')

  local function esc(s) return vim.fn.shellescape(tostring(s)) end
  local function sh(s) return "'" .. s:gsub("'", "'\\''") .. "'" end

  local steps = {
    'mkdir -p ' .. esc(obj_dir),
    'mkdir -p ' .. esc(dest_root),
    'mkdir -p ' .. esc(inc_dest),
  }

  local obj_files = {}
  for _, src in ipairs(sources) do
    local stem                = vim.fn.fnamemodify(src, ':t:r')
    local obj                 = obj_dir .. '/' .. stem .. '.o'
    obj_files[#obj_files + 1] = obj
    steps[#steps + 1]         = string.format(
      '%s %s %s %s -c %s -o %s',
      cc, std_flag, cflags, inc_str, esc(src), esc(obj))
  end

  steps[#steps + 1] = string.format('ar rcs %s %s',
    esc(archive),
    table.concat(vim.tbl_map(esc, obj_files), ' '))

  steps[#steps + 1] = 'ranlib ' .. esc(archive) .. ' 2>/dev/null || true'

  if vim.fn.isdirectory(hdr_dir) == 1 then
    steps[#steps + 1] = string.format(
      "find %s -maxdepth 2 \\( -name '*.h' -o -name '*.hpp' -o -name '*.hxx' \\) -exec cp {} %s/ \\;",
      sh(hdr_dir), sh(inc_dest))
  else
    vim.notify('[Marvin] Header directory not found: ' .. hdr_dir
      .. '\nLibrary will be built without headers.', vim.log.levels.WARN)
  end

  steps[#steps + 1] = 'rm -rf ' .. esc(obj_dir)

  local cmd = table.concat(steps, ' && \\\n  ')

  require('core.runner').execute({
    cmd      = cmd,
    cwd      = root,
    title    = 'Package lib' .. name .. '.a',
    term_cfg = require('marvin').config.terminal,
    plugin   = 'marvin',
    on_exit  = function(ok)
      if not ok then
        vim.notify('[Marvin] ❌ Library packaging failed.', vim.log.levels.ERROR)
        return
      end

      local summary = string.format(
        '[Marvin] ✅ Packaged lib%s\n'
        .. '  Archive : %s\n'
        .. '  Headers : %s\n\n'
        .. '  To use in another project:\n'
        .. '    gcc main.c -I%s/include -L%s -l%s -o app\n'
        .. '    #include <%s/foo.h>',
        name, archive, inc_dest,
        dest_root, dest_root, name, name)
      vim.notify(summary, vim.log.levels.INFO)

      vim.schedule(function()
        M._offer_register_lib(root, dest_root, name)
      end)
    end,
  })
end

function M._offer_register_lib(root, dest_root, name)
  ui().select({
    { id = 'yes', label = '󰐕 Yes — register "' .. vim.fn.fnamemodify(dest_root, ':~:.') .. '" as library search path' },
    { id = 'no', label = '󰅖 No thanks' },
  }, { prompt = 'Register for auto-discovery?', format_item = plain }, function(ch)
    if not ch or ch.id == 'no' then return end
    local ok, ll = pcall(require, 'marvin.local_libs')
    if not ok then return end
    ll.show_register_after_export(root, dest_root)
  end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- ACTION HANDLER
-- ══════════════════════════════════════════════════════════════════════════════

function M._handle(id, p, meta)
  local b    = bld()
  local root = p and p.root or vim.fn.getcwd()

  local function run(cmd, title, on_exit)
    require('core.runner').execute({
      cmd      = cmd,
      cwd      = root,
      title    = title,
      term_cfg = require('marvin').config.terminal,
      plugin   = 'marvin',
      on_exit  = on_exit,
    })
  end

  -- ── Package as Library ────────────────────────────────────────────────────
  if id == 'j_package_lib' then
    M.show_package_lib_wizard(p)

    -- ── Core build actions ────────────────────────────────────────────────────
  elseif id == 'j_build' then
    b.build()
  elseif id == 'j_run' then
    b.run()
  elseif id == 'j_test' then
    b.test()
  elseif id == 'j_clean' then
    b.clean()
  elseif id == 'j_build_run' then
    b.build_and_run()
  elseif id == 'j_build_args' then
    b.build(true)
  elseif id == 'j_run_args' then
    b.run(true)
  elseif id == 'j_test_filter' then
    b.test(true)
  elseif id == 'j_fmt' then
    b.fmt()
  elseif id == 'j_lint' then
    b.lint()
  elseif id == 'j_package' then
    b.package()
  elseif id == 'j_install' then
    b.install()
  elseif id == 'j_console' then
    require('marvin.console').toggle()
  elseif id == 'j_switch' then
    require('marvin.dashboard').show_project_picker()

    -- ── Build system submenu ──────────────────────────────────────────────────
  elseif id == 'j_build_system_menu' then
    M.show_build_system_menu(p)
  elseif id == 'j_new_cmake' then
    require('marvin.cmake_creator').create(root, function()
      det().set(nil)
      M.show_build_system_menu(det().get())
    end)
  elseif id == 'j_new_makefile' then
    require('marvin.makefile_creator').create(root, function()
      det().set(nil)
      M.show_build_system_menu(det().get())
    end)
  elseif id == 'j_new_meson' then
    require('marvin.meson_creator').create(root, function()
      -- Invalidate the cached project so the next detect() finds meson.build
      det().set(nil)
      M.show_build_system_menu(det().get())
    end)
  elseif id == 'j_gen_compile_commands' then
    M.show_compile_commands_menu(p)

    -- ── Meson-specific ────────────────────────────────────────────────────────
  elseif id == 'j_meson_setup' then
    local configured = vim.fn.isdirectory(root .. '/builddir') == 1
        or vim.fn.isdirectory(root .. '/build') == 1
    local cmd = configured
        and 'meson setup --reconfigure builddir'
        or 'meson setup builddir'
    run(cmd, 'Meson Setup', function(ok)
      if ok then
        -- Symlink compile_commands.json to root for clangd
        vim.defer_fn(function()
          local src = root .. '/builddir/compile_commands.json'
          local dst = root .. '/compile_commands.json'
          if vim.fn.filereadable(src) == 1 and vim.fn.filereadable(dst) == 0 then
            vim.fn.system('ln -sf ' .. vim.fn.shellescape(src) .. ' ' .. vim.fn.shellescape(dst))
            vim.notify('[Marvin] compile_commands.json symlinked from builddir.\nRun :LspRestart',
              vim.log.levels.INFO)
          end
        end, 800)
      end
    end)
  elseif id == 'j_meson_introspect' then
    M.show_meson_introspect_menu(p)

    -- ── compile_commands methods ──────────────────────────────────────────────
  elseif id == 'ccmd_meson' then
    run('meson setup builddir', 'Meson Setup (compile_commands)', function(ok)
      if not ok then return end
      vim.defer_fn(function()
        local src = root .. '/builddir/compile_commands.json'
        local dst = root .. '/compile_commands.json'
        if vim.fn.filereadable(src) == 1 then
          vim.fn.system('ln -sf ' .. vim.fn.shellescape(src) .. ' ' .. vim.fn.shellescape(dst))
          vim.notify('[Jason] compile_commands.json ready.\nRun :LspRestart', vim.log.levels.INFO)
        end
      end, 800)
    end)
  elseif id == 'ccmd_cmake' then
    run('cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
      'Generate compile_commands.json',
      function(ok)
        if not ok then return end
        vim.defer_fn(function()
          local src = root .. '/build/compile_commands.json'
          local dst = root .. '/compile_commands.json'
          if vim.fn.filereadable(src) == 1 then
            vim.fn.system('ln -sf ' .. vim.fn.shellescape(src) .. ' ' .. vim.fn.shellescape(dst))
            vim.notify('[Jason] compile_commands.json ready.\nRun :LspRestart', vim.log.levels.INFO)
          end
        end, 500)
      end)
  elseif id == 'ccmd_bear_make' then
    run('bear -- make', 'bear + make', function(ok)
      if ok then vim.notify('[Jason] compile_commands.json written.\nRun :LspRestart', vim.log.levels.INFO) end
    end)
  elseif id == 'ccmd_bear_custom' then
    ui().input({ prompt = 'Build command for bear', default = 'make' }, function(cmd)
      if cmd and cmd ~= '' then
        run('bear -- ' .. cmd, 'bear + ' .. cmd, function(ok)
          if ok then vim.notify('[Jason] compile_commands.json written.\nRun :LspRestart', vim.log.levels.INFO) end
        end)
      end
    end)
  elseif id == 'ccmd_compiledb' then
    run('compiledb make', 'compiledb', function(ok)
      if ok then vim.notify('[Jason] compile_commands.json written.\nRun :LspRestart', vim.log.levels.INFO) end
    end)
  elseif id == 'ccmd_clangd_file' then
    local inc_flags = {}
    for _, d in ipairs({ 'include', 'src', '.' }) do
      if vim.fn.isdirectory(root .. '/' .. d) == 1 then
        inc_flags[#inc_flags + 1] = '-I' .. d
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
    local cfg   = require('marvin').config.cpp or {}
    local std   = cfg.standard or 'c11'
    local lang  = (cfg.compiler == 'g++' or cfg.compiler == 'clang++') and 'c++' or 'c'
    local flags = {}
    for _, f in ipairs(inc_flags) do flags[#flags + 1] = f end
    flags[#flags + 1] = '-std=' .. std
    flags[#flags + 1] = '-x'
    flags[#flags + 1] = lang
    local content     = 'CompileFlags:\n  Add: [' .. table.concat(flags, ', ') .. ']\n'
    local path        = root .. '/.clangd'
    local function write_clangd()
      local f = io.open(path, 'w')
      if f then
        f:write(content); f:close()
        vim.cmd('edit ' .. vim.fn.fnameescape(path))
        vim.notify('[Jason] .clangd written.\nRun :LspRestart', vim.log.levels.INFO)
      end
    end
    if vim.fn.filereadable(path) == 1 then
      ui().select({
          { id = 'overwrite', label = 'Overwrite existing .clangd' },
          { id = 'cancel',    label = 'Cancel' },
        }, { prompt = '.clangd already exists', format_item = plain },
        function(ch) if ch and ch.id == 'overwrite' then write_clangd() end end)
    else
      write_clangd()
    end
  elseif id == 'ccmd_install_hint' then
    vim.api.nvim_echo({ { table.concat({
      '',
      '  Install bear (wraps any build system):',
      '    Ubuntu/Debian : sudo apt install bear',
      '    macOS         : brew install bear',
      '    Arch          : sudo pacman -S bear',
      '',
      '  Install compiledb (Make-based projects):',
      '    pip install compiledb',
      '',
      '  Meson generates compile_commands.json automatically:',
      '    meson setup builddir',
      '    ln -sf builddir/compile_commands.json .',
      '',
      '  Or use CMake:',
      '    cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
      '    ln -sf build/compile_commands.json .',
      '',
    }, '\n'), 'Normal' } }, true, {})

    -- ── C/C++ tools ───────────────────────────────────────────────────────────
  elseif id == 'j_cpp_info' then
    require('marvin.build').show_cpp_info()
  elseif id == 'j_build_file' then
    require('marvin.build').build_current_file()
  elseif id == 'j_cmake_cfg' then
    run('cmake -B build -S .', 'CMake Configure')

    -- ── Rust extras ───────────────────────────────────────────────────────────
  elseif id == 'j_rust_profile' then
    local cfg = require('marvin').config
    cfg.rust.profile = cfg.rust.profile == 'release' and 'dev' or 'release'
    vim.notify('[Jason] Rust profile → ' .. cfg.rust.profile, vim.log.levels.INFO)
    vim.schedule(M.show)
  elseif id == 'j_clippy' then
    b.custom('cargo clippy', 'Clippy')
  elseif id == 'j_bench' then
    b.custom('cargo bench', 'Bench')
  elseif id == 'j_doc' then
    b.custom('cargo doc --open', 'Doc')

    -- ── Go extras ─────────────────────────────────────────────────────────────
  elseif id == 'j_go_race' then
    b.custom('go test -race ./...', 'Test (race)')
  elseif id == 'j_go_cover' then
    b.custom('go test -cover -coverprofile=coverage.out ./...', 'Test + Cover')
  elseif id == 'j_go_vet' then
    b.custom('go vet ./...', 'Vet')
  elseif id == 'j_go_doc' then
    b.custom('godoc -http=:6060', 'godoc')

    -- ── GraalVM ───────────────────────────────────────────────────────────────
  elseif id == 'j_graal_build' then
    require('marvin.graalvm').build_native(p)
  elseif id == 'j_graal_run' then
    require('marvin.graalvm').run_native(p)
  elseif id == 'j_graal_agent' then
    require('marvin.graalvm').run_with_agent(p)
  elseif id == 'j_graal_info' then
    require('marvin.graalvm').show_info()
  else
    -- Custom .jason.lua task
    local ok, tasks_m = pcall(require, 'marvin.tasks')
    if ok and p then tasks_m.handle_action(id, p) end
  end
end

return M
