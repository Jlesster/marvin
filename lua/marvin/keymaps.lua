local M = {}

function M.setup(config)
  local keymaps = config.keymaps or {}

  -- Only set up keymaps if the table is not empty
  if vim.tbl_count(keymaps) == 0 then
    return
  end

  if keymaps.run_goal then
    vim.keymap.set('n', keymaps.run_goal, ':Maven<CR>', {
      desc = 'Open Maven goal menu',
      silent = true,
    })
  end

  if keymaps.clean then
    vim.keymap.set('n', keymaps.clean, ':MavenClean<CR>', {
      desc = 'Run mvn clean',
      silent = true,
    })
  end

  if keymaps.test then
    vim.keymap.set('n', keymaps.test, ':MavenTest<CR>', {
      desc = 'Run mvn test',
      silent = true,
    })
  end

  if keymaps.package then
    vim.keymap.set('n', keymaps.package, ':MavenPackage<CR>', {
      desc = 'Run mvn package',
      silent = true,
    })
  end

  if keymaps.install then
    vim.keymap.set('n', keymaps.install, ':MavenExec install<CR>', {
      desc = 'Run mvn install',
      silent = true,
    })
  end

  if keymaps.new_project then
    vim.keymap.set('n', keymaps.new_project, ':MavenNew<CR>', {
      desc = 'Create new Maven project',
      silent = true,
    })
  end

  if keymaps.dashboard then
    vim.keymap.set('n', keymaps.dashboard, ':MavenDashboard<CR>', {
      desc = 'Open Marvin dashboard',
      silent = true,
    })
  end
end

return M
