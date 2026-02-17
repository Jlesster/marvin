local M = {}

-- Check if assembly plugin is configured
local function has_assembly_plugin()
  local pom_path = vim.fn.getcwd() .. '/pom.xml'
  if vim.fn.filereadable(pom_path) == 0 then
    return false
  end

  local content = table.concat(vim.fn.readfile(pom_path), '\n')
  return content:match('maven%-assembly%-plugin') ~= nil
end

-- Get project info summary
local function get_project_summary()
  local project = require('marvin.project').get_project()
  if not project or not project.info then
    return nil
  end

  return {
    artifact = project.info.artifact_id or 'unknown',
    group = project.info.group_id or 'unknown',
    version = project.info.version or 'unknown',
    packaging = project.info.packaging or 'jar',
  }
end

-- Show main dashboard
function M.show()
  local project = require('marvin.project')
  local in_maven_project = project.detect()

  local menu_items = {}

  -- Project Creation Section
  table.insert(menu_items, {
    id = 'separator_project',
    label = 'Project',
    is_separator = true
  })

  table.insert(menu_items, {
    id = 'new_project',
    label = 'New Maven Project',
    icon = '✨',
    desc = 'Create from archetype',
    shortcut = 'n'
  })

  if in_maven_project then
    local summary = get_project_summary()

    -- Build & Package Section
    table.insert(menu_items, {
      id = 'separator_build',
      label = 'Build & Package',
      is_separator = true
    })

    table.insert(menu_items, {
      id = 'compile',
      label = 'Compile Sources',
      icon = '⚙️',
      desc = 'Compile main sources',
      shortcut = 'c'
    })

    table.insert(menu_items, {
      id = 'test',
      label = 'Run Tests',
      icon = '🧪',
      desc = 'Execute test suite',
      shortcut = 't'
    })

    table.insert(menu_items, {
      id = 'package',
      label = 'Package JAR',
      icon = '📦',
      desc = summary and string.format('Build %s-%s.jar', summary.artifact, summary.version) or 'Build JAR file',
      shortcut = 'p'
    })

    if has_assembly_plugin() then
      table.insert(menu_items, {
        id = 'package_fat',
        label = 'Package Fat JAR',
        icon = '🎁',
        desc = 'JAR with all dependencies',
        shortcut = 'f'
      })
    end

    table.insert(menu_items, {
      id = 'install',
      label = 'Install to Local Repo',
      icon = '💾',
      desc = '~/.m2/repository',
      shortcut = 'i'
    })

    table.insert(menu_items, {
      id = 'clean_install',
      label = 'Clean & Install',
      icon = '🔄',
      desc = 'Full rebuild + install',
      shortcut = 'I'
    })

    -- Development Section
    table.insert(menu_items, {
      id = 'separator_dev',
      label = 'Development',
      is_separator = true
    })

    table.insert(menu_items, {
      id = 'new_java_file',
      label = 'New Java File',
      icon = '☕',
      desc = 'Class, interface, record, etc.',
      shortcut = 'j'
    })

    table.insert(menu_items, {
      id = 'run_goal',
      label = 'Run Maven Goal',
      icon = '🎯',
      desc = 'Execute custom goal',
      shortcut = 'g'
    })

    -- Dependencies Section
    table.insert(menu_items, {
      id = 'separator_deps',
      label = 'Dependencies',
      is_separator = true
    })

    table.insert(menu_items, {
      id = 'dep_tree',
      label = 'Dependency Tree',
      icon = '🌳',
      desc = 'View dependency graph',
      shortcut = 'd'
    })

    table.insert(menu_items, {
      id = 'add_jackson',
      label = 'Add Jackson JSON',
      icon = '📋',
      desc = 'JSON processing library'
    })

    table.insert(menu_items, {
      id = 'add_lwjgl',
      label = 'Add LWJGL',
      icon = '🎮',
      desc = 'OpenGL/Vulkan bindings'
    })

    -- Configuration Section
    table.insert(menu_items, {
      id = 'separator_config',
      label = 'Configuration',
      is_separator = true
    })

    table.insert(menu_items, {
      id = 'set_java_version',
      label = 'Set Java Version',
      icon = '☕',
      desc = 'Configure compiler target'
    })

    if not has_assembly_plugin() then
      table.insert(menu_items, {
        id = 'add_assembly',
        label = 'Enable Fat JAR Build',
        icon = '🔧',
        desc = 'Add maven-assembly-plugin'
      })
    end

    table.insert(menu_items, {
      id = 'effective_pom',
      label = 'View Effective POM',
      icon = '📄',
      desc = 'Resolved configuration'
    })
  end

  local ui = require('marvin.ui')

  -- Build prompt with project info
  local prompt_text
  if in_maven_project then
    local summary = get_project_summary()
    if summary then
      prompt_text = string.format('MARVIN » %s:%s', summary.group, summary.artifact)
    else
      prompt_text = 'MARVIN Dashboard'
    end
  else
    prompt_text = 'MARVIN » Get Started'
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
    require('marvin.ui').show_goal_menu(function()
      M.show()
    end)
  elseif action_id == 'new_java_file' then
    require('marvin.java_creator').show_menu(function()
      M.show()
    end)
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

-- Prompt for Java version
function M.prompt_java_version()
  local versions = {
    {
      version = '21',
      label = 'Java 21 (LTS)',
      icon = '🔥',
      desc = 'Latest LTS • Virtual threads, pattern matching'
    },
    {
      version = '17',
      label = 'Java 17 (LTS)',
      icon = '✨',
      desc = 'Stable LTS • Sealed classes, records'
    },
    {
      version = '11',
      label = 'Java 11 (LTS)',
      icon = '📦',
      desc = 'Mature LTS • Widely adopted'
    },
    {
      version = '8',
      label = 'Java 8 (LTS)',
      icon = '🗂️',
      desc = 'Legacy LTS • Maximum compatibility'
    },
  }

  require('marvin.ui').select(versions, {
    prompt = 'Java Compiler Target',
    on_back = function()
      M.show()
    end,
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
