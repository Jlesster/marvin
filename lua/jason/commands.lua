-- lua/jason/commands.lua

local M = {}

function M.register()
  local function cmd(name, fn, opts)
    vim.api.nvim_create_user_command(name, fn, opts or {})
  end

  -- Dashboard
  cmd('Jason', function() require('jason.dashboard').show() end, { desc = 'Open Jason dashboard' })
  cmd('JasonDashboard', function() require('jason.dashboard').show() end, { desc = 'Open Jason dashboard' })

  -- Core actions
  cmd('JasonBuild', function() require('jason.executor').build() end, { desc = 'Build project' })
  cmd('JasonRun', function() require('jason.executor').run() end, { desc = 'Run project' })
  cmd('JasonTest', function() require('jason.executor').test() end, { desc = 'Test project' })
  cmd('JasonClean', function() require('jason.executor').clean() end, { desc = 'Clean build artifacts' })
  cmd('JasonPackage', function() require('jason.executor').package() end, { desc = 'Package project' })
  cmd('JasonInstall', function() require('jason.executor').install() end, { desc = 'Install project' })
  cmd('JasonFmt', function() require('jason.executor').fmt() end, { desc = 'Format source files' })
  cmd('JasonLint', function() require('jason.executor').lint() end, { desc = 'Lint source files' })

  -- With args
  cmd('JasonBuildArgs', function() require('jason.executor').build(true) end, { desc = 'Build with args prompt' })
  cmd('JasonRunArgs', function() require('jason.executor').run(true) end, { desc = 'Run with args prompt' })
  cmd('JasonTestFilter', function() require('jason.executor').test(true) end, { desc = 'Test with filter prompt' })

  -- Build & run
  cmd('JasonBuildRun', function() require('jason.executor').build_and_run() end, { desc = 'Build then run' })

  -- Arbitrary command in project context
  cmd('JasonExec', function(o)
    require('jason.executor').custom(o.args)
  end, { nargs = '+', desc = 'Run command in project root' })

  -- Config
  cmd('JasonConfig', function() require('jason.configurator').show() end, { desc = 'Configure project settings' })

  -- Job control
  cmd('JasonStop', function() require('core.runner').stop_last() end, { desc = 'Stop last job' })
  cmd('JasonStopAll', function() require('core.runner').stop_all() end, { desc = 'Stop all jobs' })

  -- History / output
  cmd('JasonHistory', function()
    require('jason.dashboard').show_history(require('jason.detector').get_project())
  end, { desc = 'Show run history' })

  -- Sub-project switcher
  cmd('JasonSwitch', function()
    require('jason.dashboard').show_project_picker()
  end, { desc = 'Switch sub-project (monorepo)' })
end

return M
