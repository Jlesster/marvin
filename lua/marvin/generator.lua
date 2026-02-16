local M = {}

function M.create_project()
  local ui = require('marvin.ui')

  -- Step 1: Select archetype
  M.select_archetype(function(archetype)
    if not archetype then return end

    -- Step 2: Get project details
    M.get_project_details(function(details)
      if not details then return end

      -- Step 3: Select directory
      M.select_directory(function(directory)
        if not directory then return end

        -- Step 4: Generate project
        M.generate(archetype, details, directory)
      end)
    end)
  end)
end

function M.select_archetype(callback)
  local ui = require('marvin.ui')
  local config = require('marvin').config -- FIXED: Was 'maven'

  local archetypes = {}

  for _, archetype_id in ipairs(config.archetypes) do
    table.insert(archetypes, {
      id = archetype_id,
      label = M.format_archetype_name(archetype_id),
      icon = M.get_archetype_icon(archetype_id),
    })
  end

  -- Add "Search for archetype" option
  table.insert(archetypes, {
    id = 'search',
    label = 'Search Maven Central...',
    icon = '🔍',
  })

  ui.select(archetypes, {
    prompt = '🔨 Maven Archetype:',
    format_item = function(item)
      return string.format('%s  %s', item.icon, item.label)
    end,
  }, function(choice)
    if not choice then
      callback(nil)
      return
    end

    if choice.id == 'search' then
      M.search_archetype(callback)
    else
      callback(choice.id)
    end
  end)
end

function M.format_archetype_name(archetype_id)
  -- Convert maven-archetype-quickstart to "Quickstart"
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

-- FIXED: Added missing search_archetype function
function M.search_archetype(callback)
  local ui = require('marvin.ui')
  
  ui.input({
    prompt = 'Search for archetype: ',
    default = '',
  }, function(search_term)
    if not search_term or search_term == '' then
      callback(nil)
      return
    end
    
    -- For now, just use the search term as archetype ID
    -- In future, could integrate with Maven Central search API
    callback(search_term)
  end)
end

function M.get_project_details(callback)
  local ui = require('marvin.ui')
  local details = {}

  -- Prompt for groupId
  ui.input({
    prompt = 'Group ID (e.g., com.example): ',
    default = 'com.example',
  }, function(group_id)
    if not group_id or group_id == '' then
      callback(nil)
      return
    end
    details.group_id = group_id

    -- Prompt for artifactId
    ui.input({
      prompt = 'Artifact ID (e.g., my-app): ',
      default = 'my-app',
    }, function(artifact_id)
      if not artifact_id or artifact_id == '' then
        callback(nil)
        return
      end
      details.artifact_id = artifact_id

      -- Prompt for version
      ui.input({
        prompt = 'Version: ',
        default = '1.0-SNAPSHOT',
      }, function(version)
        if not version or version == '' then
          callback(nil)
          return
        end
        details.version = version

        callback(details)
      end)
    end)
  end)
end

-- FIXED: Added missing select_directory function
function M.select_directory(callback)
  local ui = require('marvin.ui')
  
  ui.input({
    prompt = 'Directory (leave empty for current): ',
    default = vim.fn.getcwd(),
  }, function(directory)
    if not directory or directory == '' then
      directory = vim.fn.getcwd()
    end
    
    -- Ensure directory exists
    vim.fn.mkdir(directory, 'p')
    callback(directory)
  end)
end

function M.generate(archetype, details, directory)
  local config = require('marvin').config -- FIXED: Was 'maven'
  local ui = require('marvin.ui')

  -- Build the Maven archetype:generate command
  -- FIXED: Removed extra spaces and line break
  local cmd = string.format(
    '%s archetype:generate -DinteractiveMode=false -DarchetypeArtifactId=%s -DgroupId=%s -DartifactId=%s -Dversion=%s',
    config.maven_command,
    archetype,
    details.group_id,
    details.artifact_id,
    details.version
  )

  ui.notify('Generating project...', vim.log.levels.INFO)

  -- Run the command
  vim.fn.jobstart(cmd, {
    cwd = directory,
    on_exit = function(_, exit_code, _)
      if exit_code == 0 then
        M.on_generation_complete(details, directory)
      else
        ui.notify('Project generation failed!', vim.log.levels.ERROR)
      end
    end,
  })
end

function M.on_generation_complete(details, directory)
  local ui = require('marvin.ui')
  local project_path = directory .. '/' .. details.artifact_id

  ui.notify('Project generated successfully!', vim.log.levels.INFO)

  -- Ask if user wants to open the project
  ui.select(
    { 'Yes', 'No' },
    { prompt = 'Open project now?' },
    function(choice)
      if choice == 'Yes' then
        vim.cmd('cd ' .. project_path)
        vim.cmd('edit ' .. project_path .. '/pom.xml')
      end
    end
  )
end

return M
