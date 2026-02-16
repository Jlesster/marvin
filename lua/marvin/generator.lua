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

  -- Draw border
  local border_lines = { '╭' .. string.rep('─', win_width) .. '╮' }
  local middle_line = '│' .. string.rep(' ', win_width) .. '│'
  for i = 1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╰' .. string.rep('─', win_width) .. '╯')

  -- Add title
  if title then
    local title_str = '│ ' .. title .. ' '
    local padding = win_width - #title - 1
    border_lines[1] = '╭─ ' .. title .. ' ' .. string.rep('─', padding) .. '╮'
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

  return buf, win, border_buf, border_win
end

-- Project generation wizard with custom UI
function M.create_project()
  M.show_archetype_wizard()
end

function M.show_archetype_wizard()
  local config = require('marvin').config
  local archetypes = {}

  -- Build archetype list
  for i, archetype_id in ipairs(config.archetypes) do
    table.insert(archetypes, {
      id = archetype_id,
      label = M.format_archetype_name(archetype_id),
      icon = M.get_archetype_icon(archetype_id),
      index = i,
    })
  end

  -- Add search option
  table.insert(archetypes, {
    id = 'search',
    label = 'Search Maven Central',
    icon = '🔍',
    index = #archetypes + 1,
  })

  -- Create popup
  local buf, win, border_buf, border_win = create_popup('🔨 Maven Project Generator', 0.5, 0.6)

  -- Build content
  local lines = {
    '',
    '  Select a Maven Archetype:',
    '',
  }

  for _, archetype in ipairs(archetypes) do
    table.insert(lines, string.format('  %s  %s', archetype.icon, archetype.label))
  end

  table.insert(lines, '')
  table.insert(lines, '  ─────────────────────────────────')
  table.insert(lines, '  Use j/k or ↑/↓ to navigate')
  table.insert(lines, '  Press Enter to select')
  table.insert(lines, '  Press q or Esc to cancel')

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')

  -- Highlight current selection
  local current_line = 4 -- Start at first archetype
  local function highlight_line(line_num)
    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, -1, 'Visual', line_num - 1, 0, -1)
  end

  highlight_line(current_line)
  vim.api.nvim_win_set_cursor(win, { current_line, 0 })

  -- Handle selection
  local function select_archetype()
    local selected_index = current_line - 3 -- Offset for header lines
    if selected_index > 0 and selected_index <= #archetypes then
      local selected = archetypes[selected_index]

      -- Close windows
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_win_close(border_win, true)

      if selected.id == 'search' then
        M.show_search_input(function(archetype_id)
          if archetype_id then
            M.show_project_details_wizard(archetype_id)
          end
        end)
      else
        M.show_project_details_wizard(selected.id)
      end
    end
  end

  -- Keymaps for navigation
  local opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('n', 'j', function()
    if current_line < #lines - 6 then
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

  vim.keymap.set('n', '<Down>', function()
    if current_line < #lines - 6 then
      current_line = current_line + 1
      vim.api.nvim_win_set_cursor(win, { current_line, 0 })
      highlight_line(current_line)
    end
  end, opts)

  vim.keymap.set('n', '<Up>', function()
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

function M.show_project_details_wizard(archetype)
  local buf, win, border_buf, border_win = create_popup('📝 Project Details', 0.5, 0.5)

  local details = {
    group_id = 'com.example',
    artifact_id = 'my-app',
    version = '1.0-SNAPSHOT',
    package = '',
  }

  local fields = {
    { name = 'group_id',    label = 'Group ID',           placeholder = 'com.example' },
    { name = 'artifact_id', label = 'Artifact ID',        placeholder = 'my-app' },
    { name = 'version',     label = 'Version',            placeholder = '1.0-SNAPSHOT' },
    { name = 'package',     label = 'Package (optional)', placeholder = 'com.example.app' },
  }

  local current_field = 1

  local function render()
    local lines = {
      '',
      '  📦 Creating: ' .. M.format_archetype_name(archetype),
      '',
    }

    for i, field in ipairs(fields) do
      local value = details[field.name]
      if value == '' then
        value = field.placeholder
      end

      local prefix = i == current_field and '▶ ' or '  '
      local display_value = value ~= '' and value or field.placeholder

      table.insert(lines, prefix .. field.label .. ':')
      table.insert(lines, '  ' .. display_value)
      table.insert(lines, '')
    end

    table.insert(lines, '  ─────────────────────────────────')
    table.insert(lines, '  Tab/Shift+Tab: Navigate fields')
    table.insert(lines, '  Enter: Edit current field')
    table.insert(lines, '  Ctrl+G: Generate project')
    table.insert(lines, '  Esc/q: Cancel')

    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Highlight current field
    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
    local highlight_line = 3 + (current_field - 1) * 3
    vim.api.nvim_buf_add_highlight(buf, -1, 'Visual', highlight_line, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, -1, 'Visual', highlight_line + 1, 0, -1)
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
  local buf, win, border_buf, border_win = create_popup('📁 Select Directory', 0.5, 0.3)

  local current_dir = vim.fn.getcwd()

  local lines = {
    '',
    '  Where should the project be created?',
    '',
    '  Current directory:',
    '  ' .. current_dir,
    '',
    '  ─────────────────────────────────',
    '  Enter: Use current directory',
    '  c: Choose custom directory',
    '  Esc/q: Cancel',
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  local opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('n', '<CR>', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
    callback(current_dir)
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

function M.show_search_input(callback)
  vim.ui.input({
    prompt = '🔍 Search for archetype: ',
    default = '',
  }, function(search_term)
    if search_term and search_term ~= '' then
      callback(search_term)
    else
      callback(nil)
    end
  end)
end

function M.format_archetype_name(archetype_id)
  local name = archetype_id:gsub('maven%-archetype%-', '')
  return name:sub(1, 1):upper() .. name:sub(2)
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

  -- Build the Maven archetype:generate command
  local cmd = string.format(
    '%s archetype:generate -B -DarchetypeArtifactId=%s -DgroupId=%s -DartifactId=%s -Dversion=%s -Dpackage=%s',
    config.maven_command,
    archetype,
    details.group_id,
    details.artifact_id,
    details.version,
    details.package
  )

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
      end
    end,
  })
end

function M.show_generation_progress(artifact_id)
  local buf, win, border_buf, border_win = create_popup('🔨 Generating Project', 0.4, 0.2)

  local frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
  local frame = 1

  local function update()
    local lines = {
      '',
      '  ' .. frames[frame] .. '  Creating ' .. artifact_id .. '...',
      '',
      '  Please wait, Maven is working...',
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

function M.on_generation_complete(details, directory)
  local ui = require('marvin.ui')
  local project_path = directory .. '/' .. details.artifact_id

  -- Close progress window
  if M._progress_win and vim.api.nvim_win_is_valid(M._progress_win) then
    vim.api.nvim_win_close(M._progress_win, true)
  end
  if M._progress_border_win and vim.api.nvim_win_is_valid(M._progress_border_win) then
    vim.api.nvim_win_close(M._progress_border_win, true)
  end
  if M._progress_timer then
    M._progress_timer:stop()
  end

  ui.notify('✅ Project generated successfully!', vim.log.levels.INFO)

  -- Show completion popup
  local buf, win, border_buf, border_win = create_popup('✅ Success!', 0.4, 0.3)

  local lines = {
    '',
    '  🎉 Project created successfully!',
    '',
    '  Location:',
    '  ' .. project_path,
    '',
    '  ─────────────────────────────────',
    '  Enter: Open project',
    '  Esc/q: Close',
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  local opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('n', '<CR>', function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_win_close(border_win, true)
    vim.cmd('cd ' .. vim.fn.fnameescape(project_path))
    vim.cmd('edit ' .. vim.fn.fnameescape(project_path .. '/pom.xml'))
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
