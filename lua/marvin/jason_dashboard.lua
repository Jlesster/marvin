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
-- Declares what each project type supports so the menu only shows valid actions.
local META = {
  maven = {
    label = 'Maven',
    lang = 'Java',
    icon = '󰬷',
    has = {
      build = 1,
      run = 1,
      test = 1,
      clean = 1,
      build_run = 1,
      package = 1,
      install = 1,
      test_filter = 1
    },
  },
  gradle = {
    label = 'Gradle',
    lang = 'Java',
    icon = '󰏗',
    has = {
      build = 1,
      run = 1,
      test = 1,
      clean = 1,
      build_run = 1,
      package = 1,
      install = 1,
      test_filter = 1
    },
  },
  cargo = {
    label = 'Cargo',
    lang = 'Rust',
    icon = '󱘗',
    has = {
      build = 1,
      run = 1,
      test = 1,
      clean = 1,
      build_run = 1,
      package = 1,
      install = 1,
      fmt = 1,
      lint = 1,
      test_filter = 1
    },
  },
  go_mod = {
    label = 'Go',
    lang = 'Go',
    icon = '󰟓',
    has = {
      build = 1,
      run = 1,
      test = 1,
      clean = 1,
      build_run = 1,
      package = 1,
      install = 1,
      fmt = 1,
      lint = 1,
      test_filter = 1
    },
  },
  cmake = {
    label = 'CMake',
    lang = 'C/C++',
    icon = '󰙲',
    has = {
      build = 1,
      run = 1,
      test = 1,
      clean = 1,
      build_run = 1,
      package = 1,
      install = 1,
      fmt = 1,
      lint = 1
    },
  },
  makefile = {
    label = 'Make',
    lang = 'C/C++',
    icon = '󰙱',
    has = {
      build = 1,
      run = 1,
      test = 1,
      clean = 1,
      build_run = 1,
      package = 1,
      install = 1,
      fmt = 1,
      lint = 1
    },
  },
  single_file = {
    label = 'Single File',
    lang = nil,
    icon = '󰈙',
    has = { build = 1, run = 1, clean = 1, build_run = 1 },
  },
}

-- Language-specific extra actions
local EXTRAS = {
  cargo = function(_p)
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
  go_mod = function(_p)
    return {
      sep('Go'),
      item('j_go_race', '󰍉', 'Test (race)', 'go test -race ./...'),
      item('j_go_cover', '󰙨', 'Test + Coverage', 'go test -cover ./...'),
      item('j_go_vet', '󰅾', 'Vet', 'go vet ./...'),
      item('j_go_doc', '󰈙', 'godoc', 'godoc -http=:6060'),
    }
  end,
  cmake = function(p)
    local configured = vim.fn.isdirectory(p.root .. '/build') == 1
    return {
      sep('CMake'),
      item('j_cmake_cfg', '󰒓',
        configured and 'Re-configure' or 'Configure',
        'cmake -B build -S .'),
    }
  end,
  maven = function(_p)
    return {
      sep('GraalVM'),
      item('j_graal_build', '󰂮', 'Build Native Image', 'Compile to native binary'),
      item('j_graal_run', '󰐊', 'Run Native Binary', 'Execute native build'),
      item('j_graal_agent', '󰋊', 'Run with Agent', 'Collect reflection config'),
      item('j_graal_info', '󰙅', 'GraalVM Info', 'Status / install guide'),
    }
  end,
  gradle = function(p) return EXTRAS.maven(p) end,
}

-- ── Dashboard ─────────────────────────────────────────────────────────────────
function M.show()
  local p      = det().get()
  local meta   = p and META[p.type]
  local has    = (meta and meta.has) or {}
  local tool   = meta and meta.label or 'No Project'
  local lang   = meta and (meta.lang or (p and p.lang) or '') or ''
  local pname  = p and p.name or '(no project)'
  local icon   = meta and meta.icon or '󰙅'

  local prompt = string.format('Jason  %s %s  %s  [%s]', icon, tool, pname, lang)

  local items  = M._build_items(p, meta, has)

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

function M._build_items(p, meta, has)
  local items = {}
  local function add(t) items[#items + 1] = t end
  local function addall(t) for _, v in ipairs(t) do add(v) end end

  local tool = meta and meta.label or 'Actions'

  -- Core actions (filtered by project capability)
  add(sep(tool .. ' Actions'))
  if has.build_run then add(item('j_build_run', '󰑓', 'Build & Run', 'Compile then run')) end
  if has.build then add(item('j_build', '󰑕', 'Build', 'Compile')) end
  if has.run then add(item('j_run', '󰐊', 'Run', 'Run')) end
  if has.test then add(item('j_test', '󰙨', 'Test', 'Run tests')) end
  if has.clean then add(item('j_clean', '󰃢', 'Clean', 'Remove artifacts')) end

  -- With options
  local has_opts = has.build or has.run or has.test_filter
  if has_opts then
    add(sep('With Options'))
    if has.build then add(item('j_build_args', '󰒓', 'Build (args…)', 'Extra build flags')) end
    if has.run then add(item('j_run_args', '󰒓', 'Run (args…)', 'Runtime arguments')) end
    if has.test_filter then add(item('j_test_filter', '󰍉', 'Test (filter…)', 'Specific test name')) end
  end

  -- Extras (fmt/lint/package/install)
  local has_ex = has.fmt or has.lint or has.package or has.install
  if has_ex then
    add(sep('Extras'))
    if has.fmt then add(item('j_fmt', '󰉣', 'Format', 'Auto-format')) end
    if has.lint then add(item('j_lint', '󰅾', 'Lint', 'Run linter')) end
    if has.package then add(item('j_package', '󰏗', 'Package', 'Create distributable')) end
    if has.install then add(item('j_install', '󰇚', 'Install', 'Install to local registry')) end
  end

  -- Language-specific extras
  if p then
    local extras_fn = EXTRAS[p.type]
    if extras_fn then addall(extras_fn(p)) end
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

  -- No project: still useful
  if not p then
    add(sep('File Creation'))
    add(item('j_new_makefile', '󰈙', 'New Makefile', 'Makefile creation wizard'))
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

function M._handle(id, p, meta)
  local b = bld()

  if id == 'j_build' then
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
  elseif id == 'j_new_makefile' then
    require('marvin.makefile_creator').create(
      p and p.root or vim.fn.getcwd(), M.show)

    -- Rust extras
  elseif id == 'j_rust_profile' then
    local cfg = require('marvin').config
    cfg.rust.profile = cfg.rust.profile == 'release' and 'dev' or 'release'
    vim.notify('[Jason] Rust profile → ' .. cfg.rust.profile, vim.log.levels.INFO)
    vim.schedule(M.show) -- re-open so label updates
  elseif id == 'j_clippy' then
    b.custom('cargo clippy', 'Clippy')
  elseif id == 'j_bench' then
    b.custom('cargo bench', 'Bench')
  elseif id == 'j_doc' then
    b.custom('cargo doc --open', 'Doc')

    -- Go extras
  elseif id == 'j_go_race' then
    b.custom('go test -race ./...', 'Test (race)')
  elseif id == 'j_go_cover' then
    b.custom('go test -cover -coverprofile=coverage.out ./...', 'Test + Cover')
  elseif id == 'j_go_vet' then
    b.custom('go vet ./...', 'Vet')
  elseif id == 'j_go_doc' then
    b.custom('godoc -http=:6060', 'godoc')

    -- CMake configure
  elseif id == 'j_cmake_cfg' then
    b.custom('cmake -B build -S .', 'CMake Configure')

    -- GraalVM
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
