local M = {}

M.backend = nil

-- Define custom highlight groups for the modern UI
local function setup_highlights()
  vim.api.nvim_set_hl(0, 'MarvinSelected', { bg = '#9370db', fg = '#ffffff', bold = true })
  vim.api.nvim_set_hl(0, 'MarvinNormal', { bg = '#1e1e2e', fg = '#cdd6f4' })
  vim.api.nvim_set_hl(0, 'MarvinBorder', { fg = '#6c7086' })
  vim.api.nvim_set_hl(0, 'MarvinTitle', { fg = '#cba6f7', bold = true })
  vim.api.nvim_set_hl(0, 'MarvinIcon', { fg = '#f5c2e7' })
  vim.api.nvim_set_hl(0, 'MarvinDesc', { fg = '#6c7086' })
  vim.api.nvim_set_hl(0, 'MarvinSeparator', { fg = '#45475a' })
  vim.api.nvim_set_hl(0, 'MarvinSearch', { fg = '#89dceb', italic = true })
  vim.api.nvim_set_hl(0, 'MarvinCounter', { fg = '#94e2d5' })
end


function M.init()
  local config = require('marvin').config
  if config.ui_backend == 'auto' then
    M.backend = M.detect_backend()
  else
    M.backend = config.ui_backend
  end

  -- Setup custom highlights
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
    border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
    title = title and { { ' ' .. title .. ' ', 'FloatTitle' } } or nil,
    title_pos = 'left',
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Modern styling
  vim.api.nvim_set_option_value('winhl', 'Normal:MarvinNormal,FloatBorder:MarvinBorder', { win = win })
  vim.api.nvim_set_option_value('cursorline', false, { win = win })
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

-- Enhanced select with fuzzy search and compact display
function M.popup_select(items, opts, callback)
  opts = opts or {}
  local prompt = opts.prompt or 'Select'
  local enable_search = opts.enable_search or false
  local on_back = opts.on_back or nil -- Callback for back navigation
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
      is_separator = type(item) == 'table' and item.is_separator or false,
    })
  end

  local filtered_items = vim.deepcopy(formatted_items)
  local search_term = ''
  local current_idx = 1

  -- Find first non-separator item
  local function find_next_selectable(start_idx, direction)
    local idx = start_idx
    local count = #filtered_items

    for _ = 1, count do
      if not filtered_items[idx].is_separator then
        return idx
      end

      if direction == 'down' then
        idx = idx % count + 1
      else
        idx = idx - 1
        if idx < 1 then idx = count end
      end
    end

    return start_idx
  end

  -- Initialize to first selectable item
  current_idx = find_next_selectable(1, 'down')

  -- Calculate dynamic window height based on content
  local function calculate_window_height()
    local base_lines = 0

    -- Search bar (if enabled)
    if enable_search then
      base_lines = base_lines + 3 -- empty line, search bar, separator
    else
      base_lines = base_lines + 1 -- just empty line
    end

    -- Items
    base_lines = base_lines + #filtered_items

    -- Footer
    base_lines = base_lines + 5 -- empty, separator, count, nav help, empty

    -- Add some padding
    local total_height = base_lines + 2

    -- Constrain to reasonable bounds
    local min_height = 10
    local max_height = math.floor(vim.o.lines * 0.8)

    return math.max(min_height, math.min(total_height, max_height))
  end

  -- Create window with dynamic height
  local win_height = calculate_window_height()
  local buf, win = create_popup(prompt, 80, win_height)

  -- Calculate max label width for alignment
  local function calculate_max_label_width()
    local max_width = 0
    for _, formatted in ipairs(filtered_items) do
      if not formatted.is_separator and formatted.desc then
        local indicator_len = 2                    -- "▶ " or "  "
        local icon_len = formatted.icon and 2 or 0 -- icon + space
        local label_len = vim.fn.strdisplaywidth(formatted.display)
        local total = indicator_len + icon_len + label_len
        if total > max_width then
          max_width = total
        end
      end
    end
    return max_width + 4 -- Add padding for " • "
  end

  -- Render function
  local function render()
    local lines = {}
    local highlights = {}

    if enable_search then
      -- Search bar
      table.insert(lines, '')
      local search_display = search_term == '' and '  _' or '  ' .. search_term .. '_'
      table.insert(lines, search_display)
      table.insert(highlights,
        { line = #lines - 1, hl_group = search_term == '' and 'Comment' or '@string', col_start = 0, col_end = -1 })

      table.insert(lines, '  ' .. string.rep('─', 76))
      table.insert(highlights, { line = #lines - 1, hl_group = 'MarvinSeparator', col_start = 0, col_end = -1 })
    else
      table.insert(lines, '')
    end

    -- Items (COMPACT - no blank lines)
    local selectable = {}
    local item_map = {}
    local align_col = calculate_max_label_width()

    if #filtered_items == 0 then
      table.insert(lines, '')
      table.insert(lines, '  ❌ No matches found')
      table.insert(highlights, { line = #lines - 1, hl_group = 'WarningMsg', col_start = 0, col_end = -1 })
    else
      for i, formatted in ipairs(filtered_items) do
        local line_num = #lines + 1

        if formatted.is_separator then
          -- Separator rendering - full width
          table.insert(lines, string.rep('─', 78))
          table.insert(highlights, { line = line_num - 1, hl_group = 'MarvinSeparator', col_start = 0, col_end = -1 })

          -- Add separator text centered
          if formatted.display and formatted.display ~= '' then
            -- Extract text from separator (remove existing dashes and trim)
            local sep_text = formatted.display:gsub('─', ''):gsub('^%s+', ''):gsub('%s+$', '')
            sep_text = ' ' .. sep_text .. ' '
            local text_width = vim.fn.strdisplaywidth(sep_text)
            local start_pos = math.floor((78 - text_width) / 2)

            -- Replace part of the line with text
            lines[#lines] = string.rep('─', start_pos) .. sep_text .. string.rep('─', 78 - start_pos - text_width)
            table.insert(highlights, { line = line_num - 1, hl_group = 'MarvinDesc', col_start = 0, col_end = -1 })
          end
        else
          local is_selected = i == current_idx

          -- Selection indicator
          local indicator = is_selected and '» ' or '  '
          local icon_str = formatted.icon and (formatted.icon .. ' ') or ''
          local label_part = indicator .. icon_str .. formatted.display

          -- Calculate padding needed for alignment
          local current_width = vim.fn.strdisplaywidth(label_part)
          local padding = align_col - current_width

          if formatted.desc then
            -- Aligned description
            local line_content = label_part .. string.rep(' ', padding) .. '• ' .. formatted.desc
            table.insert(lines, line_content)

            -- Store description start position for highlighting
            local desc_start = align_col + 2 -- position after "• "

            table.insert(selectable, line_num)
            item_map[line_num] = formatted

            -- Highlight selected item
            if is_selected then
              table.insert(highlights, { line = line_num - 1, hl_group = 'MarvinSelected', col_start = 0, col_end = -1 })
              table.insert(highlights, { line = line_num - 1, hl_group = 'MarvinIcon', col_start = 0, col_end = 2 })
            else
              table.insert(highlights, { line = line_num - 1, hl_group = 'Normal', col_start = 0, col_end = -1 })
            end

            -- Highlight description
            table.insert(highlights,
              { line = line_num - 1, hl_group = 'MarvinDesc', col_start = align_col, col_end = -1 })
          else
            -- No description - just the label
            table.insert(lines, label_part)
            table.insert(selectable, line_num)
            item_map[line_num] = formatted

            -- Highlight selected item
            if is_selected then
              table.insert(highlights, { line = line_num - 1, hl_group = 'MarvinSelected', col_start = 0, col_end = -1 })
              table.insert(highlights, { line = line_num - 1, hl_group = 'MarvinIcon', col_start = 0, col_end = 2 })
            else
              table.insert(highlights, { line = line_num - 1, hl_group = 'Normal', col_start = 0, col_end = -1 })
            end
          end
        end

        -- NO blank line between items for maximum compactness
      end
    end

    -- Footer
    table.insert(lines, '')
    table.insert(lines, '  ' .. string.rep('─', 76))
    table.insert(highlights, { line = #lines - 1, hl_group = 'MarvinSeparator', col_start = 0, col_end = -1 })

    local count_text = string.format('  %d/%d items', #filtered_items, #formatted_items)
    table.insert(lines, count_text)
    table.insert(highlights, { line = #lines - 1, hl_group = 'MarvinDesc', col_start = 0, col_end = -1 })

    table.insert(lines, '  ↑↓ Navigate │ Enter Select │ Esc Cancel' .. (on_back and ' │ ⌫ Back' or ''))
    table.insert(highlights, { line = #lines - 1, hl_group = 'MarvinDesc', col_start = 0, col_end = -1 })
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
    if #selectable > 0 and current_idx <= #filtered_items then
      -- Find the line number for current_idx
      for line_num, formatted in pairs(item_map) do
        if formatted.index == filtered_items[current_idx].index then
          pcall(vim.api.nvim_win_set_cursor, win, { line_num, 0 })
          break
        end
      end
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

    -- Ensure we're on a selectable item
    current_idx = find_next_selectable(current_idx, 'down')

    -- Recalculate window height based on filtered results
    local new_height = calculate_window_height()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_height(win, new_height)
    end

    lines, selectable, item_map, highlights = render()
    update_display()
  end

  -- Initial display
  update_display()

  -- Selection handler
  local function select()
    if #filtered_items == 0 or filtered_items[current_idx].is_separator then return end

    local formatted = filtered_items[current_idx]
    if formatted then
      vim.api.nvim_win_close(win, true)
      callback(formatted.item)
    end
  end

  -- Navigation
  local function move(direction)
    if #filtered_items == 0 then return end

    if direction == 'down' then
      current_idx = current_idx % #filtered_items + 1
      current_idx = find_next_selectable(current_idx, 'down')
    elseif direction == 'up' then
      current_idx = current_idx - 1
      if current_idx < 1 then current_idx = #filtered_items end
      current_idx = find_next_selectable(current_idx, 'up')
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

  -- Only enable search if explicitly requested
  if enable_search then
    -- Backspace: delete search char OR go back if search is empty
    vim.keymap.set('n', '<BS>', function()
      if search_term == '' and on_back then
        vim.api.nvim_win_close(win, true)
        on_back()
      else
        update_search('<BS>')
      end
    end, map_opts)

    vim.keymap.set('n', '<C-u>', function() update_search('<C-u>') end, map_opts)

    -- Type to search (alphanumeric and symbols)
    for i = 32, 126 do
      local char = string.char(i)
      -- Don't override navigation keys
      if char ~= ' ' and char ~= 'j' and char ~= 'k' and char ~= 'q' then
        vim.keymap.set('n', char, function() update_search(char) end, map_opts)
      end
    end
  else
    -- Backspace goes back if search is disabled and on_back is provided
    if on_back then
      vim.keymap.set('n', '<BS>', function()
        vim.api.nvim_win_close(win, true)
        on_back()
      end, map_opts)
    end
  end

  -- CRITICAL: Prevent insert mode
  vim.keymap.set('n', 'i', '<Nop>', map_opts)
  vim.keymap.set('n', 'I', '<Nop>', map_opts)

  if not enable_search then
    vim.keymap.set('n', 'a', '<Nop>', map_opts)
    vim.keymap.set('n', 'A', '<Nop>', map_opts)
  end

  vim.keymap.set('n', 'o', '<Nop>', map_opts)
  vim.keymap.set('n', 'O', '<Nop>', map_opts)
end

-- Modern input popup
function M.popup_input(opts, callback)
  opts = opts or {}
  local prompt = opts.prompt or 'Input'
  local default = opts.default or ''
  local width = opts.width or 60

  local buf, win = create_popup(prompt, width, 5)

  -- Create input line
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    '',
    '  ' .. default,
    '',
    '  <CR> confirm  │  Esc cancel',
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
  -- Pass through on_back if provided
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
function M.show_goal_menu(on_back)
  local project = require('marvin.project')

  if not project.validate_environment() then
    return
  end

  local goals = M.get_common_goals()

  M.select(goals, {
    prompt = 'Maven Goal',
    on_back = on_back,
    format_item = function(goal)
      return goal.label
    end,
  }, function(choice)
    if not choice then return end
    if choice.needs_profile then
      M.show_profile_menu(choice.goal, function()
        M.show_goal_menu(on_back)
      end)
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
    {
      id = 'separator_build',
      label = 'Build Lifecycle',
      is_separator = true
    },
    {
      goal = 'clean',
      label = 'Clean',
      icon = '🧹',
      desc = 'Delete target/ directory',
      shortcut = 'c'
    },
    {
      goal = 'compile',
      label = 'Compile',
      icon = '⚙️',
      desc = 'Compile source code',
      shortcut = 'C'
    },
    {
      goal = 'test',
      label = 'Test',
      icon = '🧪',
      desc = 'Run unit tests',
      shortcut = 't'
    },
    {
      goal = 'package',
      label = 'Package',
      icon = '📦',
      desc = 'Create JAR/WAR file',
      shortcut = 'p'
    },
    {
      goal = 'verify',
      label = 'Verify',
      icon = '✅',
      desc = 'Run integration tests',
      shortcut = 'v'
    },
    {
      goal = 'install',
      label = 'Install',
      icon = '💾',
      desc = 'Install to ~/.m2/repository',
      shortcut = 'i'
    },

    {
      id = 'separator_common',
      label = 'Common Tasks',
      is_separator = true
    },
    {
      goal = 'clean install',
      label = 'Clean & Install',
      icon = '🔄',
      desc = 'Full rebuild and install',
      shortcut = 'I'
    },
    {
      goal = 'clean package',
      label = 'Clean & Package',
      icon = '📦',
      desc = 'Fresh build to JAR',
      shortcut = 'P'
    },
    {
      goal = 'test -DskipTests',
      label = 'Skip Tests',
      icon = '⏭️',
      desc = 'Build without running tests',
      shortcut = 's'
    },

    {
      id = 'separator_deps',
      label = 'Dependencies',
      is_separator = true
    },
    {
      goal = 'dependency:tree',
      label = 'Dependency Tree',
      icon = '🌳',
      desc = 'Show full dependency graph',
      shortcut = 'd'
    },
    {
      goal = 'dependency:resolve',
      label = 'Resolve Dependencies',
      icon = '📥',
      desc = 'Download all dependencies',
      shortcut = 'r'
    },
    {
      goal = 'dependency:analyze',
      label = 'Analyze Dependencies',
      icon = '🔍',
      desc = 'Find unused/undeclared deps',
      shortcut = 'a'
    },
    {
      goal = 'versions:display-dependency-updates',
      label = 'Check for Updates',
      icon = '🆙',
      desc = 'Find newer dependency versions',
      shortcut = 'u'
    },

    {
      id = 'separator_info',
      label = 'Information',
      is_separator = true
    },
    {
      goal = 'help:effective-pom',
      label = 'Effective POM',
      icon = '📄',
      desc = 'Show resolved configuration',
      shortcut = 'e'
    },
    {
      goal = 'help:effective-settings',
      label = 'Effective Settings',
      icon = '⚙️',
      desc = 'Show Maven settings',
      shortcut = 'S'
    },

    {
      id = 'separator_custom',
      label = 'Custom',
      is_separator = true
    },
    {
      goal = nil,
      label = 'Custom Goal',
      icon = '⚡',
      desc = 'Enter any Maven command',
      needs_options = true,
      shortcut = 'g'
    },
  }
end

function M.show_profile_menu(goal, on_back)
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
    on_back = on_back,
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
