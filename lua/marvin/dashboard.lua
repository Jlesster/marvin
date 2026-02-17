-- lua/marvin/dashboard.lua
local M = {}

local function has_assembly_plugin()
  local pom_path = vim.fn.getcwd() .. '/pom.xml'
  if vim.fn.filereadable(pom_path) == 0 then return false end
  local content = table.concat(vim.fn.readfile(pom_path), '\n')
  return content:match('maven%-assembly%-plugin') ~= nil
end

local function get_project_summary()
  local project = require('marvin.project').get_project()
  if not project or not project.info then return nil end
  return {
    artifact  = project.info.artifact_id or 'unknown',
    group     = project.info.group_id or 'unknown',
    version   = project.info.version or 'unknown',
    packaging = project.info.packaging or 'jar',
  }
end

local function sep(label)
  return { label = label, is_separator = true }
end

local function item(id, icon, label, desc, badge)
  return { id = id, icon = icon, label = label, desc = desc, badge = badge }
end

function M.show()
  local project    = require('marvin.project')
  local in_maven   = project.detect()
  local menu_items = {}
  local function add(t) menu_items[#menu_items + 1] = t end

  -- Project
  add(sep('Project'))
  add(item('new_project', '󰏗 ', 'New Maven Project', 'Create from archetype'))

  if in_maven then
    local summary = get_project_summary()

    -- Build & Package
    add(sep('Build & Package'))
    add(item('compile', '󰏗 ', 'Compile Sources', 'Compile main sources'))
    add(item('test', '󰙨 ', 'Run Tests', 'Execute test suite'))
    add(item('package', '󰏗 ', 'Package JAR',
      summary and string.format('Build %s-%s.jar', summary.artifact, summary.version) or 'Build JAR file'))
    if has_assembly_plugin() then
      add(item('package_fat', '󱊞 ', 'Package Fat JAR', 'JAR with all dependencies'))
    end
    add(item('install', '󰇚 ', 'Install to Local Repo', '~/.m2/repository'))
    add(item('clean_install', '󰑓 ', 'Clean & Install', 'Full rebuild + install'))

    -- Development
    add(sep('Development'))
    add(item('new_java_file', '󰬷 ', 'New Java File', 'Class, interface, record, etc.'))
    add(item('run_goal', '󰁔 ', 'Run Maven Goal', 'Execute any goal'))

    -- Dependencies
    add(sep('Dependencies'))
    add(item('dep_tree', '󰙅 ', 'Dependency Tree', 'View dependency graph'))
    add(item('add_jackson', '󰘦 ', 'Add Jackson JSON', 'JSON processing library'))
    add(item('add_lwjgl', '󰊗 ', 'Add LWJGL', 'OpenGL/Vulkan bindings'))

    -- Configuration
    add(sep('Configuration'))
    add(item('set_java_version', '󰬷 ', 'Set Java Version', 'Configure compiler target'))
    if not has_assembly_plugin() then
      add(item('add_assembly', '󰒓 ', 'Enable Fat JAR Build', 'Add maven-assembly-plugin'))
    end
    add(item('effective_pom', '󰒓 ', 'View Effective POM', 'Resolved configuration'))
  end

  local ui = require('marvin.ui')

  local prompt_text
  if in_maven then
    local summary = get_project_summary()
    if summary then
      prompt_text = string.format('Marvin  %s:%s', summary.group, summary.artifact)
    else
      prompt_text = 'Marvin Dashboard'
    end
  else
    prompt_text = 'Marvin  Get Started'
  end

  ui.select(menu_items, {
    prompt        = prompt_text,
    enable_search = true,
    format_item   = function(it)
      if it.is_separator then return it.label end
      return it.label
    end,
  }, function(choice)
    if choice then M.handle_action(choice.id) end
  end)
end

function M.handle_action(action_id)
  if action_id == 'new_project' then
    require('marvin.generator').create_project()
  elseif action_id == 'run_goal' then
    require('marvin.ui').show_goal_menu(function() M.show() end)
  elseif action_id == 'new_java_file' then
    require('marvin.java_creator').show_menu(function() M.show() end)
  elseif action_id == 'add_jackson' then
    require('marvin.dependencies').add_jackson()
  elseif action_id == 'add_lwjgl' then
    require('marvin.dependencies').add_lwjgl()
  elseif action_id == 'add_assembly' then
    require('marvin.dependencies').add_assembly_plugin()
  elseif action_id == 'set_java_version' then
    M.prompt_java_version()
  elseif action_id == 'compile' then
    require('marvin.executor').run('compile')
  elseif action_id == 'test' then
    require('marvin.executor').run('test')
  elseif action_id == 'package' then
    require('marvin.executor').run('package')
  elseif action_id == 'package_fat' then
    require('marvin.executor').run('package assembly:single')
  elseif action_id == 'install' then
    require('marvin.executor').run('install')
  elseif action_id == 'clean_install' then
    require('marvin.executor').run('clean install')
  elseif action_id == 'dep_tree' then
    require('marvin.executor').run('dependency:tree')
  elseif action_id == 'effective_pom' then
    require('marvin.executor').run('help:effective-pom')
  end
end

function M.prompt_java_version()
  local versions = {
    { version = '21', icon = '', label = 'Java 21 (LTS)', desc = 'Latest LTS - Virtual threads, pattern matching' },
    { version = '17', icon = '', label = 'Java 17 (LTS)', desc = 'Stable LTS - Sealed classes, records' },
    { version = '11', icon = '', label = 'Java 11 (LTS)', desc = 'Mature LTS - Widely adopted' },
    { version = '8',  icon = '', label = 'Java 8  (LTS)', desc = 'Legacy LTS - Maximum compatibility' },
  }
  require('marvin.ui').select(versions, {
    prompt      = 'Java Compiler Target',
    on_back     = function() M.show() end,
    format_item = function(it) return it.label end,
  }, function(choice)
    if choice then require('marvin.dependencies').set_java_version(choice.version) end
  end)
end

return M
