-- lua/jason/init.lua
local M = {}

M.config = {}

function M.setup(opts)
  M.config = require('jason.config').setup(opts)

  require('jason.commands').register()
  require('jason.keymaps').setup(M.config)

  M.setup_autocommands()

  require('jason.ui').init()

  -- Register history listener so dashboard history always reflects both plugins
  local runner = require('core.runner')
  -- (nothing extra needed – dashboard reads runner.history directly)
end

function M.setup_autocommands()
  local ft_pattern = { 'java', 'rust', 'go', 'c', 'cpp' }

  -- Detect project on filetype load
  vim.api.nvim_create_autocmd('FileType', {
    pattern  = ft_pattern,
    callback = function()
      require('jason.detector').detect()
    end,
  })

  -- Apply compiler settings (makeprg / errorformat) on BufEnter
  -- This is what replaces compiler.nvim
  vim.api.nvim_create_autocmd({ 'BufEnter', 'FileType' }, {
    pattern  = ft_pattern,
    callback = function()
      -- Small defer so detector has run first
      vim.defer_fn(function()
        require('jason.compiler').setup_buf()
      end, 0)
    end,
  })
end

return M
