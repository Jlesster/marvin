-- lua/jason/executor.lua
-- Command resolution + public API. All execution goes through core.runner.

local M = {}

-- ── Per-project run args memory (survives dashboard close) ───────────────────
M._run_args = {} -- project_root -> { build = '...', run = '...', test = '...' }

function M.get_args(root, action)
  return (M._run_args[root] or {})[action] or ''
end

function M.set_args(root, action, args)
  M._run_args[root] = M._run_args[root] or {}
  M._run_args[root][action] = args
end

-- ── Command builders ─────────────────────────────────────────────────────────
local B = {
  maven = {
    build   = 'mvn compile',
    run     = function(p) return 'mvn exec:java -Dexec.mainClass=' .. M.find_main_class(p) end,
    test    = 'mvn test',
    clean   = 'mvn clean',
    fmt     = nil, -- handled via spotless if available
    lint    = nil,
    install = 'mvn install',
    package = 'mvn package',
  },
  gradle = {
    build   = './gradlew build',
    run     = './gradlew run',
    test    = './gradlew test',
    clean   = './gradlew clean',
    install = './gradlew publishToMavenLocal',
    package = './gradlew jar',
  },
  cargo = {
    build   = function()
      local p = require('jason').config.rust.profile; return p == 'release' and 'cargo build --release' or 'cargo build'
    end,
    run     = function()
      local p = require('jason').config.rust.profile; return p == 'release' and 'cargo run --release' or 'cargo run'
    end,
    test    = 'cargo test',
    clean   = 'cargo clean',
    fmt     = 'cargo fmt',
    lint    = 'cargo clippy',
    install = 'cargo install --path .',
    package = function()
      local p = require('jason').config.rust.profile; return p == 'release' and 'cargo build --release' or 'cargo build'
    end,
  },
  go_mod = {
    build   = 'go build ./...',
    run     = 'go run .',
    test    = 'go test ./...',
    clean   = 'go clean ./...',
    fmt     = 'gofmt -w .',
    lint    = 'golangci-lint run',
    install = 'go install .',
    package = 'go build -o dist/ ./...',
  },
  cmake = {
    build   = 'cmake --build build',
    run     = function(p) return M.find_cmake_executable(p) or './build/main' end,
    test    = 'ctest --test-dir build',
    clean   = 'cmake --build build --target clean',
    fmt     = 'find . -name "*.cpp" -o -name "*.h" | xargs clang-format -i',
    lint    = 'clang-tidy $(find src -name "*.cpp")',
    install = 'cmake --install build',
    package = 'cpack --config build/CPackConfig.cmake',
  },
  makefile = {
    build   = 'make',
    run     = function(p) return M.find_makefile_executable(p) or './main' end,
    test    = 'make test',
    clean   = 'make clean',
    fmt     = 'find . -name "*.cpp" -o -name "*.h" | xargs clang-format -i',
    lint    = 'make lint',
    install = 'make install',
    package = 'make dist',
  },
  single_file = {
    build   = function(p)
      local ft, f = p.language, p.file
      local base  = vim.fn.fnamemodify(f, ':t:r')
      if ft == 'java' then
        return 'javac ' .. f
      elseif ft == 'rust' then
        return 'rustc ' .. f
      elseif ft == 'go' then
        return 'go build ' .. f
      elseif ft == 'cpp' then
        local cfg = require('jason').config
        return string.format('%s -std=%s %s -o %s', cfg.cpp.compiler, cfg.cpp.standard, f, base)
      elseif ft == 'c' then
        return 'gcc ' .. f .. ' -o ' .. base
      end
    end,
    run     = function(p)
      local ft, f = p.language, p.file
      local base  = vim.fn.fnamemodify(f, ':t:r')
      if ft == 'java' then
        return 'java ' .. base
      elseif ft == 'rust' then
        return './' .. base
      elseif ft == 'go' then
        return 'go run ' .. f
      elseif ft == 'cpp' or ft == 'c' then
        return './' .. base
      end
    end,
    test    = nil,
    clean   = function(p) return 'rm -f ' .. vim.fn.fnamemodify(p.file, ':t:r') end,
    fmt     = nil,
    lint    = nil,
    install = nil,
    package = nil,
  },
}

function M.get_command(action, project)
  local b = B[project.type]; if not b then return nil end
  local v = b[action]
  return type(v) == 'function' and v(project) or v
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function proj()
  local p = require('jason.detector').get_project()
  if not p then vim.notify('No project detected', vim.log.levels.ERROR) end
  return p
end

local function tcfg() return require('jason').config.terminal end

local function base_opts(p, title, action_id, extra_args)
  return {
    cwd       = p.root,
    title     = title,
    term_cfg  = tcfg(),
    plugin    = 'jason',
    action_id = action_id,
    args      = extra_args ~= '' and extra_args or nil,
  }
end

local function run_action(action, title, action_id, p, prompt_args)
  local cmd = M.get_command(action, p)
  if not cmd then
    vim.notify(action .. ' not supported for ' .. p.type, vim.log.levels.WARN); return
  end
  if prompt_args then
    local saved = M.get_args(p.root, action)
    vim.ui.input({ prompt = title .. ' args: ', default = saved }, function(args)
      if args == nil then return end
      M.set_args(p.root, action, args)
      require('core.runner').execute(vim.tbl_extend('force',
        base_opts(p, title, action_id, args), { cmd = cmd }))
    end)
  else
    require('core.runner').execute(vim.tbl_extend('force',
      base_opts(p, title, action_id, ''), { cmd = cmd }))
  end
end

-- ── Public API ────────────────────────────────────────────────────────────────
function M.build(prompt_args)
  local p = proj(); if not p then return end
  if not require('jason.detector').validate_environment(p.type) then return end
  run_action('build', 'Build', 'build', p, prompt_args)
end

function M.run(prompt_args)
  local p = proj(); if not p then return end
  run_action('run', 'Run', 'run', p, prompt_args)
end

function M.test(filter)
  local p = proj(); if not p then return end
  if filter then
    -- Prompt for test filter
    vim.ui.input({ prompt = 'Test filter: ', default = M.get_args(p.root, 'test') }, function(f)
      if f == nil then return end
      M.set_args(p.root, 'test', f)
      local cmd = M.get_test_cmd_filtered(p, f)
      require('core.runner').execute(vim.tbl_extend('force',
        base_opts(p, 'Test: ' .. f, 'test', ''), { cmd = cmd }))
    end)
  else
    run_action('test', 'Test', 'test', p, false)
  end
end

function M.clean()
  local p = proj(); if not p then return end
  run_action('clean', 'Clean', 'clean', p, false)
end

function M.fmt()
  local p = proj(); if not p then return end
  run_action('fmt', 'Format', 'fmt', p, false)
end

function M.lint()
  local p = proj(); if not p then return end
  run_action('lint', 'Lint', 'lint', p, false)
end

function M.install()
  local p = proj(); if not p then return end
  run_action('install', 'Install', 'install', p, false)
end

function M.package()
  local p = proj(); if not p then return end
  run_action('package', 'Package', 'package', p, false)
end

function M.build_and_run(prompt_args)
  local p = proj(); if not p then return end
  local bc = M.get_command('build', p)
  local rc = M.get_command('run', p)
  if not bc or not rc then
    vim.notify('Build & Run not fully supported for ' .. p.type, vim.log.levels.WARN); return
  end
  local run_args = prompt_args and M.get_args(p.root, 'run') or ''
  require('core.runner').execute_sequence(
    { { cmd = bc, title = 'Build' }, { cmd = rc .. (run_args ~= '' and ' ' .. run_args or ''), title = 'Run' } },
    base_opts(p, 'Build & Run', 'build_run', ''))
end

function M.custom(cmd, title)
  local p = proj(); if not p then return end
  require('core.runner').execute(vim.tbl_extend('force',
    base_opts(p, title or cmd, cmd, ''), { cmd = cmd }))
end

-- Backwards-compat shims for graalvm.lua
function M.execute(cmd, cwd, title)
  require('core.runner').execute({
    cmd = cmd,
    cwd = cwd,
    title = title or cmd,
    term_cfg = tcfg(),
    plugin = 'jason'
  })
end

function M.execute_sequence(steps, cwd)
  require('core.runner').execute_sequence(steps, { cwd = cwd, term_cfg = tcfg(), plugin = 'jason' })
end

function M.stop() require('core.runner').stop_last() end

-- ── Test filter command builders ──────────────────────────────────────────────
function M.get_test_cmd_filtered(project, filter)
  local t = project.type
  if t == 'cargo' then
    return 'cargo test ' .. filter
  elseif t == 'go_mod' then
    return 'go test ./... -run ' .. filter
  elseif t == 'maven' then
    return 'mvn test -Dtest=' .. filter
  elseif t == 'gradle' then
    return './gradlew test --tests ' .. filter
  elseif t == 'makefile' or t == 'cmake' then
    return 'ctest -R ' .. filter
  else
    return M.get_command('test', project)
  end
end

-- ── Project helpers ───────────────────────────────────────────────────────────
function M.find_main_class(project)
  local files = vim.fn.globpath(project.root .. '/src/main/java', '**/*.java', false, true)
  for _, file in ipairs(files) do
    local pkg, cls, has_main
    for _, line in ipairs(vim.fn.readfile(file)) do
      if line:match('^%s*package%s+') then pkg = line:match('package%s+([%w%.]+)') end
      if line:match('public%s+class%s+') then cls = line:match('class%s+(%w+)') end
      if line:match('public%s+static%s+void%s+main') then has_main = true end
      if pkg and cls and has_main then return pkg .. '.' .. cls end
    end
  end
  return 'Main'
end

function M.find_cmake_executable(p)
  local bd = p.root .. '/build'
  if vim.fn.isdirectory(bd) == 0 then return nil end
  local h = io.popen('find "' .. bd .. '" -type f -executable 2>/dev/null | head -1')
  if h then
    local e = h:read('*l'); h:close(); return e
  end
end

function M.find_makefile_executable(p)
  for _, n in ipairs({ 'main', 'app', 'program', 'a.out' }) do
    if vim.fn.executable(p.root .. '/' .. n) == 1 then return './' .. n end
  end
end

return M
