local M = {}

M.defaults = {
  maven_command = 'mvn',
  ui_backend = 'auto',
  terminal = {
    position = 'float',
    size = 0.4,
    close_on_success = false,
  },
  quickfix = {
    auto_open = true,
    height = 10,
  },

  keymaps = {
    run_goal = '<leader>Mg',
    clean = '<leader>Mc',
    test = '<leader>Mt',
    package = '<leader>Mp',
    install = '<leader>Mi',
  },

  archetypes = {
    'maven-archetype-quickstart',
    'maven-archetype-my-custom-archetype',
    'maven-archetype-simple',
  },
}

function M.setup(opts)
  return vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M
