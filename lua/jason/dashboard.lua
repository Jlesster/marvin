-- lua/jason/dashboard.lua

local M = {}

-- ── Formatting helpers ────────────────────────────────────────────────────────
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

local function dur_str(s)
  if not s then return '' end
  if s < 60 then return s .. 's' else return math.floor(s / 60) .. 'm' .. (s % 60) .. 's' end
end

local function status_badge(action_id)
  local e = require('core.runner').get_last_status(action_id)
  if not e then return nil end
  local icon = e.success and '✓' or '✗'
  return icon .. ' ' .. ago(e.timestamp) .. ' (' .. dur_str(e.duration) .. ')'
end

local function sep(label) return { id = 'sep_' .. label, label = label, is_separator = true } end
local function item(id, icon, label, desc, badge)
  return { id = id, icon = icon, label = label, desc = desc, badge = badge }
end

-- ── Menu builder ──────────────────────────────────────────────────────────────
function M.build_menu(project)
  local cfg    = require('jason').config
  local lang   = project.language
  local ptype  = project.type
  local runner = require('core.runner')
  local items  = {}
  local function add(t) items[#items + 1] = t end

  -- Running jobs indicator
  local njobs = runner.running_count()
  if njobs > 0 then
    add(sep('Running'))
    add(item('stop_all', '󰓛', 'Stop All Jobs', njobs .. ' job(s) running', '● ' .. njobs))
    add(item('stop_last', '󰓛', 'Stop Last Job', 'Stop most recent task'))
  end

  -- Custom .jason.lua tasks
  local task_items = require('jason.tasks').to_menu_items(
    require('jason.tasks').load(project.root))
  if #task_items > 0 then
    add(sep('Tasks'))
    for _, t in ipairs(task_items) do add(t) end
  end

  -- Core actions with last-run badges
  add(sep('Run'))
  add(item('build_run', '▶', 'Build & Run', 'Compile then execute', status_badge('build_run')))
  add(item('build_run_args', '󰑕', 'Build & Run…', 'Prompt for run args'))
  add(item('test', '󰙨', 'Test', 'Run full test suite', status_badge('test')))
  add(item('test_filter', '󰙨', 'Test (filter)…', 'Run matching tests only'))
  add(item('run', '󰐊', 'Run Only', 'Execute without building', status_badge('run')))
  add(item('run_args', '󰐊', 'Run with args…', 'Prompt for run arguments'))

  add(sep('Build'))
  add(item('build', '󰔷', 'Build', 'Compile sources', status_badge('build')))
  add(item('build_args', '󰔷', 'Build with args…', 'Pass extra build flags'))
  add(item('clean_build', '󰑕', 'Clean & Build', 'Wipe then compile'))
  add(item('clean', '󰃢', 'Clean', 'Remove build artifacts'))
  add(item('package', '󰏗', 'Package', 'Build distributable'))
  add(item('install', '󰇚', 'Install', 'Install to system/local repo'))

  add(sep('Quality'))
  add(item('fmt', '󰉣', 'Format', 'Auto-format source files'))
  add(item('lint', '󰁨', 'Lint', 'Run linter / static analysis'))

  -- Language-specific tools
  if lang == 'rust' then
    add(sep('Rust'))
    add(item('check', '󰄬', 'Check', 'Type-check without codegen'))
    add(item('doc', '󰈙', 'Docs', 'cargo doc --open'))
    add(item('bench', '󰦉', 'Bench', 'Run benchmarks'))
    add(item('expand', '󰈙', 'Expand Macros', 'cargo expand'))
    add(sep('Profile'))
    local cur = cfg.rust.profile
    add(item('toggle_profile', '󰒓', 'Profile: ' .. cur,
      'Switch to ' .. (cur == 'release' and 'dev' or 'release'),
      cur == 'release' and '󰓅 release' or '󰁌 dev'))
    add(sep('Dependencies'))
    add(item('update', '󰚰', 'Update', 'cargo update'))
    add(item('outdated', '󰦉', 'Outdated', 'cargo outdated'))
    add(item('audit', '󰒃', 'Audit', 'cargo audit'))
  elseif lang == 'go' then
    add(sep('Go'))
    add(item('vet', '󰁨', 'Vet', 'go vet ./...'))
    add(item('coverage', '󰦉', 'Coverage', 'go test -cover ./...'))
    add(item('build_race', '󰔷', 'Race Detector', 'go build -race'))
    add(sep('Dependencies'))
    add(item('mod_tidy', '󰚰', 'Tidy', 'go mod tidy'))
    add(item('mod_download', '󰚰', 'Download', 'go mod download'))
    add(item('mod_verify', '󰄬', 'Verify', 'go mod verify'))
    add(item('mod_graph', '󰙅', 'Dep Graph', 'go mod graph'))
  elseif lang == 'java' then
    add(sep('Java'))
    if ptype == 'maven' then
      add(item('mvn_verify', '󰄬', 'Verify', 'Run integration tests'))
      add(item('mvn_dependency_tree', '󰙅', 'Dep Tree', 'mvn dependency:tree'))
      add(item('mvn_effective_pom', '󰈙', 'Effective POM', 'Resolved config'))
      add(item('mvn_skip_tests', '󰒭', 'Build (skip tests)', 'mvn package -DskipTests'))
      add(item('mvn_profiles', '󰒓', 'Run with Profile…', 'Pick a Maven profile'))
    elseif ptype == 'gradle' then
      add(item('gradle_deps', '󰙅', 'Dependencies', './gradlew dependencies'))
      add(item('gradle_tasks', '󰒓', 'Tasks', './gradlew tasks'))
      add(item('gradle_wrapper', '󰚰', 'Wrapper Update', './gradlew wrapper --upgrade-gradle-properties'))
    end

    -- Marvin hand-off section
    add(sep('Marvin'))
    add(item('open_marvin', '󱁆', 'Open Marvin', 'Full Maven/Java toolset'))
    add(item('marvin_new_file', '󰬷', 'New Java File', 'Class, interface, record…'))
    add(item('marvin_new_project', '󰏗', 'New Maven Project', 'Generate from archetype'))
    if ptype == 'maven' then
      add(item('marvin_deps', '󰘦', 'Add Dependency', 'Jackson, LWJGL, etc.'))
      add(item('marvin_java_ver', '󰬷', 'Set Java Version', 'Configure compiler target'))
    end

    -- GraalVM
    local graal  = require('jason.graalvm')
    local has_ni = graal.native_image_bin() ~= nil
    local badge  = has_ni and '●' or '○ not installed'
    add(sep('GraalVM'))
    add(item('graal_build_native', '󰱒', 'Build Native', 'Compile to native binary', badge))
    add(item('graal_run_native', '▶', 'Run Native', 'Execute native binary'))
    add(item('graal_build_run', '󰔷', 'Build & Run', 'Native build then run'))
    add(item('graal_agent_run', '󰈙', 'Agent Run', 'Collect reflection config'))
    add(item('graal_info', '󰅾', 'GraalVM Info', 'Status & config'))
    if not has_ni then
      add(item('graal_install_ni', '󰚰', 'Install native-image', 'gu install native-image'))
    end
  elseif lang == 'cpp' then
    add(sep('C++'))
    add(item('clang_tidy', '󰁨', 'Tidy', 'clang-tidy checks'))
    add(item('clang_format', '󰉣', 'Format', 'clang-format'))
    add(item('valgrind', '󰍉', 'Valgrind', 'Memory error detection'))
    add(item('sanitize_address', '󰍉', 'ASAN Build', 'Build with AddressSanitizer'))
    if ptype == 'cmake' then
      add(item('cmake_configure', '󰒓', 'Configure', 'cmake -B build'))
      add(item('cmake_configure_debug', '󰒓', 'Debug Config', 'cmake -B build -DCMAKE_BUILD_TYPE=Debug'))
      add(item('cmake_configure_release', '󰒓', 'Release Config', 'cmake -B build -DCMAKE_BUILD_TYPE=Release'))
    end
  end

  -- Monorepo
  if require('jason.detector').is_monorepo and require('jason.detector').is_monorepo() then
    add(sep('Workspace'))
    add(item('switch_project', '󰒓', 'Switch Sub-project', 'Pick a project in this workspace'))
  end

  -- Settings
  add(sep('Settings'))
  add(item('terminal_settings', '󰆍', 'Terminal', 'Position: ' .. cfg.terminal.position))
  add(item('env_settings', '󰙩', 'Environment', 'Set env vars for this project'))
  add(item('keybindings', '󰌌', 'Keybindings', 'View all shortcuts'))

  -- History
  local h = require('core.runner').history
  if #h > 0 then
    add(sep('History'))
    add(item('show_history', '󰋚', 'History', #h .. ' recent runs'))
    local last = h[1]
    if last then
      local si = last.success and '✓' or '✗'
      add(item('rerun_last', '󰑕', 'Rerun Last',
        last.action .. ' · ' .. ago(last.timestamp), si))
      if not last.success then
        add(item('show_last_output', '󰈙', 'Last Output', 'View failed run output'))
      end
    end
  end

  return items
end

-- ── Show ──────────────────────────────────────────────────────────────────────
function M.show(project)
  project = project or require('jason.detector').get_project()
  if not project then
    vim.notify('No project detected', vim.log.levels.WARN); return
  end

  local status = { branch = '', dirty = false }
  local branch = vim.trim(vim.fn.system(
    'git -C ' .. vim.fn.shellescape(project.root) .. ' branch --show-current 2>/dev/null'))
  if branch ~= '' then
    status.branch = branch
    status.dirty  = vim.trim(vim.fn.system(
      'git -C ' .. vim.fn.shellescape(project.root) .. ' status --porcelain 2>/dev/null')) ~= ''
  end

  local ui         = require('jason.ui')
  local pname      = project.name or vim.fn.fnamemodify(project.root, ':t')
  local dirty      = status.dirty and ' ●' or ''
  local branch_str = status.branch ~= '' and ('  ' .. status.branch) or ''

  ui.select(M.build_menu(project), {
    prompt        = pname .. ' [' .. project.language:upper() .. ']' .. dirty .. branch_str,
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

  local ex     = require('jason.executor')
  local cfg    = require('jason').config
  local runner = require('core.runner')

  -- Running jobs
  if id == 'stop_all' then
    runner.stop_all(); return
  elseif id == 'stop_last' then
    runner.stop_last(); return

    -- Build / run variants
  elseif id == 'build' then
    ex.build(false)
  elseif id == 'build_args' then
    ex.build(true)
  elseif id == 'run' then
    ex.run(false)
  elseif id == 'run_args' then
    ex.run(true)
  elseif id == 'build_run' then
    ex.build_and_run(false)
  elseif id == 'build_run_args' then
    ex.build_and_run(true)
  elseif id == 'test' then
    ex.test(false)
  elseif id == 'test_filter' then
    ex.test(true)
  elseif id == 'clean' then
    ex.clean()
  elseif id == 'clean_build' then
    runner.execute_sequence(
      { { cmd = ex.get_command('clean', project), title = 'Clean' },
        { cmd = ex.get_command('build', project), title = 'Build' } },
      { cwd = project.root, term_cfg = cfg.terminal, plugin = 'jason', action_id = 'clean_build' })
  elseif id == 'package' then
    ex.package()
  elseif id == 'install' then
    ex.install()
  elseif id == 'fmt' then
    ex.fmt()
  elseif id == 'lint' then
    ex.lint()

    -- Rust
  elseif id == 'check' then
    ex.custom('cargo check', 'Check')
  elseif id == 'doc' then
    ex.custom('cargo doc --open', 'Docs')
  elseif id == 'bench' then
    ex.custom('cargo bench', 'Bench')
  elseif id == 'expand' then
    ex.custom('cargo expand', 'Expand')
  elseif id == 'update' then
    ex.custom('cargo update', 'Update')
  elseif id == 'outdated' then
    ex.custom('cargo outdated', 'Outdated')
  elseif id == 'audit' then
    ex.custom('cargo audit', 'Audit')
  elseif id == 'toggle_profile' then
    cfg.rust.profile = cfg.rust.profile == 'release' and 'dev' or 'release'
    vim.notify('Rust profile → ' .. cfg.rust.profile, vim.log.levels.INFO)
    vim.defer_fn(function() M.show(project) end, 50); return

    -- Go
  elseif id == 'vet' then
    ex.custom('go vet ./...', 'Vet')
  elseif id == 'coverage' then
    ex.custom('go test -cover ./...', 'Coverage')
  elseif id == 'build_race' then
    ex.custom('go build -race ./...', 'Race Build')
  elseif id == 'mod_tidy' then
    ex.custom('go mod tidy', 'Tidy')
  elseif id == 'mod_download' then
    ex.custom('go mod download', 'Download')
  elseif id == 'mod_verify' then
    ex.custom('go mod verify', 'Verify')
  elseif id == 'mod_graph' then
    ex.custom('go mod graph', 'Dep Graph')

    -- Java / Maven
  elseif id == 'mvn_verify' then
    ex.custom('mvn verify', 'Verify')
  elseif id == 'mvn_dependency_tree' then
    ex.custom('mvn dependency:tree', 'Dep Tree')
  elseif id == 'mvn_effective_pom' then
    ex.custom('mvn help:effective-pom', 'Effective POM')
  elseif id == 'mvn_skip_tests' then
    ex.custom('mvn package -DskipTests', 'Build (skip tests)')
  elseif id == 'mvn_profiles' then
    M.run_with_maven_profile(project)
  elseif id == 'gradle_deps' then
    ex.custom('./gradlew dependencies', 'Dependencies')
  elseif id == 'gradle_tasks' then
    ex.custom('./gradlew tasks', 'Tasks')
  elseif id == 'gradle_wrapper' then
    ex.custom('./gradlew wrapper --upgrade-gradle-properties', 'Wrapper Update')

    -- Marvin hand-offs
  elseif id == 'open_marvin' then
    local ok, m = pcall(require, 'marvin.dashboard')
    if ok then m.show() else vim.notify('Marvin not installed', vim.log.levels.WARN) end
    return
  elseif id == 'marvin_new_file' then
    local ok, jc = pcall(require, 'marvin.java_creator')
    if ok then
      jc.show_menu(function() M.show(project) end)
    else
      vim.notify('Marvin not installed', vim.log.levels.WARN)
    end
    return
  elseif id == 'marvin_new_project' then
    local ok, gen = pcall(require, 'marvin.generator')
    if ok then gen.create_project() else vim.notify('Marvin not installed', vim.log.levels.WARN) end
    return
  elseif id == 'marvin_deps' then
    M.show_dep_menu(project); return
  elseif id == 'marvin_java_ver' then
    local ok, md = pcall(require, 'marvin.dependencies')
    if ok then
      require('marvin.dashboard').prompt_java_version()
    else
      vim.notify('Marvin not installed', vim.log.levels.WARN)
    end
    return

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
  elseif id == 'clang_tidy' then
    ex.custom('clang-tidy $(find src -name "*.cpp")', 'Tidy')
  elseif id == 'clang_format' then
    ex.custom('find . \\( -name "*.cpp" -o -name "*.h" \\) | xargs clang-format -i', 'Format')
  elseif id == 'valgrind' then
    ex.custom('valgrind --leak-check=full ' .. (ex.find_cmake_executable(project) or './main'), 'Valgrind')
  elseif id == 'sanitize_address' then
    ex.custom('cmake -B build -DCMAKE_CXX_FLAGS="-fsanitize=address" && cmake --build build', 'ASAN Build')
  elseif id == 'cmake_configure' then
    ex.custom('cmake -B build', 'Configure')
  elseif id == 'cmake_configure_debug' then
    ex.custom('cmake -B build -DCMAKE_BUILD_TYPE=Debug', 'Debug Config')
  elseif id == 'cmake_configure_release' then
    ex.custom('cmake -B build -DCMAKE_BUILD_TYPE=Release', 'Release Config')

    -- Workspace
  elseif id == 'switch_project' then
    M.show_project_picker(); return

    -- Settings
  elseif id == 'terminal_settings' then
    M.show_terminal_settings()
  elseif id == 'env_settings' then
    M.show_env_settings(project)
  elseif id == 'keybindings' then
    M.show_keybindings()

    -- History
  elseif id == 'show_history' then
    M.show_history(project); return
  elseif id == 'rerun_last' then
    local h = require('core.runner').history
    if h[1] then M.handle_action(h[1].action_id, project) end
  elseif id == 'show_last_output' then
    local h = require('core.runner').history
    if h[1] then runner.show_output(h[1]) end; return
  end
end

-- ── Sub-menus ─────────────────────────────────────────────────────────────────
function M.run_with_maven_profile(project)
  local proj_info = require('marvin.project').get_project()
  local profiles  = proj_info and proj_info.info and proj_info.info.profiles or {}
  if #profiles == 0 then
    vim.notify('No Maven profiles found in pom.xml', vim.log.levels.INFO)
    require('jason.executor').custom('mvn install', 'Install')
    return
  end
  local items = {}
  for _, pid in ipairs(profiles) do
    items[#items + 1] = { id = pid, label = pid, desc = 'Maven profile' }
  end
  require('jason.ui').select(items, { prompt = 'Maven Profile' }, function(choice)
    if choice then
      require('jason.executor').custom('mvn install -P' .. choice.id, 'Install (' .. choice.id .. ')')
    end
  end)
end

function M.show_dep_menu(project)
  local ok, md = pcall(require, 'marvin.dependencies')
  if not ok then
    vim.notify('Marvin not installed', vim.log.levels.WARN); return
  end
  require('jason.ui').select({
    { id = 'add_jackson', icon = '󰘦', label = 'Add Jackson JSON', desc = 'com.fasterxml.jackson' },
    { id = 'add_lwjgl', icon = '󰊗', label = 'Add LWJGL', desc = 'OpenGL / Vulkan / GLFW' },
    { id = 'add_assembly', icon = '󰒓', label = 'Enable Fat JAR', desc = 'maven-assembly-plugin' },
    { id = 'set_version', icon = '󰬷', label = 'Set Java Version', desc = 'maven.compiler.source/target' },
  }, { prompt = 'Add Dependency' }, function(choice)
    if not choice then return end
    if choice.id == 'add_jackson' then md.add_jackson() end
    if choice.id == 'add_lwjgl' then md.add_lwjgl() end
    if choice.id == 'add_assembly' then md.add_assembly_plugin() end
    if choice.id == 'set_version' then require('marvin.dashboard').prompt_java_version() end
  end)
end

function M.show_project_picker()
  local det  = require('jason.detector')
  local subs = det.detect_sub_projects(vim.fn.getcwd())
  if not subs or #subs == 0 then
    vim.notify('No sub-projects found', vim.log.levels.INFO); return
  end
  local items = {}
  for _, p in ipairs(subs) do
    items[#items + 1] = {
      id    = p.root,
      label = p.name,
      desc  = p.type .. ' · ' .. p.language,
      _proj = p,
    }
  end
  require('jason.ui').select(items, {
      prompt = 'Switch Project',
      format_item = function(it) return it.label end
    },
    function(choice)
      if choice then
        det.set_project(choice._proj)
        vim.notify('Switched to: ' .. choice.label, vim.log.levels.INFO)
        vim.defer_fn(function() M.show(choice._proj) end, 50)
      end
    end)
end

function M.show_terminal_settings()
  local ui  = require('jason.ui')
  local cfg = require('jason').config
  ui.select({
      { id = 'float',      label = 'Float',      desc = 'Centered floating window' },
      { id = 'split',      label = 'Split',      desc = 'Horizontal split below' },
      { id = 'vsplit',     label = 'Vsplit',     desc = 'Vertical split beside' },
      { id = 'background', label = 'Background', desc = 'Silent background job' },
    }, { prompt = 'Terminal Position', format_item = function(it) return it.label end },
    function(choice)
      if choice then
        cfg.terminal.position = choice.id
        vim.notify('Terminal → ' .. choice.id, vim.log.levels.INFO)
      end
    end)
end

function M.show_env_settings(project)
  local ex    = require('jason.executor')
  local root  = project.root
  local ui    = require('jason.ui')
  -- show current per-project stored args as info
  local lines = {
    '', '  Per-project run arguments', '  ' .. string.rep('─', 32), '',
    string.format('  %-14s  %s', 'build args:', ex.get_args(root, 'build')),
    string.format('  %-14s  %s', 'run args:', ex.get_args(root, 'run')),
    string.format('  %-14s  %s', 'test filter:', ex.get_args(root, 'test')),
    '',
    '  Use "Build with args…", "Run with args…", or "Test (filter)…"',
    '  in the main menu to update these.',
    '',
  }
  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

function M.show_keybindings()
  local cfg = require('jason').config.keymaps
  local lines = {
    '', '  Jason Keybindings', '  ' .. string.rep('─', 32), '',
    string.format('  %-18s %s', cfg.dashboard or '<leader>jb', 'Open dashboard'),
    string.format('  %-18s %s', cfg.build or '<leader>jc', 'Build'),
    string.format('  %-18s %s', cfg.run or '<leader>jr', 'Run'),
    string.format('  %-18s %s', cfg.test or '<leader>jt', 'Test'),
    string.format('  %-18s %s', cfg.clean or '<leader>jx', 'Clean'),
    '',
    '  In menu: j/k navigate · ⏎ select · ⎋ quit · type to search',
    '',
  }
  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

function M.show_history(project)
  local h = require('core.runner').history
  if #h == 0 then
    vim.notify('No history yet', vim.log.levels.INFO); return
  end
  local runner = require('core.runner')
  local items  = {}
  for _, e in ipairs(h) do
    local si          = e.success and '✓' or '✗'
    local info        = (e.plugin or '?') .. ' · ' .. ago(e.timestamp)
        .. (e.duration and (' · ' .. dur_str(e.duration)) or '')
    items[#items + 1] = {
      id     = e.action_id,
      label  = e.action,
      desc   = info,
      badge  = si,
      _entry = e,
    }
  end
  require('jason.ui').select(items, {
    prompt = 'Run History',
    enable_search = true,
    format_item = function(it) return it.label end,
  }, function(choice)
    if not choice then return end
    -- Right-click-style sub-menu: rerun or view output
    require('jason.ui').select({
        { id = 'rerun',  label = 'Re-run',      desc = 'Execute this action again' },
        { id = 'output', label = 'View Output', desc = 'Open log in split' },
        {
          id == 'qf' and 'qf' or 'qf',
          label = 'Open in Quickfix',
          desc = 'Parse output into quickfix list'
        },
      }, { prompt = choice.label },
      function(act)
        if not act then return end
        if act.id == 'rerun' then
          M.handle_action(choice.id, project or require('jason.detector').get_project())
        elseif act.id == 'output' then
          runner.show_output(choice._entry)
        elseif act.id == 'qf' then
          require('jason.parser').parse_output(choice._entry.output or {})
        end
      end)
  end)
end

return M
