-- lua/marvin/trixie.lua
-- Bidirectional bridge between the Marvin nvim plugin and the Trixie compositor.
--
-- COMPOSITOR → NVIM  (compositor writes a line to the IPC socket):
--   marvin_cmd <action>         e.g. build / run / test / clean / build_run
--   marvin_cmd focus\t<f>\t<l>  open file:line in nvim
--   marvin_cmd reload           re-read project config
--
-- NVIM → COMPOSITOR  (we write IPC commands to the Unix socket):
--   marvin_project <json>
--   marvin_build   <json>
--   marvin_diag    <json>
--   marvin_git     <json>
--   marvin_buffers <json>
--   marvin_cursor  <json>
--   marvin_actions <json>

local M            = {}
local uv           = vim.uv or vim.loop
local runner       = require('core.runner')

-- ── Config ────────────────────────────────────────────────────────────────
local SOCK_PATH    = os.getenv('TRIXIE_IPC') or '/tmp/trixie.sock'
local RECONNECT_MS = 3000

-- ── State ─────────────────────────────────────────────────────────────────
local _client      = nil -- uv TCP/pipe handle
local _connected   = false
local _send_queue  = {} -- queued while disconnected
local _recv_buf    = '' -- partial line buffer

-- ── Low-level send ────────────────────────────────────────────────────────
local function raw_send(line)
  if _connected and _client then
    _client:write(line .. '\n')
  else
    _send_queue[#_send_queue + 1] = line
  end
end

-- ── Flush queue after connect ─────────────────────────────────────────────
local function flush_queue()
  local q = _send_queue
  _send_queue = {}
  for _, line in ipairs(q) do
    _client:write(line .. '\n')
  end
end

-- ── Inbound dispatcher ────────────────────────────────────────────────────
-- Lines arriving from compositor have the form:
--   {"event":"marvin_cmd","action":"build"}
--   {"event":"marvin_cmd","action":"focus","file":"…","line":42}
local function dispatch_event(line)
  local ok, obj = pcall(vim.json.decode, line)
  if not ok or type(obj) ~= 'table' then return end
  if obj.event ~= 'marvin_cmd' then return end

  local act = obj.action
  if not act then return end

  if act == 'build' then
    M.trigger_build()
  elseif act == 'run' then
    M.trigger_run()
  elseif act == 'test' then
    M.trigger_test()
  elseif act == 'clean' then
    M.trigger_clean()
  elseif act == 'build_run' then
    M.trigger_build_run()
  elseif act == 'reload' then
    M.push_project()
    M.push_actions()
  elseif act == 'focus' then
    local f = obj.file
    local l = obj.line or 0
    if f and f ~= '' then
      vim.schedule(function()
        vim.cmd('edit ' .. vim.fn.fnameescape(f))
        if l > 0 then
          vim.api.nvim_win_set_cursor(0, { l, 0 })
        end
      end)
    end
  end
end

-- ── Connect ───────────────────────────────────────────────────────────────
local function on_read(err, data)
  if err or not data then
    _connected = false
    if _client then _client:close() end
    _client = nil
    vim.defer_fn(M.connect, RECONNECT_MS)
    return
  end
  _recv_buf = _recv_buf .. data
  while true do
    local nl = _recv_buf:find('\n', 1, true)
    if not nl then break end
    local line = _recv_buf:sub(1, nl - 1)
    _recv_buf = _recv_buf:sub(nl + 1)
    if line ~= '' then
      vim.schedule(function() dispatch_event(line) end)
    end
  end
end

function M.connect()
  local pipe = uv.new_pipe(false)
  pipe:connect(SOCK_PATH, function(err)
    if err then
      pipe:close()
      vim.defer_fn(M.connect, RECONNECT_MS)
      return
    end
    _client    = pipe
    _connected = true
    pipe:read_start(on_read)
    vim.schedule(function()
      flush_queue()
      -- Announce ourselves immediately
      M.push_project()
      M.push_actions()
      M.push_git()
      M.push_buffers()
    end)
  end)
end

function M.disconnect()
  _connected = false
  if _client then
    _client:close()
    _client = nil
  end
end

-- ── Push helpers ──────────────────────────────────────────────────────────
local function send_json(cmd, obj)
  local ok, enc = pcall(vim.json.encode, obj)
  if ok then raw_send(cmd .. ' ' .. enc) end
end

-- ── Project ───────────────────────────────────────────────────────────────
function M.push_project()
  local root = vim.fn.getcwd()
  -- Detect project type
  local ptype = 'generic'
  if vim.fn.filereadable(root .. '/Cargo.toml') == 1 then
    ptype = 'cargo'
  elseif vim.fn.filereadable(root .. '/go.mod') == 1 then
    ptype = 'go'
  elseif vim.fn.filereadable(root .. '/pom.xml') == 1 then
    ptype = 'maven'
  elseif vim.fn.filereadable(root .. '/CMakeLists.txt') == 1 then
    ptype = 'cmake'
  elseif vim.fn.filereadable(root .. '/package.json') == 1 then
    ptype = 'npm'
  elseif vim.fn.filereadable(root .. '/Makefile') == 1 then
    ptype = 'make'
  elseif vim.fn.filereadable(root .. '/build.zig') == 1 then
    ptype = 'zig'
  end

  -- Project name from directory basename
  local name = vim.fn.fnamemodify(root, ':t')

  -- Default commands per type
  local build_cmds = {
    cargo = 'cargo build',
    go = 'go build ./...',
    maven = 'mvn compile',
    cmake = 'cmake --build build',
    npm = 'npm run build',
    make = 'make',
    zig = 'zig build',
    generic = 'make',
  }
  local run_cmds = {
    cargo = 'cargo run',
    go = 'go run .',
    maven = 'mvn exec:java',
    cmake = './build/app',
    npm = 'npm start',
    make = 'make run',
    zig = 'zig build run',
    generic = '',
  }

  send_json('marvin_project', {
    root      = root,
    name      = name,
    type      = ptype,
    build_cmd = build_cmds[ptype] or '',
    run_cmd   = run_cmds[ptype] or '',
  })
end

-- ── Cursor / symbol ───────────────────────────────────────────────────────
function M.push_cursor()
  local buf        = vim.api.nvim_get_current_buf()
  local win        = vim.api.nvim_get_current_win()
  local pos        = vim.api.nvim_win_get_cursor(win)
  local file       = vim.api.nvim_buf_get_name(buf)
  -- Try to get LSP symbol at cursor (non-blocking best-effort)
  local sym        = ''
  local ok, params = pcall(vim.lsp.util.make_position_params)
  if ok and params then
    -- We can't block; just use treesitter node text as fallback
    local ts_ok, node = pcall(function()
      return vim.treesitter.get_node({ pos = { pos[1] - 1, pos[2] } })
    end)
    if ts_ok and node then sym = node:type() end
  end
  send_json('marvin_cursor', {
    file   = file,
    line   = pos[1],
    col    = pos[2],
    symbol = sym,
  })
end

-- ── Diagnostics ───────────────────────────────────────────────────────────
function M.push_diag()
  local diag = vim.diagnostic.get(nil) -- all buffers
  local items = {}
  for _, d in ipairs(diag) do
    items[#items + 1] = {
      file     = vim.api.nvim_buf_get_name(d.bufnr or 0),
      lnum     = d.lnum + 1,
      col      = d.col,
      severity = d.severity,
      message  = d.message,
      source   = d.source,
    }
    if #items >= 200 then break end
  end
  send_json('marvin_diag', items)
end

-- ── Git ───────────────────────────────────────────────────────────────────
function M.push_git()
  -- Try gitsigns first, fall back to shelling out
  local ok, gs = pcall(require, 'gitsigns')
  if ok and gs.get_hunks then
    local status = vim.b.gitsigns_status_dict
    if status then
      send_json('marvin_git', {
        branch = status.head or '',
        status = (status.added == 0 and status.changed == 0 and status.removed == 0)
            and 'clean' or 'dirty',
        ahead  = 0,
        behind = 0,
      })
      return
    end
  end
  -- Shell fallback (async)
  vim.fn.jobstart({ 'git', 'status', '--porcelain', '-b' }, {
    cwd             = vim.fn.getcwd(),
    stdout_buffered = true,
    on_stdout       = function(_, data)
      local branch, dirty = '', false
      for _, l in ipairs(data) do
        if l:match('^##') then
          branch = l:match('## ([^%.%.]+)') or ''
        elseif l:match('^[^ ]') then
          dirty = true
        end
      end
      send_json('marvin_git', {
        branch = branch,
        status = dirty and 'dirty' or 'clean',
        ahead = 0,
        behind = 0,
      })
    end,
  })
end

-- ── Buffers ───────────────────────────────────────────────────────────────
function M.push_buffers()
  local bufs = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
      bufs[#bufs + 1] = {
        bufnr    = b,
        name     = vim.api.nvim_buf_get_name(b),
        modified = vim.bo[b].modified,
        filetype = vim.bo[b].filetype,
      }
    end
  end
  send_json('marvin_buffers', bufs)
end

-- ── Actions ───────────────────────────────────────────────────────────────
-- Populated by Marvin's action registry; default to project-type actions.
function M.push_actions()
  local ok, marvin = pcall(require, 'marvin')
  local actions    = {}
  if ok and marvin.get_actions then
    actions = marvin.get_actions()
  else
    actions = { 'build', 'run', 'test', 'clean', 'build_run' }
  end
  -- send as a plain JSON array of action id strings
  local ok2, enc = pcall(vim.json.encode, actions)
  if ok2 then raw_send('marvin_actions ' .. enc) end
end

-- ── Build notifications (runner.lua integration) ──────────────────────────
runner.on_start(function(entry)
  if entry.plugin ~= 'marvin' then return end
  send_json('marvin_build', {
    status    = 'running',
    exit_code = 0,
    errors    = 0,
    warnings  = 0,
    timestamp = entry.timestamp,
  })
end)

runner.on_finish(function(entry)
  if entry.plugin ~= 'marvin' then return end
  -- Count diag severity from LSP after a short settle delay
  vim.defer_fn(function()
    local diag     = vim.diagnostic.get(nil)
    local errors   = 0; local warnings = 0
    for _, d in ipairs(diag) do
      if d.severity == vim.diagnostic.severity.ERROR then
        errors = errors + 1
      elseif d.severity == vim.diagnostic.severity.WARN then
        warnings = warnings + 1
      end
    end
    send_json('marvin_build', {
      status    = entry.success and 'ok' or 'failed',
      exit_code = entry.success and 0 or 1,
      errors    = errors,
      warnings  = warnings,
      timestamp = entry.timestamp,
    })
    M.push_diag()
  end, 500)
end)

-- ── Trigger helpers (called by compositor key events or Marvin UI) ─────────
function M.trigger_build()
  local ok, marvin = pcall(require, 'marvin')
  if ok and marvin.build then
    marvin.build()
  else
    runner.execute({
      cmd = 'make',
      title = 'Build',
      plugin = 'marvin',
      action_id = 'build',
      term_cfg = { position = 'background' }
    })
  end
end

function M.trigger_run()
  local ok, marvin = pcall(require, 'marvin')
  if ok and marvin.run then
    marvin.run()
  else
    runner.execute({
      cmd = 'make run',
      title = 'Run',
      plugin = 'marvin',
      action_id = 'run',
      term_cfg = { position = 'background' }
    })
  end
end

function M.trigger_test()
  local ok, marvin = pcall(require, 'marvin')
  if ok and marvin.test then
    marvin.test()
  else
    runner.execute({
      cmd = 'make test',
      title = 'Test',
      plugin = 'marvin',
      action_id = 'test',
      term_cfg = { position = 'background' }
    })
  end
end

function M.trigger_clean()
  local ok, marvin = pcall(require, 'marvin')
  if ok and marvin.clean then
    marvin.clean()
  else
    runner.execute({
      cmd = 'make clean',
      title = 'Clean',
      plugin = 'marvin',
      action_id = 'clean',
      term_cfg = { position = 'background' }
    })
  end
end

function M.trigger_build_run()
  runner.execute_sequence(
    { { cmd = 'make', title = 'Build' },
      { cmd = 'make run', title = 'Run' } },
    { plugin = 'marvin', term_cfg = { position = 'background' } }
  )
end

-- ── Autocommands ──────────────────────────────────────────────────────────
function M.setup_autocmds()
  local g = vim.api.nvim_create_augroup('MarvinTrixie', { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufEnter' }, {
    group    = g,
    callback = function() vim.defer_fn(M.push_cursor, 80) end,
  })
  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group    = g,
    callback = function() vim.defer_fn(M.push_diag, 300) end,
  })
  vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete', 'BufWipeout' }, {
    group    = g,
    callback = function() vim.defer_fn(M.push_buffers, 100) end,
  })
  vim.api.nvim_create_autocmd('DirChanged', {
    group    = g,
    callback = function()
      vim.defer_fn(M.push_project, 50)
      vim.defer_fn(M.push_git, 200)
      vim.defer_fn(M.push_actions, 100)
    end,
  })
end

-- ── Setup entry point ─────────────────────────────────────────────────────
function M.setup(opts)
  opts = opts or {}
  if opts.sock_path then SOCK_PATH = opts.sock_path end
  M.connect()
  M.setup_autocmds()
end

return M
