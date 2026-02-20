-- lua/core/runner.lua
-- Shared job execution engine for Jason + Marvin.
-- Owns: terminal/background execution, job tracking, unified history,
--       sequence runner, watch/restart mode, output log storage.

local M            = {}

M.jobs             = {} -- jid -> { title, cmd, start_time, buf?, win? }
M.history          = {} -- newest-first list of run entries
M.MAX_HIST         = 100

-- ── Listeners ─────────────────────────────────────────────────────────────────
M._listeners       = {}
M._start_listeners = {}

function M.on_finish(fn) M._listeners[#M._listeners + 1] = fn end

function M.on_start(fn) M._start_listeners[#M._start_listeners + 1] = fn end

local function fire(entry)
  for _, fn in ipairs(M._listeners) do pcall(fn, entry) end
end

local function fire_start(entry)
  for _, fn in ipairs(M._start_listeners) do pcall(fn, entry) end
end

-- ── History ───────────────────────────────────────────────────────────────────
local function record(e)
  e.timestamp = e.timestamp or os.time()
  table.insert(M.history, 1, e)
  if #M.history > M.MAX_HIST then table.remove(M.history) end
end

function M.clear_history() M.history = {} end

function M.get_last_status(action_id)
  for _, e in ipairs(M.history) do
    if e.action_id == action_id then return e end
  end
  return nil
end

-- ── Window builders ───────────────────────────────────────────────────────────
local function win_float(buf, title, cfg)
  local ui = vim.api.nvim_list_uis()[1]
  local w  = math.floor(ui.width * 0.82)
  local h  = math.floor(ui.height * (cfg.size or 0.4))
  local r  = math.floor((ui.height - h) / 2)
  local c  = math.floor((ui.width - w) / 2)
  return vim.api.nvim_open_win(buf, true, {
    relative  = 'editor',
    width     = w,
    height    = h,
    row       = r,
    col       = c,
    style     = 'minimal',
    border    = 'rounded',
    title     = ' ' .. title .. ' ',
    title_pos = 'center',
  })
end

local function win_split(buf, cfg)
  vim.cmd('split')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(win, math.floor(vim.api.nvim_win_get_height(win) * (cfg.size or 0.4)))
  vim.api.nvim_win_set_buf(win, buf)
  return win
end

local function win_vsplit(buf, cfg)
  vim.cmd('vsplit')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(win, math.floor(vim.api.nvim_win_get_width(win) * (cfg.size or 0.4)))
  vim.api.nvim_win_set_buf(win, buf)
  return win
end

local function set_win_opts(win)
  for k, v in pairs({ number = false, relativenumber = false, signcolumn = 'no', scrolloff = 0 }) do
    pcall(vim.api.nvim_set_option_value, k, v, { win = win })
  end
end

local function buf_keymaps(buf, win)
  local o = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, o)
  vim.keymap.set('t', '<Esc><Esc>', function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, o)
end

-- ── Build environment string from table ───────────────────────────────────────
local function env_prefix(env)
  if not env or vim.tbl_isempty(env) then return '' end
  local parts = {}
  for k, v in pairs(env) do parts[#parts + 1] = k .. '=' .. vim.fn.shellescape(tostring(v)) end
  return table.concat(parts, ' ') .. ' '
end

-- ── Core execute ─────────────────────────────────────────────────────────────
-- opts:
--   cmd        string
--   cwd        string
--   title      string
--   term_cfg   { position, size, close_on_success }
--   env        table   optional k/v env vars
--   args       string  optional extra args appended to cmd
--   on_exit    fn(success, output)
--   plugin     string
--   action_id  string
function M.execute(opts)
  local cmd   = env_prefix(opts.env) .. opts.cmd .. (opts.args and (' ' .. opts.args) or '')
  local cwd   = opts.cwd or vim.fn.getcwd()
  local title = opts.title or opts.cmd
  local tcfg  = opts.term_cfg or { position = 'float', size = 0.4, close_on_success = false }

  if tcfg.position == 'background' then
    M._bg(cmd, cwd, title, opts)
  else
    M._term(cmd, cwd, title, tcfg, opts)
  end
end

function M._bg(cmd, cwd, title, opts)
  local output  = {}
  local start   = os.time()

  -- Seed a pending history entry immediately so the console shows it live
  local pending = {
    action    = title,
    action_id = opts.action_id,
    plugin    = opts.plugin,
    success   = nil, -- nil = still running
    output    = output,
    duration  = 0,
    cmd       = cmd,
    timestamp = start,
  }
  record(pending)
  fire_start(pending)

  vim.notify('🔨 ' .. title, vim.log.levels.INFO)

  local jid
  jid = vim.fn.jobstart(cmd, {
    cwd             = cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout       = function(_, d) vim.list_extend(output, d) end,
    on_stderr       = function(_, d) vim.list_extend(output, d) end,
    on_exit         = function(_, code)
      M.jobs[jid]      = nil
      local ok         = code == 0
      local dur        = os.time() - start
      -- Update the pending entry in-place so the console reflects final status
      pending.success  = ok
      pending.duration = dur
      if ok then
        vim.notify(string.format('✅ %s  (%ds)', title, dur), vim.log.levels.INFO)
      else
        vim.notify(string.format('❌ %s failed  (%ds)', title, dur), vim.log.levels.ERROR)
        M._parse(output, opts.plugin)
      end
      fire(pending)
      if opts.on_exit then pcall(opts.on_exit, ok, output) end
    end,
  })
  M.jobs[jid] = { title = title, cmd = cmd, start_time = start }
end

function M._term(cmd, cwd, title, tcfg, opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })

  local win
  local pos = tcfg.position or 'float'
  if pos == 'split' then
    win = win_split(buf, tcfg)
  elseif pos == 'vsplit' then
    win = win_vsplit(buf, tcfg)
  else
    win = win_float(buf, title, tcfg)
  end
  set_win_opts(win)

  local output  = {}
  local start   = os.time()

  -- Seed a pending history entry immediately so the console shows it live
  local pending = {
    action    = title,
    action_id = opts.action_id,
    plugin    = opts.plugin,
    success   = nil,
    output    = output,
    duration  = 0,
    cmd       = cmd,
    timestamp = start,
  }
  record(pending)
  fire_start(pending)

  local jid
  jid = vim.fn.termopen(cmd, {
    cwd       = cwd,
    on_stdout = function(_, d) vim.list_extend(output, d) end,
    on_stderr = function(_, d) vim.list_extend(output, d) end,
    on_exit   = function(_, code)
      M.jobs[jid]      = nil
      local ok         = code == 0
      local dur        = os.time() - start
      -- Update the pending entry in-place
      pending.success  = ok
      pending.duration = dur
      if ok then
        if tcfg.close_on_success then
          vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
          end, 1200)
        end
        vim.notify(string.format('✅ %s  (%ds)', title, dur), vim.log.levels.INFO)
      else
        vim.notify(string.format('❌ %s failed  (%ds)', title, dur), vim.log.levels.ERROR)
        M._parse(output, opts.plugin)
      end
      fire(pending)
      if opts.on_exit then pcall(opts.on_exit, ok, output) end
    end,
  })
  M.jobs[jid] = { title = title, cmd = cmd, start_time = start, buf = buf, win = win }
  buf_keymaps(buf, win)
  vim.cmd('startinsert')
end

-- ── Sequence ──────────────────────────────────────────────────────────────────
function M.execute_sequence(steps, base_opts)
  local idx = 1
  local function nxt()
    if idx > #steps then
      vim.notify('All tasks completed!', vim.log.levels.INFO); return
    end
    local step = steps[idx]
    local o    = vim.tbl_extend('force', base_opts, {
      cmd     = step.cmd,
      title   = step.title,
      on_exit = function(ok)
        if ok then
          idx = idx + 1; vim.schedule(nxt)
        else
          vim.notify('Stopped at: ' .. step.title, vim.log.levels.ERROR)
        end
      end,
    })
    M.execute(o)
  end
  nxt()
end

-- ── Watch / restart ───────────────────────────────────────────────────────────
M._watchers = {} -- action_id -> true

function M.execute_watch(opts)
  local id        = opts.action_id or opts.cmd
  M._watchers[id] = true
  local function launch()
    local o = vim.tbl_extend('force', opts, {
      on_exit = function(ok, output)
        if opts.on_exit then pcall(opts.on_exit, ok, output) end
        if M._watchers[id] then
          vim.defer_fn(function()
            if M._watchers[id] then
              vim.notify('[runner] Restarting: ' .. (opts.title or id), vim.log.levels.INFO)
              launch()
            end
          end, 600)
        end
      end,
    })
    M.execute(o)
  end
  launch()
end

function M.stop_watch(action_id)
  M._watchers[action_id] = nil
end

function M.is_watching(action_id)
  return M._watchers[action_id] == true
end

-- ── Stop ─────────────────────────────────────────────────────────────────────
function M.stop_all()
  for jid, info in pairs(M.jobs) do
    vim.fn.jobstop(jid)
    vim.notify('Stopped: ' .. info.title, vim.log.levels.WARN)
  end
  M.jobs      = {}
  M._watchers = {}
end

function M.stop_last()
  local jid = nil
  for j in pairs(M.jobs) do jid = j end
  if jid then
    local info = M.jobs[jid]
    vim.fn.jobstop(jid)
    M.jobs[jid] = nil
    for id in pairs(M._watchers) do
      if M._watchers[id] then
        M._watchers[id] = nil; break
      end
    end
    vim.notify('Stopped: ' .. info.title, vim.log.levels.WARN)
  else
    vim.notify('No running tasks', vim.log.levels.WARN)
  end
end

function M.running_count() return vim.tbl_count(M.jobs) end

-- ── Running jobs list (for console) ──────────────────────────────────────────
function M.get_running()
  local r = {}
  for _, info in pairs(M.jobs) do r[#r + 1] = info end
  return r
end

-- ── Output log viewer ────────────────────────────────────────────────────────
function M.show_output(entry)
  if not entry or not entry.output or #entry.output == 0 then
    vim.notify('No output recorded for this run', vim.log.levels.INFO); return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('filetype', 'log', { buf = buf })

  local header = {
    '# ' .. (entry.action or 'Run'),
    '# cmd: ' .. (entry.cmd or '?'),
    '# status: ' .. (entry.success and 'SUCCESS' or 'FAILED'),
    '# duration: ' .. (entry.duration or '?') .. 's',
    string.rep('-', 60), '',
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false,
    vim.list_extend(header, entry.output or {}))
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  vim.cmd('split')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, math.floor(vim.o.lines * 0.4))
  vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, true) end,
    { noremap = true, silent = true, buffer = buf })
end

-- ── Parser dispatch ──────────────────────────────────────────────────────────
function M._parse(output, plugin)
  if plugin == 'marvin' then
    local ok, p = pcall(require, 'marvin.parser')
    if ok then
      p.parse_output(output); return
    end
  end
  local ok, p = pcall(require, 'jason.parser')
  if ok then p.parse_output(output) end
end

return M
