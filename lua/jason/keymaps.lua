-- lua/jason/keymaps.lua
local M = {}

function M.setup(config)
  local keymaps = config.keymaps or {}

  if vim.tbl_count(keymaps) == 0 then
    return
  end

  if keymaps.dashboard then
    vim.keymap.set('n', keymaps.dashboard, function()
      require('jason.dashboard').show()
    end, {
      desc = 'Open Jason Dashboard',
      silent = true,
    })
  end

  if keymaps.build then
    vim.keymap.set('n', keymaps.build, function()
      require('jason.executor').build()
    end, {
      desc = 'Build project',
      silent = true,
    })
  end

  if keymaps.run then
    vim.keymap.set('n', keymaps.run, function()
      require('jason.executor').run()
    end, {
      desc = 'Run project',
      silent = true,
    })
  end

  if keymaps.test then
    vim.keymap.set('n', keymaps.test, function()
      require('jason.executor').test()
    end, {
      desc = 'Run tests',
      silent = true,
    })
  end

  if keymaps.clean then
    vim.keymap.set('n', keymaps.clean, function()
      require('jason.executor').clean()
    end, {
      desc = 'Clean build artifacts',
      silent = true,
    })
  end
end

return M
