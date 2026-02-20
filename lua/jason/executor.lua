-- lua/jason/executor.lua
-- Thin wrapper around core.runner. Keeps the same public API so nothing
-- in dashboard.lua or commands.lua needs to change.

local M = {}

-- ── Command builders (unchanged from original) ────────────────────────────────
local builders = {
  maven = {
    build = 'mvn compile',
    run   = function(p) return 'mvn exec:java -Dexec.mainClass=' .. M.find_main_class(p) end,
    test  = 'mvn test',
    clean = 'mvn clean',
  },
  gradle = {
    build = './gradlew build',
    run   = './gradlew run',
    test  = './gradlew test',
    clean = './gradlew clean',
  },
  cargo = {
    build = function()
      local p = require('jason').config.rust.profile
      return p == 'release' and 'cargo build --release' or 'cargo build'
    end,
    run   = function()
      local p = require('jason').config.rust.profile
      return p == 'release' and 'cargo run --release' or 'cargo run'
    end,
    test  = 'cargo test',
    clean = 'cargo clean',
  },
  go_mod = {
    build = 'go build .',
    run   = 'go run .',
    test  = 'go test ./...',
    clean = 'go clean',
  },
  cmake = {
    build = 'cmake --build build',
    run   = function(p) return M.find_cmake_executable(p) or './build/main' end,
    test  = 'ctest --test-dir build',
    clean = 'rm -rf build',
  },
  makefile = {
    build = 'make',
    run   = function(p) return M.find_makefile_executable(p) or './main' end,
    test  = 'make test',
    clean = 'make clean',
  },
  single_file = {
    build = function(p)
      local ft, file = p.language, p.file
      local base = vim.fn.fnamemodify(file, ':t:r')
      if ft == 'java' then
        return 'javac ' .. file
      elseif ft == 'rust' then
        return 'rustc ' .. file
      elseif ft == 'go' then
        return 'go build ' .. file
      elseif ft == 'cpp' then
        local cfg = require('jason').config
        return string.format('%s -std=%s %s -o %s', cfg.cpp.compiler, cfg.cpp.standard, file, base)
      elseif ft == 'c' then
        return 'gcc ' .. file .. ' -o ' .. base
      end
    end,
    run   = function(p)
      local ft, file = p.language, p.file
      local base = vim.fn.fnamemodify(file, ':t:r')
      if ft == 'java' then
        return 'java ' .. base
      elseif ft == 'rust' then
        return './' .. base
      elseif ft == 'go' then
        return 'go run ' .. file
      elseif ft == 'cpp' or ft == 'c' then
        return './' .. base
      end
    end,
    test  = nil,
    clean = function(p) return 'rm -f ' .. vim.fn.fnamemodify(p.file, ':t:r') end,
  },
}

-- ── Helpers ───────────────────────────────────────────────────────────────────
function M.get_command(action, project)
  local b = builders[project.type]
  if not b then return nil end
  local cmd = b[action]
  return type(cmd) == 'function' and cmd(project) or cmd
end

local function get_project()
  local p = require('jason.detector').get_project()
  if not p then vim.notify('No project detected', vim.log.levels.ERROR) end
  return p
end

local function term_cfg()
  return require('jason').config.terminal
end

local function runner_opts(project, title, action_id)
  return {
    cwd       = project.root,
    title     = title,
    term_cfg  = term_cfg(),
    plugin    = 'jason',
    action_id = action_id,
  }
end

-- ── Public API (mirrors original) ────────────────────────────────────────────
function M.build()
  local p = get_project(); if not p then return end
  if not require('jason.detector').validate_environment(p.type) then return end
  local cmd = M.get_command('build', p)
  if not cmd then
    vim.notify('Build not supported for ' .. p.type, vim.log.levels.WARN); return
  end
  require('core.runner').execute(vim.tbl_extend('force', runner_opts(p, 'Build', 'build'), { cmd = cmd }))
end

function M.run()
  local p = get_project(); if not p then return end
  local cmd = M.get_command('run', p)
  if not cmd then
    vim.notify('Run not supported for ' .. p.type, vim.log.levels.WARN); return
  end
  require('core.runner').execute(vim.tbl_extend('force', runner_opts(p, 'Run', 'run'), { cmd = cmd }))
end

function M.build_and_run()
  local p = get_project(); if not p then return end
  local bc = M.get_command('build', p)
  local rc = M.get_command('run', p)
  if not bc or not rc then
    vim.notify('Build & Run not fully supported', vim.log.levels.WARN); return
  end
  require('core.runner').execute_sequence(
    { { cmd = bc, title = 'Build' }, { cmd = rc, title = 'Run' } },
    runner_opts(p, 'Build & Run', 'build_run'))
end

function M.test()
  local p = get_project(); if not p then return end
  local cmd = M.get_command('test', p)
  if not cmd then
    vim.notify('Tests not supported for ' .. p.type, vim.log.levels.WARN); return
  end
  require('core.runner').execute(vim.tbl_extend('force', runner_opts(p, 'Test', 'test'), { cmd = cmd }))
end

function M.clean()
  local p = get_project(); if not p then return end
  local cmd = M.get_command('clean', p)
  if not cmd then
    vim.notify('Clean not supported for ' .. p.type, vim.log.levels.WARN); return
  end
  require('core.runner').execute(vim.tbl_extend('force', runner_opts(p, 'Clean', 'clean'), { cmd = cmd }))
end

function M.custom(cmd)
  local p = get_project(); if not p then return end
  require('core.runner').execute(vim.tbl_extend('force', runner_opts(p, 'Custom', cmd), { cmd = cmd }))
end

-- execute / execute_sequence kept for graalvm.lua + dashboard sequences
function M.execute(cmd, cwd, title)
  require('core.runner').execute({
    cmd = cmd,
    cwd = cwd,
    title = title,
    term_cfg = term_cfg(),
    plugin = 'jason'
  })
end

function M.execute_sequence(steps, cwd)
  require('core.runner').execute_sequence(steps,
    { cwd = cwd, term_cfg = term_cfg(), plugin = 'jason' })
end

function M.stop()
  require('core.runner').stop_last()
end

-- ── Project helpers (unchanged) ───────────────────────────────────────────────
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

function M.find_cmake_executable(project)
  local bd = project.root .. '/build'
  if vim.fn.isdirectory(bd) == 0 then return nil end
  local h = io.popen('find "' .. bd .. '" -type f -executable 2>/dev/null | head -1')
  if h then
    local e = h:read('*l'); h:close(); return e
  end
end

function M.find_makefile_executable(project)
  for _, n in ipairs({ 'main', 'app', 'program', 'a.out' }) do
    local p = project.root .. '/' .. n
    if vim.fn.executable(p) == 1 then return './' .. n end
  end
end

return M
