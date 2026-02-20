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
  return s < 60 and (s .. 's') or (math.floor(s / 60) .. 'm' .. (s % 60) .. 's')
end

local function status_badge(action_id)
  local e = require('core.runner').get_last_status(action_id)
  if not e then return nil end
  return (e.success and '✓' or '✗') .. ' ' .. ago(e.timestamp) .. ' (' .. dur_str(e.duration) .. ')'
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

  -- Running jobs
  local njobs = runner.running_count()
  if njobs > 0 then
    add(sep('Running'))
    add(item('stop_all', '󰓛', 'Stop All Jobs', njobs .. ' job(s) running', '● ' .. njobs))
    add(item('stop_last', '󰓛', 'Stop Last Job', 'Cancel most recent task'))
  end

  -- Custom .jason.lua tasks
  local task_items = require('jason.tasks').to_menu_items(
    require('jason.tasks').load(project.root))
  if #task_items > 0 then
    add(sep('Tasks'))
    for _, t in ipairs(task_items) do add(t) end
  end

  -- ── Core: Run ─────────────────────────────────────────────────────────────
  add(sep('Run'))
  add(item('build_run', '▶', 'Build & Run', 'Compile then execute', status_badge('build_run')))
  add(item('build_run_args', '▶', 'Build & Run…', 'Prompt for run args'))
  add(item('run', '󰐊', 'Run Only', 'Execute without building', status_badge('run')))
  add(item('run_args', '󰐊', 'Run with args…', 'Prompt for arguments'))
  add(item('test', '󰙨', 'Test', 'Run full test suite', status_badge('test')))
  add(item('test_filter', '󰙨', 'Test (filter)…', 'Run matching tests only'))

  -- ── Core: Build ───────────────────────────────────────────────────────────
  add(sep('Build'))
  add(item('build', '󰔷', 'Build', 'Compile sources', status_badge('build')))
  add(item('build_args', '󰔷', 'Build with args…', 'Pass extra flags'))
  add(item('clean_build', '󰑕', 'Clean & Build', 'Wipe artifacts then compile'))
  add(item('clean', '󰃢', 'Clean', 'Remove build artifacts'))
  add(item('package', '󰏗', 'Package', 'Build distributable output'))
  add(item('install', '󰇚', 'Install', 'Install to system / local repo'))

  -- ── Core: Quality ─────────────────────────────────────────────────────────
  add(sep('Quality'))
  add(item('fmt', '󰉣', 'Format', 'Auto-format all source files'))
  add(item('lint', '󰁨', 'Lint', 'Run linter / static analysis'))
  add(item('quality_submenu', '󰦉', 'More…', 'Coverage, audit, vet…'))

  -- ── Language tools ────────────────────────────────────────────────────────
  if lang == 'rust' then
    add(sep('Rust'))
    add(item('check', '󰄬', 'Check', 'Type-check without codegen'))
    add(item('doc', '󰈙', 'Docs', 'cargo doc --open'))
    add(item('bench', '󰦉', 'Bench', 'Run benchmarks'))
    add(item('expand', '󰈙', 'Expand Macros', 'cargo expand'))
    add(item('rust_tools', '󰒓', 'Tools…', 'Outdated, audit, update'))
    add(sep('Profile'))
    local cur = cfg.rust.profile
    add(item('toggle_profile', '󰒓', 'Profile: ' .. cur,
      'Switch to ' .. (cur == 'release' and 'dev' or 'release'),
      cur == 'release' and '󰓅 release' or '󰁌 dev'))
  elseif lang == 'go' then
    add(sep('Go'))
    add(item('vet', '󰁨', 'Vet', 'go vet ./...'))
    add(item('coverage', '󰦉', 'Coverage', 'go test -cover ./...'))
    add(item('build_race', '󰔷', 'Race Detector', 'go build -race'))
    add(item('go_tools', '󰒓', 'Tools…', 'Mod tidy, download, graph'))
  elseif lang == 'java' then
    add(sep('Java'))
    if ptype == 'maven' then
      add(item('mvn_skip_tests', '󰒭', 'Build (skip tests)', 'mvn package -DskipTests'))
      add(item('mvn_profiles', '󰒓', 'Run with Profile…', 'Pick a Maven profile'))
    elseif ptype == 'gradle' then
      add(item('gradle_tasks', '󰒓', 'Tasks', './gradlew tasks'))
      add(item('gradle_wrapper', '󰚰', 'Wrapper Update', './gradlew wrapper --upgrade-gradle-properties'))
    end
    -- Single Marvin entry point — all Java specialist tools live there
    add(sep('Marvin'))
    add(item('open_marvin', '󱁆', 'Open Marvin', 'Java/Maven specialist tools'))

    -- GraalVM
    local graal  = require('jason.graalvm')
    local has_ni = graal.native_image_bin() ~= nil
    add(sep('GraalVM'))
    add(item('graal_build_native', '󰱒', 'Build Native', 'Compile to native binary', has_ni and '●' or '○ not installed'))
    add(item('graal_run_native', '▶', 'Run Native', 'Execute native binary'))
    add(item('graal_build_run', '󰔷', 'Build & Run', 'Native build then run'))
    add(item('graal_agent_run', '󰈙', 'Agent Run', 'Collect reflection config'))
    add(item('graal_info', '󰅾', 'GraalVM Info', 'Status & config'))
    if not has_ni then
      add(item('graal_install_ni', '󰚰', 'Install native-image', 'gu install native-image'))
    end
  elseif lang == 'cpp' then
    add(sep('C++'))
    add(item('valgrind', '󰍉', 'Valgrind', 'Memory error detection'))
    add(item('sanitize_address', '󰍉', 'ASAN Build', 'Build with AddressSanitizer'))
    add(item('cpp_tools', '󰒓', 'Tools…', 'Tidy, configure, sanitizers'))
  end

  -- Monorepo switcher
  if require('jason.detector').is_monorepo() then
    add(sep('Workspace'))
    add(item('switch_project', '󰒓', 'Switch Sub-project', 'Pick a project in this workspace'))
  end

  -- Settings
  add(sep('Settings'))
  add(item('terminal_settings', '󰆍', 'Terminal', 'Position: ' .. cfg.terminal.position))
  add(item('env_settings', '󰙩', 'Run Args', 'View stored per-project args'))
  add(item('keybindings', '󰌌', 'Keybindings', 'View all shortcuts'))

  -- History
  local h = require('core.runner').history
  if #h > 0 then
    add(sep('History'))
    add(item('show_history', '󰋚', 'History', #h .. ' recent runs'))
    local last = h[1]
    if last then
      add(item('rerun_last', '󰑕', 'Rerun Last',
        last.action .. ' · ' .. ago(last.timestamp),
        last.success and '✓' or '✗'))
      if not last.success then
        add(item('show_last_output', '󰈙', 'Last Output', 'View failed run log'))
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

  local branch = vim.trim(vim.fn.system(
    'git -C ' .. vim.fn.shellescape(project.root) .. ' branch --show-current 2>/dev/null'))
  local dirty  = branch ~= '' and
      vim.trim(vim.fn.system('git -C ' .. vim.fn.shellescape(project.root) ..
        ' status --porcelain 2>/dev/null')) ~= ''

  local pname  = project.name or vim.fn.fnamemodify(project.root, ':t')
  local prompt = pname .. ' [' .. project.language:upper() .. ']'
      .. (dirty and ' ●' or '')
      .. (branch ~= '' and ('  ' .. branch) or '')

  require('jason.ui').select(M.build_menu(project), {
    prompt        = prompt,
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
  if require('jason.tasks').handle_action(id, project) then return end

  local ex     = require('jason.executor')
  local cfg    = require('jason').config
  local runner = require('core.runner')

  -- Running jobs
  if id == 'stop_all' then
    runner.stop_all(); return
  elseif id == 'stop_last' then
    runner.stop_last(); return

    -- Run
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

    -- Quality sub-menu
  elseif id == 'quality_submenu' then
    M.show_quality_menu(project); return

    -- Rust
  elseif id == 'check' then
    ex.custom('cargo check', 'Check')
  elseif id == 'doc' then
    ex.custom('cargo doc --open', 'Docs')
  elseif id == 'bench' then
    ex.custom('cargo bench', 'Bench')
  elseif id == 'expand' then
    ex.custom('cargo expand', 'Expand')
  elseif id == 'rust_tools' then
    M.show_rust_tools(project); return
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
  elseif id == 'go_tools' then
    M.show_go_tools(project); return

    -- Java / Maven
  elseif id == 'mvn_skip_tests' then
    ex.custom('mvn package -DskipTests', 'Build (skip tests)')
  elseif id == 'mvn_profiles' then
    M.run_with_maven_profile(project)
  elseif id == 'gradle_tasks' then
    ex.custom('./gradlew tasks', 'Tasks')
  elseif id == 'gradle_wrapper' then
    ex.custom('./gradlew wrapper --upgrade-gradle-properties', 'Wrapper')

    -- Marvin
  elseif id == 'open_marvin' then
    local ok, m = pcall(require, 'marvin.dashboard')
    if ok then m.show() else vim.notify('Marvin not installed', vim.log.levels.WARN) end
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
  elseif id == 'valgrind' then
    ex.custom('valgrind --leak-check=full ' .. (ex.find_cmake_executable(project) or './main'), 'Valgrind')
  elseif id == 'sanitize_address' then
    ex.custom('cmake -B build -DCMAKE_CXX_FLAGS="-fsanitize=address" && cmake --build build', 'ASAN')
  elseif id == 'cpp_tools' then
    M.show_cpp_tools(project); return

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

-- ── Language tool sub-menus ───────────────────────────────────────────────────
function M.show_quality_menu(project)
  local lang  = project.language
  local ptype = project.type
  local ex    = require('jason.executor')
  local items = {}
  local function add(id, icon, label, desc)
    items[#items + 1] = { id = id, icon = icon, label = label, desc = desc }
  end

  if lang == 'rust' then
    add('audit', '󰒃', 'Audit', 'cargo audit — check for CVEs')
    add('outdated', '󰦉', 'Outdated', 'cargo outdated — show upgrades')
    add('coverage', '󰦉', 'Coverage', 'cargo tarpaulin')
  elseif lang == 'go' then
    add('coverage', '󰦉', 'Coverage', 'go test -cover ./...')
    add('vet', '󰁨', 'Vet', 'go vet ./...')
    add('staticcheck', '󰁨', 'Staticcheck', 'staticcheck ./...')
  elseif lang == 'java' then
    add('mvn_verify', '󰄬', 'Verify', 'mvn verify — integration tests')
    if ptype == 'maven' then
      add('spotless', '󰉣', 'Spotless', 'mvn spotless:apply')
      add('checkstyle', '󰁨', 'Checkstyle', 'mvn checkstyle:check')
      add('pmd', '󰁨', 'PMD', 'mvn pmd:check')
    end
  elseif lang == 'cpp' then
    add('clang_tidy', '󰁨', 'Clang-Tidy', 'clang-tidy checks')
    add('cppcheck', '󰁨', 'Cppcheck', 'cppcheck --enable=all src/')
    add('valgrind', '󰍉', 'Valgrind', 'Memory error detection')
    add('sanitize_address', '󰍉', 'ASAN', 'AddressSanitizer build')
    add('sanitize_thread', '󰍉', 'TSAN', 'ThreadSanitizer build')
  end

  require('jason.ui').select(items, {
    prompt = 'Quality Tools',
    format_item = function(it) return it.label end,
  }, function(choice)
    if not choice then return end
    local id = choice.id
    if id == 'audit' then
      ex.custom('cargo audit', 'Audit')
    elseif id == 'outdated' then
      ex.custom('cargo outdated', 'Outdated')
    elseif id == 'coverage' and lang == 'rust' then
      ex.custom('cargo tarpaulin', 'Coverage')
    elseif id == 'coverage' and lang == 'go' then
      ex.custom('go test -cover ./...', 'Coverage')
    elseif id == 'vet' then
      ex.custom('go vet ./...', 'Vet')
    elseif id == 'staticcheck' then
      ex.custom('staticcheck ./...', 'Staticcheck')
    elseif id == 'mvn_verify' then
      ex.custom('mvn verify', 'Verify')
    elseif id == 'spotless' then
      ex.custom('mvn spotless:apply', 'Spotless')
    elseif id == 'checkstyle' then
      ex.custom('mvn checkstyle:check', 'Checkstyle')
    elseif id == 'pmd' then
      ex.custom('mvn pmd:check', 'PMD')
    elseif id == 'clang_tidy' then
      ex.custom('clang-tidy $(find src -name "*.cpp")', 'Tidy')
    elseif id == 'cppcheck' then
      ex.custom('cppcheck --enable=all src/', 'Cppcheck')
    elseif id == 'valgrind' then
      ex.custom('valgrind --leak-check=full ' .. (require('jason.executor').find_cmake_executable(project) or './main'),
        'Valgrind')
    elseif id == 'sanitize_address' then
      ex.custom('cmake -B build -DCMAKE_CXX_FLAGS="-fsanitize=address" && cmake --build build', 'ASAN')
    elseif id == 'sanitize_thread' then
      ex.custom('cmake -B build -DCMAKE_CXX_FLAGS="-fsanitize=thread" && cmake --build build', 'TSAN')
    end
  end)
end

function M.show_rust_tools(project)
  local ex = require('jason.executor')
  require('jason.ui').select({
      { id = 'update', icon = '󰚰', label = 'Update', desc = 'cargo update' },
      { id = 'outdated', icon = '󰦉', label = 'Outdated', desc = 'cargo outdated' },
      { id = 'audit', icon = '󰒃', label = 'Audit', desc = 'cargo audit — CVE check' },
      { id = 'tree', icon = '󰙅', label = 'Dep Tree', desc = 'cargo tree' },
      { id = 'bloat', icon = '󰍉', label = 'Bloat', desc = 'cargo bloat — binary size analysis' },
      { id = 'flamegraph', icon = '󰦉', label = 'Flamegraph', 'cargo flamegraph' },
    }, { prompt = 'Rust Tools', format_item = function(it) return it.label end },
    function(choice)
      if not choice then return end
      if choice.id == 'update' then
        ex.custom('cargo update', 'Update')
      elseif choice.id == 'outdated' then
        ex.custom('cargo outdated', 'Outdated')
      elseif choice.id == 'audit' then
        ex.custom('cargo audit', 'Audit')
      elseif choice.id == 'tree' then
        ex.custom('cargo tree', 'Dep Tree')
      elseif choice.id == 'bloat' then
        ex.custom('cargo bloat', 'Bloat')
      elseif choice.id == 'flamegraph' then
        ex.custom('cargo flamegraph', 'Flamegraph')
      end
    end)
end

function M.show_go_tools(project)
  local ex = require('jason.executor')
  require('jason.ui').select({
      { id = 'mod_tidy', icon = '󰚰', label = 'Tidy', desc = 'go mod tidy' },
      { id = 'mod_download', icon = '󰚰', label = 'Download', desc = 'go mod download' },
      { id = 'mod_verify', icon = '󰄬', label = 'Verify', desc = 'go mod verify' },
      { id = 'mod_graph', icon = '󰙅', label = 'Dep Graph', desc = 'go mod graph' },
      { id = 'mod_why', icon = '󰍉', label = 'Why', desc = 'go mod why — explain dep' },
      { id = 'generate', icon = '󰑕', label = 'Generate', desc = 'go generate ./...' },
      { id = 'godoc', icon = '󰈙', label = 'Godoc', desc = 'godoc -http :6060' },
    }, { prompt = 'Go Tools', format_item = function(it) return it.label end },
    function(choice)
      if not choice then return end
      if choice.id == 'mod_tidy' then
        ex.custom('go mod tidy', 'Tidy')
      elseif choice.id == 'mod_download' then
        ex.custom('go mod download', 'Download')
      elseif choice.id == 'mod_verify' then
        ex.custom('go mod verify', 'Verify')
      elseif choice.id == 'mod_graph' then
        ex.custom('go mod graph', 'Dep Graph')
      elseif choice.id == 'mod_why' then
        vim.ui.input({ prompt = 'Module name: ' }, function(mod)
          if mod and mod ~= '' then ex.custom('go mod why ' .. mod, 'Why ' .. mod) end
        end)
        return
      elseif choice.id == 'generate' then
        ex.custom('go generate ./...', 'Generate')
      elseif choice.id == 'godoc' then
        ex.custom('godoc -http :6060', 'Godoc')
      end
    end)
end

function M.show_cpp_tools(project)
  local ex = require('jason.executor')
  require('jason.ui').select({
      { id = 'cmake_debug', icon = '󰒓', label = 'CMake Debug', desc = 'cmake -B build -DCMAKE_BUILD_TYPE=Debug' },
      { id = 'cmake_release', icon = '󰒓', label = 'CMake Release', desc = 'cmake -B build -DCMAKE_BUILD_TYPE=Release' },
      { id = 'cmake_install', icon = '󰇚', label = 'CMake Install', desc = 'cmake --install build' },
      { id = 'cmake_pack', icon = '󰏗', label = 'CPack', desc = 'cpack --config build/CPackConfig.cmake' },
      { id = 'clang_tidy', icon = '󰁨', label = 'Clang-Tidy', desc = 'Static analysis' },
      { id = 'cppcheck', icon = '󰁨', label = 'Cppcheck', desc = 'cppcheck --enable=all src/' },
      { id = 'asm', icon = '󰈙', label = 'View Assembly', desc = 'objdump -d on built binary' },
    }, { prompt = 'C++ Tools', format_item = function(it) return it.label end },
    function(choice)
      if not choice then return end
      if choice.id == 'cmake_debug' then
        ex.custom('cmake -B build -DCMAKE_BUILD_TYPE=Debug', 'CMake Debug')
      elseif choice.id == 'cmake_release' then
        ex.custom('cmake -B build -DCMAKE_BUILD_TYPE=Release', 'CMake Release')
      elseif choice.id == 'cmake_install' then
        ex.custom('cmake --install build', 'CMake Install')
      elseif choice.id == 'cmake_pack' then
        ex.custom('cpack --config build/CPackConfig.cmake', 'CPack')
      elseif choice.id == 'clang_tidy' then
        ex.custom('clang-tidy $(find src -name "*.cpp")', 'Clang-Tidy')
      elseif choice.id == 'cppcheck' then
        ex.custom('cppcheck --enable=all src/', 'Cppcheck')
      elseif choice.id == 'asm' then
        local bin = ex.find_cmake_executable(project) or './main'
        ex.custom('objdump -d ' .. bin .. ' | less', 'Assembly')
      end
    end)
end

-- ── Maven profile picker ──────────────────────────────────────────────────────
function M.run_with_maven_profile(project)
  local ok, mp = pcall(require, 'marvin.project')
  local profiles = ok and mp.get_project() and mp.get_project().info and mp.get_project().info.profiles or {}
  if #profiles == 0 then
    vim.notify('No Maven profiles found in pom.xml', vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, pid in ipairs(profiles) do
    items[#items + 1] = { id = pid, label = pid, desc = 'Maven profile' }
  end
  require('jason.ui').select(items, {
      prompt = 'Maven Profile',
      format_item = function(it) return it.label end
    },
    function(choice)
      if choice then
        require('jason.executor').custom('mvn install -P' .. choice.id, 'Install (' .. choice.id .. ')')
      end
    end)
end

-- ── Project picker (monorepo) ─────────────────────────────────────────────────
function M.show_project_picker()
  local det  = require('jason.detector')
  local subs = det.detect_sub_projects(vim.fn.getcwd())
  if not subs or #subs == 0 then
    vim.notify('No sub-projects found', vim.log.levels.INFO); return
  end
  local items = {}
  for _, p in ipairs(subs) do
    items[#items + 1] = {
      id = p.root,
      label = p.name,
      desc = p.type .. ' · ' .. p.language,
      _proj = p
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

-- ── Settings sub-menus ────────────────────────────────────────────────────────
function M.show_terminal_settings()
  local cfg = require('jason').config
  require('jason.ui').select({
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
  local lines = {
    '', '  Stored run arguments for: ' .. (project.name or root),
    '  ' .. string.rep('─', 40), '',
    string.format('  %-16s  %q', 'build args:', ex.get_args(root, 'build')),
    string.format('  %-16s  %q', 'run args:', ex.get_args(root, 'run')),
    string.format('  %-16s  %q', 'test filter:', ex.get_args(root, 'test')),
    '',
    '  Use "Build with args…", "Run with args…" or "Test (filter)…"',
    '  in the Run / Build sections to update these.',
    '',
  }
  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

function M.show_keybindings()
  local cfg   = require('jason').config.keymaps
  local lines = {
    '', '  Jason Keybindings', '  ' .. string.rep('─', 32), '',
    string.format('  %-18s %s', cfg.dashboard or '<leader>jb', 'Open dashboard'),
    string.format('  %-18s %s', cfg.build or '<leader>jc', 'Build'),
    string.format('  %-18s %s', cfg.run or '<leader>jr', 'Run'),
    string.format('  %-18s %s', cfg.test or '<leader>jt', 'Test'),
    string.format('  %-18s %s', cfg.clean or '<leader>jx', 'Clean'),
    '',
    '  j/k navigate  ·  ⏎ select  ·  ⎋ quit  ·  type to fuzzy-search',
    '',
  }
  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

-- ── History viewer ────────────────────────────────────────────────────────────
function M.show_history(project)
  local h = require('core.runner').history
  if #h == 0 then
    vim.notify('No history yet', vim.log.levels.INFO); return
  end
  local items = {}
  for _, e in ipairs(h) do
    local info = (e.plugin or '?') .. ' · ' .. ago(e.timestamp)
        .. (e.duration and (' · ' .. dur_str(e.duration)) or '')
    items[#items + 1] = {
      id = e.action_id,
      label = e.action,
      desc = info,
      badge = e.success and '✓' or '✗',
      _entry = e,
    }
  end
  local runner = require('core.runner')
  require('jason.ui').select(items, {
    prompt = 'Run History',
    enable_search = true,
    format_item = function(it) return it.label end,
  }, function(choice)
    if not choice then return end
    require('jason.ui').select({
        { id = 'rerun',  label = 'Re-run',           desc = 'Execute again' },
        { id = 'output', label = 'View Output',      desc = 'Open log in split' },
        { id = 'qf',     label = 'Open in Quickfix', desc = 'Parse errors into quickfix' },
      }, { prompt = choice.label, format_item = function(it) return it.label end },
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
