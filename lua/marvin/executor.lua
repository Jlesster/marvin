local M = {}

-- Create a centered floating window
local function create_popup(title, width, height)
  local buf = vim.api.nvim_create_buf(false, true)

  -- Calculate center position
  local ui = vim.api.nvim_list_uis()[1]
  local win_width = math.floor(width * ui.width)
  local win_height = math.floor(height * ui.height)
  local row = math.floor((ui.height - win_height) / 2)
  local col = math.floor((ui.width - win_width) / 2)

  -- Create border buffer for title
  local border_buf = vim.api.nvim_create_buf(false, true)

  local border_opts = {
    relative = 'editor',
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1,
    style = 'minimal',
  }

  local border_win = vim.api.nvim_open_win(border_buf, false, border_opts)

  -- Draw border with rounded corners
  local border_lines = { '╭' .. string.rep('─', win_width) .. '╮' }
  local middle_line = '│' .. string.rep(' ', win_width) .. '│'
  for i = 1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╰' .. string.rep('─', win_width) .. '╯')

  -- Add title
  if title then
    local title_str = ' ' .. title .. ' '
    local padding = win_width - #title_str
    local left_pad = math.floor(padding / 2)
    local right_pad = padding - left_pad
    border_lines[1] = '╭' .. string.rep('─', left_pad) .. title_str .. string.rep('─', right_pad) .. '╮'
  end

  vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)
  vim.api.nvim_buf_set_option(border_buf, 'modifiable', false)

  -- Set border colors
  vim.api.nvim_win_set_option(border_win, 'winhl', 'Normal:FloatBorder')

  -- Create main window
  local opts = {
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = 'minimal',
  }

  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal')
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  return buf, win, border_buf, border_win
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
    label = 'Popular Archetypes',
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
    label = 'Advanced Options',
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

  -- Create popup
  local buf, win, border_buf, border_win = create_popup('🔨 Maven Project Generator', 0.65, 0.75)

  -- Build content with better formatting
  local lines = {}
  local selectable_lines = {} -- Track which lines are selectable
  local line_to_item = {}     -- Map line numbers to archetype items

  table.insert(lines, '')
  table.insert(lines, '  Create a new Maven project from an archetype')
  table.insert(lines, '')

  for idx, archetype in ipairs(archetypes) do
    if archetype.type == 'header' then
      table.insert(lines, '')
      table.insert(lines, '  ═══ ' .. archetype.label .. ' ═══')
      table.insert(lines, '')
    elseif archetype.type == 'separator' then
      table.insert(lines, '')
      table.insert(lines, '  ' .. string.rep('─', 60))
    elseif archetype.type == 'archetype' or archetype.type == 'action' then
      local line_num = #lines + 1
      table.insert(lines, string.format('  %s  %s', archetype.icon, archetype.label))
      if archetype.description then
        table.insert(lines, '     ' .. archetype.description)
      end
      table.insert(lines, '')

      if archetype.selectable then
        table.insert(selectable_lines, line_num)
        line_to_item[line_num] = archetype
      end
    end
  end

  table.insert(lines, '')
  table.insert(lines, '  ╭─────────────────────────────────────────────────────────╮')
  table.insert(lines, '  │  Navigation: ↑/↓ or j/k  │  Select: Enter  │  Quit: q/Esc │')
  table.insert(lines, '  ╰─────────────────────────────────────────────────────────╯')

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')

  -- Add syntax highlighting
  vim.api.nvim_buf_set_option(buf, 'filetype', 'marvin-wizard')

  -- Highlight headers and separators
  for i, line in ipairs(lines) do
    if line:match('═══') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'Title', i - 1, 0, -1)
    elseif line:match('─────') and not line:match('╭') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'Comment', i - 1, 0, -1)
    elseif line:match('│') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'Comment', i - 1, 0, -1)
    end
  end

  -- Set initial cursor position to first selectable item
  local current_idx = 1
  local current_line = selectable_lines[current_idx]

  local function highlight_line(line_num)
    vim.api.nvim_buf_clear_namespace(buf, 999, 0, -1)
    if line_num then
      vim.api.nvim_buf_add_highlight(buf, 999, 'Visual', line_num - 1, 0, -1)
      -- Also highlight description line if it exists
      if lines[line_num + 1] and lines[line_num + 1]:match('^%s+%S') and not lines[line_num + 1]:match('^%s+[═─╭╰│]') then
        vim.api.nvim_buf_add_highlight(buf, 999, 'Visual', line_num, 0, -1)
      end
    end
  end

  highlight_line(current_line)
  vim.api.nvim_win_set_cursor(win, { current_line, 0 })

  -- Handle selection
  local function select_item()
    local selected = line_to_item[current_line]
    if not selected then return end

    -- Close windows
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)

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
      vim.api.nvim_win_set_cursor(win, { current_line, 0 })
      highlight_line(current_line)
    end
  end

  local function move_up()
    if current_idx > 1 then
      current_idx = current_idx - 1
      current_line = selectable_lines[current_idx]
      vim.api.nvim_win_set_cursor(win, { current_line, 0 })
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
    vim.api.nvim_win_close(border_win, true)
  end, opts)
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
  end, opts)
end

function M.show_local_archetypes()
  local ui = require('marvin.ui')
  ui.notify('🔍 Scanning local Maven repository...', vim.log.levels.INFO)

  -- Get local archetypes from Maven repository
  local home = os.getenv('HOME') or os.getenv('USERPROFILE')
  local m2_repo = home .. '/.m2/repository'

  -- Run Maven command to list local archetypes
  local cmd = 'find ' .. m2_repo .. ' -name "*archetype*.jar" -o -name "*archetype*.pom" | head -20'

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      local archetypes = {}
      for _, line in ipairs(data) do
        if line ~= '' then
          -- Extract archetype info from path
          local parts = vim.split(line, '/')
          if #parts >= 3 then
            local artifact = parts[#parts - 2]
            if artifact:match('archetype') then
              table.insert(archetypes, artifact)
            end
          end
        end
      end

      if #archetypes == 0 then
        ui.notify('No local archetypes found. Try searching Maven Central instead.', vim.log.levels.WARN)
      else
        M.show_archetype_selection_list(archetypes, 'Local Archetypes')
      end
    end,
  })
end

function M.show_archetype_selection_list(archetypes, title)
  local buf, win, border_buf, border_win = create_popup('📦 ' .. title, 0.6, 0.7)

  local lines = { '', '  Select an archetype:', '' }
  for i, archetype in ipairs(archetypes) do
    table.insert(lines, string.format('  %d. %s', i, archetype))
  end

  table.insert(lines, '')
  table.insert(lines, '  ───────────────────────────────────')
  table.insert(lines, '  Use number or j/k to navigate')
  table.insert(lines, '  Press Enter to select')
  table.insert(lines, '  Press q or Esc to cancel')

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  local current_line = 4

  local function highlight_line(line_num)
    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, -1, 'Visual', line_num - 1, 0, -1)
  end

  highlight_line(current_line)
  vim.api.nvim_win_set_cursor(win, { current_line, 0 })

  local function select_archetype()
    local idx = current_line - 3
    if idx > 0 and idx <= #archetypes then
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_win_close(border_win, true)
      M.show_project_details_wizard(archetypes[idx])
    end
  end

  local opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('n', 'j', function()
    if current_line < #archetypes + 3 then
      current_line = current_line + 1
      vim.api.nvim_win_set_cursor(win, { current_line, 0 })
      highlight_line(current_line)
    end
  end, opts)

  vim.keymap.set('n', 'k', function()
    if current_line > 4 then
      current_line = current_line - 1
      vim.api.nvim_win_set_cursor(win, { current_line, 0 })
      highlight_line(current_line)
    end
  end, opts)

  vim.keymap.set('n', '<CR>', select_archetype, opts)
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
  end, opts)
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
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
  local buf, win, border_buf, border_win = create_popup('📝 Project Details', 0.7, 0.65)

  local details = {
    group_id = 'com.example',
    artifact_id = 'my-app',
    version = '1.0-SNAPSHOT',
    package = '',
  }

  local fields = {
    { name = 'group_id',    label = 'Group ID',    placeholder = 'com.example',     help = 'Your organization domain (e.g., com.company)' },
    { name = 'artifact_id', label = 'Artifact ID', placeholder = 'my-app',          help = 'Project name (lowercase, no spaces)' },
    { name = 'version',     label = 'Version',     placeholder = '1.0-SNAPSHOT',    help = 'Initial version number' },
    { name = 'package',     label = 'Package',     placeholder = 'com.example.app', help = 'Base package (leave empty to use Group ID)' },
  }

  local current_field = 1

  local function render()
    local lines = {}

    table.insert(lines, '')
    table.insert(lines, '  📦 Creating: ' .. M.format_archetype_display(archetype))
    table.insert(lines, '')
    table.insert(lines, '  ═══ Project Configuration ═══')
    table.insert(lines, '')

    for i, field in ipairs(fields) do
      local value = details[field.name]
      if value == '' then
        value = field.placeholder
      end

      local is_current = i == current_field
      local prefix = is_current and '▶ ' or '  '
      local display_value = value ~= '' and value or field.placeholder

      -- Field label
      table.insert(lines, prefix .. field.label .. ':')

      -- Field value with cursor indicator
      local value_line = '    ' .. display_value
      if is_current then
        value_line = value_line .. ' █'
      end
      table.insert(lines, value_line)

      -- Help text
      if is_current then
        table.insert(lines, '    ↳ ' .. field.help)
      end

      table.insert(lines, '')
    end

    table.insert(lines, '  ═══ Preview ═══')
    table.insert(lines, '')
    table.insert(lines, '  Maven Coordinates:')
    table.insert(lines, '    ' .. details.group_id .. ':' .. details.artifact_id .. ':' .. details.version)
    table.insert(lines, '')
    table.insert(lines, '  Package Structure:')
    local pkg = details.package ~= '' and details.package or details.group_id
    table.insert(lines, '    ' .. pkg:gsub('%.', '/') .. '/')
    table.insert(lines, '')
    table.insert(lines, '  ╭───────────────────────────────────────────────────────────────╮')
    table.insert(lines, '  │  Tab/Shift-Tab: Navigate  │  Enter: Edit  │  Ctrl-G: Generate  │')
    table.insert(lines, '  ╰───────────────────────────────────────────────────────────────╯')

    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Highlight current field
    vim.api.nvim_buf_clear_namespace(buf, 999, 0, -1)

    -- Find and highlight the current field's lines
    local line_offset = 6       -- Starting line for fields
    for i = 1, current_field do
      local lines_per_field = 4 -- label + value + help + blank
      if i == current_field then
        local start_line = line_offset + (i - 1) * lines_per_field
        vim.api.nvim_buf_add_highlight(buf, 999, 'Visual', start_line - 1, 0, -1)
        vim.api.nvim_buf_add_highlight(buf, 999, 'Visual', start_line, 0, -1)
        vim.api.nvim_buf_add_highlight(buf, 999, 'CursorLine', start_line + 1, 0, -1)
        break
      end
    end

    -- Highlight headers
    for i, line in ipairs(lines) do
      if line:match('═══') then
        vim.api.nvim_buf_add_highlight(buf, -1, 'Title', i - 1, 0, -1)
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
    -- Set package to group_id if not specified
    if details.package == '' then
      details.package = details.group_id
    end

    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)

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
  vim.keymap.set('n', 'e', edit_field, opts) -- Also allow 'e' for edit

  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
  end, opts)

  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
  end, opts)
end

function M.show_directory_selector(callback)
  local buf, win, border_buf, border_win = create_popup('📁 Select Directory', 0.6, 0.4)

  local current_dir = vim.fn.getcwd()
  local home_dir = os.getenv('HOME') or os.getenv('USERPROFILE')

  local lines = {
    '',
    '  Where should the project be created?',
    '',
    '  ═══ Quick Options ═══',
    '',
    '  1. Current Directory',
    '     ' .. current_dir,
    '',
    '  2. Home Directory',
    '     ' .. home_dir,
    '',
    '  3. Custom Path',
    '     Enter a custom directory path',
    '',
    '  ╭─────────────────────────────────────────────────╮',
    '  │  1/2/3: Select option  │  c: Custom  │  q: Cancel  │',
    '  ╰─────────────────────────────────────────────────╯',
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Highlight
  vim.api.nvim_buf_add_highlight(buf, -1, 'Title', 3, 0, -1)

  local opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('n', '1', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
    callback(current_dir)
  end, opts)

  vim.keymap.set('n', '2', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
    callback(home_dir)
  end, opts)

  vim.keymap.set('n', '3', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)

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
    vim.api.nvim_win_close(border_win, true)

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
    vim.api.nvim_win_close(border_win, true)
    callback(current_dir)
  end, opts)

  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
    callback(nil)
  end, opts)

  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
    callback(nil)
  end, opts)
end

function M.format_archetype_name(archetype_id)
  -- Handle full coordinates
  if archetype_id:match(':') then
    local parts = vim.split(archetype_id, ':')
    return parts[#parts - 1] or archetype_id -- Return artifactId
  end

  local name = archetype_id:gsub('maven%-archetype%-', '')
  return name:sub(1, 1):upper() .. name:sub(2)
end

function M.format_archetype_display(archetype_id)
  if archetype_id:match(':') then
    return archetype_id -- Show full coordinates
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
    '-B', -- Batch mode
  }

  -- Handle full coordinates vs simple archetype ID
  if #archetype_parts >= 2 then
    table.insert(cmd_parts, '-DarchetypeGroupId=' .. archetype_parts[1])
    table.insert(cmd_parts, '-DarchetypeArtifactId=' .. archetype_parts[2])
    if archetype_parts[3] then
      table.insert(cmd_parts, '-DarchetypeVersion=' .. archetype_parts[3])
    end
  else
    table.insert(cmd_parts, '-DarchetypeArtifactId=' .. archetype)
  end

  -- Add project details
  table.insert(cmd_parts, '-DgroupId=' .. details.group_id)
  table.insert(cmd_parts, '-DartifactId=' .. details.artifact_id)
  table.insert(cmd_parts, '-Dversion=' .. details.version)
  table.insert(cmd_parts, '-Dpackage=' .. details.package)

  local cmd = table.concat(cmd_parts, ' ')

  ui.notify('🔨 Generating project...', vim.log.levels.INFO)

  -- Show progress popup
  M.show_generation_progress(details.artifact_id)

  -- Run the command
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
  local buf, win, border_buf, border_win = create_popup('🔨 Generating Project', 0.5, 0.3)

  local frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
  local frame = 1

  local function update()
    local lines = {
      '',
      '  ' .. frames[frame] .. '  Creating ' .. artifact_id .. '...',
      '',
      '  Maven is downloading dependencies and generating',
      '  project structure. This may take a moment.',
      '',
      '  Please wait...',
      '',
    }

    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    frame = (frame % #frames) + 1
  end

  -- Animate
  local timer = vim.loop.new_timer()
  timer:start(0, 100, vim.schedule_wrap(function()
    if vim.api.nvim_win_is_valid(win) then
      update()
    else
      timer:stop()
    end
  end))

  -- Store for cleanup
  M._progress_win = win
  M._progress_border_win = border_win
  M._progress_timer = timer
end

function M.close_progress_window()
  if M._progress_win and vim.api.nvim_win_is_valid(M._progress_win) then
    vim.api.nvim_win_close(M._progress_win, true)
  end
  if M._progress_border_win and vim.api.nvim_win_is_valid(M._progress_border_win) then
    vim.api.nvim_win_close(M._progress_border_win, true)
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

  -- Show completion popup
  local buf, win, border_buf, border_win = create_popup('✅ Success!', 0.6, 0.45)

  local lines = {
    '',
    '  🎉 Project created successfully!',
    '',
    '  ═══ Project Details ═══',
    '',
    '  Name: ' .. details.artifact_id,
    '  Location: ' .. project_path,
    '  Package: ' .. details.package,
    '',
    '  ═══ Next Steps ═══',
    '',
    '  1. Press Enter to open the project',
    '  2. Press o to open in file manager',
    '  3. Press q to close this dialog',
    '',
    '  ╭─────────────────────────────────────────────╮',
    '  │  Enter: Open  │  o: File Manager  │  q: Close  │',
    '  ╰─────────────────────────────────────────────╯',
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Highlight
  for i, line in ipairs(lines) do
    if line:match('═══') then
      vim.api.nvim_buf_add_highlight(buf, -1, 'Title', i - 1, 0, -1)
    end
  end

  local opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('n', '<CR>', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
    vim.cmd('cd ' .. vim.fn.fnameescape(project_path))
    vim.cmd('edit ' .. vim.fn.fnameescape(project_path .. '/pom.xml'))
  end, opts)

  vim.keymap.set('n', 'o', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
    -- Open in file manager
    local open_cmd = vim.fn.has('mac') == 1 and 'open' or (vim.fn.has('win32') == 1 and 'explorer' or 'xdg-open')
    vim.fn.jobstart(open_cmd .. ' ' .. vim.fn.shellescape(project_path))
  end, opts)

  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
  end, opts)

  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
  end, opts)
end

return M
