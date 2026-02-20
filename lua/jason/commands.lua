-- lua/jason/commands.lua
local M = {}

function M.register()
  vim.api.nvim_create_user_command('JasonBuild', function()
    require('jason.executor').build()
  end, { desc = 'Build current project' })

  vim.api.nvim_create_user_command('JasonRun', function()
    require('jason.executor').run()
  end, { desc = 'Run current project' })

  vim.api.nvim_create_user_command('JasonTest', function()
    require('jason.executor').test()
  end, { desc = 'Test current project' })

  vim.api.nvim_create_user_command('JasonClean', function()
    require('jason.executor').clean()
  end, { desc = 'Clean build artifacts' })

  vim.api.nvim_create_user_command('JasonDashboard', function()
    require('jason.dashboard').show()
  end, { desc = 'Open Jason Dashboard' })

  vim.api.nvim_create_user_command('JasonConfig', function()
    require('jason.configurator').show()
  end, { desc = 'Configure project settings' })

  -- Shorter aliases
  vim.api.nvim_create_user_command('Jason', function()
    require('jason.dashboard').show()
  end, { desc = 'Open Jason Dashboard' })
end

return M
