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

  -- ── Run ───────────────────────────────────────────────────────────────────
  add(sep('Run'))
  add(item('build_run', '▶', 'Build & Run', 'Compile then execute', status_badge('build_run')))
  add(item('run', '󰐊', 'Run', 'Execute without building', status_badge('run')))
  add(item('test', '󰙨', 'Test', 'Run full test suite', status_badge('test')))
  add(item('run_submenu', '󰒓', 'Run Options…', 'Args, filter, build+run w/ args'))

  -- ── Build ─────────────────────────────────────────────────────────────────
  add(sep('Build'))
  add(item('build', '󰔷', 'Build', 'Compile sources', status_badge('build')))
  add(item('clean_build', '󰑕', 'Clean & Build', 'Wipe artifacts then compile'))
  add(item('build_submenu', '󰒓', 'Build Options…', 'Package, install, skip tests, more'))

  -- ── Quality ───────────────────────────────────────────────────────────────
  add(sep('Quality'))
  add(item('fmt', '󰉣', 'Format', 'Auto-format all source files'))
  add(item('lint', '󰁨', 'Lint', 'Run linter / static analysis'))
  add(item('quality_submenu', '󰦉', 'More…', 'Coverage, audit, vet…'))

  -- ── Language tools ────────────────────────────────────────────────────────
  if lang == 'rust' then
    add(sep('Rust'))
    add(item('check', '󰄬', 'Check', 'Type-check without codegen'))
    local cur = cfg.rust.profile
    add(item('toggle_profile', '󰒓', 'Profile: ' .. cur,
      'Switch to ' .. (cur == 'release' and 'dev' or 'release'),
      cur == 'release' and '󰓅 release' or '󰁌 dev'))
    add(item('rust_submenu', '󰒓', 'Rust Tools…', 'Doc, bench, audit, flamegraph'))
  elseif lang == 'go' then
    add(sep('Go'))
    add(item('vet', '󰁨', 'Vet', 'go vet ./...'))
    add(item('coverage', '󰦉', 'Coverage', 'go test -cover ./...'))
    add(item('go_submenu', '󰒓', 'Go Tools…', 'Race, mod tidy, godoc, generate'))
  elseif lang == 'java' then
    add(sep('Java'))
    if ptype == 'maven' then
      add(item('mvn_skip_tests', '󰒭', 'Build (skip tests)', 'mvn package -DskipTests'))
      add(item('mvn_profiles', '󰒓', 'Run with Profile…', 'Pick a Maven profile'))
    elseif ptype == 'gradle' then
      add(item('gradle_tasks', '󰒓', 'Gradle Tasks', './gradlew tasks'))
      add(item('gradle_wrapper', '󰚰', 'Wrapper Update', './gradlew wrapper --upgrade-gradle-properties'))
    end
    add(item('open_marvin', '󱁆', 'Open Marvin…', 'POM, archetypes, deps, file gen'))
    add(item('graal_submenu', '󰱒', 'GraalVM…', 'Native image build, run, agent'))
  elseif lang == 'cpp' then
    add(sep('C/C++'))
    add(item('cpp_compiler_submenu', '󰒓', 'Compiler…', 'Debug, Release, ASAN, TSAN, LTO'))
    add(item('cpp_tools', '󰒓', 'Tools…', 'Tidy, cppcheck, valgrind, assembly'))
  end

  -- Monorepo
  if require('jason.detector').is_monorepo() then
    add(sep('Workspace'))
    add(item('switch_project', '󰒓', 'Switch Sub-project', 'Pick a project in this workspace'))
  end

  -- ── Console & History ─────────────────────────────────────────────────────
  add(sep('Console'))
  local h = require('core.runner').history
  add(item('open_console', '󰋚', 'Task Console',
    #h > 0 and (#h .. ' entries') or 'No runs yet',
    #h > 0 and (h[1].success and '✓' or '✗') or nil))
  if #h > 0 then
    local last = h[1]
    add(item('rerun_last', '󰑕', 'Rerun Last',
      last.action .. ' · ' .. ago(last.timestamp),
      last.success and '✓' or '✗'))
  end

  -- Settings
  add(sep('Settings'))
  add(item('settings_submenu', '󰒓', 'Settings…', 'Terminal, args, keybindings'))

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
  elseif id == 'build_run' then
    ex.build_and_run(false)
  elseif id == 'run' then
    ex.run(false)
  elseif id == 'test' then
    ex.test(false)
  elseif id == 'run_submenu' then
    M.show_run_submenu(project); return

    -- Build
  elseif id == 'build' then
    ex.build(false)
  elseif id == 'clean_build' then
    runner.execute_sequence(
      { { cmd = ex.get_command('clean', project), title = 'Clean' },
        { cmd = ex.get_command('build', project), title = 'Build' } },
      { cwd = project.root, term_cfg = cfg.terminal, plugin = 'jason', action_id = 'clean_build' })
  elseif id == 'build_submenu' then
    M.show_build_submenu(project); return

    -- Quality
  elseif id == 'fmt' then
    ex.fmt()
  elseif id == 'lint' then
    ex.lint()
  elseif id == 'quality_submenu' then
    M.show_quality_menu(project); return

    -- Rust
  elseif id == 'check' then
    ex.custom('cargo check', 'Check')
  elseif id == 'toggle_profile' then
    cfg.rust.profile = cfg.rust.profile == 'release' and 'dev' or 'release'
    vim.notify('Rust profile → ' .. cfg.rust.profile, vim.log.levels.INFO)
    vim.defer_fn(function() M.show(project) end, 50); return
  elseif id == 'rust_submenu' then
    M.show_rust_submenu(project); return

    -- Go
  elseif id == 'vet' then
    ex.custom('go vet ./...', 'Vet')
  elseif id == 'coverage' then
    ex.custom('go test -cover ./...', 'Coverage')
  elseif id == 'go_submenu' then
    M.show_go_submenu(project); return

    -- Java
  elseif id == 'mvn_skip_tests' then
    ex.custom('mvn package -DskipTests', 'Build (skip tests)')
  elseif id == 'mvn_profiles' then
    M.run_with_maven_profile(project)
  elseif id == 'gradle_tasks' then
    ex.custom('./gradlew tasks', 'Tasks')
  elseif id == 'gradle_wrapper' then
    ex.custom('./gradlew wrapper --upgrade-gradle-properties', 'Wrapper')
  elseif id == 'open_marvin' then
    local ok, m = pcall(require, 'marvin.dashboard')
    if ok then m.show() else vim.notify('Marvin not installed', vim.log.levels.WARN) end
    return
  elseif id == 'graal_submenu' then
    M.show_graal_submenu(project); return

    -- C/C++
  elseif id == 'cpp_compiler_submenu' then
    M.show_cpp_compiler_submenu(project); return
  elseif id == 'cpp_tools' then
    M.show_cpp_tools(project); return

    -- Workspace
  elseif id == 'switch_project' then
    M.show_project_picker(); return

    -- Console / History
  elseif id == 'open_console' then
    require('jason.console').open(); return
  elseif id == 'rerun_last' then
    local h = runner.history
    if h[1] then ex.custom(h[1].cmd, h[1].action) end

    -- Settings
  elseif id == 'settings_submenu' then
    M.show_settings_submenu(project); return
  elseif id == 'terminal_settings' then
    M.show_terminal_settings()
  elseif id == 'env_settings' then
    M.show_env_settings(project)
  elseif id == 'keybindings' then
    M.show_keybindings()
  end
end

-- ── Run sub-menu ──────────────────────────────────────────────────────────────
function M.show_run_submenu(project)
  local ex = require('jason.executor')
  require('jason.ui').select({
      { id = 'build_run_args', icon = '▶', label = 'Build & Run…', desc = 'Prompt for run args' },
      { id = 'run_args', icon = '󰐊', label = 'Run with Args…', desc = 'Prompt for arguments' },
      { id = 'test_filter', icon = '󰙨', label = 'Test (filter)…', desc = 'Run matching tests only' },
      { id = 'build_args', icon = '󰔷', label = 'Build with Args…', desc = 'Pass extra compiler flags' },
    }, { prompt = 'Run Options', format_item = function(it) return it.icon .. ' ' .. it.label end },
    function(choice)
      if not choice then return end
      if choice.id == 'build_run_args' then
        ex.build_and_run(true)
      elseif choice.id == 'run_args' then
        ex.run(true)
      elseif choice.id == 'test_filter' then
        ex.test(true)
      elseif choice.id == 'build_args' then
        ex.build(true)
      end
    end)
end

-- ── Build sub-menu ────────────────────────────────────────────────────────────
function M.show_build_submenu(project)
  local ex = require('jason.executor')
  require('jason.ui').select({
      { id = 'package', icon = '󰏗', label = 'Package', desc = 'Build distributable output' },
      { id = 'install', icon = '󰇚', label = 'Install', desc = 'Install to system / local repo' },
      { id = 'clean', icon = '󰃢', label = 'Clean', desc = 'Remove build artifacts' },
    }, { prompt = 'Build Options', format_item = function(it) return it.icon .. ' ' .. it.label end },
    function(choice)
      if not choice then return end
      if choice.id == 'package' then
        ex.package()
      elseif choice.id == 'install' then
        ex.install()
      elseif choice.id == 'clean' then
        ex.clean()
      end
    end)
end

-- ── GraalVM sub-menu ──────────────────────────────────────────────────────────
function M.show_graal_submenu(project)
  local graal  = require('jason.graalvm')
  local has_ni = graal.native_image_bin() ~= nil
  local items  = {
    {
      id    = 'graal_build_native',
      icon  = '󰱒',
      label = 'Build Native',
      desc  = 'Compile to native binary',
      badge = has_ni and '●' or '○ not installed',
    },
    { id = 'graal_run_native', icon = '▶', label = 'Run Native', desc = 'Execute native binary' },
    { id = 'graal_build_run', icon = '󰔷', label = 'Build & Run Native', desc = 'Native build then run' },
    { id = 'graal_agent_run', icon = '󰈙', label = 'Agent Run', desc = 'Collect reflection config' },
    { id = 'graal_info', icon = '󰅾', label = 'GraalVM Info', desc = 'Status & config' },
  }
  if not has_ni then
    items[#items + 1] = {
      id = 'graal_install_ni', icon = '󰚰', label = 'Install native-image', desc = 'gu install native-image',
    }
  end
  require('jason.ui').select(items, {
    prompt = 'GraalVM',
    format_item = function(it) return it.icon .. ' ' .. it.label end,
  }, function(choice)
    if not choice then return end
    if choice.id == 'graal_build_native' then
      graal.build_native(project)
    elseif choice.id == 'graal_run_native' then
      graal.run_native(project)
    elseif choice.id == 'graal_build_run' then
      graal.build_and_run_native(project)
    elseif choice.id == 'graal_agent_run' then
      graal.run_with_agent(project)
    elseif choice.id == 'graal_info' then
      graal.show_info()
    elseif choice.id == 'graal_install_ni' then
      graal.install_native_image(project)
    end
  end)
end

-- ── Rust sub-menu ─────────────────────────────────────────────────────────────
function M.show_rust_submenu(project)
  local ex   = require('jason.executor')
  local cmds = {
    doc        = 'cargo doc --open',
    bench      = 'cargo bench',
    expand     = 'cargo expand',
    update     = 'cargo update',
    outdated   = 'cargo outdated',
    audit      = 'cargo audit',
    tree       = 'cargo tree',
    bloat      = 'cargo bloat',
    flamegraph = 'cargo flamegraph',
  }
  require('jason.ui').select({
      { id = 'doc', icon = '󰈙', label = 'Docs', desc = 'cargo doc --open' },
      { id = 'bench', icon = '󰦉', label = 'Bench', desc = 'cargo bench' },
      { id = 'expand', icon = '󰈙', label = 'Expand', desc = 'cargo expand — macro output' },
      { id = 'update', icon = '󰚰', label = 'Update', desc = 'cargo update' },
      { id = 'outdated', icon = '󰦉', label = 'Outdated', desc = 'cargo outdated' },
      { id = 'audit', icon = '󰒃', label = 'Audit', desc = 'cargo audit — CVE check' },
      { id = 'tree', icon = '󰙅', label = 'Dep Tree', desc = 'cargo tree' },
      { id = 'bloat', icon = '󰍉', label = 'Bloat', desc = 'Binary size analysis' },
      { id = 'flamegraph', icon = '󰦉', label = 'Flamegraph', desc = 'cargo flamegraph' },
    }, { prompt = 'Rust Tools', format_item = function(it) return it.icon .. ' ' .. it.label end },
    function(choice)
      if choice and cmds[choice.id] then
        ex.custom(cmds[choice.id], choice.label)
      end
    end)
end

-- ── Go sub-menu ───────────────────────────────────────────────────────────────
function M.show_go_submenu(project)
  local ex = require('jason.executor')
  require('jason.ui').select({
      { id = 'build_race', icon = '󰔷', label = 'Race Detector', desc = 'go build -race' },
      { id = 'mod_tidy', icon = '󰚰', label = 'Mod Tidy', desc = 'go mod tidy' },
      { id = 'mod_download', icon = '󰚰', label = 'Mod Download', desc = 'go mod download' },
      { id = 'mod_verify', icon = '󰄬', label = 'Mod Verify', desc = 'go mod verify' },
      { id = 'mod_graph', icon = '󰙅', label = 'Dep Graph', desc = 'go mod graph' },
      { id = 'mod_why', icon = '󰍉', label = 'Why…', desc = 'go mod why — explain dep' },
      { id = 'generate', icon = '󰑕', label = 'Generate', desc = 'go generate ./...' },
      { id = 'godoc', icon = '󰈙', label = 'Godoc', desc = 'godoc -http :6060' },
    }, { prompt = 'Go Tools', format_item = function(it) return it.icon .. ' ' .. it.label end },
    function(choice)
      if not choice then return end
      if choice.id == 'build_race' then
        ex.custom('go build -race ./...', 'Race Build')
      elseif choice.id == 'mod_tidy' then
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
      elseif choice.id == 'generate' then
        ex.custom('go generate ./...', 'Generate')
      elseif choice.id == 'godoc' then
        ex.custom('godoc -http :6060', 'Godoc')
      end
    end)
end

-- ── C/C++ Compiler sub-menu ───────────────────────────────────────────────────
function M.show_cpp_compiler_submenu(project)
  local ex  = require('jason.executor')
  local cfg = require('jason').config
  require('jason.ui').select({
      { id = 'cmake_debug', icon = '󰒓', label = 'CMake Debug', desc = '-DCMAKE_BUILD_TYPE=Debug' },
      { id = 'cmake_release', icon = '󰓅', label = 'CMake Release', desc = '-DCMAKE_BUILD_TYPE=Release' },
      { id = 'cmake_reldbg', icon = '󰒓', label = 'RelWithDebInfo', desc = 'Optimised + debug symbols' },
      { id = 'cmake_minsz', icon = '󰒓', label = 'MinSizeRel', desc = 'Optimise for binary size' },
      { id = 'asan', icon = '󰍉', label = 'ASAN Build', desc = 'AddressSanitizer' },
      { id = 'tsan', icon = '󰍉', label = 'TSAN Build', desc = 'ThreadSanitizer' },
      { id = 'ubsan', icon = '󰍉', label = 'UBSAN Build', desc = 'UndefinedBehaviorSanitizer' },
      { id = 'lto', icon = '󰦉', label = 'LTO Build', desc = 'Link-time optimisation' },
      { id = 'compile_commands', icon = '󰈙', label = 'Compile DB', desc = 'Generate compile_commands.json' },
      { id = 'cpp_standard', icon = '󰒓', label = 'C++ Standard…', desc = 'Current: ' .. (cfg.cpp.standard or 'c++17') },
      { id = 'cpp_compiler_pick', icon = '󰒓', label = 'Compiler…', desc = 'Current: ' .. (cfg.cpp.compiler or 'g++') },
    }, { prompt = 'C/C++ Compiler', format_item = function(it) return it.icon .. ' ' .. it.label end },
    function(choice)
      if not choice then return end
      local function run(c, t) ex.custom(c, t) end
      if choice.id == 'cmake_debug' then
        run('cmake -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build', 'CMake Debug')
      elseif choice.id == 'cmake_release' then
        run('cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build', 'CMake Release')
      elseif choice.id == 'cmake_reldbg' then
        run('cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo && cmake --build build', 'RelWithDebInfo')
      elseif choice.id == 'cmake_minsz' then
        run('cmake -B build -DCMAKE_BUILD_TYPE=MinSizeRel && cmake --build build', 'MinSizeRel')
      elseif choice.id == 'asan' then
        run(
        'cmake -B build -DCMAKE_CXX_FLAGS="-fsanitize=address -fno-omit-frame-pointer" -DCMAKE_BUILD_TYPE=Debug && cmake --build build',
          'ASAN')
      elseif choice.id == 'tsan' then
        run('cmake -B build -DCMAKE_CXX_FLAGS="-fsanitize=thread" -DCMAKE_BUILD_TYPE=Debug && cmake --build build',
          'TSAN')
      elseif choice.id == 'ubsan' then
        run('cmake -B build -DCMAKE_CXX_FLAGS="-fsanitize=undefined" -DCMAKE_BUILD_TYPE=Debug && cmake --build build',
          'UBSAN')
      elseif choice.id == 'lto' then
        run('cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON && cmake --build build',
          'LTO Release')
      elseif choice.id == 'compile_commands' then
        run('cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && cp build/compile_commands.json .', 'Compile DB')
      elseif choice.id == 'cpp_standard' then
        M.pick_cpp_standard(project)
      elseif choice.id == 'cpp_compiler_pick' then
        M.pick_cpp_compiler(project)
      end
    end)
end

function M.pick_cpp_standard(project)
  local cfg = require('jason').config
  require('jason.ui').select({
      { id = 'c++23', label = 'C++23', desc = 'Latest standard' },
      { id = 'c++20', label = 'C++20', desc = 'Concepts, ranges, coroutines' },
      { id = 'c++17', label = 'C++17', desc = 'Widely supported (default)' },
      { id = 'c++14', label = 'C++14', desc = 'Broad compatibility' },
      { id = 'c++11', label = 'C++11', desc = 'Modern baseline' },
    }, { prompt = 'C++ Standard', format_item = function(it) return it.label end },
    function(c) if c then
        cfg.cpp.standard = c.id; vim.notify('C++ standard → ' .. c.id)
      end end)
end

function M.pick_cpp_compiler(project)
  local cfg = require('jason').config
  require('jason.ui').select({
      { id = 'g++',     label = 'g++',     desc = 'GNU C++ compiler' },
      { id = 'clang++', label = 'clang++', desc = 'LLVM Clang compiler' },
      { id = 'icpx',    label = 'icpx',    desc = 'Intel DPC++ compiler' },
    }, { prompt = 'C++ Compiler', format_item = function(it) return it.label end },
    function(c) if c then
        cfg.cpp.compiler = c.id; vim.notify('Compiler → ' .. c.id)
      end end)
end

-- ── C++ Tools sub-menu ────────────────────────────────────────────────────────
function M.show_cpp_tools(project)
  local ex = require('jason.executor')
  require('jason.ui').select({
      { id = 'valgrind', icon = '󰍉', label = 'Valgrind', desc = 'Memory error detection' },
      { id = 'clang_tidy', icon = '󰁨', label = 'Clang-Tidy', desc = 'Static analysis' },
      { id = 'cppcheck', icon = '󰁨', label = 'Cppcheck', desc = 'cppcheck --enable=all src/' },
      { id = 'cmake_pack', icon = '󰏗', label = 'CPack', desc = 'cpack --config build/CPackConfig.cmake' },
      { id = 'cmake_inst', icon = '󰇚', label = 'CMake Install', desc = 'cmake --install build' },
      { id = 'asm', icon = '󰈙', label = 'View Assembly', desc = 'objdump -d on built binary' },
      { id = 'size', icon = '󰦉', label = 'Binary Size', desc = 'size on built binary' },
    }, { prompt = 'C++ Tools', format_item = function(it) return it.icon .. ' ' .. it.label end },
    function(choice)
      if not choice then return end
      if choice.id == 'valgrind' then
        ex.custom('valgrind --leak-check=full ' .. (ex.find_cmake_executable(project) or './main'), 'Valgrind')
      elseif choice.id == 'clang_tidy' then
        ex.custom('clang-tidy $(find src -name "*.cpp")', 'Clang-Tidy')
      elseif choice.id == 'cppcheck' then
        ex.custom('cppcheck --enable=all src/', 'Cppcheck')
      elseif choice.id == 'cmake_pack' then
        ex.custom('cpack --config build/CPackConfig.cmake', 'CPack')
      elseif choice.id == 'cmake_inst' then
        ex.custom('cmake --install build', 'CMake Install')
      elseif choice.id == 'asm' then
        ex.custom('objdump -d ' .. (ex.find_cmake_executable(project) or './main') .. ' | less', 'Assembly')
      elseif choice.id == 'size' then
        ex.custom('size ' .. (ex.find_cmake_executable(project) or './main'), 'Binary Size')
      end
    end)
end

-- ── Quality sub-menu ──────────────────────────────────────────────────────────
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
    add('mvn_verify', '󰄬', 'Verify', 'mvn verify')
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
    format_item = function(it) return it.icon .. ' ' .. it.label end,
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
      ex.custom('valgrind --leak-check=full ' .. (ex.find_cmake_executable(project) or './main'), 'Valgrind')
    elseif id == 'sanitize_address' then
      ex.custom('cmake -B build -DCMAKE_CXX_FLAGS="-fsanitize=address" && cmake --build build', 'ASAN')
    elseif id == 'sanitize_thread' then
      ex.custom('cmake -B build -DCMAKE_CXX_FLAGS="-fsanitize=thread" && cmake --build build', 'TSAN')
    end
  end)
end

-- ── Maven profile picker ──────────────────────────────────────────────────────
function M.run_with_maven_profile(project)
  local ok, mp   = pcall(require, 'marvin.project')
  local profiles = ok and mp.get_project() and mp.get_project().info and mp.get_project().info.profiles or {}
  if #profiles == 0 then
    vim.notify('No Maven profiles found in pom.xml', vim.log.levels.INFO); return
  end
  local items = {}
  for _, pid in ipairs(profiles) do
    items[#items + 1] = { id = pid, label = pid, desc = 'Maven profile' }
  end
  require('jason.ui').select(items,
    { prompt = 'Maven Profile', format_item = function(it) return it.label end },
    function(choice)
      if choice then
        require('jason.executor').custom('mvn install -P' .. choice.id, 'Install (' .. choice.id .. ')')
      end
    end)
end

-- ── Monorepo switcher ─────────────────────────────────────────────────────────
function M.show_project_picker()
  local det  = require('jason.detector')
  local subs = det.detect_sub_projects(vim.fn.getcwd())
  if not subs or #subs == 0 then
    vim.notify('No sub-projects found', vim.log.levels.INFO); return
  end
  local items = {}
  for _, p in ipairs(subs) do
    items[#items + 1] = { id = p.root, label = p.name, desc = p.type .. ' · ' .. p.language, _proj = p }
  end
  require('jason.ui').select(items,
    { prompt = 'Switch Project', format_item = function(it) return it.label end },
    function(choice)
      if choice then
        det.set_project(choice._proj)
        vim.notify('Switched to: ' .. choice.label, vim.log.levels.INFO)
        vim.defer_fn(function() M.show(choice._proj) end, 50)
      end
    end)
end

-- ── Settings sub-menu ─────────────────────────────────────────────────────────
function M.show_settings_submenu(project)
  local cfg = require('jason').config
  require('jason.ui').select({
      { id = 'terminal_settings', icon = '󰆍', label = 'Terminal', desc = 'Position: ' .. cfg.terminal.position },
      { id = 'env_settings', icon = '󰙩', label = 'Run Args', desc = 'View stored per-project args' },
      { id = 'keybindings', icon = '󰌌', label = 'Keybindings', desc = 'View all shortcuts' },
    }, { prompt = 'Settings', format_item = function(it) return it.icon .. ' ' .. it.label end },
    function(choice)
      if not choice then return end
      if choice.id == 'terminal_settings' then
        M.show_terminal_settings()
      elseif choice.id == 'env_settings' then
        M.show_env_settings(project)
      elseif choice.id == 'keybindings' then
        M.show_keybindings()
      end
    end)
end

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
        cfg.terminal.position = choice.id; vim.notify('Terminal → ' .. choice.id)
      end
    end)
end

function M.show_env_settings(project)
  local ex   = require('jason.executor')
  local root = project.root
  vim.api.nvim_echo({ { table.concat({
    '', '  Stored run arguments for: ' .. (project.name or root),
    '  ' .. string.rep('─', 40), '',
    string.format('  %-16s  %q', 'build args:', ex.get_args(root, 'build')),
    string.format('  %-16s  %q', 'run args:', ex.get_args(root, 'run')),
    string.format('  %-16s  %q', 'test filter:', ex.get_args(root, 'test')),
    '', '  Use "Run Options…" to update these.', '',
  }, '\n'), 'Normal' } }, true, {})
end

function M.show_keybindings()
  local cfg = require('jason').config.keymaps
  vim.api.nvim_echo({ { table.concat({
    '', '  Jason Keybindings', '  ' .. string.rep('─', 32), '',
    string.format('  %-18s %s', cfg.dashboard or '<leader>jb', 'Open dashboard'),
    string.format('  %-18s %s', cfg.build or '<leader>jc', 'Build'),
    string.format('  %-18s %s', cfg.run or '<leader>jr', 'Run'),
    string.format('  %-18s %s', cfg.test or '<leader>jt', 'Test'),
    string.format('  %-18s %s', cfg.clean or '<leader>jx', 'Clean'),
    string.format('  %-18s %s', cfg.console or '<leader>jo', 'Task Console'),
    '', '  j/k navigate  ·  ⏎ select  ·  ⎋ quit  ·  type to fuzzy-search', '',
  }, '\n'), 'Normal' } }, true, {})
end

-- ── History viewer (legacy, routes to console) ────────────────────────────────
function M.show_history(project)
  require('jason.console').open()
end

return M
