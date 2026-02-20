-- lua/core/runner.lua
-- Shared job runner used by both Jason and Marvin.
-- Replaces the duplicated executor logic in each plugin.

local M      = {}

M.jobs       = {} -- keyed by job_id
M.history    = {} -- unified run history (max 50)
M.MAX_HIST   = 50

-- ── Listeners (plugins register callbacks here) ───────────────────────────────
M._on_finish = {} -- list of fn(entry) called after every job finishes

function M.on_finish(fn)
  M._on_finish[#M._on_finish + 1] = fn
end

local function fire_finish(entry)
  for _, fn in ipairs(M._on_finish) do
    pcall(fn, entry)
  end
end

-- ── History ───────────────────────────────────────────────────────────────────
local function record(entry)
  entry.timestamp = os.time()
  table.insert(M.history, 1, entry)
  if #M.history > M.MAX_HIST then
    table.remove(M.history)
  end
  fire_finish(entry)
end

-- ── Window helpers ────────────────────────────────────────────────────────────
local function make_float_win(buf, title, term_cfg)
  local ui     = vim.api.nvim_list_uis()[1]
  local width  = math.floor(ui.width * 0.8)
  local height = math.floor(ui.height * (term_cfg.size or 0.4))
  local row    = math.floor((ui.height - height) / 2)
  local col    = math.floor((ui.width - width) / 2)
  return vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. title .. ' ',
    title_pos = 'center',
  })
end

local function make_split_win(buf, term_cfg)
  vim.cmd('split')
  local win = vim.api.nvim_get_current_win()
  local h   = math.floor(vim.api.nvim_win_get_height(win) * (term_cfg.size or 0.4))
  vim.api.nvim_win_set_height(win, h)
  vim.api.nvim_win_set_buf(win, buf)
  return win
end

local function make_vsplit_win(buf, term_cfg)
  vim.cmd('vsplit')
  local win = vim.api.nvim_get_current_win()
  local w   = math.floor(vim.api.nvim_win_get_width(win) * (term_cfg.size or 0.4))
  vim.api.nvim_win_set_width(win, w)
  vim.api.nvim_win_set_buf(win, buf)
  return win
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

-- ── Core execute ─────────────────────────────────────────────────────────────
-- opts:
--   cmd        string
--   cwd        string
--   title      string
--   term_cfg   table  { position, size, close_on_success }
--   on_exit    fn(success, output)   optional extra callback
--   plugin     string  'jason'|'marvin'|...  (for history tagging)
--   action_id  string  (for re-run support)
function M.execute(opts)
  local cmd      = opts.cmd
  local cwd      = opts.cwd or vim.fn.getcwd()
  local title    = opts.title or cmd
  local term_cfg = opts.term_cfg or { position = 'float', size = 0.4, close_on_success = false }

  if term_cfg.position == 'background' then
    M._run_background(cmd, cwd, title, opts)
  else
    M._run_terminal(cmd, cwd, title, term_cfg, opts)
  end
end

function M._run_background(cmd, cwd, title, opts)
  local output = {}
  vim.notify('🔨 ' .. title .. ': ' .. cmd, vim.log.levels.INFO)

  local jid = vim.fn.jobstart(cmd, {
    cwd             = cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout       = function(_, d) vim.list_extend(output, d) end,
    on_stderr       = function(_, d) vim.list_extend(output, d) end,
    on_exit         = function(_, code)
      M.jobs[jid] = nil
      local ok = code == 0
      if ok then
        vim.notify('✅ ' .. title .. ' successful!', vim.log.levels.INFO)
      else
        vim.notify('❌ ' .. title .. ' failed!', vim.log.levels.ERROR)
        M._dispatch_parser(output, opts.plugin)
      end
      record({
        action = title,
        action_id = opts.action_id,
        plugin = opts.plugin,
        success = ok,
        output = output
      })
      if opts.on_exit then pcall(opts.on_exit, ok, output) end
    end,
  })
  M.jobs[jid] = { title = title, cmd = cmd }
end

function M._run_terminal(cmd, cwd, title, term_cfg, opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })

  local win
  local pos = term_cfg.position or 'float'
  if pos == 'split' then
    win = make_split_win(buf, term_cfg)
  elseif pos == 'vsplit' then
    win = make_vsplit_win(buf, term_cfg)
  else
    win = make_float_win(buf, title, term_cfg)
  end

  vim.api.nvim_set_option_value('number', false, { win = win })
  vim.api.nvim_set_option_value('relativenumber', false, { win = win })

  local output = {}
  local jid = vim.fn.termopen(cmd, {
    cwd       = cwd,
    on_stdout = function(_, d) vim.list_extend(output, d) end,
    on_stderr = function(_, d) vim.list_extend(output, d) end,
    on_exit   = function(_, code)
      M.jobs[jid] = nil
      local ok = code == 0
      if ok then
        if term_cfg.close_on_success then
          vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
          end, 1000)
        end
        vim.notify('✅ ' .. title .. ' successful!', vim.log.levels.INFO)
      else
        vim.notify('❌ ' .. title .. ' failed!', vim.log.levels.ERROR)
        M._dispatch_parser(output, opts.plugin)
      end
      record({
        action = title,
        action_id = opts.action_id,
        plugin = opts.plugin,
        success = ok,
        output = output
      })
      if opts.on_exit then pcall(opts.on_exit, ok, output) end
    end,
  })
  M.jobs[jid] = { title = title, cmd = cmd }

  buf_keymaps(buf, win)
  vim.cmd('startinsert')
end

-- ── Sequence runner ───────────────────────────────────────────────────────────
-- steps: list of { cmd, title }
-- opts: same as execute() minus cmd/title
function M.execute_sequence(steps, opts)
  local idx = 1
  local function next()
    if idx > #steps then
      vim.notify('✅ All tasks completed!', vim.log.levels.INFO)
      return
    end
    local step = steps[idx]
    local step_opts = vim.tbl_extend('force', opts, {
      cmd     = step.cmd,
      title   = step.title,
      on_exit = function(ok)
        if ok then
          idx = idx + 1
          vim.schedule(next)
        else
          vim.notify('❌ Sequence stopped at: ' .. step.title, vim.log.levels.ERROR)
        end
      end,
    })
    M.execute(step_opts)
  end
  next()
end

-- ── Stop all / specific ───────────────────────────────────────────────────────
function M.stop_all()
  for jid, info in pairs(M.jobs) do
    vim.fn.jobstop(jid)
    vim.notify('Stopped: ' .. info.title, vim.log.levels.WARN)
  end
  M.jobs = {}
end

function M.stop_last()
  local last_jid = nil
  for jid in pairs(M.jobs) do last_jid = jid end
  if last_jid then
    vim.fn.jobstop(last_jid)
    vim.notify('Stopped: ' .. M.jobs[last_jid].title, vim.log.levels.WARN)
    M.jobs[last_jid] = nil
  else
    vim.notify('No running tasks', vim.log.levels.WARN)
  end
end

-- ── Parser dispatch ───────────────────────────────────────────────────────────
-- Tries jason.parser then marvin.parser depending on which is loaded.
function M._dispatch_parser(output, plugin)
  if plugin == 'marvin' then
    local ok, p = pcall(require, 'marvin.parser')
    if ok then
      p.parse_output(output); return
    end
  end
  local ok, p = pcall(require, 'jason.parser')
  if ok then p.parse_output(output) end
end

-- ── Task file loader (.jason.lua) ─────────────────────────────────────────────
-- Returns list of task defs or nil.
function M.load_task_file(root)
  local path = root .. '/.jason.lua'
  if vim.fn.filereadable(path) == 0 then return nil end
  local ok, result = pcall(dofile, path)
  if not ok or type(result) ~= 'table' then
    vim.notify('runner: error loading ' .. path .. ': ' .. tostring(result), vim.log.levels.WARN)
    return nil
  end
  return result.tasks
end

return M
