local M = {}

-- Scan for packages in project (filtered and smart)
local function scan_packages()
  local project = require('marvin.project').get_project()

  if not project then
    return {}
  end

  local packages = {}
  local src_paths = {
    project.root .. '/src/main/java',
    project.root .. '/src/test/java',
  }

  for _, src_path in ipairs(src_paths) do
    if vim.fn.isdirectory(src_path) == 1 then
      -- Use find but exclude hidden directories
      local cmd = string.format('find "%s" -type d 2>/dev/null | grep -v "/\\."', src_path)
      local handle = io.popen(cmd)

      if handle then
        for dir in handle:lines() do
          -- Skip the base source directory itself
          if dir ~= src_path then
            -- Convert path to package name
            local package = dir:gsub(vim.pesc(src_path) .. '/', ''):gsub('/', '.')

            -- Filter out problematic packages
            if package ~= '' and not packages[package] then
              -- Skip packages with dots at start or that look like hidden dirs
              local has_hidden = package:match('^%.') or package:match('%/%.') or dir:match('%/%.')

              -- Skip packages that are too deep (more than 5 levels)
              local depth = select(2, package:gsub('%.', '.'))

              -- Must be valid Java package (lowercase start, valid chars)
              local is_valid = package:match('^[a-z][a-z0-9_]*') and not package:match('[A-Z]')

              -- Check if directory contains actual Java files
              local has_java_files = vim.fn.glob(dir .. '/*.java') ~= ''

              if not has_hidden and depth <= 5 and is_valid and has_java_files then
                packages[package] = true
              end
            end
          end
        end
        handle:close()
      end
    end
  end

  -- Convert to array and sort intelligently
  local package_list = {}
  for pkg, _ in pairs(packages) do
    table.insert(package_list, pkg)
  end

  -- Sort packages: shorter (parent) packages first, then alphabetically
  table.sort(package_list, function(a, b)
    local a_depth = select(2, a:gsub('%.', '.'))
    local b_depth = select(2, b:gsub('%.', '.'))

    if a_depth == b_depth then
      return a < b
    end
    return a_depth < b_depth
  end)

  -- Limit to top 10 most relevant packages if too many
  if #package_list > 10 then
    local limited = {}
    for i = 1, 10 do
      table.insert(limited, package_list[i])
    end
    return limited
  end

  return package_list
end

-- Create package selector with modern UI
function M.select_package(callback)
  local templates = require('marvin.templates')
  local ui = require('marvin.ui')

  local packages = scan_packages()
  local current_package = templates.get_package_from_path()
  local default_package = current_package or templates.get_default_package()

  -- Build package items with better organization
  local package_items = {}

  -- Add current/default at top
  table.insert(package_items, {
    value = default_package,
    label = default_package,
    desc = 'Current/default package',
    icon = '📍'
  })

  -- Add new package option
  table.insert(package_items, {
    value = 'new',
    label = 'Create New Package',
    desc = 'Enter a new package name',
    icon = '✨'
  })

  -- Add existing packages if any (compact list)
  if #packages > 0 then
    for _, pkg in ipairs(packages) do
      -- Skip if it's the same as default
      if pkg ~= default_package then
        table.insert(package_items, {
          value = pkg,
          label = pkg,
          desc = 'Existing package',
          icon = '📦'
        })
      end
    end
  end

  -- Use the modern select UI (this should stay in normal mode)
  ui.select(package_items, {
    prompt = 'Select Package',
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      callback(nil)
      return
    end

    if choice.value == 'new' then
      -- ONLY when creating new package, use input (which goes to insert mode)
      vim.schedule(function()
        ui.input({
          prompt = '📦 New Package Name',
          default = default_package,
        }, function(new_package)
          if new_package and new_package ~= '' then
            callback(new_package)
          else
            callback(nil)
          end
        end)
      end)
    else
      -- For existing packages, just callback immediately (stay in normal mode)
      callback(choice.value)
    end
  end)
end

-- Create a new Java file with package selector
function M.create_file_interactive(type_name, options)
  options = options or {}
  local templates = require('marvin.templates')
  local ui = require('marvin.ui')

  -- Step 1: Get class name (input - insert mode is OK here)
  ui.input({
    prompt = '☕ ' .. type_name .. ' Name',
  }, function(class_name)
    if not class_name or class_name == '' then
      return
    end

    -- Step 2: Select package (should stay in normal mode unless creating new)
    vim.schedule(function()
      M.select_package(function(package_name)
        if not package_name then
          return
        end

        -- Generate content based on type
        local lines
        if type_name == 'Class' then
          lines = templates.class_template(class_name, package_name, options)
        elseif type_name == 'Interface' then
          lines = templates.interface_template(class_name, package_name, options)
        elseif type_name == 'Enum' then
          lines = templates.enum_template(class_name, package_name, options)
        elseif type_name == 'Record' then
          lines = templates.record_template(class_name, package_name, options)
        elseif type_name == 'Abstract Class' then
          lines = templates.abstract_class_template(class_name, package_name, options)
        elseif type_name == 'Exception' then
          lines = templates.exception_template(class_name, package_name, options)
        elseif type_name == 'Test' then
          lines = templates.test_template(class_name, package_name, options)
        elseif type_name == 'Builder' then
          lines = templates.builder_template(class_name, package_name, options)
        end

        if not lines then
          vim.notify('Unknown type: ' .. type_name, vim.log.levels.ERROR)
          return
        end

        -- Determine file path
        local file_path = M.get_file_path(class_name, package_name, type_name)

        if not file_path then
          return
        end

        -- Create directory if it doesn't exist
        local dir = vim.fn.fnamemodify(file_path, ':h')
        vim.fn.mkdir(dir, 'p')

        -- Write file
        M.write_file(file_path, lines)

        -- Open the file
        vim.cmd('edit ' .. file_path)

        ui.notify('✅ Created ' .. type_name .. ': ' .. class_name, vim.log.levels.INFO)
      end)
    end)
  end)
end

-- Get file path for a class
function M.get_file_path(class_name, package_name, type_name)
  local project = require('marvin.project').get_project()

  if not project then
    vim.notify('Not in a Maven project', vim.log.levels.ERROR)
    return nil
  end

  local base_path
  if type_name == 'Test' then
    base_path = project.root .. '/src/test/java/'
  else
    base_path = project.root .. '/src/main/java/'
  end

  local package_path = package_name:gsub('%.', '/')
  return base_path .. package_path .. '/' .. class_name .. '.java'
end

-- Write lines to file
function M.write_file(file_path, lines)
  local file = io.open(file_path, 'w')
  if not file then
    vim.notify('Failed to create file: ' .. file_path, vim.log.levels.ERROR)
    return
  end

  for _, line in ipairs(lines) do
    file:write(line .. '\n')
  end

  file:close()
end

-- Prompt for enum values
function M.prompt_enum_values(callback)
  local ui = require('marvin.ui')

  ui.input({
    prompt = '🔢 Enum Values (comma-separated)',
    default = 'VALUE1, VALUE2, VALUE3',
  }, function(input)
    if not input or input == '' then
      callback(nil)
      return
    end

    local values = {}
    for value in input:gmatch('[^,]+') do
      table.insert(values, vim.trim(value):upper())
    end

    callback(values)
  end)
end

-- Prompt for record/builder fields
function M.prompt_fields(callback, prompt_text)
  local ui = require('marvin.ui')

  ui.input({
    prompt = prompt_text or '📋 Fields (Type name, ...)',
    default = 'String name, int value',
  }, function(input)
    if not input or input == '' then
      callback(nil)
      return
    end

    local fields = {}
    for field_def in input:gmatch('[^,]+') do
      local trimmed = vim.trim(field_def)
      local type_name, field_name = trimmed:match('(%S+)%s+(%S+)')
      if type_name and field_name then
        table.insert(fields, { type = type_name, name = field_name })
      end
    end

    callback(#fields > 0 and fields or nil)
  end)
end

-- Show creation menu
function M.show_menu()
  local ui = require('marvin.ui')

  local types = {
    { id = 'class', label = 'Java Class', icon = '☕', desc = 'Standard Java class' },
    { id = 'class_main', label = 'Main Class', icon = '🚀', desc = 'Class with main method' },
    { id = 'interface', label = 'Interface', icon = '📋', desc = 'Java interface' },
    { id = 'enum', label = 'Enum', icon = '🔢', desc = 'Enumeration type' },
    { id = 'record', label = 'Record', icon = '📦', desc = 'Java record (14+)' },
    { id = 'abstract', label = 'Abstract Class', icon = '🎨', desc = 'Abstract class' },
    { id = 'exception', label = 'Exception', icon = '❌', desc = 'Custom exception class' },
    { id = 'test', label = 'JUnit Test', icon = '🧪', desc = 'JUnit test class' },
    { id = 'builder', label = 'Builder Pattern', icon = '🏗️', desc = 'Class with builder pattern' },
  }

  ui.select(types, {
    prompt = '☕ Create Java File',
  }, function(choice)
    if not choice then return end

    local options = {}

    if choice.id == 'class' then
      M.create_file_interactive('Class', options)
    elseif choice.id == 'class_main' then
      options.main = true
      M.create_file_interactive('Class', options)
    elseif choice.id == 'interface' then
      M.create_file_interactive('Interface', options)
    elseif choice.id == 'enum' then
      M.prompt_enum_values(function(values)
        if values then
          options.values = values
          M.create_file_interactive('Enum', options)
        end
      end)
    elseif choice.id == 'record' then
      M.prompt_fields(function(fields)
        if fields then
          options.fields = fields
          M.create_file_interactive('Record', options)
        end
      end, '📦 Record Fields (Type name, ...)')
    elseif choice.id == 'abstract' then
      M.create_file_interactive('Abstract Class', options)
    elseif choice.id == 'exception' then
      M.create_file_interactive('Exception', options)
    elseif choice.id == 'test' then
      M.create_file_interactive('Test', options)
    elseif choice.id == 'builder' then
      M.prompt_fields(function(fields)
        if fields then
          -- Mark first field as required
          if #fields > 0 then
            fields[1].required = true
          end
          options.fields = fields
          M.create_file_interactive('Builder', options)
        end
      end, '🏗️  Builder Fields (Type name, ...)')
    end
  end)
end

return M
