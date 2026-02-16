local M = {}

-- Modern popup creator (matches ui.lua style)
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
  vim.api.nvim_set_option_value('number', false, { win = win })
  vim.api.nvim_set_option_value('relativenumber', false, { win = win })

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

  -- Build menu items with consistent structure (like other menus)
  local menu_items = {
    { id = 'new_project', label = 'Create New Maven Project', icon = '🗂️', desc = 'Generate project from archetype' },
    { id = 'new_java_file', label = 'Create Java File', icon = '☕', desc = 'Class, interface, enum, etc.' },
  }

  if in_maven_project then
    table.insert(menu_items, { id = 'run_goal', label = 'Run Maven Goal', icon = '🎯', desc = 'Execute any Maven goal' })
    table.insert(menu_items, { id = 'add_jackson', label = 'Add Jackson JSON', icon = '📋', desc = 'Jackson 2.18.2' })
    table.insert(menu_items, { id = 'add_lwjgl', label = 'Add LWJGL', icon = '🎮', desc = 'LWJGL 3.3.6 + natives' })
    table.insert(menu_items,
      { id = 'set_java_version', label = 'Set Java Version', icon = '☕', desc = 'Configure compiler version' })

    if not has_assembly_plugin() then
      table.insert(menu_items,
        { id = 'add_assembly', label = 'Setup Fat JAR Build', icon = '📦', desc = 'Add Assembly Plugin' })
    end

    table.insert(menu_items, { id = 'package', label = 'Package Project', icon = '📦', desc = 'Build regular JAR' })

    if has_assembly_plugin() then
      table.insert(menu_items,
        { id = 'package_fat', label = 'Build Fat JAR', icon = '🎁', desc = 'JAR with dependencies' })
    end

    table.insert(menu_items, { id = 'clean_install', label = 'Clean Install', icon = '🔄', desc = 'Clean and install' })
  end

  -- Use the standard UI select (matches other menus)
  local ui = require('marvin.ui')

  -- Add project info to prompt if in Maven project
  local prompt_text = '⚡ MARVIN Dashboard'
  if in_maven_project then
    local proj = project.get_project()
    if proj and proj.info then
      prompt_text = string.format('⚡ MARVIN - %s:%s',
        proj.info.group_id or 'unknown',
        proj.info.artifact_id or 'unknown')
    end
  end

  ui.select(menu_items, {
    prompt = prompt_text,
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      M.handle_action(choice.id)
    end
  end)
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
