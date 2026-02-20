-- lua/jason/dashboard.lua
-- Updated to:
--  • pull run history from core.runner instead of local table
--  • inject .jason.lua custom tasks into the menu
--  • hand Java projects off to Marvin for specialist features
--  • delegate action execution to core.runner via executor

local M = {}

-- History is now owned by core.runner; keep a local ref for ago()
local function history() return require('core.runner').history end

local function ago(ts)
  local d = os.time() - ts
  if d < 60 then
    return 'just now'
  elseif d < 3600 then
    return math.floor(d / 60) .. 'm ago'
  elseif d < 86400 then
    return math.floor(d / 3600) .. 'h ago'
  else
    return math.floor(d / 86400) .. 'd ago'
  end
end

local function sep(label) return { id = 'sep_' .. label, label = label, is_separator = true } end
local function item(id, icon, label, desc, badge)
  return { id = id, icon = icon, label = label, desc = desc, badge = badge }
end

-- ── Build menu ────────────────────────────────────────────────────────────────
function M.build_menu(project, status)
  local cfg   = require('jason').config
  local lang  = project.language
  local ptype = project.type
  local items = {}
  local function add(t) items[#items + 1] = t end

  -- ── Custom tasks from .jason.lua ──────────────────────────────────────────
  local task_items = require('jason.tasks').to_menu_items(
    require('jason.tasks').load(project.root))
  if #task_items > 0 then
    add(sep('Tasks'))
    for _, t in ipairs(task_items) do add(t) end
  end

  -- ── Core actions ──────────────────────────────────────────────────────────
  add(sep('Run'))
  add(item('build_run', '▶', 'Build & Run', 'Compile then execute'))
  add(item('test', '󰙨', 'Test', 'Run test suite'))
  add(item('run', '󰐊', 'Run Only', 'Execute last build'))

  add(sep('Build'))
  add(item('build', '󰔷', 'Build', 'Compile sources'))
  add(item('clean_build', '󰑕', 'Clean & Build', 'Wipe then compile'))
  add(item('clean', '󰃢', 'Clean', 'Remove build artifacts'))

  -- ── Language tools ────────────────────────────────────────────────────────
  if lang == 'rust' then
    add(sep('Rust'))
    add(item('check', '󰄬', 'Check', 'Type-check without codegen'))
    add(item('clippy', '󰁨', 'Clippy', 'Lints and suggestions'))
    add(item('fmt', '󰉣', 'Format', 'Run rustfmt'))
    add(item('doc', '󰈙', 'Docs', 'cargo doc --open'))
    add(item('bench', '󰦉', 'Bench', 'Run benchmarks'))
    add(sep('Profile'))
    local cur = cfg.rust.profile
    local nxt = cur == 'release' and 'dev' or 'release'
    add(item('toggle_profile', '󰒓', 'Profile: ' .. cur, 'Switch to ' .. nxt,
      cur == 'release' and '󰓅 release' or '󰁌 dev'))
  elseif lang == 'go' then
    add(sep('Go'))
    add(item('fmt', '󰉣', 'Format', 'gofmt -w .'))
    add(item('vet', '󰁨', 'Vet', 'go vet ./...'))
    add(item('lint', '󰁨', 'Lint', 'golangci-lint run'))
    add(item('coverage', '󰦉', 'Coverage', 'go test -cover ./...'))
  elseif lang == 'java' then
    add(sep('Java'))
    if ptype == 'maven' then
      add(item('dependency_tree', '󰙅', 'Dep Tree', 'mvn dependency:tree'))
      add(item('effective_pom', '󰈙', 'Effective POM', 'mvn help:effective-pom'))
      add(item('verify', '󰄬', 'Verify', 'Run integration tests'))
    elseif ptype == 'gradle' then
      add(item('dependencies', '󰙅', 'Dependencies', './gradlew dependencies'))
      add(item('tasks', '󰒓', 'Tasks', './gradlew tasks'))
    end

    -- Marvin hand-off (always shown for Java projects)
    add(sep('Marvin'))
    add(item('open_marvin', '󱁆', 'Open Marvin', 'Full Maven/Java toolset'))
    add(item('marvin_new_file', '󰬷', 'New Java File', 'Class, interface, record…'))
    if ptype == 'maven' then
      add(item('marvin_deps', '󰘦', 'Manage Dependencies', 'Add Jackson, LWJGL, etc.'))
    end

    -- GraalVM
    local graal  = require('jason.graalvm')
    local has_ni = graal.native_image_bin() ~= nil
    add(sep('GraalVM'))
    add(item('graal_build_native', '󰱒', 'Build Native', 'Compile to native binary', has_ni and '●' or '○ needs install'))
    add(item('graal_run_native', '▶', 'Run Native', 'Execute native binary'))
    add(item('graal_build_run', '󰔷', 'Build & Run', 'Native build then run'))
    add(item('graal_agent_run', '󰈙', 'Agent Run', 'Collect reflection config'))
    add(item('graal_info', '󰅾', 'GraalVM Info', 'Show status & config'))
    if not has_ni then
      add(item('graal_install_ni', '󰚰', 'Install native-image', 'Run: gu install native-image'))
    end
  elseif lang == 'cpp' then
    add(sep('C++'))
    add(item('clang_format', '󰉣', 'Format', 'clang-format -i'))
    add(item('clang_tidy', '󰁨', 'Tidy', 'clang-tidy checks'))
    if ptype == 'cmake' then
      add(item('configure_cmake', '󰒓', 'Configure', 'cmake -B build'))
    end
  end

  -- ── Dependencies ──────────────────────────────────────────────────────────
  add(sep('Dependencies'))
  if lang == 'rust' then
    add(item('update', '󰚰', 'Update', 'cargo update'))
    add(item('outdated', '󰦉', 'Outdated', 'cargo outdated'))
    add(item('audit', '󰒃', 'Audit', 'cargo audit'))
  elseif lang == 'go' then
    add(item('mod_tidy', '󰚰', 'Tidy', 'go mod tidy'))
    add(item('mod_download', '󰚰', 'Download', 'go mod download'))
    add(item('mod_verify', '󰄬', 'Verify', 'go mod verify'))
  elseif lang == 'java' and ptype == 'maven' then
    add(item('update', '󰚰', 'Check Updates', 'mvn versions:display-dependency-updates'))
    add(item('purge', '󰃢', 'Purge Cache', 'mvn dependency:purge-local-repository'))
  end

  -- ── Settings ──────────────────────────────────────────────────────────────
  add(sep('Settings'))
  add(item('terminal_settings', '󰆍', 'Terminal', 'Position: ' .. cfg.terminal.position))
  add(item('keybindings', '󰌌', 'Keybindings', 'View all shortcuts'))

  -- ── History ───────────────────────────────────────────────────────────────
  local h = history()
  if #h > 0 then
    add(sep('History'))
    add(item('show_history', '󰋚', 'History', #h .. ' recent runs'))
    local last = h[1]
    if last then
      local si = last.success and '✓' or last.success == false and '✗' or '…'
      add(item('rerun_last', '󰑕', 'Rerun Last',
        last.action .. ' · ' .. ago(last.timestamp), si))
    end
  end

  return items
end

-- ── Show dashboard ────────────────────────────────────────────────────────────
function M.show()
  local project = require('jason.detector').get_project()
  if not project then
    vim.notify('No project detected', vim.log.levels.WARN); return
  end

  local status = { branch = 'main', dirty = false }
  local branch = vim.trim(vim.fn.system(
    'git -C ' .. vim.fn.shellescape(project.root) .. ' branch --show-current 2>/dev/null'))
  if branch ~= '' then
    status.branch = branch
    status.dirty  = vim.trim(vim.fn.system(
      'git -C ' .. vim.fn.shellescape(project.root) .. ' status --porcelain 2>/dev/null')) ~= ''
  end

  local menu  = M.build_menu(project, status)
  local ui    = require('jason.ui')
  local pname = vim.fn.fnamemodify(project.root, ':t')
  local dirty = status.dirty and ' ●' or ''

  ui.select(menu, {
    prompt        = pname .. ' [' .. project.language:upper() .. ']' .. dirty,
    project       = project,
    show_preview  = true,
    enable_search = true,
    format_item   = function(it)
      if it.is_separator then return it.label end
      return (it.icon and it.icon .. ' ' or '') .. it.label
    end,
  }, function(choice)
    if choice then M.handle_action(choice.id, project) end
  end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle_action(id, project)
  if not id then return end

  -- Custom task?
  if require('jason.tasks').handle_action(id, project) then return end

  local ex  = require('jason.executor')
  local cfg = require('jason').config

  -- Marvin hand-offs
  if id == 'open_marvin' then
    local ok, marvin = pcall(require, 'marvin.dashboard')
    if ok then
      marvin.show()
    else
      vim.notify('Marvin not installed', vim.log.levels.WARN)
    end
    return
  elseif id == 'marvin_new_file' then
    local ok, jc = pcall(require, 'marvin.java_creator')
    if ok then
      jc.show_menu(function() M.show() end)
    else
      vim.notify('Marvin not installed', vim.log.levels.WARN)
    end
    return
  elseif id == 'marvin_deps' then
    local ok, md = pcall(require, 'marvin.dependencies')
    if not ok then
      vim.notify('Marvin not installed', vim.log.levels.WARN); return
    end
    -- Show a small sub-menu for dep actions
    require('jason.ui').select({
      { id = 'add_jackson',  label = 'Add Jackson JSON', desc = 'com.fasterxml.jackson' },
      { id = 'add_lwjgl',    label = 'Add LWJGL',        desc = 'OpenGL/Vulkan bindings' },
      { id = 'add_assembly', label = 'Enable Fat JAR',   desc = 'maven-assembly-plugin' },
    }, { prompt = 'Manage Dependencies' }, function(choice)
      if not choice then return end
      if choice.id == 'add_jackson' then md.add_jackson() end
      if choice.id == 'add_lwjgl' then md.add_lwjgl() end
      if choice.id == 'add_assembly' then md.add_assembly_plugin() end
    end)
    return
  end

  -- Standard actions
  if id == 'build' then
    ex.build()
  elseif id == 'run' then
    ex.run()
  elseif id == 'build_run' then
    ex.build_and_run()
  elseif id == 'test' then
    ex.test()
  elseif id == 'clean' then
    ex.clean()
  elseif id == 'clean_build' then
    local p = project
    require('core.runner').execute_sequence(
      { { cmd = ex.get_command('clean', p), title = 'Clean' },
        { cmd = ex.get_command('build', p), title = 'Build' } },
      { cwd = p.root, term_cfg = cfg.terminal, plugin = 'jason', action_id = 'clean_build' })

    -- Rust
  elseif id == 'check' then
    ex.custom('cargo check')
  elseif id == 'clippy' then
    ex.custom('cargo clippy')
  elseif id == 'fmt' then
    ex.custom(project.language == 'rust' and 'cargo fmt'
      or project.language == 'go' and 'gofmt -w .'
      or 'clang-format -i $(find . -name "*.cpp" -o -name "*.h" | head -20)')
  elseif id == 'doc' then
    ex.custom('cargo doc --open')
  elseif id == 'bench' then
    ex.custom('cargo bench')
  elseif id == 'toggle_profile' then
    cfg.rust.profile = cfg.rust.profile == 'release' and 'dev' or 'release'
    vim.notify('Rust profile: ' .. cfg.rust.profile, vim.log.levels.INFO)
    vim.defer_fn(function() M.show() end, 50)
    return

    -- Go
  elseif id == 'vet' then
    ex.custom('go vet ./...')
  elseif id == 'lint' then
    ex.custom('golangci-lint run')
  elseif id == 'coverage' then
    ex.custom('go test -cover ./...')
  elseif id == 'mod_tidy' then
    ex.custom('go mod tidy')
  elseif id == 'mod_download' then
    ex.custom('go mod download')
  elseif id == 'mod_verify' then
    ex.custom('go mod verify')

    -- Java / Maven / Gradle
  elseif id == 'dependency_tree' then
    ex.custom('mvn dependency:tree')
  elseif id == 'effective_pom' then
    ex.custom('mvn help:effective-pom')
  elseif id == 'verify' then
    ex.custom('mvn verify')
  elseif id == 'dependencies' then
    ex.custom('./gradlew dependencies')
  elseif id == 'tasks' then
    ex.custom('./gradlew tasks')
  elseif id == 'update' then
    ex.custom(project.language == 'rust' and 'cargo update'
      or project.language == 'java' and 'mvn versions:display-dependency-updates'
      or 'go get -u ./...')
  elseif id == 'outdated' then
    ex.custom('cargo outdated')
  elseif id == 'audit' then
    ex.custom('cargo audit')
  elseif id == 'purge' then
    ex.custom('mvn dependency:purge-local-repository')

    -- GraalVM
  elseif id == 'graal_build_native' then
    require('jason.graalvm').build_native(project)
  elseif id == 'graal_run_native' then
    require('jason.graalvm').run_native(project)
  elseif id == 'graal_build_run' then
    require('jason.graalvm').build_and_run_native(project)
  elseif id == 'graal_agent_run' then
    require('jason.graalvm').run_with_agent(project)
  elseif id == 'graal_info' then
    require('jason.graalvm').show_info(); return
  elseif id == 'graal_install_ni' then
    require('jason.graalvm').install_native_image(project)

    -- C++
  elseif id == 'clang_format' then
    ex.custom('find . -name "*.cpp" -o -name "*.h" | xargs clang-format -i')
  elseif id == 'clang_tidy' then
    ex.custom('clang-tidy src/*.cpp')
  elseif id == 'configure_cmake' then
    ex.custom('cmake -B build')

    -- Settings / util
  elseif id == 'terminal_settings' then
    M.show_terminal_settings()
  elseif id == 'keybindings' then
    M.show_keybindings()
  elseif id == 'show_history' then
    M.show_history()
  elseif id == 'rerun_last' then
    local h = history()
    if h[1] then M.handle_action(h[1].action_id, project) end
  end
end

-- ── Sub-menus (unchanged) ─────────────────────────────────────────────────────
function M.show_terminal_settings()
  local ui  = require('jason.ui')
  local cfg = require('jason').config
  ui.select({
      { id = 'float',      label = 'Float',      desc = 'Centered overlay window' },
      { id = 'split',      label = 'Split',      desc = 'Horizontal split below' },
      { id = 'vsplit',     label = 'Vsplit',     desc = 'Vertical split beside' },
      { id = 'background', label = 'Background', desc = 'Silent, notify on done' },
    }, { prompt = 'Terminal Position', format_item = function(it) return it.label end },
    function(choice)
      if choice then
        cfg.terminal.position = choice.id; vim.notify('Terminal: ' .. choice.id)
      end
    end)
end

function M.show_keybindings()
  local cfg = require('jason').config.keymaps
  local lines = {
    '', '  Jason Keybindings', '  ' .. string.rep('─', 30), '',
    string.format('  %-18s %s', cfg.dashboard or '<leader>jb', 'Open dashboard'),
    string.format('  %-18s %s', cfg.build or '<leader>jc', 'Build'),
    string.format('  %-18s %s', cfg.run or '<leader>jr', 'Run'),
    string.format('  %-18s %s', cfg.test or '<leader>jt', 'Test'),
    string.format('  %-18s %s', cfg.clean or '<leader>jx', 'Clean'),
    '', '  In the menu: j/k  navigate · ⏎ select · ⎋ quit', '               type to fuzzy-search', '',
  }
  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

function M.show_history()
  local h = history()
  if #h == 0 then
    vim.notify('No history yet', vim.log.levels.INFO); return
  end
  local ui    = require('jason.ui')
  local items = {}
  for _, e in ipairs(h) do
    local si = e.success and '✓' or e.success == false and '✗' or '…'
    items[#items + 1] = {
      id     = e.action_id,
      label  = e.action,
      desc   = (e.plugin or '?') .. ' · ' .. ago(e.timestamp),
      badge  = si,
      _entry = e,
    }
  end
  ui.select(items, {
      prompt = 'Run History',
      enable_search = true,
      format_item = function(it) return it.label end
    },
    function(choice)
      if choice then
        M.handle_action(choice.id, require('jason.detector').get_project())
      end
    end)
end

return M
