-- lua/marvin/console.lua
-- Overseer-style task console (was jason.console).
-- Shows a split panel: left = job history list, right = live/stored output.

local M = {}

local C = {
  bg = '#1e1e2e',
  bg2 = '#181825',
  bg3 = '#11111b',
  surface0 = '#313244',
  surface1 = '#45475a',
  text = '#cdd6f4',
  sub1 = '#bac2de',
  ov0 = '#6c7086',
  blue = '#89b4fa',
  mauve = '#cba6f7',
  green = '#a6e3a1',
  yellow = '#f9e2af',
  peach = '#fab387',
  red = '#f38ba8',
  sky = '#89dceb',
}

local function setup_hl()
  local function hl(n, o) vim.api.nvim_set_hl(0, n, o) end
  hl('JasonConWin', { bg = C.bg, fg = C.text })
  hl('JasonConBorder', { fg = C.surface1, bg = C.bg })
  hl('JasonConTitle', { fg = C.mauve, bold = true })
  hl('JasonConOutWin', { bg = C.bg3, fg = C.sub1 })
  hl('JasonConOutBorder', { fg = C.surface0, bg = C.bg3 })
  hl('JasonConOutTitle', { fg = C.blue, bold = true })
  hl('JasonConSep', { fg = C.surface1 })
  hl('JasonConSepLbl', { fg = C.ov0, italic = true })
  hl('JasonConSel', { bg = C.surface0, fg = C.text })
  hl('JasonConOk', { fg = C.green, bold = true })
  hl('JasonConFail', { fg = C.red, bold = true })
  hl('JasonConRunning', { fg = C.yellow, bold = true })
  hl('JasonConDim', { fg = C.ov0 })
  hl('JasonConCmd', { fg = C.sky })
  hl('JasonConTime', { fg = C.peach })
  hl('JasonConFooter', { fg = C.ov0 })
  hl('JasonConFooterKey', { fg = C.peach, bold = true })
end

local state = {
  list_buf = nil,
  out_buf  = nil,
  list_win = nil,
  out_win  = nil,
  sel      = 1,
  ns_list  = vim.api.nvim_create_namespace('jason_con_list'),
  ns_out   = vim.api.nvim_create_namespace('jason_con_out'),
  open     = false,
  _timer   = nil,
}

local function ago(ts)
  if not ts then return '' end
  local d = os.time() - ts
  if d < 5 then
    return 'just now'
  elseif d < 60 then
    return d .. 's ago'
  elseif d < 3600 then
    return math.floor(d / 60) .. 'm ago'
  else
    return math.floor(d / 3600) .. 'h ago'
  end
end

local function dur(s)
  if not s or s == 0 then return '' end
  if s < 60 then return string.format('%.1fs', s) end
  return string.format('%dm%ds', math.floor(s / 60), s % 60)
end

local function history()
  local ok, r = pcall(require, 'core.runner')
  return ok and r.history or {}
end

local function running_jobs()
  local ok, r = pcall(require, 'core.runner')
  return ok and r.get_running and r.get_running() or {}
end

local function is_valid_win(w) return w and vim.api.nvim_win_is_valid(w) end
local function is_valid_buf(b) return b and vim.api.nvim_buf_is_valid(b) end

local LIST_W = 42

local function render_list()
  if not is_valid_buf(state.list_buf) then return end
  local lines, hls = {}, {}
  local function add(ln, specs)
    lines[#lines + 1] = ln
    for _, s in ipairs(specs or {}) do
      hls[#hls + 1] = { line = #lines - 1, hl = s[1], cs = s[2], ce = s[3] }
    end
  end
  local function ahr(li, hl_name) hls[#hls + 1] = { line = li, hl = hl_name, cs = 0, ce = -1 } end

  add('  󰋚 Task Console', { { 'JasonConTitle', 2, -1 } })
  add(string.rep('─', LIST_W), { { 'JasonConSep', 0, -1 } })

  local running = running_jobs()
  if running and #running > 0 then
    add(' ● Running', { { 'JasonConRunning', 1, 2 }, { 'JasonConSepLbl', 3, -1 } })
    for _, job in ipairs(running) do
      local t = (job.title or job.cmd or '?'):sub(1, LIST_W - 6)
      add('  ⟳ ' .. t, { { 'JasonConRunning', 2, 3 }, { 'JasonConCmd', 4, -1 } })
    end
    add(string.rep('─', LIST_W), { { 'JasonConSep', 0, -1 } })
  end

  local h = history()
  if #h == 0 then
    add('', {})
    add('  No history yet.', { { 'JasonConDim', 0, -1 } })
    add('  Run a build to see output here.', { { 'JasonConDim', 0, -1 } })
  else
    add(' History', { { 'JasonConSepLbl', 1, -1 } })
    for i, entry in ipairs(h) do
      local is_sel = (i == state.sel)
      local status = entry.success == nil and '⟳' or (entry.success and '✓' or '✗')
      local hl_st  = entry.success == nil and 'JasonConRunning'
          or (entry.success and 'JasonConOk' or 'JasonConFail')
      local title  = (entry.action or entry.cmd or '?')
      local ts     = ago(entry.timestamp)
      local d      = dur(entry.duration)
      local right  = (d ~= '' and (d .. '  ') or '') .. ts
      local avail  = LIST_W - 2 - 2 - #right - 1
      local tdisp  = title:sub(1, math.max(4, avail))
      local pad    = math.max(0, avail - vim.fn.strdisplaywidth(tdisp))
      local ln     = '  ' .. status .. ' ' .. tdisp .. string.rep(' ', pad) .. right
      local li     = #lines
      add(ln, {})
      if is_sel then
        ahr(li, 'JasonConSel')
      else
        hls[#hls + 1] = { line = li, hl = hl_st, cs = 2, ce = 3 }
        hls[#hls + 1] = { line = li, hl = 'JasonConCmd', cs = 4, ce = 4 + #tdisp }
        hls[#hls + 1] = { line = li, hl = 'JasonConTime', cs = LIST_W - #right, ce = -1 }
      end
    end
  end

  add('', {})
  add(string.rep('─', LIST_W), { { 'JasonConSep', 0, -1 } })
  add('  j/k select  r re-run  d dismiss  q quit', { { 'JasonConFooterKey', 0, -1 } })
  add('  <CR>/<Tab> jump to output', { { 'JasonConFooter', 0, -1 } })

  vim.api.nvim_set_option_value('modifiable', true, { buf = state.list_buf })
  vim.api.nvim_buf_set_lines(state.list_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = state.list_buf })
  vim.api.nvim_buf_clear_namespace(state.list_buf, state.ns_list, 0, -1)
  for _, h2 in ipairs(hls) do
    pcall(vim.api.nvim_buf_add_highlight, state.list_buf, state.ns_list, h2.hl, h2.line, h2.cs, h2.ce)
  end
end

local function render_output()
  if not is_valid_buf(state.out_buf) then return end
  local h          = history()
  local entry      = h[state.sel]
  local lines, hls = {}, {}
  local function add(ln, specs)
    lines[#lines + 1] = ln
    for _, s in ipairs(specs or {}) do
      hls[#hls + 1] = { line = #lines - 1, hl = s[1], cs = s[2], ce = s[3] }
    end
  end

  if not entry then
    local running = running_jobs()
    if running and #running > 0 then
      local job = running[1]
      add('  ⟳ ' .. (job.title or job.cmd or 'Running…'), { { 'JasonConRunning', 2, 3 } })
      add('', {})
      if job.output then
        for _, ln in ipairs(job.output) do add('  ' .. ln, {}) end
      else
        add('  (waiting for output…)', { { 'JasonConDim', 0, -1 } })
      end
    else
      add('', {}); add('  No entry selected.', { { 'JasonConDim', 0, -1 } })
    end
  else
    local ok_str = entry.success == nil and '⟳ Running'
        or (entry.success and '✓ Success' or '✗ Failed')
    local ok_hl  = entry.success == nil and 'JasonConRunning'
        or (entry.success and 'JasonConOk' or 'JasonConFail')
    add('  ' .. ok_str .. '  ' .. (entry.action or ''), { { ok_hl, 2, 2 + #ok_str } })
    add('  cmd: ' .. (entry.cmd or '?'), { { 'JasonConCmd', 7, -1 } })
    if entry.timestamp then
      add('  ran: ' .. os.date('%H:%M:%S', entry.timestamp) .. '  ' .. ago(entry.timestamp),
        { { 'JasonConTime', 7, -1 } })
    end
    if entry.duration and entry.duration > 0 then
      add('  dur: ' .. dur(entry.duration), { { 'JasonConDim', 0, -1 } })
    end
    add(string.rep('─', 60), { { 'JasonConSep', 0, -1 } })
    local output = entry.output or {}
    if #output == 0 then
      add('  (no captured output)', { { 'JasonConDim', 0, -1 } })
    else
      for _, ln in ipairs(output) do
        local specs = {}
        if ln:match('%[ERROR%]') or ln:match('^error') or ln:match('FAILED') then
          specs = { { 'JasonConFail', 0, -1 } }
        elseif ln:match('%[WARNING%]') or ln:match('^warning') then
          specs = { { 'JasonConRunning', 0, -1 } }
        elseif ln:match('%[INFO%]') or ln:match('^%s*at ') then
          specs = { { 'JasonConDim', 0, -1 } }
        end
        add('  ' .. ln, specs)
      end
    end
  end

  vim.api.nvim_set_option_value('modifiable', true, { buf = state.out_buf })
  vim.api.nvim_buf_set_lines(state.out_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = state.out_buf })
  vim.api.nvim_buf_clear_namespace(state.out_buf, state.ns_out, 0, -1)
  for _, h2 in ipairs(hls) do
    pcall(vim.api.nvim_buf_add_highlight, state.out_buf, state.ns_out, h2.hl, h2.line, h2.cs, h2.ce)
  end
  if is_valid_win(state.out_win) then
    local e  = history()[state.sel]
    local ti = e and (e.action or 'output') or 'output'
    pcall(vim.api.nvim_win_set_config, state.out_win, {
      title = { { ' ' .. ti .. ' ', 'JasonConOutTitle' } },
    })
  end
end

local function redraw()
  render_list(); render_output()
end

local _hooks_registered = false
local function register_hooks()
  if _hooks_registered then return end
  _hooks_registered = true
  local runner = require('core.runner')
  runner.on_start(function(_entry)
    vim.schedule(function()
      state.sel = 1
      if not state.open then M.open() else redraw() end
    end)
  end)
  runner.on_finish(function(_entry)
    vim.schedule(function()
      if state.open and is_valid_win(state.list_win) then redraw() end
    end)
  end)
end

local function start_timer()
  if state._timer then return end
  state._timer = vim.loop.new_timer()
  state._timer:start(0, 500, vim.schedule_wrap(function()
    if not state.open or not is_valid_win(state.list_win) then
      if state._timer then
        state._timer:stop(); state._timer = nil
      end
      return
    end
    redraw()
  end))
end

local function stop_timer()
  if state._timer then
    state._timer:stop(); state._timer:close(); state._timer = nil
  end
end

function M.close()
  stop_timer()
  state.open = false
  pcall(vim.api.nvim_win_close, state.list_win, true)
  pcall(vim.api.nvim_win_close, state.out_win, true)
  state.list_win = nil; state.out_win = nil
  state.list_buf = nil; state.out_buf = nil
end

function M.open()
  setup_hl()
  if state.open and is_valid_win(state.list_win) then
    M.close(); return
  end
  register_hooks()
  state.open    = true
  local h       = history()
  state.sel     = math.max(1, math.min(state.sel, math.max(1, #h)))

  local screen  = vim.api.nvim_list_uis()[1]
  local H       = screen.height
  local W       = screen.width
  local TOTAL_H = math.floor(H * 0.45)
  local OUT_W   = W - LIST_W - 3
  local ROW     = H - TOTAL_H - 2
  local COL     = 1

  local function mkbuf()
    local b = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = b })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = b })
    vim.api.nvim_set_option_value('swapfile', false, { buf = b })
    vim.api.nvim_set_option_value('modifiable', false, { buf = b })
    return b
  end
  state.list_buf = mkbuf()
  state.out_buf  = mkbuf()

  local common   = {
    relative = 'editor',
    height = TOTAL_H,
    row = ROW,
    style = 'minimal',
    zindex = 45,
    border = 'single',
  }
  state.list_win = vim.api.nvim_open_win(state.list_buf, true,
    vim.tbl_extend('force', common, {
      width = LIST_W,
      col = COL,
      title = { { ' Jason Console ', 'JasonConTitle' } },
      title_pos = 'center',
    }))
  state.out_win  = vim.api.nvim_open_win(state.out_buf, false,
    vim.tbl_extend('force', common, {
      width = OUT_W,
      col = COL + LIST_W + 1,
      title = { { ' output ', 'JasonConOutTitle' } },
      title_pos = 'left',
    }))

  local function setwhl(w, n, b2)
    vim.api.nvim_set_option_value('winhl', 'Normal:' .. n .. ',FloatBorder:' .. b2, { win = w })
  end
  setwhl(state.list_win, 'JasonConWin', 'JasonConBorder')
  setwhl(state.out_win, 'JasonConOutWin', 'JasonConOutBorder')

  local base_wopts = {
    wrap = false,
    number = false,
    relativenumber = false,
    signcolumn = 'no',
    scrolloff = 2,
    cursorline = false
  }
  for k, v in pairs(base_wopts) do
    pcall(vim.api.nvim_set_option_value, k, v, { win = state.list_win })
    pcall(vim.api.nvim_set_option_value, k, v, { win = state.out_win })
  end
  pcall(vim.api.nvim_set_option_value, 'wrap', true, { win = state.out_win })

  local mo = { noremap = true, silent = true, buffer = state.list_buf }

  local function nav_h(n)
    local hh = history()
    if #hh == 0 then return end
    state.sel = math.max(1, math.min(state.sel + n, #hh))
    redraw()
  end
  local function focus_output()
    if is_valid_win(state.out_win) then vim.api.nvim_set_current_win(state.out_win) end
  end
  local function rerun_sel()
    local hh = history(); local e = hh[state.sel]
    if not e then return end
    local p = require('marvin.detector').get()
    if not p then return end
    require('marvin.build').custom(e.cmd, e.action)
  end
  local function dismiss_sel()
    local hh = history()
    if #hh == 0 then return end
    table.remove(hh, state.sel)
    state.sel = math.max(1, math.min(state.sel, #hh))
    redraw()
  end

  vim.keymap.set('n', 'j', function() nav_h(1) end, mo)
  vim.keymap.set('n', 'k', function() nav_h(-1) end, mo)
  vim.keymap.set('n', '<Down>', function() nav_h(1) end, mo)
  vim.keymap.set('n', '<Up>', function() nav_h(-1) end, mo)
  vim.keymap.set('n', '<C-d>', function() nav_h(5) end, mo)
  vim.keymap.set('n', '<C-u>', function() nav_h(-5) end, mo)
  vim.keymap.set('n', '<CR>', focus_output, mo)
  vim.keymap.set('n', '<Tab>', focus_output, mo)
  vim.keymap.set('n', 'r', rerun_sel, mo)
  vim.keymap.set('n', 'd', dismiss_sel, mo)
  vim.keymap.set('n', 'q', M.close, mo)
  vim.keymap.set('n', '<Esc>', M.close, mo)

  local omo = { noremap = true, silent = true, buffer = state.out_buf }
  vim.keymap.set('n', 'q', M.close, omo)
  vim.keymap.set('n', '<Esc>', M.close, omo)
  vim.keymap.set('n', 'r', rerun_sel, omo)
  vim.keymap.set('n', '<Tab>', function()
    if is_valid_win(state.list_win) then vim.api.nvim_set_current_win(state.list_win) end
  end, omo)

  vim.api.nvim_create_autocmd('WinClosed', {
    pattern  = tostring(state.list_win) .. ',' .. tostring(state.out_win),
    once     = false,
    callback = function(ev)
      local closed = tonumber(ev.match)
      if closed == state.list_win or closed == state.out_win then
        vim.defer_fn(function()
          if not is_valid_win(state.list_win) or not is_valid_win(state.out_win) then
            M.close()
          end
        end, 10)
      end
    end,
  })

  redraw()
  start_timer()
end

function M.toggle() M.open() end

function M.show_for(action_id)
  local h = history()
  for i, e in ipairs(h) do
    if e.action_id == action_id then
      state.sel = i; break
    end
  end
  M.open()
end

function M.on_job_event()
  if state.open and is_valid_win(state.list_win) then vim.schedule(redraw) end
end

return M
