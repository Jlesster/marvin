-- Enhanced select with fuzzy search and compact display
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
  local max_height = math.min(#filtered_items + 10, 40)
  local buf, win = create_popup('🔍 ' .. prompt, 80, max_height)

  -- Render function
  local function render()
    local lines = {}
    local highlights = {}

    -- Search bar
    table.insert(lines, '')
    local search_display = search_term == '' and '  Type to search...' or '  ' .. search_term .. '▮'
    table.insert(lines, search_display)
    table.insert(highlights,
      { line = #lines - 1, hl_group = search_term == '' and 'Comment' or '@string', col_start = 0, col_end = -1 })

    table.insert(lines, '  ' .. string.rep('─', 76))
    table.insert(highlights, { line = #lines - 1, hl_group = 'FloatBorder', col_start = 0, col_end = -1 })

    -- Items (COMPACT - no blank lines)
    local selectable = {}
    local item_map = {}

    if #filtered_items == 0 then
      table.insert(lines, '')
      table.insert(lines, '  ❌ No matches found')
      table.insert(highlights, { line = #lines - 1, hl_group = 'WarningMsg', col_start = 0, col_end = -1 })
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

        -- Description on same line if short, otherwise next line
        if formatted.desc then
          if #formatted.desc < 40 then
            -- Short desc: append to same line
            local desc_start = #lines[#lines]
            lines[#lines] = lines[#lines] .. '  • ' .. formatted.desc
            table.insert(highlights, { line = #lines - 1, hl_group = 'Comment', col_start = desc_start, col_end = -1 })
          else
            -- Long desc: new line (but still no blank line after)
            table.insert(lines, '    ' .. formatted.desc)
            table.insert(highlights, { line = #lines - 1, hl_group = 'Comment', col_start = 0, col_end = -1 })
          end
        end

        -- NO blank line between items for maximum compactness
      end
    end

    -- Footer
    table.insert(lines, '')
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
