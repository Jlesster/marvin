-- lua/marvin/commands.lua
-- All user commands for Marvin (project manager) and Jason (task runner).

local M = {}

function M.register()
  local function cmd(name, fn, opts)
    vim.api.nvim_create_user_command(name, fn, opts or {})
  end

  -- ════════════════════════════════════════════════════════════════════════════
  -- MARVIN — Project management
  -- ════════════════════════════════════════════════════════════════════════════

  -- Main dashboard
  cmd('Marvin', function() require('marvin.dashboard').show() end,
    { desc = 'Open Marvin project dashboard' })
  cmd('MarvinDashboard', function() require('marvin.dashboard').show() end,
    { desc = 'Open Marvin project dashboard' })

  -- Project info
  cmd('MarvinInfo', function()
    local p = require('marvin.detector').get()
    if not p then
      vim.notify('[Marvin] No project detected', vim.log.levels.WARN); return
    end
    local info = p.info or {}
    local lines = {
      'Project : ' .. (p.name or '?'),
      'Type    : ' .. p.type,
      'Lang    : ' .. p.lang,
      'Root    : ' .. p.root,
    }
    for k, v in pairs(info) do
      if type(v) == 'string' or type(v) == 'number' or type(v) == 'boolean' then
        lines[#lines + 1] = string.format('%-8s: %s', k, tostring(v))
      end
    end
    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
  end, { desc = 'Show current project info' })

  -- Project reload
  cmd('MarvinReload', function()
    require('marvin.detector').reload()
    vim.notify('[Marvin] Project reloaded', vim.log.levels.INFO)
  end, { desc = 'Re-parse project manifest' })

  -- Switch project (monorepo)
  cmd('MarvinSwitch', function()
    require('marvin.dashboard').show_project_picker()
  end, { desc = 'Switch active sub-project' })

  -- ── Java / Maven ────────────────────────────────────────────────────────────
  cmd('JavaNew', function()
    require('marvin.creator.java').show_menu(function()
      require('marvin.dashboard').show()
    end)
  end, { desc = 'New Java file (class/interface/record/enum…)' })

  cmd('MavenNew', function()
    local ok, gen = pcall(require, 'marvin.generator')
    if ok then gen.create_project() end
  end, { desc = 'New Maven project from archetype' })

  -- Direct Maven goal
  cmd('Maven', function(args)
    local goal = args.args
    if goal == '' then
      vim.notify('[Marvin] Usage: :Maven <goal>', vim.log.levels.WARN); return
    end
    require('marvin.executor').run(goal)
  end, { nargs = '+', desc = 'Run Maven goal' })

  -- Common Maven shortcuts
  for _, spec in ipairs({
    { 'MavenCompile', 'compile', 'mvn compile' },
    { 'MavenTest',    'test',    'mvn test' },
    { 'MavenPackage', 'package', 'mvn package' },
    { 'MavenInstall', 'install', 'mvn install' },
    { 'MavenClean',   'clean',   'mvn clean' },
    { 'MavenVerify',  'verify',  'mvn verify' },
    { 'MavenDeploy',  'deploy',  'mvn deploy' },
  }) do
    local name, goal = spec[1], spec[2]
    cmd(name, function() require('marvin.executor').run(goal) end,
      { desc = spec[3] })
  end

  cmd('MavenStop', function()
    local ok, runner = pcall(require, 'core.runner')
    if ok then runner.stop_all() end
  end, { desc = 'Stop running Maven process' })

  -- ── Rust / Cargo ────────────────────────────────────────────────────────────
  cmd('RustNew', function()
    require('marvin.creator.rust').create_crate()
  end, { desc = 'New Cargo crate (bin or lib)' })

  -- ── Go ───────────────────────────────────────────────────────────────────────
  cmd('GoNew', function()
    local p = require('marvin.detector').get()
    if not p or p.type ~= 'go_mod' then
      vim.notify('[Marvin] Not in a Go project', vim.log.levels.WARN); return
    end
    require('marvin.dashboard').show()
  end, { desc = 'Open Go creation menu' })

  -- ── C / C++ ──────────────────────────────────────────────────────────────────
  cmd('CppNew', function()
    local p = require('marvin.detector').get()
    if not p or (p.type ~= 'cmake' and p.type ~= 'makefile' and p.type ~= 'single_file') then
      vim.notify('[Marvin] Not in a C/C++ project', vim.log.levels.WARN); return
    end
    require('marvin.creator.cpp').handle(
      nil,  -- id = nil → show menu
      function() require('marvin.dashboard').show() end
    )
  end, { desc = 'New C/C++ file (class/struct/enum/test…)' })

  -- ── File creation ────────────────────────────────────────────────────────────
  cmd('MarvinNewMakefile', function()
    require('marvin.makefile_creator').create(vim.fn.getcwd())
  end, { desc = 'Create a Makefile from template' })

  -- ════════════════════════════════════════════════════════════════════════════
  -- JASON — Task runner
  -- ════════════════════════════════════════════════════════════════════════════

  cmd('Jason', function()
    require('marvin.jason_dashboard').show()
  end, { desc = 'Open Jason task runner dashboard' })
  cmd('JasonDashboard', function()
    require('marvin.jason_dashboard').show()
  end, { desc = 'Open Jason task runner dashboard' })

  -- Core build actions
  local bld = function() return require('marvin.build') end
  cmd('JasonBuild', function() bld().build() end, { desc = 'Jason: Build project' })
  cmd('JasonRun', function() bld().run() end, { desc = 'Jason: Run project' })
  cmd('JasonTest', function() bld().test() end, { desc = 'Jason: Run tests' })
  cmd('JasonClean', function() bld().clean() end, { desc = 'Jason: Clean' })
  cmd('JasonPackage', function() bld().package() end, { desc = 'Jason: Package' })
  cmd('JasonInstall', function() bld().install() end, { desc = 'Jason: Install' })
  cmd('JasonFmt', function() bld().fmt() end, { desc = 'Jason: Format' })
  cmd('JasonLint', function() bld().lint() end, { desc = 'Jason: Lint' })
  cmd('JasonBuildRun', function() bld().build_and_run() end, { desc = 'Jason: Build then run' })

  -- With prompts
  cmd('JasonBuildArgs', function() bld().build(true) end, { desc = 'Jason: Build with args' })
  cmd('JasonRunArgs', function() bld().run(true) end, { desc = 'Jason: Run with args' })
  cmd('JasonTestFilter', function() bld().test(true) end, { desc = 'Jason: Test with filter' })

  -- Exec arbitrary command in project root
  cmd('JasonExec', function(args)
    if args.args == '' then
      vim.notify('[Jason] Usage: :JasonExec <command>', vim.log.levels.WARN); return
    end
    bld().custom(args.args, args.args)
  end, { nargs = '+', desc = 'Jason: Run arbitrary command' })

  -- Console
  cmd('JasonConsole', function()
    require('marvin.console').toggle()
  end, { desc = 'Jason: Toggle task console' })
  cmd('JasonHistory', function()
    require('marvin.console').open()
  end, { desc = 'Jason: Open task history' })

  -- Stop
  cmd('JasonStop', function()
    local ok, runner = pcall(require, 'core.runner')
    if ok then runner.stop() end
  end, { desc = 'Jason: Stop current task' })
  cmd('JasonStopAll', function()
    local ok, runner = pcall(require, 'core.runner')
    if ok then runner.stop_all() end
  end, { desc = 'Jason: Stop all tasks' })

  -- Sub-project switch
  cmd('JasonSwitch', function()
    require('marvin.dashboard').show_project_picker()
  end, { desc = 'Jason: Switch sub-project' })

  -- Makefile
  cmd('JasonNewMakefile', function()
    require('marvin.makefile_creator').create(vim.fn.getcwd())
  end, { desc = 'Create a Makefile from template' })

  -- GraalVM
  cmd('GraalBuild', function()
    local p = require('marvin.detector').get()
    require('marvin.graalvm').build_native(p)
  end, { desc = 'GraalVM: Build native image' })
  cmd('GraalRun', function()
    local p = require('marvin.detector').get()
    require('marvin.graalvm').run_native(p)
  end, { desc = 'GraalVM: Run native binary' })
  cmd('GraalInfo', function()
    require('marvin.graalvm').show_info()
  end, { desc = 'GraalVM: Show status / install info' })
end

return M
