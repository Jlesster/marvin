-- lua/jason/tasks.lua
-- Loads .jason.lua task definitions from the project root and integrates
-- them into Jason's dashboard and executor. Replaces overseer task configs.

local M = {}

M._cache = {} -- root -> { tasks, mtime }

-- ── Schema ────────────────────────────────────────────────────────────────────
-- A task definition (what users write in .jason.lua):
--
-- {
--   name    = "dev",               -- required, shown in dashboard
--   cmd     = "cargo run -- -w",   -- required
--   title   = "Dev Server",        -- optional, shown in terminal title bar
--   cwd     = ".",                 -- optional, relative to project root
--   restart = false,               -- if true, re-run on exit (watch mode)
--   env     = { PORT = "3000" },   -- optional env vars
--   depends = { "build" },         -- run these task names first in sequence
--   desc    = "Start dev server",  -- shown in dashboard description
-- }

local function mtime(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.mtime.sec or 0
end

-- ── Load / cache ──────────────────────────────────────────────────────────────
function M.load(root)
  local path = root .. '/.jason.lua'
  if vim.fn.filereadable(path) == 0 then return {} end

  local mt = mtime(path)
  local cached = M._cache[root]
  if cached and cached.mtime == mt then return cached.tasks end

  local ok, result = pcall(dofile, path)
  if not ok or type(result) ~= 'table' then
    vim.notify('[jason] Error in .jason.lua: ' .. tostring(result), vim.log.levels.WARN)
    return {}
  end

  local tasks = result.tasks or {}
  M._cache[root] = { tasks = tasks, mtime = mt }
  return tasks
end

-- ── Build dashboard menu items from task definitions ─────────────────────────
function M.to_menu_items(tasks)
  local items = {}
  for _, t in ipairs(tasks) do
    items[#items + 1] = {
      id    = '__task__' .. t.name,
      icon  = t.restart and '󰑖' or '󰐊',
      label = t.name,
      desc  = t.desc or t.cmd,
      badge = t.restart and 'watch' or nil,
      _task = t,
    }
  end
  return items
end

-- ── Run a task by definition ──────────────────────────────────────────────────
-- Resolves `depends` chains then executes.
function M.run(task_def, project, term_cfg)
  term_cfg = term_cfg or require('jason').config.terminal
  local runner = require('core.runner')

  local cwd = task_def.cwd
      and (project.root .. '/' .. task_def.cwd)
      or project.root

  local title = task_def.title or task_def.name

  -- Prepend env vars to command if provided
  local cmd = task_def.cmd
  if task_def.env then
    local pairs_list = {}
    for k, v in pairs(task_def.env) do
      pairs_list[#pairs_list + 1] = k .. '=' .. vim.fn.shellescape(v)
    end
    cmd = table.concat(pairs_list, ' ') .. ' ' .. cmd
  end

  -- Resolve depends into a sequence
  if task_def.depends and #task_def.depends > 0 then
    local all_tasks = M.load(project.root)
    local steps = {}
    for _, dep_name in ipairs(task_def.depends) do
      for _, t in ipairs(all_tasks) do
        if t.name == dep_name then
          steps[#steps + 1] = {
            cmd   = t.cmd,
            title = t.title or t.name,
          }
          break
        end
      end
    end
    steps[#steps + 1] = { cmd = cmd, title = title }
    runner.execute_sequence(steps, {
      cwd       = cwd,
      term_cfg  = term_cfg,
      plugin    = 'jason',
      action_id = '__task__' .. task_def.name,
    })
    return
  end

  -- Watch / restart mode
  if task_def.restart then
    M._run_watch(task_def, cmd, cwd, title, term_cfg, project)
    return
  end

  runner.execute({
    cmd       = cmd,
    cwd       = cwd,
    title     = title,
    term_cfg  = term_cfg,
    plugin    = 'jason',
    action_id = '__task__' .. task_def.name,
  })
end

-- ── Watch mode (restart on exit) ─────────────────────────────────────────────
M._watch_jobs = {} -- name -> job_id

function M._run_watch(task_def, cmd, cwd, title, term_cfg, project)
  local runner = require('core.runner')
  local name   = task_def.name

  local function launch()
    runner.execute({
      cmd       = cmd,
      cwd       = cwd,
      title     = '󰑖 ' .. title,
      term_cfg  = term_cfg,
      plugin    = 'jason',
      action_id = '__task__' .. name,
      on_exit   = function(ok)
        -- Only restart if the task is still registered as a watch task
        if M._watch_jobs[name] then
          vim.defer_fn(function()
            if M._watch_jobs[name] then
              vim.notify('[jason] Restarting watch task: ' .. name, vim.log.levels.INFO)
              launch()
            end
          end, 500)
        end
      end,
    })
  end

  M._watch_jobs[name] = true
  launch()
end

function M.stop_watch(name)
  if M._watch_jobs[name] then
    M._watch_jobs[name] = nil
    vim.notify('[jason] Watch task stopped: ' .. name, vim.log.levels.INFO)
  end
end

function M.stop_all_watch()
  for name in pairs(M._watch_jobs) do
    M._watch_jobs[name] = nil
  end
  require('core.runner').stop_all()
end

-- ── Handle dashboard action id ────────────────────────────────────────────────
-- Returns true if the id was a task action and was handled.
function M.handle_action(id, project)
  if not id or not id:match('^__task__') then return false end
  local name  = id:sub(10) -- strip '__task__'
  local tasks = M.load(project.root)
  for _, t in ipairs(tasks) do
    if t.name == name then
      -- Toggle watch tasks off if already running
      if t.restart and M._watch_jobs[name] then
        M.stop_watch(name)
      else
        M.run(t, project)
      end
      return true
    end
  end
  return false
end

return M
