local M = {}

-- Modern popup creator
local function create_popup(title, width, height)
  local buf = vim.api.nvim_create_buf(false, true)
  local ui = vim.api.nvim_list_uis()[1]

  local win_width = width > 1 and width or math.floor(width * ui.width)
  local win_height = height > 1 and height or math.floor(height * ui.height)
  local row = math.floor((ui.height - win_height) / 2)
  local col = math.floor((ui.width - win_width) / 2)

  local opts = {
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

  local win = vim.api.nvim_open_win(buf, true, opts)

  vim.api.nvim_set_option_value('winhl', 'Normal:NormalFloat,FloatBorder:FloatBorder', { win = win })
  vim.api.nvim_set_option_value('cursorline', true, { win = win })
  vim.api.nvim_set_option_value('wrap', false, { win = win })

  return buf, win
end

-- Check if assembly plugin is configured
local function has_assembly_plugin()
  local pom_path = vim.fn.getcwd() .. '/pom.xml'
  if vim.fn.filereadable(pom_path) == 0 then
    return false
  end

  local content = table.concat(vim.fn.readfile(pom_path), '\n')
  return content:match('maven%-assembly%-plugin') ~= nil
end

-- Show main dashboard
function M.show()
  local project = require('marvin.project')
  local in_maven_project = project.detect()

  -- Build menu items with consistent colors
  local menu_items = {
    { type = 'action', id = 'new_project', label = 'Create New Maven Project', icon = '🏗️', desc = 'Generate project from archetype', color = 'DiagnosticInfo' },
    { type = 'action', id = 'new_java_file', label = 'Create Java File', icon = '☕', desc = 'Class, interface, enum, etc.', color = 'DiagnosticWarn' },
  }

  if in_maven_project then
    table.insert(menu_items, { type = 'separator' })
    table.insert(menu_items,
      { type = 'action', id = 'run_goal', label = 'Run Maven Goal', icon = '🎯', desc = 'Execute any Maven goal', color =
      'DiagnosticOk' })

    table.insert(menu_items, { type = 'separator' })
    table.insert(menu_items, { type = 'header', label = '📦 Dependencies', color = '@function' })
    table.insert(menu_items,
      { type = 'action', id = 'add_jackson', label = 'Add Jackson JSON', icon = '📋', desc = 'Jackson 2.18.2', color =
      '@string' })
    table.insert(menu_items,
      { type = 'action', id = 'add_lwjgl', label = 'Add LWJGL', icon = '🎮', desc = 'LWJGL 3.3.6 + natives', color =
      '@string' })

    table.insert(menu_items, { type = 'separator' })
    table.insert(menu_items, { type = 'header', label = '🔧 Build Tools', color = '@type' })
    table.insert(menu_items,
      { type = 'action', id = 'set_java_version', label = 'Set Java Version', icon = '☕', desc =
      'Configure compiler version', color = '@variable' })

    if not has_assembly_plugin() then
      table.insert(menu_items,
        { type = 'action', id = 'add_assembly', label = 'Setup Fat JAR Build', icon = '📦', desc = 'Add Assembly Plugin', color =
        '@variable' })
    end

    table.insert(menu_items,
      { type = 'action', id = 'package', label = 'Package Project', icon = '📦', desc = 'Build regular JAR', color =
      '@keyword' })

    if has_assembly_plugin() then
      table.insert(menu_items,
        { type = 'action', id = 'package_fat', label = 'Build Fat JAR', icon = '🎁', desc = 'JAR with dependencies', color =
        '@keyword' })
    end

    table.insert(menu_items,
      { type = 'action', id = 'clean_install', label = 'Clean Install', icon = '🔄', desc = 'Clean and install', color =
      'DiagnosticHint' })
  end

  -- Render function
  local function render(current_idx)
    local lines = {}
    local highlights = {}
    local selectable = {}
    local action_map = {}

    -- Header
    table.insert(lines, '')
    table.insert(lines, '  ⚡ MARVIN - Maven for Neovim')
    table.insert(highlights, { line = #lines - 1, hl_group = '@constructor', col_start = 0, col_end = -1 })

    table.insert(lines, '')

    if in_maven_project then
      local proj_info = project.get_project()
      if proj_info and proj_info.info then
        local proj_text = string.format('  📁 %s:%s',
          proj_info.info.group_id or 'unknown',
          proj_info.info.artifact_id or 'unknown')
        table.insert(lines, proj_text)
        table.insert(highlights, { line = #lines - 1, hl_group = '@string', col_start = 0, col_end = -1 })
      end
    else
      table.insert(lines, '  💡 Not in a Maven project')
      table.insert(highlights, { line = #lines - 1, hl_group = 'Comment', col_start = 0, col_end = -1 })
    end

    table.insert(lines, '')
    table.insert(lines, '  ' .. string.rep('─', 76))
    table.insert(highlights, { line = #lines - 1, hl_group = 'FloatBorder', col_start = 0, col_end = -1 })
    table.insert(lines, '')

    -- Menu items
    local item_idx = 0
    for _, item in ipairs(menu_items) do
      if item.type == 'header' then
        table.insert(lines, '')
        table.insert(lines, '  ' .. item.label)
        table.insert(highlights, { line = #lines - 1, hl_group = item.color or '@keyword', col_start = 0, col_end = -1 })
      elseif item.type == 'separator' then
        -- Don't add extra lines
      elseif item.type == 'action' then
        item_idx = item_idx + 1
        local is_selected = item_idx == current_idx
        local line_num = #lines + 1

        table.insert(lines, '')

        -- Format with selection indicator
        if is_selected then
          table.insert(lines, '  ▶ ' .. item.icon .. '  ' .. item.label)
          table.insert(highlights, { line = line_num, hl_group = 'CursorLine', col_start = 0, col_end = -1 })
          table.insert(highlights, { line = line_num, hl_group = '@keyword', col_start = 0, col_end = 3 })
          table.insert(highlights, { line = line_num, hl_group = item.color, col_start = 6, col_end = -1 })
        else
          table.insert(lines, '    ' .. item.icon .. '  ' .. item.label)
          table.insert(highlights, { line = line_num, hl_group = item.color, col_start = 0, col_end = -1 })
        end

        table.insert(lines, '      ' .. item.desc)
        table.insert(highlights, { line = line_num + 1, hl_group = 'Comment', col_start = 0, col_end = -1 })

        table.insert(selectable, line_num)
        action_map[line_num] = item.id
      end
    end

    -- Footer
    table.insert(lines, '')
    table.insert(lines, '  ' .. string.rep('─', 76))
    table.insert(highlights, { line = #lines - 1, hl_group = 'FloatBorder', col_start = 0, col_end = -1 })

    table.insert(lines, '  ↑↓ j/k Navigate  │  Enter Select  │  q/Esc Cancel')
    table.insert(highlights, { line = #lines - 1, hl_group = '@comment', col_start = 0, col_end = -1 })
    table.insert(lines, '')

    return lines, highlights, selectable, action_map
  end

  local current_idx = 1
  local lines, highlights, selectable, action_map = render(current_idx)
  local buf, win = create_popup('⚡ Marvin Dashboard', 82, #lines)

  -- Update display function
  local function update_display()
    lines, highlights, selectable, action_map = render(current_idx)

    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

    -- Apply highlights
    local ns = vim.api.nvim_create_namespace('marvin_dashboard')
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    for _, hl in ipairs(highlights) do
      vim.api.nvim_buf_add_highlight(buf, ns, hl.hl_group, hl.line, hl.col_start, hl.col_end)
    end

    -- Position cursor EXACTLY on the line with the arrow
    if #selectable > 0 and current_idx <= #selectable then
      local line_num = selectable[current_idx]
      pcall(vim.api.nvim_win_set_cursor, win, { line_num, 0 })
    end
  end

  -- Initial display
  update_display()

  -- Navigation
  local function move(direction)
    if #selectable == 0 then return end

    if direction == 'down' then
      current_idx = current_idx < #selectable and current_idx + 1 or 1
    else
      current_idx = current_idx > 1 and current_idx - 1 or #selectable
    end

    update_display()
  end

  -- Selection handler
  local function select()
    if #selectable == 0 then return end
    local line_num = selectable[current_idx]
    local action_id = action_map[line_num]

    if not action_id then return end

    vim.api.nvim_win_close(win, true)
    M.handle_action(action_id)
  end

  -- Keymaps
  local opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('n', 'j', function() move('down') end, opts)
  vim.keymap.set('n', 'k', function() move('up') end, opts)
  vim.keymap.set('n', '<Down>', function() move('down') end, opts)
  vim.keymap.set('n', '<Up>', function() move('up') end, opts)
  vim.keymap.set('n', '<C-n>', function() move('down') end, opts)
  vim.keymap.set('n', '<C-p>', function() move('up') end, opts)

  vim.keymap.set('n', '<CR>', select, opts)
  vim.keymap.set('n', '<Space>', select, opts)

  vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, true) end, opts)
  vim.keymap.set('n', '<Esc>', function() vim.api.nvim_win_close(win, true) end, opts)

  -- Prevent insert mode
  vim.keymap.set('n', 'i', '<Nop>', opts)
  vim.keymap.set('n', 'I', '<Nop>', opts)
  vim.keymap.set('n', 'a', '<Nop>', opts)
  vim.keymap.set('n', 'A', '<Nop>', opts)
  vim.keymap.set('n', 'o', '<Nop>', opts)
  vim.keymap.set('n', 'O', '<Nop>', opts)
end

-- Handle dashboard actions
function M.handle_action(action_id)
  if action_id == 'new_project' then
    require('marvin.generator').create_project()
  elseif action_id == 'run_goal' then
    require('marvin.ui').show_goal_menu()
  elseif action_id == 'new_java_file' then
    require('marvin.java_creator').show_menu()
  elseif action_id == 'add_jackson' then
    require('marvin.dependencies').add_jackson()
  elseif action_id == 'add_lwjgl' then
    require('marvin.dependencies').add_lwjgl()
  elseif action_id == 'add_assembly' then
    require('marvin.dependencies').add_assembly_plugin()
  elseif action_id == 'set_java_version' then
    M.prompt_java_version()
  elseif action_id == 'package' then
    require('marvin.executor').run('package')
  elseif action_id == 'package_fat' then
    require('marvin.executor').run('package assembly:single')
  elseif action_id == 'clean_install' then
    require('marvin.executor').run('clean install')
  end
end

-- Prompt for Java version
function M.prompt_java_version()
  local versions = {
    { version = '21', label = 'Java 21 (LTS)', desc = 'Latest LTS release' },
    { version = '17', label = 'Java 17 (LTS)', desc = 'Stable LTS release' },
    { version = '11', label = 'Java 11 (LTS)', desc = 'Older LTS release' },
    { version = '8',  label = 'Java 8 (LTS)',  desc = 'Legacy LTS release' },
  }

  require('marvin.ui').select(versions, {
    prompt = 'Select Java Version',
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      require('marvin.dependencies').set_java_version(choice.version)
    end
  end)
end

return M
