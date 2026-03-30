-- lua/marvin/dashboard.lua
-- Unified Marvin dashboard. Detects the current project and routes
-- to the appropriate language module (lang/java, lang/rust, lang/go).
-- Jason (build/run/test) is accessed separately via :Jason / <leader>j.

local M = {}

-- ── UI helpers ────────────────────────────────────────────────────────────────
local function plain(it) return it.label end
local function sep(l) return { label = l, is_separator = true } end

local function item(id, icon, label, desc)
  return { id = id, _icon = icon, label = label, desc = desc }
end

local function ui() return require('marvin.ui') end
local function det() return require('marvin.detector') end

-- ── Language module registry ──────────────────────────────────────────────────
local LANG = {
  maven    = 'marvin.lang.java',
  gradle   = 'marvin.lang.java',
  cargo    = 'marvin.lang.rust',
  go_mod   = 'marvin.lang.go',
  cmake    = 'marvin.lang.cpp',
  makefile = 'marvin.lang.cpp',
}

local function lang_mod(ptype)
  local mod_name = LANG[ptype]
  if not mod_name then return nil end
  local ok, mod = pcall(require, mod_name)
  return ok and mod or nil
end

-- ── Dashboard header ──────────────────────────────────────────────────────────
local LANG_ICONS = {
  maven = '󰬷',
  gradle = '󰏗',
  cargo = '󱘗',
  go_mod = '󰟓',
  cmake = '󰙲',
  makefile = '󰙱',
  single_file = '󰈙',
}

local LANG_LABELS = {
  maven = 'Maven',
  gradle = 'Gradle',
  cargo = 'Cargo',
  go_mod = 'Go',
  cmake = 'CMake',
  makefile = 'Make',
  single_file = 'Single File',
}

local function build_prompt(p)
  if not p then return 'Marvin  (no project detected)' end
  local icon   = LANG_ICONS[p.type] or '󰙅'
  local label  = LANG_LABELS[p.type] or p.type
  local lmod   = lang_mod(p.type)
  local header = lmod and lmod.prompt_header(p) or p.name
  return string.format('Marvin  %s %s  %s', icon, label, header)
end

-- ── Create section (always shown) ────────────────────────────────────────────
local function create_items()
  return {
    sep('Create Project'),
    item('gen_maven', '󰬷', 'New Maven Project', 'Generate from Maven archetype'),
    item('gen_cargo_bin', '󱘗', 'New Cargo Binary', 'cargo new <name>'),
    item('gen_cargo_lib', '󱘗', 'New Cargo Library', 'cargo new --lib <name>'),
    item('gen_go', '󰟓', 'New Go Module', 'go mod init <module>'),
    sep('Create File'),
    item('new_makefile', '󰈙', 'New Makefile', 'Makefile creation wizard'),
  }
end

-- ── New-project / file handlers ───────────────────────────────────────────────

-- Shared helper: show ~/Code subdirs as a picker, then call back with the chosen dir.
local function prompt_location(callback)
  local code_dir    = vim.fn.expand('~/Code')
  local items       = {}

  -- Always offer ~/Code itself as the first option
  items[#items + 1] = {
    id    = '__code_root__',
    label = '~/Code',
    desc  = 'Project root',
    _path = code_dir,
  }

  -- List immediate subdirectories of ~/Code
  if vim.fn.isdirectory(code_dir) == 1 then
    local ok, entries = pcall(vim.fn.readdir, code_dir)
    if ok then
      -- Sort: directories only, alphabetical
      local dirs = {}
      for _, name in ipairs(entries) do
        if name:sub(1, 1) ~= '.'
            and vim.fn.isdirectory(code_dir .. '/' .. name) == 1 then
          dirs[#dirs + 1] = name
        end
      end
      table.sort(dirs)
      for _, name in ipairs(dirs) do
        items[#items + 1] = {
          id    = name,
          label = name,
          desc  = '~/Code/' .. name,
          _path = code_dir .. '/' .. name,
        }
      end
    end
  end

  -- Always offer a manual entry option at the bottom
  items[#items + 1] = {
    id    = '__custom__',
    label = 'Other…',
    desc  = 'Enter a custom path',
    _path = nil,
  }

  ui().select(items, {
    prompt        = 'Project location',
    enable_search = true,
    format_item   = function(it) return it.label end,
  }, function(choice)
    if not choice then return end

    if choice.id == '__custom__' then
      ui().input({ prompt = 'Parent directory', default = code_dir }, function(dir)
        if not dir or dir == '' then return end
        dir = vim.fn.expand(dir)
        if vim.fn.isdirectory(dir) == 0 then
          vim.notify('[Marvin] Directory not found: ' .. dir, vim.log.levels.ERROR)
          return
        end
        callback(dir)
      end)
    else
      callback(choice._path)
    end
  end)
end

-- Prompt to cd into the new project and open its manifest file.
local function offer_open_project(proj_dir, entry)
  vim.schedule(function()
    ui().select({
      { id = 'yes', label = '󰄬 Open project', desc = proj_dir },
      { id = 'no', label = '󰅖 Stay here', desc = '' },
    }, {
      prompt      = 'Project ready!',
      format_item = function(it) return it.label end,
    }, function(choice)
      if not choice or choice.id == 'no' then return end
      vim.cmd('cd ' .. vim.fn.fnameescape(proj_dir))
      local full = proj_dir .. '/' .. entry
      if vim.fn.filereadable(full) == 1 then
        vim.cmd('edit ' .. vim.fn.fnameescape(full))
      end
      -- Force Marvin to re-detect the new project
      require('marvin.detector')._project = nil
    end)
  end)
end

local function handle_no_project(id)
  if id == 'gen_maven' then
    require('marvin.generator').create_project()
  elseif id == 'gen_cargo_bin' then
    ui().input({ prompt = 'Crate name' }, function(name)
      if not name or name == '' then return end
      prompt_location(function(dir)
        local proj_dir = dir .. '/' .. name
        local cfg = vim.tbl_extend('force', require('marvin').config.terminal, { close_on_success = true })
        require('core.runner').execute({
          cmd      = 'cargo new ' .. name,
          cwd      = dir,
          title    = 'New Cargo Binary',
          term_cfg = cfg,
          on_exit  = function(ok)
            if ok then offer_open_project(proj_dir, 'Cargo.toml') end
          end,
        })
      end)
    end)
  elseif id == 'gen_cargo_lib' then
    ui().input({ prompt = 'Crate name' }, function(name)
      if not name or name == '' then return end
      prompt_location(function(dir)
        local proj_dir = dir .. '/' .. name
        local cfg = vim.tbl_extend('force', require('marvin').config.terminal, { close_on_success = true })
        require('core.runner').execute({
          cmd      = 'cargo new --lib ' .. name,
          cwd      = dir,
          title    = 'New Cargo Library',
          term_cfg = cfg,
          on_exit  = function(ok)
            if ok then offer_open_project(proj_dir, 'Cargo.toml') end
          end,
        })
      end)
    end)
  elseif id == 'gen_go' then
    ui().input({ prompt = 'Module path (e.g. github.com/you/project)' }, function(mod)
      if not mod or mod == '' then return end
      local default_name = vim.fn.fnamemodify(mod, ':t')
      ui().input({ prompt = 'Project directory name', default = default_name }, function(dirname)
        if not dirname or dirname == '' then return end
        prompt_location(function(parent)
          local proj_dir = parent .. '/' .. dirname
          vim.fn.mkdir(proj_dir, 'p')
          local cfg = vim.tbl_extend('force', require('marvin').config.terminal, { close_on_success = true })
          require('core.runner').execute({
            cmd      = 'go mod init ' .. mod,
            cwd      = proj_dir,
            title    = 'go mod init',
            term_cfg = cfg,
            on_exit  = function(ok)
              if ok then offer_open_project(proj_dir, 'go.mod') end
            end,
          })
        end)
      end)
    end)
  elseif id == 'new_makefile' then
    require('marvin.makefile_creator').create(vim.fn.getcwd(), M.show)
  end
end

-- ── C/C++ fallback (cmake/makefile — no lang module) ─────────────────────────
local function cpp_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end

  add(sep('Create'))
  add(item('new_makefile', '󰈙', 'New/Regenerate Makefile', 'Makefile creation wizard'))

  add(sep('Build'))
  if p.type == 'cmake' then
    add(item('cmake_cfg', '󰒓', 'Configure', 'cmake -B build -S .'))
    add(item('cmake_build', '󰑕', 'Build', 'cmake --build build'))
    add(item('cmake_test', '󰙨', 'Test', 'ctest --test-dir build'))
    add(item('cmake_clean', '󰃢', 'Clean', 'cmake --build build --target clean'))
    add(item('cmake_install', '󰇚', 'Install', 'cmake --install build'))
  else
    add(item('make_build', '󰑕', 'Build', 'make'))
    add(item('make_test', '󰙨', 'Test', 'make test'))
    add(item('make_clean', '󰃢', 'Clean', 'make clean'))
    add(item('make_install', '󰇚', 'Install', 'make install'))
  end

  add(sep('Console'))
  add(item('console', '󰋚', 'Task Console', 'View build output history'))
  return items
end

local function handle_cpp(id, p)
  local function run(cmd, title)
    require('core.runner').execute({
      cmd = cmd,
      cwd = p.root,
      title = title,
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  end
  if id == 'new_makefile' then
    require('marvin.makefile_creator').create(p.root, M.show)
  elseif id == 'cmake_cfg' then
    run('cmake -B build -S .', 'CMake Configure')
  elseif id == 'cmake_build' then
    run('cmake --build build', 'CMake Build')
  elseif id == 'cmake_test' then
    run('ctest --test-dir build', 'CTest')
  elseif id == 'cmake_clean' then
    run('cmake --build build --target clean', 'CMake Clean')
  elseif id == 'cmake_install' then
    run('cmake --install build', 'CMake Install')
  elseif id == 'make_build' then
    run('make', 'Make')
  elseif id == 'make_test' then
    run('make test', 'Make Test')
  elseif id == 'make_clean' then
    run('make clean', 'Make Clean')
  elseif id == 'make_install' then
    run('make install', 'Make Install')
  elseif id == 'console' then
    require('marvin.console').toggle()
  end
end

-- ── Common footer (always appended) ──────────────────────────────────────────
local function footer_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end

  if p then
    local subs = require('marvin.detector').detect_sub_projects(vim.fn.getcwd())
    if subs and #subs > 1 then
      add(sep('Workspace'))
      add(item('switch_project', '󰙅', 'Switch Project…',
        #subs .. ' sub-projects detected'))
    end
  end

  add(sep('Tools'))
  add(item('console', '󰋚', 'Task Console', 'Jason build output history'))
  add(item('reload', '󰚰', 'Reload Project', 'Re-parse the manifest'))
  if p then
    add(item('open_manifest', '󰈙', 'Open Manifest', 'Edit the project manifest file'))
  end

  return items
end

local function handle_footer(id, p)
  if id == 'console' then
    require('marvin.console').toggle()
  elseif id == 'switch_project' then
    M.show_project_picker()
  elseif id == 'reload' then
    require('marvin.detector').reload()
    vim.notify('[Marvin] Project reloaded', vim.log.levels.INFO)
    vim.schedule(M.show)
  elseif id == 'open_manifest' and p then
    local manifests = {
      maven = 'pom.xml',
      gradle = 'build.gradle',
      cargo = 'Cargo.toml',
      go_mod = 'go.mod',
      cmake = 'CMakeLists.txt',
    }
    local f = manifests[p.type]
    if f and vim.fn.filereadable(p.root .. '/' .. f) == 1 then
      vim.cmd('edit ' .. vim.fn.fnameescape(p.root .. '/' .. f))
    end
  end
end

-- ── Main show function ────────────────────────────────────────────────────────
function M.show()
  local det   = require('marvin.detector')
  local p     = det.get()
  local lmod  = p and lang_mod(p.type)

  local items = {}
  local function add_all(t) for _, v in ipairs(t) do items[#items + 1] = v end end

  if not p then
    -- No project: create options first
    add_all(create_items())
    add_all(footer_items(nil))
  elseif lmod then
    -- Full language module (Java, Rust, Go)
    add_all(lmod.menu_items(p))
    add_all(footer_items(p))
    add_all(create_items())
  else
    -- single_file or unknown
    add_all(create_items())
    add_all(footer_items(p))
  end

  local prompt = build_prompt(p)

  ui().select(items, {
    prompt        = prompt,
    enable_search = true,
    format_item   = function(it)
      if it.is_separator then return it.label end
      return (it._icon and (it._icon .. ' ') or '') .. it.label
    end,
  }, function(choice)
    if not choice then return end
    local id   = choice.id
    local back = M.show

    -- Create / new-project actions (available from any context)
    if id == 'gen_maven' or id == 'gen_cargo_bin' or id == 'gen_cargo_lib'
        or id == 'gen_go' or id == 'new_makefile' then
      handle_no_project(id)

      -- Footer / tools actions
    elseif id == 'console' or id == 'switch_project'
        or id == 'reload' or id == 'open_manifest' then
      handle_footer(id, p)

      -- Language module actions (Java / Rust / Go)
    elseif lmod then
      lmod.handle(id, p, back)
    end
  end)
end

-- ── Project switcher (monorepo) ───────────────────────────────────────────────
function M.show_project_picker()
  local det  = require('marvin.detector')
  local subs = det.detect_sub_projects(vim.fn.getcwd())
  if not subs or #subs == 0 then
    vim.notify('[Marvin] No sub-projects found', vim.log.levels.INFO); return
  end

  local items = {}
  for _, sp in ipairs(subs) do
    local icon        = LANG_ICONS[sp.type] or '󰙅'
    local label       = LANG_LABELS[sp.type] or sp.type
    items[#items + 1] = {
      id    = sp.root,
      label = icon .. ' ' .. sp.name,
      desc  = label .. ' — ' .. sp.root,
      _proj = sp,
    }
  end

  ui().select(items, {
    prompt      = 'Switch Project',
    format_item = plain,
  }, function(choice)
    if choice then
      det.set(choice._proj)
      vim.notify('[Marvin] Active project → ' .. choice._proj.name, vim.log.levels.INFO)
      vim.schedule(M.show)
    end
  end)
end

return M
