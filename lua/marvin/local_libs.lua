-- lua/marvin/local_libs.lua
-- Local static library discovery, registration, linking, and building.
--
-- Discovery order:
--   1. Registered paths in .marvin-libs (per-project config file, auto-created)
--   2. Scan of common dirs: lib/, libs/, build/, . relative to project root
--      (also walks one level deep, e.g. build/lib/)
--
-- Build:
--   Compile all .c/.cpp sources in a directory into a static archive (.a)
--   then optionally export (copy) the .a + headers to a user-chosen prefix.
--
-- Link:
--   Show a picker of discovered libs; user selects which to add. The selected
--   libs produce -L<dir> -l<name> flags that are injected into the build pipeline.

local M = {}

local function ui() return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function plain(it) return it.label end

-- ── Config file helpers ───────────────────────────────────────────────────────
-- .marvin-libs lives at <project_root>/.marvin-libs
-- Format: one path per line (absolute or relative to root)

local CONFIG_FILE = '.marvin-libs'

local function config_path(root)
  return root .. '/' .. CONFIG_FILE
end

local function read_registered(root)
  local path = config_path(root)
  local f    = io.open(path, 'r')
  if not f then return {} end
  local paths = {}
  for line in f:lines() do
    local t = vim.trim(line)
    if t ~= '' and not t:match('^#') then
      paths[#paths + 1] = t
    end
  end
  f:close()
  return paths
end

local function write_registered(root, paths)
  local f = io.open(config_path(root), 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. config_path(root), vim.log.levels.ERROR)
    return false
  end
  f:write('# Marvin local library search paths\n')
  f:write('# One path per line — absolute or relative to project root\n')
  for _, p in ipairs(paths) do
    f:write(p .. '\n')
  end
  f:close()
  return true
end

local function add_registered_path(root, new_path)
  local existing = read_registered(root)
  for _, p in ipairs(existing) do
    if p == new_path then return end -- already registered
  end
  existing[#existing + 1] = new_path
  write_registered(root, existing)
  vim.notify('[Marvin] Registered library path: ' .. new_path, vim.log.levels.INFO)
end

local function remove_registered_path(root, target)
  local existing = read_registered(root)
  local new = {}
  for _, p in ipairs(existing) do
    if p ~= target then new[#new + 1] = p end
  end
  write_registered(root, new)
  vim.notify('[Marvin] Removed library path: ' .. target, vim.log.levels.INFO)
end

-- ── Library scanning ──────────────────────────────────────────────────────────
-- Returns a list of { name, path, dir, kind } where:
--   name = "tui"  (stripped of lib prefix and .a suffix)
--   path = "/abs/path/to/libtui.a"
--   dir  = "/abs/path/to/"  (for -L flag)
--   kind = "static" | "shared"

local SCAN_DIRS = {
  '.',
  'lib',
  'libs',
  'build',
  'build/lib',
  'build/libs',
  'out',
  'out/lib',
  'dist',
}

local function abs(path)
  return vim.fn.fnamemodify(path, ':p'):gsub('/+$', '')
end

local function scan_dir_for_libs(dir_abs)
  local found = {}
  if vim.fn.isdirectory(dir_abs) == 0 then return found end

  -- Find .a and .so/.dylib files one level deep
  local patterns = { '*.a', '*.so', '*.dylib' }
  for _, pat in ipairs(patterns) do
    local files = vim.fn.glob(dir_abs .. '/' .. pat, false, true)
    for _, f in ipairs(files) do
      local fname = vim.fn.fnamemodify(f, ':t')
      local kind  = fname:match('%.a$') and 'static'
          or fname:match('%.so') and 'shared'
          or fname:match('%.dylib$') and 'shared'
          or nil
      if kind then
        -- Strip lib prefix and extension: libtui.a → tui
        local name = fname:gsub('^lib', ''):gsub('%.a$', ''):gsub('%.so.*$', ''):gsub('%.dylib$', '')
        if name ~= '' then
          found[#found + 1] = {
            name = name,
            path = abs(f),
            dir  = dir_abs,
            kind = kind,
          }
        end
      end
    end
  end
  return found
end

-- Deduplicate by path
local function dedup(libs)
  local seen, out = {}, {}
  for _, lib in ipairs(libs) do
    if not seen[lib.path] then
      seen[lib.path] = true
      out[#out + 1] = lib
    end
  end
  return out
end

function M.discover(root)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())
  local all = {}

  -- 1. Registered paths
  for _, rpath in ipairs(read_registered(root)) do
    local resolved = rpath:match('^/') and rpath or (root .. '/' .. rpath)
    resolved = abs(resolved)
    for _, lib in ipairs(scan_dir_for_libs(resolved)) do
      all[#all + 1] = lib
    end
  end

  -- 2. Common dirs
  for _, d in ipairs(SCAN_DIRS) do
    local full = abs(root .. '/' .. d)
    for _, lib in ipairs(scan_dir_for_libs(full)) do
      all[#all + 1] = lib
    end
  end

  return dedup(all)
end

-- ── Companion header dir detection ───────────────────────────────────────────
-- Given a lib path like /some/path/libtui.a, looks for include/ or headers/
-- next to the .a or one level up.
local function find_include_dir(lib)
  local dir = lib.dir
  for _, sub in ipairs({ 'include', 'headers', '../include', '../headers' }) do
    local candidate = abs(dir .. '/' .. sub)
    if vim.fn.isdirectory(candidate) == 1 then
      return candidate
    end
  end
  return nil
end

-- ── Linker flag generation ────────────────────────────────────────────────────
-- Returns { lflags = "-Ldir -lname ...", iflags = "-Iinclude ..." }
function M.flags_for(selected_libs)
  local ldirs, lnames, idirs = {}, {}, {}
  local seen_ldir, seen_inc = {}, {}

  for _, lib in ipairs(selected_libs) do
    if not seen_ldir[lib.dir] then
      seen_ldir[lib.dir] = true
      ldirs[#ldirs + 1] = '-L' .. lib.dir
    end
    lnames[#lnames + 1] = '-l' .. lib.name

    local inc = find_include_dir(lib)
    if inc and not seen_inc[inc] then
      seen_inc[inc] = true
      idirs[#idirs + 1] = '-I' .. inc
    end
  end

  local lflags = table.concat(ldirs, ' ') .. ' ' .. table.concat(lnames, ' ')
  local iflags = table.concat(idirs, ' ')
  return { lflags = vim.trim(lflags), iflags = vim.trim(iflags) }
end

-- ── Persistent selection store ────────────────────────────────────────────────
-- Which libs the user has selected for this project live in .marvin-libs-sel
local SEL_FILE = '.marvin-libs-sel'

local function sel_path(root) return root .. '/' .. SEL_FILE end

local function read_selection(root)
  local f = io.open(sel_path(root), 'r')
  if not f then return {} end
  local sel = {}
  for line in f:lines() do
    local t = vim.trim(line)
    if t ~= '' then sel[t] = true end
  end
  f:close()
  return sel
end

local function write_selection(root, paths_set)
  local f = io.open(sel_path(root), 'w')
  if not f then return end
  for path, _ in pairs(paths_set) do
    f:write(path .. '\n')
  end
  f:close()
end

-- ── Public: get currently selected libs for a project ─────────────────────────
function M.selected_libs(root)
  root           = abs(root)
  local sel      = read_selection(root)
  local all      = M.discover(root)
  local selected = {}
  for _, lib in ipairs(all) do
    if sel[lib.path] then
      selected[#selected + 1] = lib
    end
  end
  return selected
end

-- ── Public: flags to inject into build (called from build.lua CPP engine) ─────
function M.build_flags(root)
  local sel = M.selected_libs(root)
  if #sel == 0 then return { lflags = '', iflags = '' } end
  return M.flags_for(sel)
end

-- ── UI: link picker ───────────────────────────────────────────────────────────
function M.show_link_picker(root, on_done)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())
  local libs = M.discover(root)

  if #libs == 0 then
    vim.notify(
      '[Marvin] No local libraries found.\n'
      .. 'Use "Register Library Path" to add a search directory,\n'
      .. 'or place .a/.so files in lib/, libs/, or build/.',
      vim.log.levels.WARN)
    return
  end

  local sel   = read_selection(root)
  local items = {}
  for _, lib in ipairs(libs) do
    local inc         = find_include_dir(lib)
    local inc_tag     = inc and ('  +I' .. vim.fn.fnamemodify(inc, ':~:.')) or ''
    local tick        = sel[lib.path] and '● ' or '○ '
    items[#items + 1] = {
      id    = lib.path,
      label = tick .. lib.name .. '  [' .. lib.kind .. ']' .. inc_tag,
      desc  = vim.fn.fnamemodify(lib.path, ':~:.'),
      _lib  = lib,
      _sel  = sel[lib.path] or false,
    }
  end

  -- Summary header item
  local n_sel = 0
  for _ in pairs(sel) do n_sel = n_sel + 1 end
  local prompt = string.format('Link Libraries  (%d found, %d selected)', #libs, n_sel)

  ui().select(items, {
    prompt        = prompt,
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then
      if on_done then on_done() end
      return
    end
    -- Toggle selection
    if sel[choice.id] then
      sel[choice.id] = nil
    else
      sel[choice.id] = true
    end
    write_selection(root, sel)

    local action = sel[choice.id] and 'Added' or 'Removed'
    vim.notify(
      string.format('[Marvin] %s %s\nFlags: %s',
        action, choice._lib.name,
        M.flags_for(M.selected_libs(root)).lflags),
      vim.log.levels.INFO)

    -- Re-open picker so user can toggle more
    vim.schedule(function() M.show_link_picker(root, on_done) end)
  end)
end

-- ── UI: register a path ───────────────────────────────────────────────────────
function M.show_register_path(root, on_back)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())

  ui().input({
    prompt  = 'Library search path (absolute or relative to project root)',
    default = 'lib',
  }, function(input)
    if not input or input == '' then return end
    local resolved = input:match('^/') and input or (root .. '/' .. input)
    if vim.fn.isdirectory(resolved) == 0 then
      vim.notify(
        '[Marvin] Directory does not exist: ' .. resolved .. '\n'
        .. '(It will still be saved — useful if the dir will be created by a build step)',
        vim.log.levels.WARN)
    end
    add_registered_path(root, input)
    if on_back then on_back() end
  end)
end

-- ── UI: manage registered paths ───────────────────────────────────────────────
function M.show_manage_paths(root, on_back)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())
  local paths = read_registered(root)

  local items = {}
  for _, p in ipairs(paths) do
    items[#items + 1] = {
      id    = p,
      label = '󰍴 ' .. p,
      desc  = 'Click to remove',
    }
  end
  items[#items + 1] = {
    id    = '__add__',
    label = '󰐕 Add new path…',
    desc  = 'Register a directory to scan for .a/.so files',
  }

  local prompt = 'Registered Library Paths'
      .. (#paths > 0 and ('  (' .. #paths .. ')') or '  (none)')

  ui().select(items, {
    prompt      = prompt,
    on_back     = on_back,
    format_item = plain,
  }, function(choice)
    if not choice then return end
    if choice.id == '__add__' then
      M.show_register_path(root, function()
        vim.schedule(function() M.show_manage_paths(root, on_back) end)
      end)
    else
      -- Confirm removal
      ui().select({
        { id = 'yes', label = 'Yes — remove this path' },
        { id = 'no', label = 'Cancel' },
      }, { prompt = 'Remove: ' .. choice.id, format_item = plain }, function(ch)
        if ch and ch.id == 'yes' then
          remove_registered_path(root, choice.id)
        end
        vim.schedule(function() M.show_manage_paths(root, on_back) end)
      end)
    end
  end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- LIBRARY BUILDER
-- Compiles all .c/.cpp sources in a chosen directory into a static archive.
-- ══════════════════════════════════════════════════════════════════════════════

local function run(cmd, root, title, on_exit)
  require('core.runner').execute({
    cmd      = cmd,
    cwd      = root,
    title    = title,
    term_cfg = require('marvin').config.terminal,
    plugin   = 'marvin',
    on_exit  = on_exit,
  })
end

local function esc(s) return vim.fn.shellescape(tostring(s)) end

local function sh_path(p)
  return "'" .. p:gsub("'", "'\\''") .. "'"
end

-- Collect .c/.cpp sources from a directory (non-recursive by default)
local function collect_sources(dir, recursive)
  local exts = { '*.c', '*.cpp', '*.cxx', '*.cc' }
  local files = {}
  for _, pat in ipairs(exts) do
    local glob_pat = recursive and ('**/' .. pat) or pat
    local found    = vim.fn.glob(dir .. '/' .. glob_pat, false, true)
    for _, f in ipairs(found) do
      files[#files + 1] = abs(f)
    end
  end
  return files
end

-- Infer include dirs relative to the source dir
local function infer_includes(src_dir, root)
  local candidates = {
    src_dir,
    src_dir .. '/include',
    src_dir .. '/../include',
    root .. '/include',
    root,
  }
  local flags      = {}
  local seen       = {}
  for _, d in ipairs(candidates) do
    local a = abs(d)
    if not seen[a] and vim.fn.isdirectory(a) == 1 then
      seen[a] = true
      flags[#flags + 1] = '-I' .. a
    end
  end
  return flags
end

-- Build a static lib from sources in `src_dir`, output to `out_dir/lib<name>.a`
function M.build_static(opts)
  -- opts: { name, src_dir, out_dir, root, recursive, std, cflags }
  local name      = opts.name
  local src_dir   = abs(opts.src_dir)
  local out_dir   = abs(opts.out_dir)
  local root      = abs(opts.root or vim.fn.getcwd())
  local std       = opts.std or 'c11'
  local cflags    = opts.cflags or '-Wall -Wextra'
  local recursive = opts.recursive ~= false -- default true

  local sources   = collect_sources(src_dir, recursive)
  if #sources == 0 then
    vim.notify('[Marvin] No C/C++ sources found in: ' .. src_dir, vim.log.levels.ERROR)
    return
  end

  -- Detect language from sources
  local has_cpp = false
  for _, f in ipairs(sources) do
    if f:match('%.cpp$') or f:match('%.cxx$') or f:match('%.cc$') then
      has_cpp = true; break
    end
  end
  local cc        = has_cpp and 'g++' or 'gcc'
  local std_flag  = '-std=' .. (has_cpp and std:gsub('^c(%d)', 'c++%1') or std)

  local inc_flags = table.concat(infer_includes(src_dir, root), ' ')
  local obj_dir   = out_dir .. '/.marvin-obj-' .. name
  local archive   = out_dir .. '/lib' .. name .. '.a'

  -- Build compile steps for each source
  local steps     = {
    'mkdir -p ' .. esc(obj_dir),
    'mkdir -p ' .. esc(out_dir),
  }
  local obj_files = {}
  for _, src in ipairs(sources) do
    local rel                 = vim.fn.fnamemodify(src, ':t:r')
    local obj                 = obj_dir .. '/' .. rel .. '.o'
    obj_files[#obj_files + 1] = obj
    steps[#steps + 1]         = string.format(
      '%s %s %s %s -c %s -o %s',
      cc, std_flag, cflags, inc_flags, esc(src), esc(obj))
  end

  -- Archive step
  steps[#steps + 1] = string.format(
    'ar rcs %s %s',
    esc(archive),
    table.concat(vim.tbl_map(esc, obj_files), ' '))

  -- Cleanup obj dir
  steps[#steps + 1] = 'rm -rf ' .. esc(obj_dir)

  local cmd = table.concat(steps, ' && \\\n  ')
  local title = 'Build lib' .. name .. '.a'

  run(cmd, root, title, function(ok)
    if ok then
      vim.notify(
        string.format('[Marvin] ✅ Built %s\n→ %s', 'lib' .. name .. '.a', archive),
        vim.log.levels.INFO)
      -- Offer to export
      vim.schedule(function()
        M.show_export_prompt(name, archive, src_dir, root)
      end)
    else
      vim.notify('[Marvin] ❌ Build failed for lib' .. name .. '.a', vim.log.levels.ERROR)
    end
  end)
end

-- ── Export / install built library ───────────────────────────────────────────
-- Copies the .a and header files to a chosen destination so other projects
-- can discover it via scan or registered path.

function M.show_export_prompt(name, archive_path, src_dir, root)
  ui().select({
    { id = 'local_lib', label = '󰉿 Export to project lib/ dir', desc = root .. '/lib/lib' .. name .. '.a' },
    { id = 'local_home', label = '󰋜 Export to ~/.local/lib', desc = '~/.local/lib/lib' .. name .. '.a' },
    { id = 'custom', label = '󰏫 Choose export directory…', desc = 'Enter a custom path' },
    { id = 'skip', label = '󰅖 Skip export', desc = 'Keep the .a where it is' },
  }, { prompt = 'Export lib' .. name .. '.a ?', format_item = plain }, function(choice)
    if not choice or choice.id == 'skip' then return end

    local function do_export(dest_dir)
      dest_dir = abs(dest_dir)
      -- Also copy headers if include/ exists next to src
      local inc_src = nil
      for _, sub in ipairs({ src_dir .. '/include', abs(src_dir .. '/../include'), root .. '/include' }) do
        if vim.fn.isdirectory(sub) == 1 then
          inc_src = sub; break
        end
      end

      local dest_lib    = dest_dir .. '/lib' .. name .. '.a'
      local steps       = { 'mkdir -p ' .. esc(dest_dir) }
      steps[#steps + 1] = 'cp ' .. esc(archive_path) .. ' ' .. esc(dest_lib)

      local dest_inc    = nil
      if inc_src then
        dest_inc = dest_dir .. '/include'
        -- Only copy headers named after the lib (lib-specific) or all if small
        steps[#steps + 1] = 'mkdir -p ' .. esc(dest_inc)
        steps[#steps + 1] = 'cp -r ' .. esc(inc_src) .. '/. ' .. esc(dest_inc) .. '/'
      end

      local cmd = table.concat(steps, ' && \\\n  ')
      run(cmd, root, 'Export lib' .. name .. '.a', function(ok)
        if not ok then
          vim.notify('[Marvin] ❌ Export failed', vim.log.levels.ERROR)
          return
        end
        vim.notify(
          string.format('[Marvin] ✅ Exported lib%s.a → %s', name, dest_dir),
          vim.log.levels.INFO)
        -- Offer to register the destination as a search path
        vim.schedule(function()
          M.show_register_after_export(root, dest_dir)
        end)
      end)
    end

    if choice.id == 'local_lib' then
      do_export(root .. '/lib')
    elseif choice.id == 'local_home' then
      do_export(vim.fn.expand('~/.local/lib'))
    elseif choice.id == 'custom' then
      ui().input({ prompt = 'Export directory', default = root .. '/lib' }, function(d)
        if d and d ~= '' then do_export(d) end
      end)
    end
  end)
end

-- After export: offer to register the dir so it shows up in the link picker
function M.show_register_after_export(root, exported_dir)
  local rel = exported_dir:sub(#root + 2) -- make relative if inside project
  local display = rel ~= '' and rel or exported_dir

  ui().select({
    { id = 'yes', label = '󰐕 Yes — register "' .. display .. '" as a library search path' },
    { id = 'no', label = '󰅖 No thanks' },
  }, { prompt = 'Register path for auto-discovery?', format_item = plain }, function(ch)
    if ch and ch.id == 'yes' then
      add_registered_path(root, display)
    end
  end)
end

-- ── UI: Build Library wizard ──────────────────────────────────────────────────
function M.show_build_wizard(root, on_back)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())

  -- Step 1: library name
  ui().input({ prompt = '󰙲 Library name (e.g. tui, utils)', default = '' }, function(name)
    if not name or name == '' then return end
    name = name:gsub('^lib', '') -- strip accidental "lib" prefix

    -- Step 2: source directory
    ui().select({
      { id = 'src', label = 'src/', desc = root .. '/src' },
      { id = 'lib', label = 'lib/', desc = root .. '/lib' },
      { id = 'root', label = '. (project root)', desc = root },
      { id = 'custom', label = '󰏫 Custom…', desc = 'Enter path' },
    }, { prompt = 'Source directory', on_back = on_back, format_item = plain }, function(src_ch)
      if not src_ch then return end

      local function after_src(src_dir)
        -- Step 3: output directory
        ui().select({
          { id = 'lib', label = 'lib/', desc = root .. '/lib (recommended)' },
          { id = 'build', label = 'build/', desc = root .. '/build' },
          { id = 'custom', label = '󰏫 Custom…', desc = 'Enter path' },
        }, { prompt = 'Output directory for .a', format_item = plain }, function(out_ch)
          if not out_ch then return end

          local function after_out(out_dir)
            -- Step 4: C standard
            ui().select({
              { id = 'c11',   label = 'C11',   desc = 'Recommended for C' },
              { id = 'c17',   label = 'C17' },
              { id = 'c++17', label = 'C++17', desc = 'If sources are C++' },
              { id = 'c++20', label = 'C++20' },
            }, { prompt = 'Language standard', format_item = plain }, function(std_ch)
              local std = std_ch and std_ch.id or 'c11'

              -- Step 5: extra cflags
              ui().input({
                prompt  = 'Extra CFLAGS (optional)',
                default = '-Wall -Wextra -O2',
              }, function(cflags)
                M.build_static({
                  name      = name,
                  src_dir   = src_dir,
                  out_dir   = out_dir,
                  root      = root,
                  std       = std,
                  cflags    = cflags or '-Wall -Wextra -O2',
                  recursive = true,
                })
              end)
            end)
          end

          if out_ch.id == 'custom' then
            ui().input({ prompt = 'Output directory', default = root .. '/lib' }, function(d)
              if d and d ~= '' then after_out(d) end
            end)
          else
            after_out(root .. '/' .. out_ch.id)
          end
        end)
      end

      if src_ch.id == 'custom' then
        ui().input({ prompt = 'Source directory', default = root }, function(d)
          if d and d ~= '' then after_src(d) end
        end)
      else
        after_src(src_ch.id == 'root' and root or (root .. '/' .. src_ch.id))
      end
    end)
  end)
end

-- ── Main menu items (for lang/cpp.lua injection) ──────────────────────────────
function M.menu_items()
  local items = {}
  local function sep(l) items[#items + 1] = { label = l, is_separator = true } end
  local function it(id, icon, label, desc)
    items[#items + 1] = { id = id, label = icon .. ' ' .. label, desc = desc }
  end
  sep('Local Libraries')
  it('libs_link', '󰘦', 'Link Libraries…', 'Pick local .a/.so libs to link')
  it('libs_build', '󰑕', 'Build Static Library…', 'Compile sources → .a archive')
  it('libs_paths', '󰉿', 'Manage Library Paths…', 'Register / remove search dirs')
  it('libs_report', '󰙅', 'Library Report', 'Show discovered libs + active flags')
  return items
end

function M.handle(id, root, on_back)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())

  if id == 'libs_link' then
    M.show_link_picker(root, on_back)
  elseif id == 'libs_build' then
    M.show_build_wizard(root, on_back)
  elseif id == 'libs_paths' then
    M.show_manage_paths(root, on_back)
  elseif id == 'libs_report' then
    M.show_report(root)
  end
end

-- ── Report ────────────────────────────────────────────────────────────────────
function M.show_report(root)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())
  local all = M.discover(root)
  local sel = read_selection(root)

  local lines = {
    '',
    '  Local Library Report — ' .. vim.fn.fnamemodify(root, ':t'),
    '  ' .. string.rep('─', 56),
  }

  if #all == 0 then
    lines[#lines + 1] = '  (no libraries found)'
  else
    lines[#lines + 1] = string.format('  %-20s %-8s  %s', 'Library', 'Kind', 'Path')
    lines[#lines + 1] = '  ' .. string.rep('─', 56)
    for _, lib in ipairs(all) do
      local tick = sel[lib.path] and '● ' or '○ '
      lines[#lines + 1] = string.format('  %s%-18s %-8s  %s',
        tick, lib.name, lib.kind, vim.fn.fnamemodify(lib.path, ':~:.'))
    end
  end

  lines[#lines + 1] = ''
  local flags = M.build_flags(root)
  if flags.lflags ~= '' then
    lines[#lines + 1] = '  Active link flags:'
    lines[#lines + 1] = '    LDFLAGS: ' .. flags.lflags
    if flags.iflags ~= '' then
      lines[#lines + 1] = '    IFLAGS:  ' .. flags.iflags
    end
  else
    lines[#lines + 1] = '  No libraries selected for linking.'
    lines[#lines + 1] = '  Use "Link Libraries…" to pick from discovered libs.'
  end

  lines[#lines + 1] = ''
  lines[#lines + 1] = '  Registered search paths:'
  local reg = read_registered(root)
  if #reg == 0 then
    lines[#lines + 1] = '    (none)'
  else
    for _, p in ipairs(reg) do
      lines[#lines + 1] = '    ' .. p
    end
  end
  lines[#lines + 1] = ''

  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

return M
