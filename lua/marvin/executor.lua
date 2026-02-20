-- lua/marvin/executor.lua
-- Delegates to core.runner. Keeps the same public API.

local M = {}

function M.run(goal, options)
  options = options or {}

  local project = require('marvin.project')
  if not project.validate_environment() then return end

  local proj = project.get_project()
  if not proj then
    vim.notify('No Maven project found', vim.log.levels.ERROR); return
  end

  local config = require('marvin').config
  local parts  = { config.maven_command }
  if options.profile then
    parts[#parts + 1] = '-P' .. options.profile
  end
  parts[#parts + 1] = goal
  local cmd = table.concat(parts, ' ')

  require('core.runner').execute({
    cmd       = cmd,
    cwd       = proj.root,
    title     = 'mvn ' .. goal,
    term_cfg  = config.terminal,
    plugin    = 'marvin',
    action_id = 'mvn_' .. goal,
  })
end

-- Stop the last running job (same behaviour as before)
function M.stop()
  require('core.runner').stop_last()
end

return M
