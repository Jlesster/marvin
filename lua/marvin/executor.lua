-- lua/marvin/executor.lua
-- Marvin side: Maven execution via  M.run(goal, options).
-- Jason side:  Multi-language build actions live in  marvin.build  (separate
--              module below).  This file re-exports a backwards-compat shim
--              so any code that did  require('jason.executor')  can be pointed
--              at  require('marvin.build')  instead.

local M = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- MARVIN — Maven executor
-- ══════════════════════════════════════════════════════════════════════════════

function M.run(goal, options)
  options = options or {}

  local project = require('marvin.project')
  if not project.validate_environment() then return end
  local proj = project.get()
  if not proj then
    vim.notify('No Maven project found', vim.log.levels.ERROR); return
  end

  local parts  = { require('marvin').get_mvn_cmd() }
  if options.profile then parts[#parts + 1] = '-P' .. options.profile end
  parts[#parts + 1] = goal
  local cmd = table.concat(parts, ' ')

  require('core.runner').execute({
    cmd       = cmd,
    cwd       = proj.root,
    title     = 'mvn ' .. goal,
    term_cfg  = config.terminal,
    plugin    = 'marvin',
    action_id = 'mvn_' .. goal:gsub('%s+', '_'),
  })
end

function M.stop() require('core.runner').stop_last() end

return M
