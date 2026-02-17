-- lua/marvin/ui.lua
local M = {}
M.backend = nil

local C = {
  bg       = '#1e1e2e',
  bg3      = '#11111b',
  surface0 = '#313244',
  surface1 = '#45475a',
  surface2 = '#585b70',
  text     = '#cdd6f4',
  sub1     = '#bac2de',
  sub0     = '#a6adc8',
  ov0      = '#6c7086',
  ov1      = '#7f849c',
  blue     = '#89b4fa',
  mauve    = '#cba6f7',
  green    = '#a6e3a1',
  yellow   = '#f9e2af',
  peach    = '#fab387',
  red      = '#f38ba8',
  sky      = '#89dceb',
}

local function setup_highlights()
  local function hl(n, o) vim.api.nvim_set_hl(0, n, o) end
  hl('MarvinWin', { bg = C.bg, fg = C.text })
  hl('MarvinBorder', { fg = C.surface1, bg = C.bg })
  hl('MarvinTitle', { fg = C.mauve, bold = true })
  hl('MarvinSelected', { bg = C.mauve, fg = C.bg, bold = true })
  hl('MarvinItem', { fg = C.sub1 })
  hl('MarvinItemIcon', { fg = C.text })
  hl('MarvinDesc', { fg = C.ov0 })
  hl('MarvinSepLine', { fg = C.surface1 })
  hl('MarvinSepLabel', { fg = C.ov1, italic = true })
  hl('MarvinSearch', { fg = C.sky, bold = true })
  hl('MarvinSearchBox', { fg = C.ov0 })
  hl('MarvinFooter', { fg = C.ov0 })
  hl('MarvinFooterKey', { fg = C.peach, bold = true })
  hl('MarvinBadge', { fg = C.yellow })
  hl('MarvinHiddenCursor', { fg = C.bg, bg = C.bg, blend = 100 })
  hl('MarvinInputText', { fg = C.sky })
  hl('MarvinInputHint', { fg = C.ov0 })
end

function M.init()
  local cfg = require('marvin').config
  M.backend = cfg.ui_backend == 'auto' and M.detect_backend() or cfg.ui_backend
  setup_highlights()
end

function M.detect_backend()
  if pcall(require, 'snacks') then
    return 'snacks'
  elseif pcall(require, 'dressing') then
    return 'dressing'
  else
    return 'builtin'
  end
end

-- Fuzzy match
local function fuzzy(str, pat)
  if pat == '' then return true, 0 end
  str = str:lower(); pat = pat:lower()
  local sc, s, p, con = 0, 1, 1, 0
  while p <= #pat and s <= #str do
    if str:sub(s, s) == pat:sub(p, p) then
      sc = sc + 1 + con * 5; con = con + 1; p = p + 1
    else
      con = 0
    end
    s = s + 1
  end
  if p > #pat then
    if str:sub(1, #pat) == pat then sc = sc + 20 end
    return true, sc
  end
  return false, 0
end

-- Main select
function M.select(items, opts, callback)
  opts                = opts or {}
  local prompt        = opts.prompt or 'Select'
  local enable_search = opts.enable_search ~= false
  local on_back       = opts.on_back or nil
  local format_fn     = opts.format_item or function(item)
    return type(item) == 'table' and (item.label or item.name or tostring(item)) or tostring(item)
  end

  -- Pre-format — icon is stored separately so we can highlight it independently
  local all           = {}
  for i, item in ipairs(items) do
    all[i] = {
      idx     = i,
      item    = item,
      display = format_fn(item),
      icon    = type(item) == 'table' and item.icon or nil,
      desc    = type(item) == 'table' and item.desc or nil,
      badge   = type(item) == 'table' and item.badge or nil,
      is_sep  = type(item) == 'table' and (item.is_separator == true) or false,
    }
  end

  local vis    = vim.deepcopy(all)
  local search = ''
  local screen = vim.api.nvim_list_uis()[1]

  -- Layout
  local LIST_W = math.min(80, math.max(60, math.floor(screen.width * 0.55)))

  local function sel_total()
    local n = 0
    for _, f in ipairs(vis) do if not f.is_sep then n = n + 1 end end
    return n
  end

  local function content_lines()
    local n = #vis
    n = n + (enable_search and 3 or 1)
    n = n + 4
    return n
  end

  local function win_h()
    return math.max(10, math.min(content_lines(), math.floor(screen.height * 0.82)))
  end

  local WIN_H = win_h()
  local ROW   = math.floor((screen.height - WIN_H) / 2)
  local COL   = math.floor((screen.width - LIST_W) / 2)

  -- Buffer
  local lbuf  = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = lbuf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = lbuf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = lbuf })
  vim.api.nvim_set_option_value('modifiable', false, { buf = lbuf })

  -- Hide cursor
  local saved_gc = vim.o.guicursor
  vim.o.guicursor = 'a:MarvinHiddenCursor'

  -- Window
  local lwin = vim.api.nvim_open_win(lbuf, true, {
    relative  = 'editor',
    width     = LIST_W,
    height    = WIN_H,
    row       = ROW,
    col       = COL,
    style     = 'minimal',
    zindex    = 50,
    border    = 'single',
    title     = { { ' ' .. prompt .. ' ', 'MarvinTitle' } },
    title_pos = 'left',
  })
  vim.api.nvim_set_option_value('winhl',
    'Normal:MarvinWin,FloatBorder:MarvinBorder', { win = lwin })
  for k, v in pairs({
    cursorline = false, wrap = false,
    number = false, relativenumber = false,
    signcolumn = 'no', scrolloff = 0,
  }) do vim.api.nvim_set_option_value(k, v, { win = lwin }) end

  -- State
  local ns      = vim.api.nvim_create_namespace('marvin_select')
  local sel_pos = 1
  local vt      = 1

  local function visible_rows()
    local header = enable_search and 3 or 1
    local footer = 4
    return math.max(1, WIN_H - header - footer)
  end

  local function desc_col()
    local mx = 0
    for _, f in ipairs(vis) do
      if not f.is_sep and f.desc then
        -- account for caret (3) + icon (2 if present) + label
        local w = 3 + (f.icon and 2 or 0) + vim.fn.strdisplaywidth(f.display)
        mx = math.max(mx, w + 2)
      end
    end
    return math.min(mx, math.floor((LIST_W - 2) * 0.55))
  end

  local function redraw()
    local lines, hls = {}, {}
    local VR         = visible_rows()
    local total      = sel_total()
    local DC         = desc_col()

    local function ahl(l, h, cs, ce)
      hls[#hls + 1] = { line = l, hl = h, cs = cs, ce = ce }
    end

    sel_pos = math.max(1, math.min(sel_pos, math.max(1, total)))
    if sel_pos < vt then vt = sel_pos end
    if sel_pos > vt + VR - 1 then vt = sel_pos - VR + 1 end
    vt = math.max(1, vt)

    -- Search bar
    if enable_search then
      if search == '' then
        lines[#lines + 1] = '  _'
        ahl(#lines - 1, 'MarvinSearchBox', 0, -1)
      else
        lines[#lines + 1] = '  ' .. search .. '_'
        ahl(#lines - 1, 'MarvinSearch', 0, -1)
      end
      lines[#lines + 1] = string.rep('-', LIST_W)
      ahl(#lines - 1, 'MarvinSepLine', 0, -1)
      lines[#lines + 1] = ''
    else
      lines[#lines + 1] = ''
    end

    if #vis == 0 then
      lines[#lines + 1] = '  No matches found'
      ahl(#lines - 1, 'MarvinDesc', 0, -1)
    else
      local view_end  = math.min(vt + VR - 1, total)
      local show_up   = vt > 1
      local show_down = view_end < total
      local rank      = 0

      for _, f in ipairs(vis) do
        if f.is_sep then
          local ln          = #lines
          local t           = ' ' .. f.display .. ' '
          local tw          = vim.fn.strdisplaywidth(t)
          local rem         = math.max(0, LIST_W - tw)
          local ll          = math.floor(rem / 2)
          local lr          = rem - ll
          lines[#lines + 1] = string.rep('-', ll) .. t .. string.rep('-', lr)
          ahl(ln, 'MarvinSepLine', 0, -1)
          ahl(ln, 'MarvinSepLabel', ll, ll + tw)
        else
          rank = rank + 1
          if rank >= vt and rank <= view_end then
            local is_sel     = (rank == sel_pos)
            local caret      = is_sel and '>> ' or '   '
            local icon_str   = f.icon and (f.icon .. ' ') or ''
            local label      = f.display
            local lw         = vim.fn.strdisplaywidth(label)
            local iw         = vim.fn.strdisplaywidth(icon_str)
            local body_start = #caret + iw -- byte offset where label starts

            local body
            if f.desc then
              local used = #caret + iw + lw
              local gap  = math.max(1, DC - (#caret + iw + lw))
              body       = icon_str .. label .. string.rep(' ', gap) .. '* ' .. f.desc
            else
              body = icon_str .. label
            end
            if f.badge then body = body .. '  ' .. f.badge end

            local row = caret .. body
            local rw  = vim.fn.strdisplaywidth(row)
            if rw < LIST_W - 2 then
              row = row .. string.rep(' ', LIST_W - 2 - rw)
            end

            local ln = #lines
            lines[#lines + 1] = row

            if is_sel then
              ahl(ln, 'MarvinSelected', 0, -1)
            else
              -- icon highlight
              if f.icon then
                ahl(ln, 'MarvinItemIcon', #caret, #caret + iw)
              end
              -- label highlight
              ahl(ln, 'MarvinItem', #caret + iw, #caret + iw + lw)
              if f.desc then
                local dc = DC + 2 -- past the '* '
                ahl(ln, 'MarvinDesc', dc, -1)
              end
              if f.badge then
                ahl(ln, 'MarvinBadge', -vim.fn.strdisplaywidth(f.badge) - 2, -1)
              end
            end

            if rank == vt and show_up then
              ahl(ln, 'MarvinFooter', LIST_W - 3, LIST_W - 2)
            end
            if rank == view_end and show_down then
              ahl(ln, 'MarvinFooter', LIST_W - 3, LIST_W - 2)
            end
          end
        end
      end
    end

    -- Footer
    lines[#lines + 1] = string.rep('-', LIST_W)
    ahl(#lines - 1, 'MarvinSepLine', 0, -1)
    local info = string.format('  %d/%d items', sel_pos, total)
    if search ~= '' then info = info .. '  "' .. search .. '"' end
    lines[#lines + 1] = info
    ahl(#lines - 1, 'MarvinFooter', 0, -1)
    local hint = '  j/k Navigate | <CR> Select | <Esc> Cancel'
    if on_back then hint = hint .. ' | <BS> Back' end
    lines[#lines + 1] = hint
    ahl(#lines - 1, 'MarvinFooterKey', 0, -1)

    vim.api.nvim_set_option_value('modifiable', true, { buf = lbuf })
    vim.api.nvim_buf_set_lines(lbuf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = lbuf })
    vim.api.nvim_buf_clear_namespace(lbuf, ns, 0, -1)
    for _, h in ipairs(hls) do
      pcall(vim.api.nvim_buf_add_highlight, lbuf, ns, h.hl, h.line, h.cs, h.ce)
    end
    pcall(vim.api.nvim_win_set_cursor, lwin, { 1, 0 })
  end

  -- Navigation
  local function move(d)
    local total = sel_total()
    if total == 0 then return end
    if d == 'dn' then
      sel_pos = sel_pos % total + 1
    elseif d == 'up' then
      sel_pos = sel_pos - 1; if sel_pos < 1 then sel_pos = total end
    elseif d == 'pgd' then
      sel_pos = math.min(sel_pos + 8, total)
    elseif d == 'pgu' then
      sel_pos = math.max(sel_pos - 8, 1)
    elseif d == 'top' then
      sel_pos = 1
    elseif d == 'bot' then
      sel_pos = total
    end
    redraw()
  end

  local function do_search(c)
    if c == '<BS>' then
      search = search:sub(1, -2)
    elseif c == '<C-u>' then
      search = ''
    else
      search = search .. c
    end
    vis = {}
    for _, f in ipairs(all) do
      if f.is_sep then
        if search == '' then vis[#vis + 1] = vim.deepcopy(f) end
      else
        local ok, sc = fuzzy(f.display, search)
        if ok then
          local fc = vim.deepcopy(f); fc.score = sc; vis[#vis + 1] = fc
        end
      end
    end
    if search ~= '' then
      table.sort(vis, function(a, b) return (a.score or 0) > (b.score or 0) end)
    end
    sel_pos = 1; vt = 1
    local nh = win_h()
    pcall(vim.api.nvim_win_set_height, lwin, nh)
    redraw()
  end

  local function close()
    vim.o.guicursor = saved_gc
    pcall(vim.api.nvim_win_close, lwin, true)
  end

  local function pick()
    local rank = 0
    for _, f in ipairs(vis) do
      if not f.is_sep then
        rank = rank + 1
        if rank == sel_pos then
          local chosen = f.item; close(); callback(chosen); return
        end
      end
    end
  end

  -- Keymaps
  local mo = { noremap = true, silent = true, buffer = lbuf }
  vim.keymap.set('n', 'j', function() move('dn') end, mo)
  vim.keymap.set('n', 'k', function() move('up') end, mo)
  vim.keymap.set('n', '<Down>', function() move('dn') end, mo)
  vim.keymap.set('n', '<Up>', function() move('up') end, mo)
  vim.keymap.set('n', '<C-d>', function() move('pgd') end, mo)
  vim.keymap.set('n', '<C-u>', function() move('pgu') end, mo)
  vim.keymap.set('n', '<C-n>', function() move('dn') end, mo)
  vim.keymap.set('n', '<C-p>', function() move('up') end, mo)
  vim.keymap.set('n', 'G', function() move('bot') end, mo)
  vim.keymap.set('n', 'gg', function() move('top') end, mo)
  vim.keymap.set('n', '<CR>', pick, mo)
  vim.keymap.set('n', '<Space>', pick, mo)
  vim.keymap.set('n', 'l', pick, mo)
  vim.keymap.set('n', '<Esc>', function()
    close(); callback(nil)
  end, mo)
  vim.keymap.set('n', 'q', function()
    close(); callback(nil)
  end, mo)
  vim.keymap.set('n', '<BS>', function()
    if on_back and search == '' then
      close(); on_back()
    elseif enable_search then
      do_search('<BS>')
    end
  end, mo)

  if enable_search then
    local nav = { j = true, k = true, q = true, l = true, G = true, g = true }
    vim.keymap.set('n', '<C-u>', function() do_search('<C-u>') end, mo)
    for i = 32, 126 do
      local c = string.char(i)
      if not nav[c] then
        vim.keymap.set('n', c, function() do_search(c) end, mo)
      end
    end
  end

  for _, k in ipairs({ 'i', 'I', 'a', 'A', 'o', 'O', 'c', 'C', 's', 'S' }) do
    vim.keymap.set('n', k, '<Nop>', mo)
  end

  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = lbuf,
    once = true,
    callback = function() vim.o.guicursor = saved_gc end,
  })

  redraw()
end

-- Input popup
function M.input(opts, cb)
  opts          = opts or {}
  local prompt  = opts.prompt or 'Input'
  local default = opts.default or ''
  local screen  = vim.api.nvim_list_uis()[1]
  local W       = math.min(60, math.floor(screen.width * 0.5))
  local ROW     = math.floor((screen.height - 4) / 2)
  local COL     = math.floor((screen.width - W) / 2)

  local ibuf    = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = ibuf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = ibuf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = ibuf })

  local iwin = vim.api.nvim_open_win(ibuf, true, {
    relative = 'editor',
    width = W,
    height = 4,
    row = ROW,
    col = COL,
    style = 'minimal',
    border = 'single',
    title = { { ' ' .. prompt .. ' ', 'MarvinTitle' } },
    title_pos = 'left',
    zindex = 60,
  })
  vim.api.nvim_set_option_value('winhl',
    'Normal:MarvinWin,FloatBorder:MarvinBorder', { win = iwin })

  vim.api.nvim_buf_set_lines(ibuf, 0, -1, false, {
    '', '  ' .. default, '',
    '  <CR> confirm | <Esc> cancel',
  })
  local ns = vim.api.nvim_create_namespace('marvin_input')
  vim.api.nvim_buf_add_highlight(ibuf, ns, 'MarvinInputText', 1, 0, -1)
  vim.api.nvim_buf_add_highlight(ibuf, ns, 'MarvinInputHint', 3, 0, -1)
  vim.api.nvim_win_set_cursor(iwin, { 2, #default + 2 })
  vim.schedule(function() vim.cmd('startinsert!') end)

  local function submit()
    local text = vim.trim(vim.api.nvim_buf_get_lines(ibuf, 1, 2, false)[1] or '')
    pcall(vim.api.nvim_win_close, iwin, true)
    cb(text ~= '' and text or nil)
  end
  local function cancel()
    pcall(vim.api.nvim_win_close, iwin, true); cb(nil)
  end

  local mo = { noremap = true, silent = true, buffer = ibuf }
  vim.keymap.set('i', '<CR>', submit, mo)
  vim.keymap.set('i', '<Esc>', cancel, mo)
  vim.keymap.set('i', '<C-c>', cancel, mo)
  vim.keymap.set('n', '<CR>', submit, mo)
  vim.keymap.set('n', '<Esc>', cancel, mo)
  vim.keymap.set('n', 'q', cancel, mo)
  vim.keymap.set('i', '<Up>', '<Nop>', mo)
  vim.keymap.set('i', '<Down>', '<Nop>', mo)
end

function M.notify(msg, level, opts)
  opts  = opts or {}
  level = level or vim.log.levels.INFO
  if M.backend == 'snacks' then
    local ok, snacks = pcall(require, 'snacks')
    if ok then
      local lm = { [vim.log.levels.ERROR] = 'error', [vim.log.levels.WARN] = 'warn', [vim.log.levels.INFO] = 'info' }
      snacks.notify(msg, { level = lm[level] or 'info', title = opts.title or 'Marvin' })
      return
    end
  end
  vim.notify(msg, level, { title = opts.title or 'Marvin' })
end

-- Maven goal menu
function M.show_goal_menu(on_back)
  local project = require('marvin.project')
  if not project.validate_environment() then return end
  M.select(M.get_common_goals(), {
    prompt        = 'Maven Goal',
    on_back       = on_back,
    enable_search = true,
    format_item   = function(g) return g.label end,
  }, function(choice)
    if not choice then return end
    if choice.needs_profile then
      M.show_profile_menu(choice.goal, function() M.show_goal_menu(on_back) end)
    elseif choice.needs_options then
      M.show_options_menu()
    else
      require('marvin.executor').run(choice.goal)
    end
  end)
end

function M.get_common_goals()
  return {
    { label = 'Build Lifecycle', is_separator = true },
    { goal = 'clean', label = 'Clean', icon = '󰃢 ', desc = 'Delete target/ directory' },
    { goal = 'compile', label = 'Compile', icon = '󰑕 ', desc = 'Compile source code' },
    { goal = 'test', label = 'Test', icon = '󰙨 ', desc = 'Run unit tests' },
    { goal = 'package', label = 'Package', icon = '󰏗 ', desc = 'Create JAR/WAR file' },
    { goal = 'verify', label = 'Verify', icon = '󰄬 ', desc = 'Run integration tests' },
    { goal = 'install', label = 'Install', icon = '󰇚 ', desc = 'Install to ~/.m2/repository' },
    { label = 'Common Tasks', is_separator = true },
    { goal = 'clean install', label = 'Clean & Install', icon = '󰑓 ', desc = 'Full rebuild and install' },
    { goal = 'clean package', label = 'Clean & Package', icon = '󰑓 ', desc = 'Fresh build to JAR' },
    { goal = 'test -DskipTests', label = 'Skip Tests', icon = '󰒭 ', desc = 'Build without running tests' },
    { label = 'Dependencies', is_separator = true },
    { goal = 'dependency:tree', label = 'Dependency Tree', icon = '󰙅 ', desc = 'Show full dependency graph' },
    { goal = 'dependency:resolve', label = 'Resolve Deps', icon = '󰚰 ', desc = 'Download all dependencies' },
    { goal = 'dependency:analyze', label = 'Analyze Deps', icon = '󰍉 ', desc = 'Find unused/undeclared deps' },
    { goal = 'versions:display-dependency-updates', label = 'Check for Updates', icon = '󰚰 ', desc = 'Find newer dependency versions' },
    { label = 'Information', is_separator = true },
    { goal = 'help:effective-pom', label = 'Effective POM', icon = '󰈙 ', desc = 'Show resolved configuration' },
    { goal = 'help:effective-settings', label = 'Effective Settings', icon = '󰈙', desc = 'Show Maven settings' },
    { label = 'Custom', is_separator = true },
    { goal = nil, label = 'Custom Goal', icon = '', desc = 'Enter any Maven command', needs_options = true },
  }
end

function M.show_profile_menu(goal, on_back)
  local project = require('marvin.project').get_project()
  if not project or not project.info or #project.info.profiles == 0 then
    vim.notify('No profiles found in pom.xml', vim.log.levels.WARN)
    require('marvin.executor').run(goal); return
  end
  local profiles = { { id = nil, label = '(default)', icon = '', desc = 'No profile selected' } }
  for _, pid in ipairs(project.info.profiles) do
    profiles[#profiles + 1] = { id = pid, label = pid, icon = '', desc = 'Maven profile' }
  end
  M.select(profiles, { prompt = 'Select Profile', on_back = on_back }, function(choice)
    if choice then require('marvin.executor').run(goal, { profile = choice.id }) end
  end)
end

function M.show_options_menu()
  M.input({ prompt = 'Maven goal(s)' }, function(custom_goal)
    if not custom_goal or custom_goal == '' then return end
    M.input({ prompt = 'Additional options (optional)' }, function(extra)
      local full = custom_goal
      if extra and extra ~= '' then full = full .. ' ' .. extra end
      require('marvin.executor').run(full)
    end)
  end)
end

return M
