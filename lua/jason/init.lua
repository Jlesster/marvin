-- lua/jason/init.lua

local M = {}
M.config = {}

function M.setup(opts)
  M.config = require('jason.config').setup(opts)
  require('jason.commands').register()
  require('jason.keymaps').setup(M.config)
  require('jason.ui').init()
  M._setup_autocommands()
end

function M._setup_autocommands()
  local pat = { 'java', 'rust', 'go', 'c', 'cpp' }

  -- Detect project once per filetype entry
  vim.api.nvim_create_autocmd('FileType', {
    pattern  = pat,
    callback = function() require('jason.detector').detect() end,
  })

  -- Apply makeprg / errorformat (replaces compiler.nvim)
  vim.api.nvim_create_autocmd({ 'BufEnter', 'FileType' }, {
    pattern  = pat,
    callback = function()
      vim.defer_fn(function() require('jason.compiler').setup_buf() end, 0)
    end,
  })
end

return M
