-- lua/jason/ui.lua
local M = {}
M.backend = nil

local C = {
  bg       = '#1e1e2e',
  bg2      = '#181825',
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
  lavender = '#b4befe',
  green    = '#a6e3a1',
  yellow   = '#f9e2af',
  peach    = '#fab387',
  red      = '#f38ba8',
  sky      = '#89dceb',
  teal     = '#94e2d5',
  pink     = '#f5c2e7',
}

local function setup_highlights()
  local function hl(n, o) vim.api.nvim_set_hl(0, n, o) end
  hl('JasonWin', { bg = C.bg, fg = C.text })
  hl('JasonBorder', { fg = C.surface1, bg = C.bg })
  hl('JasonTitle', { fg = C.mauve, bold = true })
  hl('JasonCursorLine', { bg = C.surface0, fg = C.text })
  hl('JasonSelected', { bg = C.mauve, fg = C.bg, bold = true })
  hl('JasonItem', { fg = C.sub1 })
  hl('JasonItemIcon', { fg = C.text })
  hl('JasonDesc', { fg = C.ov0 })
  hl('JasonSepLine', { fg = C.surface1 })
  hl('JasonSepLabel', { fg = C.ov1, italic = true })
  hl('JasonSearch', { fg = C.sky, bold = true })
  hl('JasonSearchBox', { fg = C.ov0 })
  hl('JasonFooter', { fg = C.ov0 })
  hl('JasonFooterKey', { fg = C.peach, bold = true })
  hl('JasonBadge', { fg = C.yellow })
  hl('JasonPrevWin', { bg = C.bg3, fg = C.text })
  hl('JasonPrevBorder', { fg = C.surface0, bg = C.bg3 })
  hl('JasonPrevTitle', { fg = C.blue, bold = true })
  hl('JasonPrevHdr', { fg = C.blue, bold = true })
  hl('JasonPrevSep', { fg = C.surface1 })
  hl('JasonGitHash', { fg = C.mauve })
  hl('JasonGitDate', { fg = C.ov0 })
  hl('JasonGitAuthor', { fg = C.peach })
  hl('JasonGitMsg', { fg = C.sub1 })
  hl('JasonBranch', { fg = C.green, bold = true })
  hl('JasonDirty', { fg = C.yellow })
  hl('JasonFileDir', { fg = C.blue })
  hl('JasonFileNorm', { fg = C.sub0 })
  hl('JasonFileExe', { fg = C.green })
  hl('JasonDiffAdd', { fg = C.green })
  hl('JasonDiffDel', { fg = C.red })
  hl('JasonDiffMod', { fg = C.yellow })
  hl('JasonTreeConn', { fg = C.surface2 })
end

function M.init()
  local cfg = require('jason').config
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

-- Git helpers
local function git(root, args)
  local out = vim.fn.system(
    'git -C ' .. vim.fn.shellescape(root) .. ' ' .. args .. ' 2>/dev/null')
  return vim.v.shell_error == 0, vim.trim(out)
end

-- File tree (neo-tree style ASCII connectors)
local SKIP = {
  ['.git'] = true,
  ['node_modules'] = true,
  ['target'] = true,
  ['build'] = true,
  ['.gradle'] = true,
  ['__pycache__'] = true,
  ['.idea'] = true,
  ['.vscode'] = true,
  ['dist'] = true,
  ['out'] = true,
}

local function build_tree(dir, prefix, depth, max_depth, results)
  results = results or {}
  if depth > max_depth then return results end

  local ok, ents = pcall(vim.fn.readdir, dir)
  if not ok or type(ents) ~= 'table' then return results end

  table.sort(ents, function(a, b)
    local ad = vim.fn.isdirectory(dir .. '/' .. a) == 1
    local bd = vim.fn.isdirectory(dir .. '/' .. b) == 1
    local ah = a:sub(1, 1) == '.'
    local bh = b:sub(1, 1) == '.'
    if ah ~= bh then return bh end
    if ad ~= bd then return ad end
    return a < b
  end)

  local visible = {}
  for _, name in ipairs(ents) do
    if not SKIP[name] and (depth == 1 or name:sub(1, 1) ~= '.') then
      visible[#visible + 1] = name
    end
  end

  local cap = 12
  local shown = 0
  for i, name in ipairs(visible) do
    if shown >= cap then
      local conn = prefix .. '+- '
      results[#results + 1] = {
        text     = conn .. '... ' .. (#visible - cap) .. ' more',
        conn_end = #conn,
        is_dir   = false,
        is_exe   = false,
        overflow = true,
      }
      break
    end
    shown                 = shown + 1

    local is_last         = (i == #visible or shown == cap)
    local fp              = dir .. '/' .. name
    local is_dir          = vim.fn.isdirectory(fp) == 1
    local is_exe          = not is_dir and vim.fn.executable(fp) == 1
    local icon            = is_dir and '[d] ' or '[f] '
    local branch          = is_last and '`- ' or '+- '
    local conn            = prefix .. branch
    local text            = conn .. icon .. name .. (is_dir and '/' or '')

    results[#results + 1] = {
      text     = text,
      conn_end = #conn,
      is_dir   = is_dir,
      is_exe   = is_exe,
    }

    if is_dir and depth < max_depth then
      local child_pfx = prefix .. (is_last and '  ' or '| ')
      build_tree(fp, child_pfx, depth + 1, max_depth, results)
    end
  end

  return results
end

-- Build preview content
local function build_preview(project, width)
  local root = project and project.root
  local lines, hls = {}, {}

  local function add(ln, specs)
    lines[#lines + 1] = ln
    if specs then
      for _, s in ipairs(specs) do
        hls[#hls + 1] = { line = #lines - 1, hl = s[1], cs = s[2], ce = s[3] }
      end
    end
  end

  local function hr()
    add(string.rep('-', width), { { 'JasonPrevSep', 0, -1 } })
  end

  local function hdr(t)
    add(t, { { 'JasonPrevHdr', 0, -1 } })
  end

  local IND = ' '

  if not root then
    add(IND .. 'No project.', { { 'JasonDesc', 0, -1 } })
    return lines, hls
  end

  -- Branch line (no leading blank)
  local gok, branch = git(root, 'branch --show-current')
  local is_git = gok and branch ~= ''

  if is_git then
    local _, st = git(root, 'status --porcelain')
    local dirty = st ~= ''
    local sign  = dirty and ' ~ dirty' or ' + clean'
    local shl   = dirty and 'JasonDirty' or 'JasonBranch'
    local pfx   = IND .. '@ '
    local ln    = pfx .. branch .. sign
    add(ln, {
      { 'JasonDesc',   0,              #pfx },
      { 'JasonBranch', #pfx,           #pfx + #branch },
      { shl,           #pfx + #branch, -1 },
    })
  else
    add(IND .. 'Not a git repository', { { 'JasonDesc', 0, -1 } })
  end

  if is_git then
    -- Commits (max 5, tighter format)
    hdr('Commits'); hr()
    local ok2, log = git(root, 'log --format=">>>%h|%ar|%an|%s" -5')
    if ok2 and log ~= '' then
      for entry in log:gmatch('>>>([^\n]+)') do
        local h, d, a, m = entry:match('([^|]+)|([^|]+)|([^|]+)|(.+)')
        if h then
          -- Shorten date: "2 weeks ago" -> "2w", "31 hours ago" -> "31h"
          local ds  = d:gsub(' hours? ago', 'h'):gsub(' days? ago', 'd')
              :gsub(' weeks? ago', 'w'):gsub(' months? ago', 'mo')
              :gsub(' minutes? ago', 'm'):gsub('just now', 'now')
          ds        = ds:sub(1, 5)
          -- Author: first 7 chars
          local as  = a:sub(1, 7)
          local pre = IND .. h .. ' ' .. ds .. ' ' .. as .. ' '
          local pw  = vim.fn.strdisplaywidth(pre)
          local ms  = m:sub(1, math.max(2, width - pw - 1))
          local p1  = #IND
          local p2  = p1 + #h
          local p3  = p2 + 1 + #ds
          local p4  = p3 + 1 + #as
          add(pre .. ms, {
            { 'JasonGitHash',   p1,     p2 },
            { 'JasonGitDate',   p2 + 1, p3 },
            { 'JasonGitAuthor', p3 + 1, p4 },
            { 'JasonGitMsg',    p4 + 1, -1 },
          })
        end
      end
    else
      add(IND .. '(no commits)', { { 'JasonDesc', 0, -1 } })
    end

    -- Diff stat (no blank line before)
    local _, diff = git(root, 'diff --stat HEAD')
    if diff ~= '' then
      hdr('Changes'); hr()
      for ln in (diff .. '\n'):gmatch('([^\n]+)\n') do
        local t = vim.trim(ln)
        if t ~= '' then
          local hg
          if t:match('^%d+%s+files?') then
            hg = 'JasonDesc'
          elseif t:match('%+') and t:match('%-') then
            hg = 'JasonDiffMod'
          elseif t:match('%+') then
            hg = 'JasonDiffAdd'
          else
            hg = 'JasonDiffDel'
          end
          add(IND .. t, { { hg, 0, -1 } })
        end
      end
    end
  end

  hdr('Files'); hr()

  -- .gitignore entry if it exists
  local gitignore = root .. '/.gitignore'
  if vim.fn.filereadable(gitignore) == 1 then
    add(IND .. '[f] .gitignore', { { 'JasonFileNorm', 0, -1 } })
  end

  -- Tree rooted at src/
  local src = root .. '/src'
  local tree = vim.fn.isdirectory(src) == 1
      and build_tree(src, IND, 1, 4)
      or {}

  -- Prepend a synthetic src/ root entry if it exists
  if vim.fn.isdirectory(src) == 1 then
    add(IND .. '[d] src/', { { 'JasonFileDir', 0, -1 } })
    -- indent the tree one level so it hangs under src/
    for _, node in ipairs(tree) do
      node.text     = '  ' .. node.text
      node.conn_end = node.conn_end + 2
    end
  end

  for _, node in ipairs(tree) do
    local ge = node.conn_end
    if node.overflow then
      add(node.text, { { 'JasonDesc', 0, -1 } })
    elseif node.is_dir then
      add(node.text, { { 'JasonTreeConn', 0, ge }, { 'JasonFileDir', ge, -1 } })
    elseif node.is_exe then
      add(node.text, { { 'JasonTreeConn', 0, ge }, { 'JasonFileExe', ge, -1 } })
    else
      add(node.text, { { 'JasonTreeConn', 0, ge }, { 'JasonFileNorm', ge, -1 } })
    end
  end

  return lines, hls
end

-- Main select
function M.select(items, opts, callback)
  opts                = opts or {}
  local prompt        = opts.prompt or 'Select'
  local enable_search = opts.enable_search ~= false
  local show_preview  = opts.show_preview == true
  local project       = opts.project
  local format_fn     = opts.format_item or function(item)
    return type(item) == 'table' and (item.label or tostring(item)) or tostring(item)
  end

  local all           = {}
  for i, item in ipairs(items) do
    all[i] = {
      idx     = i,
      item    = item,
      display = format_fn(item),
      desc    = type(item) == 'table' and item.desc or nil,
      badge   = type(item) == 'table' and item.badge or nil,
      is_sep  = type(item) == 'table' and (item.is_separator == true) or false,
    }
  end

  local vis     = vim.deepcopy(all)
  local search  = ''
  local screen  = vim.api.nvim_list_uis()[1]

  -- Layout
  local PREV_W  = show_preview and 48 or 0
  local LIST_W  = math.min(80, math.floor(screen.width * 0.55))
  local TOTAL_W = LIST_W + (show_preview and PREV_W + 1 or 0)
  TOTAL_W       = math.min(TOTAL_W, screen.width - 4)
  if show_preview then PREV_W = TOTAL_W - LIST_W - 1 end
  local INNER = LIST_W - 4

  local function content_lines(v)
    local n = #v
    n = n + (enable_search and 4 or 1)
    n = n + 5
    return n
  end

  local function win_h()
    return math.max(14, math.min(content_lines(vis), math.floor(screen.height * 0.82)))
  end

  local WIN_H = win_h()
  local ROW   = math.floor((screen.height - WIN_H) / 2)
  local COL   = math.floor((screen.width - TOTAL_W) / 2)

  -- Buffers
  local lbuf  = vim.api.nvim_create_buf(false, true)
  local pbuf  = show_preview and vim.api.nvim_create_buf(false, true) or nil

  local function ibuf(b)
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = b })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = b })
    vim.api.nvim_set_option_value('swapfile', false, { buf = b })
    vim.api.nvim_set_option_value('modifiable', false, { buf = b })
  end
  ibuf(lbuf)
  if pbuf then ibuf(pbuf) end

  -- Windows
  local lwin = vim.api.nvim_open_win(lbuf, true, {
    relative  = 'editor',
    width     = LIST_W,
    height    = WIN_H,
    row       = ROW,
    col       = COL,
    style     = 'minimal',
    zindex    = 50,
    border    = 'single',
    title     = { { ' ' .. prompt .. ' ', 'JasonTitle' } },
    title_pos = 'left',
  })

  vim.api.nvim_set_option_value('winhl',
    'Normal:JasonWin,FloatBorder:JasonBorder',
    { win = lwin })
  for k, v in pairs({
    cursorline = false,
    wrap = false, number = false, relativenumber = false,
    signcolumn = 'no', scrolloff = 0,
  }) do
    vim.api.nvim_set_option_value(k, v, { win = lwin })
  end

  -- Hide the real cursor while the menu is open, restore on close
  local saved_guicursor = vim.o.guicursor
  vim.api.nvim_set_hl(0, 'JasonHiddenCursor', { fg = C.bg, bg = C.bg, blend = 100 })
  vim.o.guicursor = 'a:JasonHiddenCursor'
  vim.api.nvim_create_autocmd('WinLeave', {
    buffer   = lbuf,
    once     = true,
    callback = function()
      vim.o.guicursor = saved_guicursor
    end,
  })

  local pwin = nil
  if pbuf then
    pwin = vim.api.nvim_open_win(pbuf, false, {
      relative  = 'editor',
      width     = PREV_W,
      height    = WIN_H,
      row       = ROW,
      col       = COL + LIST_W + 1,
      style     = 'minimal',
      zindex    = 50,
      border    = 'single',
      title     = { { ' Project ', 'JasonPrevTitle' } },
      title_pos = 'center',
    })
    vim.api.nvim_set_option_value('winhl',
      'Normal:JasonPrevWin,FloatBorder:JasonPrevBorder', { win = pwin })
    for k, v in pairs({
      wrap = false, number = false, relativenumber = false, scrolloff = 0,
    }) do
      vim.api.nvim_set_option_value(k, v, { win = pwin })
    end
  end

  -- State
  local ns      = vim.api.nvim_create_namespace('jason_list')
  local sel_pos = 1 -- rank among selectables (1-based, never counts separators)
  local vt      = 1 -- view_top: rank of the first visible selectable

  -- Number of selectable (non-separator) items in vis[]
  local function sel_total()
    local n = 0
    for _, f in ipairs(vis) do if not f.is_sep then n = n + 1 end end
    return n
  end

  -- How many item rows fit between header and footer
  local function visible_rows()
    local header = enable_search and 4 or 1
    local footer = 5
    return math.max(1, WIN_H - header - footer)
  end

  -- Render
  local function redraw()
    local lines, hls = {}, {}
    local VR         = visible_rows()
    local total      = sel_total()

    -- Clamp sel_pos and vt
    sel_pos          = math.max(1, math.min(sel_pos, math.max(1, total)))
    if sel_pos < vt then vt = sel_pos end
    if sel_pos > vt + VR - 1 then vt = sel_pos - VR + 1 end
    vt = math.max(1, vt)

    local function ahl(l, h, cs, ce)
      hls[#hls + 1] = { line = l, hl = h, cs = cs, ce = ce }
    end

    if enable_search then
      lines[#lines + 1] = ''
      if search == '' then
        lines[#lines + 1] = '  _'
        ahl(#lines - 1, 'JasonSearchBox', 0, -1)
      else
        lines[#lines + 1] = '  ' .. search .. '_'
        ahl(#lines - 1, 'JasonSearch', 0, -1)
      end
      lines[#lines + 1] = string.rep('-', LIST_W)
      ahl(#lines - 1, 'JasonSepLine', 0, -1)
      lines[#lines + 1] = ''
    else
      lines[#lines + 1] = ''
    end

    -- Desc alignment
    local max_lw = 0
    for _, f in ipairs(vis) do
      if not f.is_sep and f.desc then
        max_lw = math.max(max_lw, vim.fn.strdisplaywidth(f.display) + 4)
      end
    end
    local desc_col = math.min(max_lw, math.floor(INNER * 0.55))

    if #vis == 0 then
      lines[#lines + 1] = ''
      lines[#lines + 1] = '  No matches found'
      ahl(#lines - 1, 'JasonDesc', 0, -1)
    else
      local view_end  = math.min(vt + VR - 1, total)
      local show_up   = vt > 1
      local show_down = view_end < total

      local rank      = 0

      for _, f in ipairs(vis) do
        if f.is_sep then
          -- Full-width separator with centered label (Marvin style)
          local ln          = #lines
          local t           = ' ' .. f.display .. ' '
          local tw          = vim.fn.strdisplaywidth(t)
          local rem         = math.max(0, LIST_W - tw)
          local ll          = math.floor(rem / 2)
          local lr          = rem - ll
          lines[#lines + 1] = string.rep('-', ll) .. t .. string.rep('-', lr)
          ahl(ln, 'JasonSepLine', 0, -1)
          ahl(ln, 'JasonSepLabel', ll, ll + tw)
        else
          rank = rank + 1
          if rank >= vt and rank <= view_end then
            local is_sel = (rank == sel_pos)
            -- Marvin uses >> for selected, two spaces for unselected
            local caret  = is_sel and '>> ' or '   '
            local label  = f.display
            local lw     = vim.fn.strdisplaywidth(label)
            local body

            if f.desc then
              local gap = math.max(2, desc_col - lw)
              -- Marvin style: label + spaces + bullet + desc
              body = label .. string.rep(' ', gap) .. '* ' .. f.desc
            else
              body = label
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
              ahl(ln, 'JasonSelected', 0, -1)
            else
              ahl(ln, 'JasonItem', 3, 3 + lw)
              if f.desc then
                local dc = 3 + lw + math.max(2, desc_col - lw) + 2
                ahl(ln, 'JasonDesc', dc, -1)
              end
              if f.badge then
                ahl(ln, 'JasonBadge', -vim.fn.strdisplaywidth(f.badge) - 2, -1)
              end
            end

            if rank == vt and show_up then
              ahl(ln, 'JasonFooter', LIST_W - 4, LIST_W - 3)
            end
            if rank == view_end and show_down then
              ahl(ln, 'JasonFooter', LIST_W - 4, LIST_W - 3)
            end
          end
        end
      end
    end

    -- Footer (Marvin style)
    lines[#lines + 1] = ''
    lines[#lines + 1] = string.rep('-', LIST_W)
    ahl(#lines - 1, 'JasonSepLine', 0, -1)
    local info = string.format('  %d/%d items', sel_pos, total)
    if search ~= '' then info = info .. '  "' .. search .. '"' end
    lines[#lines + 1] = info
    ahl(#lines - 1, 'JasonFooter', 0, -1)
    lines[#lines + 1] = '  j/k Navigate | <CR> Select | <Esc> Cancel'
    ahl(#lines - 1, 'JasonFooterKey', 0, -1)
    lines[#lines + 1] = ''

    vim.api.nvim_set_option_value('modifiable', true, { buf = lbuf })
    vim.api.nvim_buf_set_lines(lbuf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = lbuf })
    vim.api.nvim_buf_clear_namespace(lbuf, ns, 0, -1)
    for _, h in ipairs(hls) do
      pcall(vim.api.nvim_buf_add_highlight, lbuf, ns, h.hl, h.line, h.cs, h.ce)
    end

    -- Park the real cursor at line 1 so Neovim is happy; the caret is visual-only
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
    sel_pos  = 1
    view_top = 1

    local nh = win_h()
    pcall(vim.api.nvim_win_set_height, lwin, nh)
    if pwin then pcall(vim.api.nvim_win_set_height, pwin, nh) end
    redraw()
  end

  local function close()
    vim.o.guicursor = saved_guicursor
    pcall(vim.api.nvim_win_close, lwin, true)
    if pwin then pcall(vim.api.nvim_win_close, pwin, true) end
  end

  local function pick()
    local rank = 0
    for i, f in ipairs(vis) do
      if not f.is_sep then
        rank = rank + 1
        if rank == sel_pos then
          local chosen = f.item
          close()
          callback(chosen)
          return
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

  if enable_search then
    local nav = { j = true, k = true, q = true, l = true, G = true, g = true }
    vim.keymap.set('n', '<BS>', function() do_search('<BS>') end, mo)
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

  -- Initial draw
  redraw()

  if pbuf and project then
    vim.schedule(function()
      local plines, phls = build_preview(project, PREV_W - 2)
      local pns = vim.api.nvim_create_namespace('jason_prev')
      vim.api.nvim_set_option_value('modifiable', true, { buf = pbuf })
      vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, plines)
      vim.api.nvim_set_option_value('modifiable', false, { buf = pbuf })
      vim.api.nvim_buf_clear_namespace(pbuf, pns, 0, -1)
      for _, h in ipairs(phls) do
        pcall(vim.api.nvim_buf_add_highlight, pbuf, pns, h.hl, h.line, h.cs, h.ce)
      end
    end)
  end
end

function M.input(opts, cb)
  opts = opts or {}
  vim.ui.input({ prompt = (opts.prompt or 'Input') .. ': ', default = opts.default or '' }, cb)
end

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = 'Jason' })
end

return M
