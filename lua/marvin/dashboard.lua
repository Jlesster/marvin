local M = {}

-- Create centered popup
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
    border = {
      { '╭', 'FloatBorder' },
      { '─', 'FloatBorder' },
      { '╮', 'FloatBorder' },
      { '│', 'FloatBorder' },
      { '╯', 'FloatBorder' },
      { '─', 'FloatBorder' },
      { '╰', 'FloatBorder' },
      { '│', 'FloatBorder' },
    },
    title = title and { { ' ' .. title .. ' ', 'FloatTitle' } } or nil,
    title_pos = 'center',
  }

  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')
  vim.api.nvim_win_set_option(win, 'cursorline', true)

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

  -- Detect if in Maven project (but don't require it)
  local in_maven_project = project.detect()

  local menu_items = {
    { type = 'header', label = '󱁻 Project Actions' },
    { type = 'action', id = 'new_project', label = ' Create New Maven Project', icon = '', desc = 'Generate a new Maven project from archetype' },
  }

  -- Add Maven-specific actions if in a Maven project
  if in_maven_project then
    table.insert(menu_items,
      { type = 'action', id = 'run_goal', label = ' Run Maven Goal', icon = '', desc = 'Execute any Maven goal' })

    table.insert(menu_items, { type = 'separator' })

    table.insert(menu_items, { type = 'header', label = '󱑤 Add Dependencies' })
    table.insert(menu_items,
      {
        type = 'action',
        id = 'add_jackson',
        label = ' Add Jackson JSON',
        icon = '',
        desc =
        'Add Jackson JSON library (2.18.2)'
      })
    table.insert(menu_items,
      {
        type = 'action',
        id = 'add_lwjgl',
        label = '󰊖 Add LWJGL',
        icon = '',
        desc =
        'Add LWJGL 3.3.6 with platform natives'
      })

    table.insert(menu_items, { type = 'separator' })

    table.insert(menu_items, { type = 'header', label = '🔧 Build Tools' })

    table.insert(menu_items,
      {
        type = 'action',
        id = 'set_java_version',
        label = 'Set Java Version',
        icon = '',
        desc =
        'Configure Java compiler version'
      })

    -- Check if assembly plugin is already configured
    local has_assembly = has_assembly_plugin()

    if not has_assembly then
      table.insert(menu_items,
        {
          type = 'action',
          id = 'add_assembly',
          label = '󰬷 Setup Fat JAR Build',
          icon = '',
          desc =
          'Add Maven Assembly Plugin'
        })
    end

    table.insert(menu_items,
      {
        type = 'action',
        id = 'package',
        label = ' Package Project (Regular JAR)',
        icon = '',
        desc =
        'Build regular JAR with mvn package'
      })

    if has_assembly then
      table.insert(menu_items,
        {
          type = 'action',
          id = 'package_fat',
          label = ' Build Fat JAR',
          icon = '',
          desc =
          'Build executable JAR with dependencies'
        })
    end

    table.insert(menu_items,
      { type = 'action', id = 'clean_install', label = ' Clean Install', icon = '', desc = 'Run mvn clean install' })
  end

  local lines = {}
  local selectable = {}
  local action_map = {}

  table.insert(lines, '')
  table.insert(lines, '  MARVIN - Maven for Neovim')
  table.insert(lines, '')

  if in_maven_project then
    local proj_info = project.get_project()
    if proj_info and proj_info.info then
      table.insert(lines,
        string.format('  Project: %s:%s', proj_info.info.group_id or 'unknown', proj_info.info.artifact_id or 'unknown'))
    end
  else
    table.insert(lines, '   Not in a Maven project - Create a new one!')
  end

  table.insert(lines, '')
  table.insert(lines, '  ═══════════════════════════════════════════════════════════════════')
  table.insert(lines, '')

  for _, item in ipairs(menu_items) do
    if item.type == 'header' then
      table.insert(lines, '')
      table.insert(lines, '  ' .. item.label)
      table.insert(lines, '  ' .. string.rep('─', 68))
    elseif item.type == 'separator' then
      table.insert(lines, '')
    elseif item.type == 'action' then
      local line_num = #lines + 1
      table.insert(lines, '')
      table.insert(lines, '    ' .. item.icon .. ' ' .. item.label)
      table.insert(lines, '      ' .. item.desc)
      table.insert(selectable, line_num + 1)
      action_map[line_num + 1] = item.id
    end
  end

  table.insert(lines, '')
  table.insert(lines, '  ═══════════════════════════════════════════════════════════════════')
  table.insert(lines, '')
  table.insert(lines, '  ↑/↓ j/k Navigate  │  Enter Select  │  q/Esc Cancel')
  table.insert(lines, '')

  local buf, win = create_popup(' Marvin Dashboard', 76, #lines)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')

  -- Highlighting
  local ns = vim.api.nvim_create_namespace('marvin_dashboard')
  for i, line in ipairs(lines) do
    if line:match('⚡ MARVIN') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Title', i - 1, 0, -1)
    elseif line:match('Project:') or line:match('📁') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'String', i - 1, 0, -1)
    elseif line:match('🚀') or line:match('📚') or line:match('🔧') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Title', i - 1, 0, -1)
    elseif line:match('═') or line:match('─') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'FloatBorder', i - 1, 0, -1)
      -- FIX: Escape the square brackets with % to treat them as literal characters
    elseif line:match('%[%]') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Special', i - 1, 0, -1)
    elseif line:match('^%s+[A-Z]') and not line:match('MARVIN') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
    elseif line:match('↑/↓') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
    end
  end

  -- Selection state
  local current_idx = 1
  local highlight_ns = vim.api.nvim_create_namespace('marvin_select')

  local function update_highlight()
    vim.api.nvim_buf_clear_namespace(buf, highlight_ns, 0, -1)
    local line_num = selectable[current_idx]
    vim.api.nvim_buf_add_highlight(buf, highlight_ns, 'Visual', line_num - 1, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, highlight_ns, 'Visual', line_num, 0, -1)
    vim.api.nvim_win_set_cursor(win, { line_num, 0 })
  end

  update_highlight()

  -- Handle selection
  local function select()
    local line_num = selectable[current_idx]
    local action_id = action_map[line_num]

    if not action_id then return end

    vim.api.nvim_win_close(win, true)
    M.handle_action(action_id)
  end

  -- Keymaps
  local opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('n', 'j', function()
    if current_idx < #selectable then
      current_idx = current_idx + 1
      update_highlight()
    end
  end, opts)

  vim.keymap.set('n', 'k', function()
    if current_idx > 1 then
      current_idx = current_idx - 1
      update_highlight()
    end
  end, opts)

  vim.keymap.set('n', '<Down>', function()
    if current_idx < #selectable then
      current_idx = current_idx + 1
      update_highlight()
    end
  end, opts)

  vim.keymap.set('n', '<Up>', function()
    if current_idx > 1 then
      current_idx = current_idx - 1
      update_highlight()
    end
  end, opts)

  vim.keymap.set('n', '<CR>', select, opts)
  vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, true) end, opts)
  vim.keymap.set('n', '<Esc>', function() vim.api.nvim_win_close(win, true) end, opts)
end

-- Handle dashboard actions
function M.handle_action(action_id)
  if action_id == 'new_project' then
    require('marvin.generator').create_project()
  elseif action_id == 'run_goal' then
    require('marvin.ui').show_goal_menu()
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
    -- Run assembly:single which creates the fat JAR
    require('marvin.executor').run('package assembly:single')
  elseif action_id == 'clean_install' then
    require('marvin.executor').run('clean install')
  end
end

-- Prompt for Java version
function M.prompt_java_version()
  local versions = {
    { version = '21', label = 'Java 21 (LTS)' },
    { version = '17', label = 'Java 17 (LTS)' },
    { version = '11', label = 'Java 11 (LTS)' },
    { version = '8',  label = 'Java 8 (LTS)' },
  }

  vim.ui.select(versions, {
    prompt = '☕ Select Java Version:',
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
