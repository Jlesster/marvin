local M = {}

M.backend = nil

function M.init()
  local config = require('marvin').config
  if config.ui_backend == 'auto' then
    M.backend = M.detect_backend()
  else
    M.backend = config.ui_backend
  end
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

-- Modern popup with rounded borders
local function create_popup(title, width, height, opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(false, true)
  local ui = vim.api.nvim_list_uis()[1]

  local win_width = width > 1 and width or math.floor(width * ui.width)
  local win_height = height > 1 and height or math.floor(height * ui.height)
  local row = math.floor((ui.height - win_height) / 2)
  local col = math.floor((ui.width - win_width) / 2)

  local win_opts = {
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = title and { { ' ' .. title .. ' ', 'FloatTitle' } } or nil,
    title_pos = 'center',
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Modern styling
  vim.api.nvim_set_option_value('winhl', 'Normal:NormalFloat,FloatBorder:FloatBorder', { win = win })
  vim.api.nvim_set_option_value('cursorline', true, { win = win })
  vim.api.nvim_set_option_value('wrap', false, { win = win })
  vim.api.nvim_set_option_value('number', false, { win = win })
  vim.api.nvim_set_option_value('relativenumber', false, { win = win })

  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = buf })

  return buf, win
end

-- Fuzzy search with scoring
local function fuzzy_match(str, pattern)
  if pattern == '' then return true, 0 end

  str = str:lower()
  pattern = pattern:lower()

  local score = 0
  local str_idx = 1
  local pattern_idx = 1
  local consecutive = 0

  while pattern_idx <= #pattern and str_idx <= #str do
    if str:sub(str_idx, str_idx) == pattern:sub(pattern_idx, pattern_idx) then
      score = score + 1 + consecutive * 5
      consecutive = consecutive + 1
      pattern_idx = pattern_idx + 1
    else
      consecutive = 0
    end
    str_idx = str_idx + 1
  end

  if pattern_idx > #pattern then
    if str:sub(1, #pattern) == pattern then
      score = score + 20
    end
    return true, score
  end

  return false, 0
end

-- Enhanced select with fuzzy search and smooth scrolling
function M.popup_select(items, opts, callback)
  opts = opts or {}
  local prompt = opts.prompt or 'Select'
  local format_fn = opts.format_item or function(item)
    if type(item) == 'table' then
      return item.label or item.name or tostring(item)
    end
    return tostring(item)
  end

  -- Format items
  local formatted_items = {}
  for i, item in ipairs(items) do
    table.insert(formatted_items, {
      index = i,
      item = item,
      display = format_fn(item),
      desc = type(item) == 'table' and item.desc or nil,
      icon = type(item) == 'table' and item.icon or nil,
    })
  end

  local filtered_items = vim.deepcopy(formatted_items)
  local search_term = ''
  local current_idx = 1

  -- Create window
  local max_height = math.min(#filtered_items * 3 + 8, 35)
  local buf, win = create_popup('🔍 ' .. prompt, 80, max_height)

  -- Render function
  local function render()
    local lines = {}
    local highlights = {}

    -- Search bar
    table.insert(lines, '')
    local search_display = search_term == '' and '  Type to search...' or '  ' .. search_term .. '█'
    table.insert(lines, search_display)
    table.insert(highlights,
      { line = #lines - 1, hl_group = search_term == '' and 'Comment' or '@string', col_start = 0, col_end = -1 })

    table.insert(lines, '  ' .. string.rep('─', 76))
    table.insert(highlights, { line = #lines - 1, hl_group = 'FloatBorder', col_start = 0, col_end = -1 })
    table.insert(lines, '')

    -- Items
    local selectable = {}
    local item_map = {}

    if #filtered_items == 0 then
      table.insert(lines, '')
      table.insert(lines, '  ❌ No matches found')
      table.insert(highlights, { line = #lines - 1, hl_group = 'WarningMsg', col_start = 0, col_end = -1 })
      table.insert(lines, '')
    else
      for i, formatted in ipairs(filtered_items) do
        local line_num = #lines + 1
        local is_selected = i == current_idx

        -- Selection indicator
        local indicator = is_selected and '▶ ' or '  '
        local icon_str = formatted.icon and (formatted.icon .. ' ') or ''

        table.insert(lines, indicator .. icon_str .. formatted.display)
        table.insert(selectable, line_num)
        item_map[line_num] = formatted

        -- Highlight selected item
        if is_selected then
          table.insert(highlights, { line = line_num - 1, hl_group = 'CursorLine', col_start = 0, col_end = -1 })
          table.insert(highlights, { line = line_num - 1, hl_group = '@keyword', col_start = 0, col_end = 2 })
        else
          table.insert(highlights, { line = line_num - 1, hl_group = 'Normal', col_start = 0, col_end = -1 })
        end

        -- Description on next line
        if formatted.desc then
          table.insert(lines, '    ' .. formatted.desc)
          table.insert(highlights, { line = #lines - 1, hl_group = 'Comment', col_start = 0, col_end = -1 })
        end

        table.insert(lines, '')
      end
    end

    -- Footer
    table.insert(lines, '  ' .. string.rep('─', 76))
    table.insert(highlights, { line = #lines - 1, hl_group = 'FloatBorder', col_start = 0, col_end = -1 })

    local count_text = string.format('  %d/%d items', #filtered_items, #formatted_items)
    table.insert(lines, count_text)
    table.insert(highlights, { line = #lines - 1, hl_group = 'Comment', col_start = 0, col_end = -1 })

    table.insert(lines, '  ↑↓ Navigate │ Enter Select │ Esc Cancel')
    table.insert(highlights, { line = #lines - 1, hl_group = 'Comment', col_start = 0, col_end = -1 })
    table.insert(lines, '')

    return lines, selectable, item_map, highlights
  end

  local lines, selectable, item_map, highlights = render()

  -- Update display
  local function update_display()
    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

    -- Apply highlights
    local ns = vim.api.nvim_create_namespace('marvin_select')
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    for _, hl in ipairs(highlights) do
      vim.api.nvim_buf_add_highlight(buf, ns, hl.hl_group, hl.line, hl.col_start, hl.col_end)
    end

    -- Smooth scroll to current item
    if #selectable > 0 and current_idx <= #selectable then
      pcall(vim.api.nvim_win_set_cursor, win, { selectable[current_idx], 0 })
    end
  end

  -- Update search and filter
  local function update_search(char)
    if char == '<BS>' then
      search_term = search_term:sub(1, -2)
    elseif char == '<C-u>' then
      search_term = ''
    else
      search_term = search_term .. char
    end

    -- Fuzzy filter with scoring
    filtered_items = {}
    for _, formatted in ipairs(formatted_items) do
      local matches, score = fuzzy_match(formatted.display, search_term)
      if matches then
        formatted.score = score
        table.insert(filtered_items, formatted)
      end
    end

    -- Sort by score
    table.sort(filtered_items, function(a, b)
      return (a.score or 0) > (b.score or 0)
    end)

    current_idx = math.min(current_idx, #filtered_items)
    if current_idx == 0 and #filtered_items > 0 then
      current_idx = 1
    end

    lines, selectable, item_map, highlights = render()
    update_display()
  end

  -- Initial display
  update_display()

  -- Selection handler
  local function select()
    if #selectable == 0 then return end
    local line_num = selectable[current_idx]
    local formatted = item_map[line_num]
    if formatted then
      vim.api.nvim_win_close(win, true)
      callback(formatted.item)
    end
  end

  -- Navigation
  local function move(direction)
    if #filtered_items == 0 then return end

    if direction == 'down' then
      current_idx = current_idx < #filtered_items and current_idx + 1 or 1
    elseif direction == 'up' then
      current_idx = current_idx > 1 and current_idx - 1 or #filtered_items
    end

    lines, selectable, item_map, highlights = render()
    update_display()
  end

  -- Keymaps
  local map_opts = { noremap = true, silent = true, buffer = buf }

  -- Navigation
  vim.keymap.set('n', 'j', function() move('down') end, map_opts)
  vim.keymap.set('n', 'k', function() move('up') end, map_opts)
  vim.keymap.set('n', '<Down>', function() move('down') end, map_opts)
  vim.keymap.set('n', '<Up>', function() move('up') end, map_opts)
  vim.keymap.set('n', '<C-n>', function() move('down') end, map_opts)
  vim.keymap.set('n', '<C-p>', function() move('up') end, map_opts)

  -- Selection
  vim.keymap.set('n', '<CR>', select, map_opts)
  vim.keymap.set('n', '<Space>', select, map_opts)

  -- Cancel
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
    callback(nil)
  end, map_opts)

  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
    callback(nil)
  end, map_opts)

  -- Search
  vim.keymap.set('n', '<BS>', function() update_search('<BS>') end, map_opts)
  vim.keymap.set('n', '<C-u>', function() update_search('<C-u>') end, map_opts)

  -- Type to search (alphanumeric and symbols)
  for i = 32, 126 do
    local char = string.char(i)
    vim.keymap.set('n', char, function() update_search(char) end, map_opts)
  end

  -- CRITICAL: Prevent insert mode
  vim.keymap.set('n', 'i', '<Nop>', map_opts)
  vim.keymap.set('n', 'I', '<Nop>', map_opts)
  vim.keymap.set('n', 'a', function() update_search('a') end, map_opts)
  vim.keymap.set('n', 'A', function() update_search('A') end, map_opts)
  vim.keymap.set('n', 'o', function() update_search('o') end, map_opts)
  vim.keymap.set('n', 'O', function() update_search('O') end, map_opts)
end

-- Modern input popup
function M.popup_input(opts, callback)
  opts = opts or {}
  local prompt = opts.prompt or 'Input'
  local default = opts.default or ''
  local width = opts.width or 60

  local buf, win = create_popup('✏️  ' .. prompt, width, 5)

  -- Create input line
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    '',
    '  ' .. default,
    '',
    '  Enter to confirm │ Esc to cancel',
    ''
  })

  -- Highlight
  local ns = vim.api.nvim_create_namespace('marvin_input')
  vim.api.nvim_buf_add_highlight(buf, ns, '@string', 1, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', 3, 0, -1)

  -- Make line editable
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })

  -- Position cursor at end of input
  vim.api.nvim_win_set_cursor(win, { 2, #default + 2 })

  -- Enter insert mode
  vim.schedule(function()
    vim.cmd('startinsert!')
  end)

  -- Submit handler
  local function submit()
    local lines = vim.api.nvim_buf_get_lines(buf, 1, 2, false)
    local text = lines[1] and lines[1]:gsub('^%s*', '') or ''

    vim.api.nvim_win_close(win, true)
    callback(text ~= '' and text or nil)
  end

  -- Cancel handler
  local function cancel()
    vim.api.nvim_win_close(win, true)
    callback(nil)
  end

  -- Keymaps
  local map_opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('i', '<CR>', submit, map_opts)
  vim.keymap.set('i', '<Esc>', cancel, map_opts)
  vim.keymap.set('i', '<C-c>', cancel, map_opts)

  vim.keymap.set('n', '<CR>', submit, map_opts)
  vim.keymap.set('n', '<Esc>', cancel, map_opts)
  vim.keymap.set('n', 'q', cancel, map_opts)

  -- Prevent moving to other lines
  vim.keymap.set('i', '<Up>', '<Nop>', map_opts)
  vim.keymap.set('i', '<Down>', '<Nop>', map_opts)
end

-- Public API
function M.select(items, opts, callback)
  M.popup_select(items, opts, callback)
end

function M.input(opts, callback)
  M.popup_input(opts, callback)
end

function M.notify(message, level, opts)
  opts = opts or {}
  level = level or vim.log.levels.INFO

  if M.backend == 'snacks' then
    local ok, snacks = pcall(require, 'snacks')
    if ok then
      snacks.notify(message, {
        level = M.level_to_snacks(level),
        title = opts.title or 'Marvin',
      })
      return
    end
  end

  vim.notify(message, level, {
    title = opts.title or 'Marvin',
  })
end

function M.level_to_snacks(level)
  if level == vim.log.levels.ERROR then return 'error' end
  if level == vim.log.levels.WARN then return 'warn' end
  if level == vim.log.levels.INFO then return 'info' end
  return 'debug'
end

-- Maven goal menu
function M.show_goal_menu()
  local project = require('marvin.project')

  if not project.validate_environment() then
    return
  end

  local goals = M.get_common_goals()

  M.select(goals, {
    prompt = 'Maven Goal',
    format_item = function(goal)
      return goal.label
    end,
  }, function(choice)
    if not choice then return end
    if choice.needs_profile then
      M.show_profile_menu(choice.goal)
    elseif choice.needs_options then
      M.show_options_menu(choice.goal)
    else
      local executor = require('marvin.executor')
      executor.run(choice.goal)
    end
  end)
end

function M.get_common_goals()
  return {
    { goal = 'clean', label = 'Clean', icon = '🧹', desc = 'Remove target directory' },
    { goal = 'compile', label = 'Compile', icon = '🔨', desc = 'Compile source code' },
    { goal = 'test', label = 'Test', icon = '🧪', desc = 'Run unit tests' },
    { goal = 'test -DskipTests', label = 'Test (skip)', icon = '⏭️', desc = 'Skip running tests' },
    { goal = 'package', label = 'Package', icon = '📦', desc = 'Create JAR/WAR file' },
    { goal = 'install', label = 'Install', icon = '💾', desc = 'Install to local repo' },
    { goal = 'verify', label = 'Verify', icon = '✅', desc = 'Run integration tests' },
    { goal = 'clean install', label = 'Clean + Install', icon = '🔄', desc = 'Clean and install' },
    { goal = 'dependency:tree', label = 'Dependency Tree', icon = '🌳', desc = 'Show dependency tree' },
    { goal = 'dependency:resolve', label = 'Resolve Dependencies', icon = '📥', desc = 'Download dependencies' },
    { goal = 'help:effective-pom', label = 'Effective POM', icon = '📄', desc = 'Show effective POM' },
    { goal = nil, label = 'Custom Goal...', icon = '⚙️', desc = 'Enter custom Maven goal', needs_options = true },
  }
end

function M.show_profile_menu(goal)
  local project = require('marvin.project').get_project()

  if not project or not project.info or #project.info.profiles == 0 then
    vim.notify('No profiles found in pom.xml', vim.log.levels.WARN)
    local executor = require('marvin.executor')
    executor.run(goal)
    return
  end

  local profiles = {}
  table.insert(profiles, { id = nil, label = '(default)', desc = 'No profile selected' })

  for _, profile_id in ipairs(project.info.profiles) do
    table.insert(profiles, { id = profile_id, label = profile_id, desc = 'Maven profile' })
  end

  M.select(profiles, {
    prompt = 'Select Profile',
  }, function(choice)
    if not choice then return end

    local executor = require('marvin.executor')
    executor.run(goal, { profile = choice.id })
  end)
end

function M.show_options_menu(goal)
  M.input({
    prompt = 'Maven goal(s)',
    default = '',
  }, function(custom_goal)
    if not custom_goal or custom_goal == '' then
      return
    end

    M.input({
      prompt = 'Additional options (optional)',
      default = '',
    }, function(extra_opts)
      local executor = require('marvin.executor')

      local full_goal = custom_goal
      if extra_opts and extra_opts ~= '' then
        full_goal = full_goal .. ' ' .. extra_opts
      end

      executor.run(full_goal)
    end)
  end)
end

function M.show_advanced_menu()
  local options = {
    { goal = 'clean install -DskipTests=true', label = 'Clean Install (skip tests)', icon = '⚡' },
    { goal = 'clean install -U', label = 'Clean Install (force update)', icon = '🔄' },
    { goal = 'clean package -Dmaven.test.skip=true', label = 'Package (skip tests)', icon = '📦' },
    { goal = 'dependency:tree -Dverbose', label = 'Verbose Dependency Tree', icon = '🌳' },
    { goal = 'dependency:analyze', label = 'Analyze Dependencies', icon = '🔍' },
    { goal = 'versions:display-dependency-updates', label = 'Check for Updates', icon = '🆙' },
    { goal = 'help:effective-settings', label = 'Show Effective Settings', icon = '⚙️' },
  }

  M.select(options, {
    prompt = 'Advanced Options',
  }, function(choice)
    if not choice then return end

    local executor = require('marvin.executor')
    executor.run(choice.goal)
  end)
end

return M
