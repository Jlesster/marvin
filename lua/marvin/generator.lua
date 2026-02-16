local M = {}

-- Create centered popup window
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

-- Entry point
function M.create_project()
  M.scan_local_archetypes()
end

-- Scan for local archetypes
function M.scan_local_archetypes()
  local ui = require('marvin.ui')
  ui.notify('🔍 Scanning local Maven repository...', vim.log.levels.INFO)

  local home = os.getenv('HOME') or os.getenv('USERPROFILE')
  local m2_repo = home .. '/.m2/repository'

  -- Try to find archetype JARs
  local cmd = string.format('find "%s" -type f -name "*archetype*.jar" 2>/dev/null | grep -v "maven-archetype-plugin"',
    m2_repo)

  local archetypes = {}
  local seen = {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      for _, line in ipairs(data) do
        if line and line ~= '' then
          -- Parse: ~/.m2/repository/org/jless/jless-schema-archetype/1.0/jless-schema-archetype-1.0.jar
          local parts = vim.split(line, '/')

          -- Find repository index
          local repo_idx = nil
          for i, part in ipairs(parts) do
            if part == 'repository' then
              repo_idx = i
              break
            end
          end

          if repo_idx and #parts >= repo_idx + 3 then
            local version = parts[#parts - 1]     -- The directory before the jar
            local artifact_id = parts[#parts - 2] -- The directory before version

            -- Build groupId from everything between repository and artifactId
            local group_parts = {}
            for i = repo_idx + 1, #parts - 3 do
              table.insert(group_parts, parts[i])
            end
            local group_id = table.concat(group_parts, '.')

            if group_id ~= '' and artifact_id ~= '' and version ~= '' then
              local key = group_id .. ':' .. artifact_id .. ':' .. version

              if not seen[key] then
                seen[key] = true
                table.insert(archetypes, {
                  group_id = group_id,
                  artifact_id = artifact_id,
                  version = version,
                  display = artifact_id .. ' (' .. version .. ')',
                  coordinates = key,
                })
                print('Found archetype: ' .. key)
              end
            end
          end
        end
      end
    end,
    on_exit = function()
      vim.schedule(function()
        if #archetypes == 0 then
          ui.notify('No local archetypes found in ' .. m2_repo, vim.log.levels.WARN)
          print('No archetypes found. Check ~/.m2/repository')
        else
          print('Total archetypes found: ' .. #archetypes)
          M.show_archetype_menu(archetypes)
        end
      end)
    end,
  })
end

-- Show pretty archetype selection menu
function M.show_archetype_menu(archetypes)
  local lines = {}
  local selectable = {}

  table.insert(lines, '')
  table.insert(lines, '  Select a local archetype:')
  table.insert(lines, '')
  table.insert(lines, '  ✨ Available Archetypes')
  table.insert(lines, '  ' .. string.rep('─', 70))
  table.insert(lines, '')

  for i, archetype in ipairs(archetypes) do
    local line_num = #lines + 1
    table.insert(lines, string.format('    %d. %s', i, archetype.display))
    table.insert(lines, string.format('       %s', archetype.coordinates))
    table.insert(lines, '')
    table.insert(selectable, line_num)
  end

  table.insert(lines, '  ┌' .. string.rep('─', 70) .. '┐')
  table.insert(lines, '  │  j/k or ↑/↓: Navigate  │  Enter: Select  │  q/Esc: Cancel  │')
  table.insert(lines, '  └' .. string.rep('─', 70) .. '┘')

  local buf, win = create_popup('📦 Local Maven Archetypes', 76, #lines)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')

  -- Highlighting
  local ns = vim.api.nvim_create_namespace('marvin_menu')
  for i, line in ipairs(lines) do
    if line:match('✨') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Title', i - 1, 0, -1)
    elseif line:match('─') and not line:match('┌') and not line:match('└') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', i - 1, 0, -1)
    elseif line:match('[┌└│┐]') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'FloatBorder', i - 1, 0, -1)
    end
  end

  -- Selection state
  local current_idx = 1
  local highlight_ns = vim.api.nvim_create_namespace('marvin_highlight')

  local function update_highlight()
    vim.api.nvim_buf_clear_namespace(buf, highlight_ns, 0, -1)
    local line_num = selectable[current_idx]
    vim.api.nvim_buf_add_highlight(buf, highlight_ns, 'Visual', line_num - 1, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, highlight_ns, 'Visual', line_num, 0, -1)
    vim.api.nvim_win_set_cursor(win, { line_num, 0 })
  end

  update_highlight()

  -- Keymaps
  local function select()
    vim.api.nvim_win_close(win, true)
    M.get_project_details(archetypes[current_idx])
  end

  local opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('n', 'j', function()
    if current_idx < #archetypes then
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
    if current_idx < #archetypes then
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

-- Get project details from user
function M.get_project_details(archetype)
  local details = {
    group_id = 'com.example',
    artifact_id = 'my-app',
    version = '1.0-SNAPSHOT',
  }

  -- Simple prompts
  vim.ui.input({ prompt = 'Group ID: ', default = details.group_id }, function(input)
    if not input then return end
    details.group_id = input

    vim.ui.input({ prompt = 'Artifact ID: ', default = details.artifact_id }, function(input)
      if not input then return end
      details.artifact_id = input

      vim.ui.input({ prompt = 'Version: ', default = details.version }, function(input)
        if not input then return end
        details.version = input

        -- Choose directory
        vim.ui.input({ prompt = 'Directory: ', default = vim.fn.getcwd(), completion = 'dir' }, function(dir)
          if not dir then return end

          M.generate_project(archetype, details, dir)
        end)
      end)
    end)
  end)
end

-- Generate the Maven project
function M.generate_project(archetype, details, directory)
  local config = require('marvin').config
  local ui = require('marvin.ui')

  -- Build Maven command
  local cmd = string.format(
    '%s archetype:generate -B ' ..
    '-DarchetypeGroupId=%s ' ..
    '-DarchetypeArtifactId=%s ' ..
    '-DarchetypeVersion=%s ' ..
    '-DgroupId=%s ' ..
    '-DartifactId=%s ' ..
    '-Dversion=%s ' ..
    '-Dpackage=%s',
    config.maven_command,
    archetype.group_id,
    archetype.artifact_id,
    archetype.version,
    details.group_id,
    details.artifact_id,
    details.version,
    details.group_id
  )

  ui.notify('🔨 Generating project: ' .. details.artifact_id, vim.log.levels.INFO)
  print('Running: ' .. cmd)

  local output = {}

  vim.fn.jobstart(cmd, {
    cwd = directory,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= '' then
          table.insert(output, line)
          print('[MAVEN] ' .. line)
        end
      end
    end,
    on_stderr = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= '' then
          table.insert(output, line)
          print('[MAVEN ERR] ' .. line)
        end
      end
    end,
    on_exit = function(_, exit_code, _)
      if exit_code == 0 then
        ui.notify('✅ Project created successfully!', vim.log.levels.INFO)

        -- Ask to open
        vim.ui.select({ 'Yes', 'No' }, { prompt = 'Open project now?' }, function(choice)
          if choice == 'Yes' then
            local project_path = directory .. '/' .. details.artifact_id
            vim.cmd('cd ' .. vim.fn.fnameescape(project_path))
            vim.cmd('edit ' .. vim.fn.fnameescape(project_path .. '/pom.xml'))
          end
        end)
      else
        ui.notify('❌ Project generation failed!', vim.log.levels.ERROR)
        print('Exit code: ' .. exit_code)
        print('Output:\n' .. table.concat(output, '\n'))
      end
    end,
  })
end

return M
