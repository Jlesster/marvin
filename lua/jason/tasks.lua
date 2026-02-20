-- lua/jason/tasks.lua
-- .jason.lua task definitions: loading, menu building, execution, watch mode.

local M     = {}
M._cache    = {} -- root -> { tasks, mtime }
M._watchers = {} -- action_id -> true

-- ── File loading ──────────────────────────────────────────────────────────────
local function mtime(path)
  local s = vim.loop.fs_stat(path); return s and s.mtime.sec or 0
end

function M.load(root)
  if not root then return {} end
  local path = root .. '/.jason.lua'
  if vim.fn.filereadable(path) == 0 then return {} end
  local mt = mtime(path)
  local c  = M._cache[root]
  if c and c.mtime == mt then return c.tasks end
  local ok, result = pcall(dofile, path)
  if not ok or type(result) ~= 'table' then
    vim.notify('[jason] .jason.lua error: ' .. tostring(result), vim.log.levels.WARN)
    return {}
  end
  local tasks = result.tasks or {}
  M._cache[root] = { tasks = tasks, mtime = mt }
  return tasks
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.to_menu_items(tasks)
  local items = {}
  for _, t in ipairs(tasks) do
    local watching = M._watchers['__task__' .. t.name]
    items[#items + 1] = {
      id    = '__task__' .. t.name,
      icon  = watching and '󰓛' or (t.restart and '󰑖' or '󰐊'),
      label = t.name,
      desc  = t.desc or t.cmd,
      badge = watching and 'watching' or (t.restart and 'watch' or nil),
      _task = t,
    }
  end
  return items
end

-- ── Execution ─────────────────────────────────────────────────────────────────
function M.run(task_def, project, term_cfg)
  term_cfg     = term_cfg or require('jason').config.terminal
  local runner = require('core.runner')
  local id     = '__task__' .. task_def.name
  local title  = task_def.title or task_def.name
  local cwd    = task_def.cwd and (project.root .. '/' .. task_def.cwd) or project.root

  -- Build env-prefixed cmd
  local cmd    = task_def.cmd
  if task_def.env then
    local parts = {}
    for k, v in pairs(task_def.env) do
      parts[#parts + 1] = k .. '=' .. vim.fn.shellescape(tostring(v))
    end
    cmd = table.concat(parts, ' ') .. ' ' .. cmd
  end

  -- Resolve depends
  if task_def.depends and #task_def.depends > 0 then
    local all   = M.load(project.root)
    local steps = {}
    for _, dep in ipairs(task_def.depends) do
      for _, t in ipairs(all) do
        if t.name == dep then
          steps[#steps + 1] = { cmd = t.cmd, title = t.title or t.name }
          break
        end
      end
    end
    steps[#steps + 1] = { cmd = cmd, title = title }
    runner.execute_sequence(steps, {
      cwd = cwd, term_cfg = term_cfg, plugin = 'jason', action_id = id })
    return
  end

  if task_def.restart then
    M._start_watch(id, cmd, cwd, title, term_cfg)
  else
    runner.execute({
      cmd = cmd,
      cwd = cwd,
      title = title,
      term_cfg = term_cfg,
      plugin = 'jason',
      action_id = id
    })
  end
end

function M._start_watch(id, cmd, cwd, title, term_cfg)
  M._watchers[id] = true
  require('core.runner').execute_watch({
    cmd       = cmd,
    cwd       = cwd,
    title     = '󰑖 ' .. title,
    term_cfg  = term_cfg,
    plugin    = 'jason',
    action_id = id,
  })
end

function M.stop_watch(id)
  M._watchers[id] = nil
  require('core.runner').stop_watch(id)
  vim.notify('[jason] Watch stopped: ' .. id:sub(9), vim.log.levels.INFO)
end

-- ── handle_action (called from dashboard) ────────────────────────────────────
-- Returns true if handled.
function M.handle_action(id, project)
  if not id or not id:match('^__task__') then return false end
  local name  = id:sub(9)
  local tasks = M.load(project.root)
  for _, t in ipairs(tasks) do
    if t.name == name then
      if t.restart and M._watchers[id] then
        M.stop_watch(id)
      else
        M.run(t, project)
      end
      return true
    end
  end
  return false
end

return M
