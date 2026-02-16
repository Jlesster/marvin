local M = {}

function M.register()
  vim.api.nvim_create_user_command('Maven', function(opts)
    M.interactive_menu()
  end, {
    desc = 'Open Maven Menu',
  })

  vim.api.nvim_create_user_command('MavenDashboard', function()
    require('marvin.dashboard').show()
  end, {
    desc = 'Open Marvin Dashboard',
  })

  vim.api.nvim_create_user_command('MavenExec', function(opts)
    M.execute_goal(opts.args)
  end, {
    nargs = '+',
    complete = M.complete_goals,
    desc = 'Execute Maven Goal',
  })

  vim.api.nvim_create_user_command('MavenClean', function()
    M.execute_goal('clean')
  end, { desc = 'Run mvn clean' })

  vim.api.nvim_create_user_command('MavenTest', function()
    M.execute_goal('test')
  end, { desc = 'Run mvn test' })

  vim.api.nvim_create_user_command('MavenPackage', function()
    M.execute_goal('package')
  end, { desc = 'Run mvn package' })

  -- Project generation
  vim.api.nvim_create_user_command('MavenNew', function()
    local generator = require('marvin.generator')
    generator.create_project()
  end, { desc = 'Create new Maven project' })
end

function M.interactive_menu()
  local ui = require('marvin.ui')
  ui.show_goal_menu()
end

function M.execute_goal(goal)
  local executor = require('marvin.executor') -- FIXED: Added quotes
  executor.run(goal)
end

function M.complete_goals(arg_lead, cmd_line, cursor_pos)
  return {
    'clean',
    'compile', -- FIXED: Was 'complile'
    'test',
    'test-compile',
    'package',
    'install',
    'deploy',
    'site',
    'verify',
    'dependency:tree',
    'dependency:list',
    'dependency:resolve',
  }
end

return M
