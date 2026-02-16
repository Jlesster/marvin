local M = {}

-- Create a centered floating window with modern styling
local function create_popup(title, width, height)
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Calculate center position
  local ui = vim.api.nvim_list_uis()[1]
  
  -- If width/height are numbers > 1, use them as absolute values
  -- Otherwise treat as percentages
  local win_width = width > 1 and width or math.floor(width * ui.width)
  local win_height = height > 1 and height or math.floor(height * ui.height)
  local row = math.floor((ui.height - win_height) / 2)
  local col = math.floor((ui.width - win_width) / 2)
  
  -- Window options with border
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
  
  -- Set window options
  vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  
  return buf, win
end

-- Project generation wizard with custom UI
function M.create_project()
  M.show_archetype_wizard()
end

function M.show_archetype_wizard()
  local config = require('marvin').config
  local archetypes = {}
  
  -- Header section
  table.insert(archetypes, {
    type = 'header',
    label = '✨ Popular Archetypes',
    selectable = false,
  })
  
  -- Build archetype list from config
  for i, archetype_id in ipairs(config.archetypes) do
    table.insert(archetypes, {
      type = 'archetype',
      id = archetype_id,
      label = M.format_archetype_name(archetype_id),
      description = M.get_archetype_description(archetype_id),
      icon = M.get_archetype_icon(archetype_id),
      selectable = true,
    })
  end
  
  -- Separator
  table.insert(archetypes, {
    type = 'separator',
    selectable = false,
  })
  
  -- Advanced options header
  table.insert(archetypes, {
    type = 'header',
    label = '🔧 Advanced Options',
    selectable = false,
  })
  
  -- Add local archetype option
  table.insert(archetypes, {
    type = 'action',
    id = 'local',
    label = 'Use Local Archetype',
    description = 'Browse installed archetypes from local repository',
    icon = '📦',
    selectable = true,
  })
  
  -- Add search option
  table.insert(archetypes, {
    type = 'action',
    id = 'search',
    label = 'Search Maven Central',
    description = 'Find and use any archetype from Maven Central',
    icon = '🔍',
    selectable = true,
  })
  
  -- Add custom archetype option
  table.insert(archetypes, {
    type = 'action',
    id = 'custom',
    label = 'Custom Archetype Coordinates',
    description = 'Enter full Maven coordinates manually',
    icon = '⚙️',
    selectable = true,
  })
  
  -- Build content first to calculate size
  local lines = {}
  local selectable_lines = {}
  local line_to_item = {}
  
  table.insert(lines, '')
  table.insert(lines, '  Create a new Maven project from an archetype')
  table.insert(lines, '')
  
  for idx, archetype in ipairs(archetypes) do
    if archetype.type == 'header' then
      table.insert(lines, '')
      table.insert(lines, '  ' .. archetype.label)
      table.insert(lines, '  ' .. string.rep('─', 70))
    elseif archetype.type == 'separator' then
      table.insert(lines, '')
    elseif archetype.type == 'archetype' or archetype.type == 'action' then
      local line_num = #lines + 1
      table.insert(lines, '')
      table.insert(lines, '    ' .. archetype.icon .. '  ' .. archetype.label)
      if archetype.description then
        table.insert(lines, '       ' .. archetype.description)
      end
      
      if archetype.selectable then
        table.insert(selectable_lines, line_num + 1)
        line_to_item[line_num + 1] = archetype
      end
    end
  end
  
  table.insert(lines, '')
  table.insert(lines, '')
  table.insert(lines, '  ┌' .. string.rep('─', 70) .. '┐')
  table.insert(lines, '  │  Navigation: ↑/↓ or j/k  │  Select: Enter  │  Quit: q/Esc            │')
  table.insert(lines, '  └' .. string.rep('─', 70) .. '┘')
  
  -- Calculate window size based on content
  local content_width = 76  -- 70 + 6 for padding
  local content_height = #lines
  
  -- Create popup with fixed size
  local buf, win = create_popup('🔨 Maven Project Generator', content_width, content_height)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  
  -- Create namespace for highlights
  local ns = vim.api.nvim_create_namespace('marvin_wizard')
  
  -- Add syntax highlighting
  for i, line in ipairs(lines) do
    if line:match('^%s+✨') or line:match('^%s+🔧') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Title', i - 1, 0, -1)
    elseif line:match('^%s+─') and not line:match('┌') and not line:match('└') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
    elseif line:match('┌') or line:match('└') or line:match('│') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'FloatBorder', i - 1, 0, -1)
    elseif line:match('^%s+%s+%s+[📦🔍⚙️⚡🌐📋]') then
      -- Highlight icon
      vim.api.nvim_buf_add_highlight(buf, ns, 'Special', i - 1, 0, -1)
    elseif line:match('^%s+%s+%s+%s+%s+%s+') then
      -- Description text
      vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
    end
  end
  
  -- Set initial cursor position to first selectable item
  local current_idx = 1
  local current_line = selectable_lines[current_idx]
  
  local highlight_ns = vim.api.nvim_create_namespace('marvin_selection')
  
  local function highlight_line(line_num)
    vim.api.nvim_buf_clear_namespace(buf, highlight_ns, 0, -1)
    if line_num then
      -- Highlight the main line
      vim.api.nvim_buf_add_highlight(buf, highlight_ns, 'CursorLine', line_num - 1, 0, -1)
      -- Also highlight description line if it exists
      if lines[line_num + 1] and lines[line_num + 1]:match('^%s+%s+%s+%s+%s+%s+') then
        vim.api.nvim_buf_add_highlight(buf, highlight_ns, 'CursorLine', line_num, 0, -1)
      end
    end
  end
  
  highlight_line(current_line)
  vim.api.nvim_win_set_cursor(win, {current_line, 0})
  
  -- Handle selection
  local function select_item()
    local selected = line_to_item[current_line]
    if not selected then return end
    
    -- Close window
    vim.api.nvim_win_close(win, true)
    
    if selected.type == 'archetype' then
      M.show_project_details_wizard(selected.id)
    elseif selected.id == 'search' then
      M.show_search_maven_central()
    elseif selected.id == 'local' then
      M.show_local_archetypes()
    elseif selected.id == 'custom' then
      M.show_custom_archetype_input()
    end
  end
  
  -- Navigation functions
  local function move_down()
    if current_idx < #selectable_lines then
      current_idx = current_idx + 1
      current_line = selectable_lines[current_idx]
      vim.api.nvim_win_set_cursor(win, {current_line, 0})
      highlight_line(current_line)
    end
  end
  
  local function move_up()
    if current_idx > 1 then
      current_idx = current_idx - 1
      current_line = selectable_lines[current_idx]
      vim.api.nvim_win_set_cursor(win, {current_line, 0})
      highlight_line(current_line)
    end
  end
  
  -- Keymaps for navigation
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set('n', 'j', move_down, opts)
  vim.keymap.set('n', 'k', move_up, opts)
  vim.keymap.set('n', '<Down>', move_down, opts)
  vim.keymap.set('n', '<Up>', move_up, opts)
  vim.keymap.set('n', '<CR>', select_item, opts)
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
end

function M.show_local_archetypes()
  local ui = require('marvin.ui')
  ui.notify('🔍 Scanning local Maven repository...', vim.log.levels.INFO)
  
  -- Get local archetypes from Maven repository
  local home = os.getenv('HOME') or os.getenv('USERPROFILE')
  local m2_repo = home .. '/.m2/repository'
  
  -- More comprehensive search - look for pom files with 'archetype' in path
  local cmd = string.format(
    'find "%s" -type f -path "*archetype*/*.pom" 2>/dev/null | grep -v "^$" | head -50',
    m2_repo
  )
  
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      local archetypes = {}
      local seen = {}
      
      for _, line in ipairs(data) do
        if line ~= '' and not line:match('^%s*

function M.show_archetype_selection_list(archetypes, title)
  -- Build content first
  local lines = { '', '  Select an archetype:', '', '' }
  
  for i, archetype in ipairs(archetypes) do
    table.insert(lines, '    ' .. i .. '. ' .. archetype)
    table.insert(lines, '')
  end
  
  table.insert(lines, '')
  table.insert(lines, '  ┌' .. string.rep('─', 66) .. '┐')
  table.insert(lines, '  │  Use j/k or ↑/↓ to navigate  │  Enter to select  │  q to cancel  │')
  table.insert(lines, '  └' .. string.rep('─', 66) .. '┘')
  
  -- Calculate size
  local content_width = 72
  local content_height = #lines
  
  local buf, win = create_popup('📦 ' .. title, content_width, content_height)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  local selectable_start = 5  -- First archetype line
  local current_line = selectable_start
  local ns = vim.api.nvim_create_namespace('marvin_selection')
  
  local function highlight_line(line_num)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, 'CursorLine', line_num - 1, 0, -1)
  end
  
  highlight_line(current_line)
  vim.api.nvim_win_set_cursor(win, {current_line, 0})
  
  local function select_archetype()
    local idx = math.floor((current_line - selectable_start) / 2) + 1
    if idx > 0 and idx <= #archetypes then
      vim.api.nvim_win_close(win, true)
      M.show_project_details_wizard(archetypes[idx])
    end
  end
  
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set('n', 'j', function()
    local max_line = selectable_start + (#archetypes - 1) * 2
    if current_line < max_line then
      current_line = current_line + 2
      vim.api.nvim_win_set_cursor(win, {current_line, 0})
      highlight_line(current_line)
    end
  end, opts)
  
  vim.keymap.set('n', 'k', function()
    if current_line > selectable_start then
      current_line = current_line - 2
      vim.api.nvim_win_set_cursor(win, {current_line, 0})
      highlight_line(current_line)
    end
  end, opts)
  
  vim.keymap.set('n', '<CR>', select_archetype, opts)
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
end

function M.show_search_maven_central()
  vim.ui.input({
    prompt = '🔍 Search Maven Central (e.g., "spring-boot", "quarkus"): ',
    default = '',
  }, function(search_term)
    if not search_term or search_term == '' then
      return
    end
    
    local ui = require('marvin.ui')
    ui.notify('🔍 Searching Maven Central for: ' .. search_term, vim.log.levels.INFO)
    
    -- Common archetype patterns
    local common_archetypes = {
      'org.springframework.boot:spring-boot-starter-archetype',
      'io.quarkus:quarkus-amazon-lambda-archetype',
      'org.apache.maven.archetypes:maven-archetype-quickstart',
      'org.apache.maven.archetypes:maven-archetype-webapp',
      'org.apache.maven.archetypes:maven-archetype-j2ee-simple',
      'io.micronaut:micronaut-application-archetype',
    }
    
    -- Filter based on search
    local matches = {}
    for _, archetype in ipairs(common_archetypes) do
      if archetype:lower():find(search_term:lower()) then
        table.insert(matches, archetype)
      end
    end
    
    if #matches == 0 then
      ui.notify('No matches found. Try entering custom coordinates.', vim.log.levels.WARN)
      M.show_custom_archetype_input()
    else
      M.show_archetype_selection_list(matches, 'Search Results')
    end
  end)
end

function M.show_custom_archetype_input()
  vim.ui.input({
    prompt = '⚙️  Enter archetype coordinates (groupId:artifactId:version): ',
    default = 'org.apache.maven.archetypes:maven-archetype-quickstart:1.4',
  }, function(coordinates)
    if not coordinates or coordinates == '' then
      return
    end
    
    -- Validate format
    local parts = vim.split(coordinates, ':')
    if #parts < 2 then
      local ui = require('marvin.ui')
      ui.notify('Invalid format. Use groupId:artifactId:version', vim.log.levels.ERROR)
      return
    end
    
    M.show_project_details_wizard(coordinates)
  end)
end

function M.show_project_details_wizard(archetype)
  local details = {
    group_id = 'com.example',
    artifact_id = 'my-app',
    version = '1.0-SNAPSHOT',
    package = '',
  }
  
  local fields = {
    { name = 'group_id', label = 'Group ID', placeholder = 'com.example', help = 'Your organization domain (e.g., com.company)' },
    { name = 'artifact_id', label = 'Artifact ID', placeholder = 'my-app', help = 'Project name (lowercase, no spaces)' },
    { name = 'version', label = 'Version', placeholder = '1.0-SNAPSHOT', help = 'Initial version number' },
    { name = 'package', label = 'Package', placeholder = 'com.example.app', help = 'Base package (leave empty to use Group ID)' },
  }
  
  local current_field = 1
  
  -- Fixed window size
  local content_width = 76
  local content_height = 28
  
  local buf, win = create_popup('📝 Project Configuration', content_width, content_height)
  
  local function render()
    local lines = {}
    
    table.insert(lines, '')
    table.insert(lines, '  📦 Creating: ' .. M.format_archetype_display(archetype))
    table.insert(lines, '')
    table.insert(lines, '  ✨ Project Configuration')
    table.insert(lines, '  ' .. string.rep('─', 68))
    table.insert(lines, '')
    
    for i, field in ipairs(fields) do
      local value = details[field.name]
      if value == '' then
        value = field.placeholder
      end
      
      local is_current = i == current_field
      local prefix = is_current and '  ▶' or '   '
      local display_value = value ~= '' and value or field.placeholder
      
      -- Field label
      table.insert(lines, prefix .. ' ' .. field.label)
      
      -- Field value
      local value_line = '      ' .. display_value
      if is_current then
        value_line = value_line .. ' ◀'
      end
      table.insert(lines, value_line)
      
      -- Help text (only for current field)
      if is_current then
        table.insert(lines, '      ↳ ' .. field.help)
      end
      
      table.insert(lines, '')
    end
    
    table.insert(lines, '  📋 Preview')
    table.insert(lines, '  ' .. string.rep('─', 68))
    table.insert(lines, '')
    table.insert(lines, '    Maven Coordinates: ' .. details.group_id .. ':' .. details.artifact_id .. ':' .. details.version)
    local pkg = details.package ~= '' and details.package or details.group_id
    table.insert(lines, '    Package Structure: ' .. pkg:gsub('%.', '/') .. '/')
    table.insert(lines, '')
    table.insert(lines, '')
    table.insert(lines, '  ┌' .. string.rep('─', 68) .. '┐')
    table.insert(lines, '  │  Tab/Shift-Tab: Navigate  │  Enter: Edit  │  Ctrl-G: Generate  │  q: Cancel  │')
    table.insert(lines, '  └' .. string.rep('─', 68) .. '┘')
    
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    -- Highlight
    local ns = vim.api.nvim_create_namespace('marvin_wizard')
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    
    for i, line in ipairs(lines) do
      if line:match('^%s+✨') or line:match('^%s+📋') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'Title', i - 1, 0, -1)
      elseif line:match('^%s+─') and not line:match('┌') and not line:match('└') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
      elseif line:match('┌') or line:match('└') or line:match('│') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'FloatBorder', i - 1, 0, -1)
      elseif line:match('^%s+▶') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'CursorLine', i - 1, 0, -1)
      elseif line:match('◀') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'CursorLine', i - 1, 0, -1)
      elseif line:match('↳') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
      end
    end
  end
  
  render()
  
  local function edit_field()
    local field = fields[current_field]
    local current_value = details[field.name]
    
    vim.ui.input({
      prompt = field.label .. ': ',
      default = current_value ~= '' and current_value or field.placeholder,
    }, function(input)
      if input then
        details[field.name] = input
        render()
      end
    end)
  end
  
  local function generate_project()
    if details.package == '' then
      details.package = details.group_id
    end
    
    vim.api.nvim_win_close(win, true)
    
    M.show_directory_selector(function(directory)
      if directory then
        M.generate(archetype, details, directory)
      end
    end)
  end
  
  -- Keymaps
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set('n', '<Tab>', function()
    current_field = current_field % #fields + 1
    render()
  end, opts)
  
  vim.keymap.set('n', '<S-Tab>', function()
    current_field = current_field - 1
    if current_field < 1 then current_field = #fields end
    render()
  end, opts)
  
  vim.keymap.set('n', '<CR>', edit_field, opts)
  vim.keymap.set('n', '<C-g>', generate_project, opts)
  vim.keymap.set('n', 'e', edit_field, opts)
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
  
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
end

function M.show_directory_selector(callback)
  local current_dir = vim.fn.getcwd()
  local home_dir = os.getenv('HOME') or os.getenv('USERPROFILE')
  
  local lines = {
    '',
    '  Where should the project be created?',
    '',
    '  ✨ Quick Options',
    '  ' .. string.rep('─', 66),
    '',
    '    1. Current Directory',
    '       ' .. current_dir,
    '',
    '    2. Home Directory',
    '       ' .. home_dir,
    '',
    '    3. Custom Path',
    '       Enter a custom directory path',
    '',
    '',
    '  ┌' .. string.rep('─', 66) .. '┐',
    '  │  1/2/3: Select option  │  c: Custom  │  Enter: Current  │  q: Cancel  │',
    '  └' .. string.rep('─', 66) .. '┘',
  }
  
  local content_width = 72
  local content_height = #lines
  
  local buf, win = create_popup('📁 Select Directory', content_width, content_height)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Highlight
  local ns = vim.api.nvim_create_namespace('marvin_wizard')
  for i, line in ipairs(lines) do
    if line:match('✨') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Title', i - 1, 0, -1)
    elseif line:match('^%s+─') and not line:match('┌') and not line:match('└') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
    elseif line:match('┌') or line:match('└') or line:match('│') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'FloatBorder', i - 1, 0, -1)
    end
  end
  
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set('n', '1', function()
    vim.api.nvim_win_close(win, true)
    callback(current_dir)
  end, opts)
  
  vim.keymap.set('n', '2', function()
    vim.api.nvim_win_close(win, true)
    callback(home_dir)
  end, opts)
  
  vim.keymap.set('n', '3', function()
    vim.api.nvim_win_close(win, true)
    
    vim.ui.input({
      prompt = 'Directory path: ',
      default = current_dir,
      completion = 'dir',
    }, function(input)
      if input then
        callback(input)
      end
    end)
  end, opts)
  
  vim.keymap.set('n', 'c', function()
    vim.api.nvim_win_close(win, true)
    
    vim.ui.input({
      prompt = 'Directory path: ',
      default = current_dir,
      completion = 'dir',
    }, function(input)
      if input then
        callback(input)
      end
    end)
  end, opts)
  
  vim.keymap.set('n', '<CR>', function()
    vim.api.nvim_win_close(win, true)
    callback(current_dir)
  end, opts)
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
    callback(nil)
  end, opts)
  
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
    callback(nil)
  end, opts)
end

function M.format_archetype_name(archetype_id)
  if archetype_id:match(':') then
    local parts = vim.split(archetype_id, ':')
    return parts[#parts - 1] or archetype_id
  end
  
  local name = archetype_id:gsub('maven%-archetype%-', '')
  return name:sub(1, 1):upper() .. name:sub(2)
end

function M.format_archetype_display(archetype_id)
  if archetype_id:match(':') then
    return archetype_id
  end
  return M.format_archetype_name(archetype_id)
end

function M.get_archetype_description(archetype_id)
  local descriptions = {
    ['maven-archetype-quickstart'] = 'Simple Java console application',
    ['maven-archetype-webapp'] = 'Java web application with servlet support',
    ['maven-archetype-simple'] = 'Minimal Maven project structure',
  }
  return descriptions[archetype_id] or 'Maven project archetype'
end

function M.get_archetype_icon(archetype_id)
  local icons = {
    ['maven-archetype-quickstart'] = '⚡',
    ['maven-archetype-webapp'] = '🌐',
    ['maven-archetype-simple'] = '📋',
  }
  return icons[archetype_id] or '🔨'
end

function M.generate(archetype, details, directory)
  local config = require('marvin').config
  local ui = require('marvin.ui')
  
  -- Build archetype generate command
  local archetype_parts = vim.split(archetype, ':')
  local cmd_parts = {
    config.maven_command,
    'archetype:generate',
    '-B',
  }
  
  if #archetype_parts >= 2 then
    table.insert(cmd_parts, '-DarchetypeGroupId=' .. archetype_parts[1])
    table.insert(cmd_parts, '-DarchetypeArtifactId=' .. archetype_parts[2])
    if archetype_parts[3] then
      table.insert(cmd_parts, '-DarchetypeVersion=' .. archetype_parts[3])
    end
  else
    table.insert(cmd_parts, '-DarchetypeArtifactId=' .. archetype)
  end
  
  table.insert(cmd_parts, '-DgroupId=' .. details.group_id)
  table.insert(cmd_parts, '-DartifactId=' .. details.artifact_id)
  table.insert(cmd_parts, '-Dversion=' .. details.version)
  table.insert(cmd_parts, '-Dpackage=' .. details.package)
  
  local cmd = table.concat(cmd_parts, ' ')
  
  ui.notify('🔨 Generating project...', vim.log.levels.INFO)
  
  M.show_generation_progress(details.artifact_id)
  
  vim.fn.jobstart(cmd, {
    cwd = directory,
    on_exit = function(_, exit_code, _)
      if exit_code == 0 then
        M.on_generation_complete(details, directory)
      else
        ui.notify('❌ Project generation failed!', vim.log.levels.ERROR)
        M.close_progress_window()
      end
    end,
  })
end

function M.show_generation_progress(artifact_id)
  local lines = {
    '',
    '',
    '    ⠋  Creating ' .. artifact_id .. '...',
    '',
    '    Maven is downloading dependencies and',
    '    generating project structure.',
    '',
    '    Please wait...',
    '',
    '',
  }
  
  local content_width = 56
  local content_height = #lines
  
  local buf, win = create_popup('🔨 Generating Project', content_width, content_height)
  
  local frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
  local frame = 1
  
  local function update()
    local lines = {
      '',
      '',
      '    ' .. frames[frame] .. '  Creating ' .. artifact_id .. '...',
      '',
      '    Maven is downloading dependencies and',
      '    generating project structure.',
      '',
      '    Please wait...',
      '',
      '',
    }
    
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    frame = (frame % #frames) + 1
  end
  
  local timer = vim.loop.new_timer()
  timer:start(0, 100, vim.schedule_wrap(function()
    if vim.api.nvim_win_is_valid(win) then
      update()
    else
      timer:stop()
    end
  end))
  
  M._progress_win = win
  M._progress_timer = timer
end

function M.close_progress_window()
  if M._progress_win and vim.api.nvim_win_is_valid(M._progress_win) then
    vim.api.nvim_win_close(M._progress_win, true)
  end
  if M._progress_timer then
    M._progress_timer:stop()
  end
end

function M.on_generation_complete(details, directory)
  local ui = require('marvin.ui')
  local project_path = directory .. '/' .. details.artifact_id
  
  M.close_progress_window()
  
  ui.notify('✅ Project generated successfully!', vim.log.levels.INFO)
  
  local lines = {
    '',
    '',
    '    🎉 Project created successfully!',
    '',
    '  ✨ Project Details',
    '  ' .. string.rep('─', 66),
    '',
    '    Name:     ' .. details.artifact_id,
    '    Location: ' .. project_path,
    '    Package:  ' .. details.package,
    '',
    '  📝 Next Steps',
    '  ' .. string.rep('─', 66),
    '',
    '    • Press Enter to open the project',
    '    • Press o to open in file manager',
    '    • Press q to close this dialog',
    '',
    '',
    '  ┌' .. string.rep('─', 66) .. '┐',
    '  │  Enter: Open Project  │  o: File Manager  │  q: Close  │',
    '  └' .. string.rep('─', 66) .. '┘',
  }
  
  local content_width = 72
  local content_height = #lines
  
  local buf, win = create_popup('✅ Success!', content_width, content_height)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Highlight
  local ns = vim.api.nvim_create_namespace('marvin_wizard')
  for i, line in ipairs(lines) do
    if line:match('✨') or line:match('📝') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Title', i - 1, 0, -1)
    elseif line:match('^%s+─') and not line:match('┌') and not line:match('└') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
    elseif line:match('┌') or line:match('└') or line:match('│') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'FloatBorder', i - 1, 0, -1)
    end
  end
  
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set('n', '<CR>', function()
    vim.api.nvim_win_close(win, true)
    vim.cmd('cd ' .. vim.fn.fnameescape(project_path))
    vim.cmd('edit ' .. vim.fn.fnameescape(project_path .. '/pom.xml'))
  end, opts)
  
  vim.keymap.set('n', 'o', function()
    vim.api.nvim_win_close(win, true)
    local open_cmd = vim.fn.has('mac') == 1 and 'open' or (vim.fn.has('win32') == 1 and 'explorer' or 'xdg-open')
    vim.fn.jobstart(open_cmd .. ' ' .. vim.fn.shellescape(project_path))
  end, opts)
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
  
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
end

return M) then
          -- Path format: ~/.m2/repository/com/example/my-archetype/1.0/my-archetype-1.0.pom
          local parts = vim.split(line, '/')
          
          -- Find 'repository' index
          local repo_idx = nil
          for i, part in ipairs(parts) do
            if part == 'repository' then
              repo_idx = i
              break
            end
          end
          
          if repo_idx and #parts >= repo_idx + 3 then
            -- Get the version (second to last directory before filename)
            local version = parts[#parts - 1]
            -- Get the artifactId (third to last directory)
            local artifact_id = parts[#parts - 2]
            
            -- Only proceed if it has 'archetype' in the name
            if artifact_id:match('archetype') then
              -- Build groupId from everything between repository and artifactId
              local group_parts = {}
              for i = repo_idx + 1, #parts - 3 do
                table.insert(group_parts, parts[i])
              end
              
              local group_id = table.concat(group_parts, '.')
              
              if group_id ~= '' and artifact_id ~= '' and version ~= '' then
                local coordinates = group_id .. ':' .. artifact_id .. ':' .. version
                
                if not seen[coordinates] then
                  seen[coordinates] = true
                  table.insert(archetypes, {
                    coordinates = coordinates,
                    display = artifact_id .. ' (' .. version .. ')',
                  })
                end
              end
            end
          end
        end
      end
      
      vim.schedule(function()
        if #archetypes == 0 then
          ui.notify('No local archetypes found in ' .. m2_repo, vim.log.levels.WARN)
        else
          -- Extract just the coordinates for the selection list
          local archetype_list = {}
          for _, arch in ipairs(archetypes) do
            table.insert(archetype_list, arch.coordinates)
          end
          M.show_archetype_selection_list(archetype_list, 'Local Archetypes (' .. #archetypes .. ' found)')
        end
      end)
    end,
    on_stderr = function(_, data, _)
      -- Ignore stderr
    end,
  })
end

function M.show_archetype_selection_list(archetypes, title)
  -- Build content first
  local lines = { '', '  Select an archetype:', '', '' }
  
  for i, archetype in ipairs(archetypes) do
    table.insert(lines, '    ' .. i .. '. ' .. archetype)
    table.insert(lines, '')
  end
  
  table.insert(lines, '')
  table.insert(lines, '  ┌' .. string.rep('─', 66) .. '┐')
  table.insert(lines, '  │  Use j/k or ↑/↓ to navigate  │  Enter to select  │  q to cancel  │')
  table.insert(lines, '  └' .. string.rep('─', 66) .. '┘')
  
  -- Calculate size
  local content_width = 72
  local content_height = #lines
  
  local buf, win = create_popup('📦 ' .. title, content_width, content_height)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  local selectable_start = 5  -- First archetype line
  local current_line = selectable_start
  local ns = vim.api.nvim_create_namespace('marvin_selection')
  
  local function highlight_line(line_num)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, 'CursorLine', line_num - 1, 0, -1)
  end
  
  highlight_line(current_line)
  vim.api.nvim_win_set_cursor(win, {current_line, 0})
  
  local function select_archetype()
    local idx = math.floor((current_line - selectable_start) / 2) + 1
    if idx > 0 and idx <= #archetypes then
      vim.api.nvim_win_close(win, true)
      M.show_project_details_wizard(archetypes[idx])
    end
  end
  
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set('n', 'j', function()
    local max_line = selectable_start + (#archetypes - 1) * 2
    if current_line < max_line then
      current_line = current_line + 2
      vim.api.nvim_win_set_cursor(win, {current_line, 0})
      highlight_line(current_line)
    end
  end, opts)
  
  vim.keymap.set('n', 'k', function()
    if current_line > selectable_start then
      current_line = current_line - 2
      vim.api.nvim_win_set_cursor(win, {current_line, 0})
      highlight_line(current_line)
    end
  end, opts)
  
  vim.keymap.set('n', '<CR>', select_archetype, opts)
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
end

function M.show_search_maven_central()
  vim.ui.input({
    prompt = '🔍 Search Maven Central (e.g., "spring-boot", "quarkus"): ',
    default = '',
  }, function(search_term)
    if not search_term or search_term == '' then
      return
    end
    
    local ui = require('marvin.ui')
    ui.notify('🔍 Searching Maven Central for: ' .. search_term, vim.log.levels.INFO)
    
    -- Common archetype patterns
    local common_archetypes = {
      'org.springframework.boot:spring-boot-starter-archetype',
      'io.quarkus:quarkus-amazon-lambda-archetype',
      'org.apache.maven.archetypes:maven-archetype-quickstart',
      'org.apache.maven.archetypes:maven-archetype-webapp',
      'org.apache.maven.archetypes:maven-archetype-j2ee-simple',
      'io.micronaut:micronaut-application-archetype',
    }
    
    -- Filter based on search
    local matches = {}
    for _, archetype in ipairs(common_archetypes) do
      if archetype:lower():find(search_term:lower()) then
        table.insert(matches, archetype)
      end
    end
    
    if #matches == 0 then
      ui.notify('No matches found. Try entering custom coordinates.', vim.log.levels.WARN)
      M.show_custom_archetype_input()
    else
      M.show_archetype_selection_list(matches, 'Search Results')
    end
  end)
end

function M.show_custom_archetype_input()
  vim.ui.input({
    prompt = '⚙️  Enter archetype coordinates (groupId:artifactId:version): ',
    default = 'org.apache.maven.archetypes:maven-archetype-quickstart:1.4',
  }, function(coordinates)
    if not coordinates or coordinates == '' then
      return
    end
    
    -- Validate format
    local parts = vim.split(coordinates, ':')
    if #parts < 2 then
      local ui = require('marvin.ui')
      ui.notify('Invalid format. Use groupId:artifactId:version', vim.log.levels.ERROR)
      return
    end
    
    M.show_project_details_wizard(coordinates)
  end)
end

function M.show_project_details_wizard(archetype)
  local details = {
    group_id = 'com.example',
    artifact_id = 'my-app',
    version = '1.0-SNAPSHOT',
    package = '',
  }
  
  local fields = {
    { name = 'group_id', label = 'Group ID', placeholder = 'com.example', help = 'Your organization domain (e.g., com.company)' },
    { name = 'artifact_id', label = 'Artifact ID', placeholder = 'my-app', help = 'Project name (lowercase, no spaces)' },
    { name = 'version', label = 'Version', placeholder = '1.0-SNAPSHOT', help = 'Initial version number' },
    { name = 'package', label = 'Package', placeholder = 'com.example.app', help = 'Base package (leave empty to use Group ID)' },
  }
  
  local current_field = 1
  
  -- Fixed window size
  local content_width = 76
  local content_height = 28
  
  local buf, win = create_popup('📝 Project Configuration', content_width, content_height)
  
  local function render()
    local lines = {}
    
    table.insert(lines, '')
    table.insert(lines, '  📦 Creating: ' .. M.format_archetype_display(archetype))
    table.insert(lines, '')
    table.insert(lines, '  ✨ Project Configuration')
    table.insert(lines, '  ' .. string.rep('─', 68))
    table.insert(lines, '')
    
    for i, field in ipairs(fields) do
      local value = details[field.name]
      if value == '' then
        value = field.placeholder
      end
      
      local is_current = i == current_field
      local prefix = is_current and '  ▶' or '   '
      local display_value = value ~= '' and value or field.placeholder
      
      -- Field label
      table.insert(lines, prefix .. ' ' .. field.label)
      
      -- Field value
      local value_line = '      ' .. display_value
      if is_current then
        value_line = value_line .. ' ◀'
      end
      table.insert(lines, value_line)
      
      -- Help text (only for current field)
      if is_current then
        table.insert(lines, '      ↳ ' .. field.help)
      end
      
      table.insert(lines, '')
    end
    
    table.insert(lines, '  📋 Preview')
    table.insert(lines, '  ' .. string.rep('─', 68))
    table.insert(lines, '')
    table.insert(lines, '    Maven Coordinates: ' .. details.group_id .. ':' .. details.artifact_id .. ':' .. details.version)
    local pkg = details.package ~= '' and details.package or details.group_id
    table.insert(lines, '    Package Structure: ' .. pkg:gsub('%.', '/') .. '/')
    table.insert(lines, '')
    table.insert(lines, '')
    table.insert(lines, '  ┌' .. string.rep('─', 68) .. '┐')
    table.insert(lines, '  │  Tab/Shift-Tab: Navigate  │  Enter: Edit  │  Ctrl-G: Generate  │  q: Cancel  │')
    table.insert(lines, '  └' .. string.rep('─', 68) .. '┘')
    
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    -- Highlight
    local ns = vim.api.nvim_create_namespace('marvin_wizard')
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    
    for i, line in ipairs(lines) do
      if line:match('^%s+✨') or line:match('^%s+📋') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'Title', i - 1, 0, -1)
      elseif line:match('^%s+─') and not line:match('┌') and not line:match('└') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
      elseif line:match('┌') or line:match('└') or line:match('│') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'FloatBorder', i - 1, 0, -1)
      elseif line:match('^%s+▶') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'CursorLine', i - 1, 0, -1)
      elseif line:match('◀') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'CursorLine', i - 1, 0, -1)
      elseif line:match('↳') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
      end
    end
  end
  
  render()
  
  local function edit_field()
    local field = fields[current_field]
    local current_value = details[field.name]
    
    vim.ui.input({
      prompt = field.label .. ': ',
      default = current_value ~= '' and current_value or field.placeholder,
    }, function(input)
      if input then
        details[field.name] = input
        render()
      end
    end)
  end
  
  local function generate_project()
    if details.package == '' then
      details.package = details.group_id
    end
    
    vim.api.nvim_win_close(win, true)
    
    M.show_directory_selector(function(directory)
      if directory then
        M.generate(archetype, details, directory)
      end
    end)
  end
  
  -- Keymaps
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set('n', '<Tab>', function()
    current_field = current_field % #fields + 1
    render()
  end, opts)
  
  vim.keymap.set('n', '<S-Tab>', function()
    current_field = current_field - 1
    if current_field < 1 then current_field = #fields end
    render()
  end, opts)
  
  vim.keymap.set('n', '<CR>', edit_field, opts)
  vim.keymap.set('n', '<C-g>', generate_project, opts)
  vim.keymap.set('n', 'e', edit_field, opts)
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
  
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
end

function M.show_directory_selector(callback)
  local current_dir = vim.fn.getcwd()
  local home_dir = os.getenv('HOME') or os.getenv('USERPROFILE')
  
  local lines = {
    '',
    '  Where should the project be created?',
    '',
    '  ✨ Quick Options',
    '  ' .. string.rep('─', 66),
    '',
    '    1. Current Directory',
    '       ' .. current_dir,
    '',
    '    2. Home Directory',
    '       ' .. home_dir,
    '',
    '    3. Custom Path',
    '       Enter a custom directory path',
    '',
    '',
    '  ┌' .. string.rep('─', 66) .. '┐',
    '  │  1/2/3: Select option  │  c: Custom  │  Enter: Current  │  q: Cancel  │',
    '  └' .. string.rep('─', 66) .. '┘',
  }
  
  local content_width = 72
  local content_height = #lines
  
  local buf, win = create_popup('📁 Select Directory', content_width, content_height)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Highlight
  local ns = vim.api.nvim_create_namespace('marvin_wizard')
  for i, line in ipairs(lines) do
    if line:match('✨') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Title', i - 1, 0, -1)
    elseif line:match('^%s+─') and not line:match('┌') and not line:match('└') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
    elseif line:match('┌') or line:match('└') or line:match('│') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'FloatBorder', i - 1, 0, -1)
    end
  end
  
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set('n', '1', function()
    vim.api.nvim_win_close(win, true)
    callback(current_dir)
  end, opts)
  
  vim.keymap.set('n', '2', function()
    vim.api.nvim_win_close(win, true)
    callback(home_dir)
  end, opts)
  
  vim.keymap.set('n', '3', function()
    vim.api.nvim_win_close(win, true)
    
    vim.ui.input({
      prompt = 'Directory path: ',
      default = current_dir,
      completion = 'dir',
    }, function(input)
      if input then
        callback(input)
      end
    end)
  end, opts)
  
  vim.keymap.set('n', 'c', function()
    vim.api.nvim_win_close(win, true)
    
    vim.ui.input({
      prompt = 'Directory path: ',
      default = current_dir,
      completion = 'dir',
    }, function(input)
      if input then
        callback(input)
      end
    end)
  end, opts)
  
  vim.keymap.set('n', '<CR>', function()
    vim.api.nvim_win_close(win, true)
    callback(current_dir)
  end, opts)
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
    callback(nil)
  end, opts)
  
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
    callback(nil)
  end, opts)
end

function M.format_archetype_name(archetype_id)
  if archetype_id:match(':') then
    local parts = vim.split(archetype_id, ':')
    return parts[#parts - 1] or archetype_id
  end
  
  local name = archetype_id:gsub('maven%-archetype%-', '')
  return name:sub(1, 1):upper() .. name:sub(2)
end

function M.format_archetype_display(archetype_id)
  if archetype_id:match(':') then
    return archetype_id
  end
  return M.format_archetype_name(archetype_id)
end

function M.get_archetype_description(archetype_id)
  local descriptions = {
    ['maven-archetype-quickstart'] = 'Simple Java console application',
    ['maven-archetype-webapp'] = 'Java web application with servlet support',
    ['maven-archetype-simple'] = 'Minimal Maven project structure',
  }
  return descriptions[archetype_id] or 'Maven project archetype'
end

function M.get_archetype_icon(archetype_id)
  local icons = {
    ['maven-archetype-quickstart'] = '⚡',
    ['maven-archetype-webapp'] = '🌐',
    ['maven-archetype-simple'] = '📋',
  }
  return icons[archetype_id] or '🔨'
end

function M.generate(archetype, details, directory)
  local config = require('marvin').config
  local ui = require('marvin.ui')
  
  -- Build archetype generate command
  local archetype_parts = vim.split(archetype, ':')
  local cmd_parts = {
    config.maven_command,
    'archetype:generate',
    '-B',
  }
  
  if #archetype_parts >= 2 then
    table.insert(cmd_parts, '-DarchetypeGroupId=' .. archetype_parts[1])
    table.insert(cmd_parts, '-DarchetypeArtifactId=' .. archetype_parts[2])
    if archetype_parts[3] then
      table.insert(cmd_parts, '-DarchetypeVersion=' .. archetype_parts[3])
    end
  else
    table.insert(cmd_parts, '-DarchetypeArtifactId=' .. archetype)
  end
  
  table.insert(cmd_parts, '-DgroupId=' .. details.group_id)
  table.insert(cmd_parts, '-DartifactId=' .. details.artifact_id)
  table.insert(cmd_parts, '-Dversion=' .. details.version)
  table.insert(cmd_parts, '-Dpackage=' .. details.package)
  
  local cmd = table.concat(cmd_parts, ' ')
  
  ui.notify('🔨 Generating project...', vim.log.levels.INFO)
  
  M.show_generation_progress(details.artifact_id)
  
  vim.fn.jobstart(cmd, {
    cwd = directory,
    on_exit = function(_, exit_code, _)
      if exit_code == 0 then
        M.on_generation_complete(details, directory)
      else
        ui.notify('❌ Project generation failed!', vim.log.levels.ERROR)
        M.close_progress_window()
      end
    end,
  })
end

function M.show_generation_progress(artifact_id)
  local lines = {
    '',
    '',
    '    ⠋  Creating ' .. artifact_id .. '...',
    '',
    '    Maven is downloading dependencies and',
    '    generating project structure.',
    '',
    '    Please wait...',
    '',
    '',
  }
  
  local content_width = 56
  local content_height = #lines
  
  local buf, win = create_popup('🔨 Generating Project', content_width, content_height)
  
  local frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
  local frame = 1
  
  local function update()
    local lines = {
      '',
      '',
      '    ' .. frames[frame] .. '  Creating ' .. artifact_id .. '...',
      '',
      '    Maven is downloading dependencies and',
      '    generating project structure.',
      '',
      '    Please wait...',
      '',
      '',
    }
    
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    frame = (frame % #frames) + 1
  end
  
  local timer = vim.loop.new_timer()
  timer:start(0, 100, vim.schedule_wrap(function()
    if vim.api.nvim_win_is_valid(win) then
      update()
    else
      timer:stop()
    end
  end))
  
  M._progress_win = win
  M._progress_timer = timer
end

function M.close_progress_window()
  if M._progress_win and vim.api.nvim_win_is_valid(M._progress_win) then
    vim.api.nvim_win_close(M._progress_win, true)
  end
  if M._progress_timer then
    M._progress_timer:stop()
  end
end

function M.on_generation_complete(details, directory)
  local ui = require('marvin.ui')
  local project_path = directory .. '/' .. details.artifact_id
  
  M.close_progress_window()
  
  ui.notify('✅ Project generated successfully!', vim.log.levels.INFO)
  
  local lines = {
    '',
    '',
    '    🎉 Project created successfully!',
    '',
    '  ✨ Project Details',
    '  ' .. string.rep('─', 66),
    '',
    '    Name:     ' .. details.artifact_id,
    '    Location: ' .. project_path,
    '    Package:  ' .. details.package,
    '',
    '  📝 Next Steps',
    '  ' .. string.rep('─', 66),
    '',
    '    • Press Enter to open the project',
    '    • Press o to open in file manager',
    '    • Press q to close this dialog',
    '',
    '',
    '  ┌' .. string.rep('─', 66) .. '┐',
    '  │  Enter: Open Project  │  o: File Manager  │  q: Close  │',
    '  └' .. string.rep('─', 66) .. '┘',
  }
  
  local content_width = 72
  local content_height = #lines
  
  local buf, win = create_popup('✅ Success!', content_width, content_height)
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Highlight
  local ns = vim.api.nvim_create_namespace('marvin_wizard')
  for i, line in ipairs(lines) do
    if line:match('✨') or line:match('📝') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Title', i - 1, 0, -1)
    elseif line:match('^%s+─') and not line:match('┌') and not line:match('└') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
    elseif line:match('┌') or line:match('└') or line:match('│') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'FloatBorder', i - 1, 0, -1)
    end
  end
  
  local opts = { noremap = true, silent = true, buffer = buf }
  
  vim.keymap.set('n', '<CR>', function()
    vim.api.nvim_win_close(win, true)
    vim.cmd('cd ' .. vim.fn.fnameescape(project_path))
    vim.cmd('edit ' .. vim.fn.fnameescape(project_path .. '/pom.xml'))
  end, opts)
  
  vim.keymap.set('n', 'o', function()
    vim.api.nvim_win_close(win, true)
    local open_cmd = vim.fn.has('mac') == 1 and 'open' or (vim.fn.has('win32') == 1 and 'explorer' or 'xdg-open')
    vim.fn.jobstart(open_cmd .. ' ' .. vim.fn.shellescape(project_path))
  end, opts)
  
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
  
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, opts)
end

return M
