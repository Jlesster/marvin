local M = {}

M.config = {}

function M.setup(opts)
  local config = require('marvin.config')
  M.config = config.setup(opts)

  local commands = require('marvin.commands')
  commands.register()

  -- Setup keymaps
  local keymaps = require('marvin.keymaps')
  keymaps.setup(M.config)

  M.setup_autocommands()

  local ui = require('marvin.ui')
  ui.init()
end

function M.setup_autocommands()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'java', 'kotlin', 'xml' },
    callback = function()
      local project = require('marvin.project')
      project.detect()
    end,
  })
end

return M
