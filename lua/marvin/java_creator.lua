local M = {}

-- Scan for packages in project with metadata
local function scan_packages()
  local project = require('marvin.project').get_project()

  if not project then
    return {}
  end

  local packages = {}
  local src_paths = {
    { path = project.root .. '/src/main/java', type = 'main' },
    { path = project.root .. '/src/test/java', type = 'test' },
  }

  for _, src_info in ipairs(src_paths) do
    if vim.fn.isdirectory(src_info.path) == 1 then
      local cmd = string.format('find "%s" -type d -not -path "*/\\.*" 2>/dev/null', src_info.path)
      local handle = io.popen(cmd)

      if handle then
        for dir in handle:lines() do
          if dir ~= src_info.path then
            local package = dir:gsub(vim.pesc(src_info.path) .. '/', ''):gsub('/', '.')

            if package ~= '' then
              if not packages[package] then
                packages[package] = {
                  name = package,
                  types = {},
                  file_count = 0,
                }
              end
              packages[package].types[src_info.type] = true

              -- Count Java files
              local java_files = vim.fn.glob(dir .. '/*.java', false, true)
              packages[package].file_count = packages[package].file_count + #java_files
            end
          end
        end
        handle:close()
      end
    end
  end

  -- Convert to array and sort
  local package_list = {}
  for _, pkg_info in pairs(packages) do
    table.insert(package_list, pkg_info)
  end

  -- Sort: parent packages first, then alphabetically
  table.sort(package_list, function(a, b)
    local a_depth = select(2, a.name:gsub('%.', '.'))
    local b_depth = select(2, b.name:gsub('%.', '.'))

    if a_depth == b_depth then
      return a.name < b.name
    end
    return a_depth < b_depth
  end)

  return package_list
end

-- Get package hierarchy depth
local function get_package_depth(package_name)
  return select(2, package_name:gsub('%.', '.'))
end

-- Enhanced package selector with visual hierarchy
function M.select_package(callback, on_back)
  local templates = require('marvin.templates')
  local ui = require('marvin.ui')

  local packages = scan_packages()
  local current_package = templates.get_package_from_path()
  local default_package = current_package or templates.get_default_package()

  local package_items = {}

  -- ===== SECTION: Current/Suggested =====
  table.insert(package_items, {
    id = 'separator_current',
    label = 'Current Location',
    is_separator = true
  })

  if current_package then
    table.insert(package_items, {
      value = current_package,
      label = current_package,
      icon = '📍',
      desc = 'Current file location',
      shortcut = 'c'
    })
  end

  if default_package ~= current_package then
    table.insert(package_items, {
      value = default_package,
      label = default_package,
      icon = '🏠',
      desc = 'Project default package',
      shortcut = 'd'
    })
  end

  -- ===== SECTION: Quick Actions =====
  table.insert(package_items, {
    id = 'separator_actions',
    label = 'Quick Actions',
    is_separator = true
  })

  table.insert(package_items, {
    value = '__CREATE_NEW__',
    label = 'Create New Package',
    icon = '✨',
    desc = 'Enter custom package name',
    shortcut = 'n'
  })

  -- Suggest creating a subpackage of current location
  if current_package then
    table.insert(package_items, {
      value = '__CREATE_SUB__',
      label = 'Create Subpackage',
      icon = '📁',
      desc = 'Create under ' .. current_package,
      shortcut = 's'
    })
  end

  -- ===== SECTION: Existing Packages by Hierarchy =====
  if #packages > 0 then
    -- Group packages by depth
    local root_packages = {}
    local sub_packages = {}

    for _, pkg_info in ipairs(packages) do
      local depth = get_package_depth(pkg_info.name)

      -- Skip current and default as they're already shown
      if pkg_info.name ~= current_package and pkg_info.name ~= default_package then
        if depth == 0 then
          table.insert(root_packages, pkg_info)
        else
          table.insert(sub_packages, pkg_info)
        end
      end
    end

    -- Root packages
    if #root_packages > 0 then
      table.insert(package_items, {
        id = 'separator_root',
        label = 'Root Packages',
        is_separator = true
      })

      for _, pkg_info in ipairs(root_packages) do
        local type_indicator = ''
        if pkg_info.types.main and pkg_info.types.test then
          type_indicator = 'main + test'
        elseif pkg_info.types.main then
          type_indicator = 'main'
        elseif pkg_info.types.test then
          type_indicator = 'test'
        end

        table.insert(package_items, {
          value = pkg_info.name,
          label = pkg_info.name,
          icon = '📦',
          desc = string.format('%d files • %s', pkg_info.file_count, type_indicator)
        })
      end
    end

    -- Subpackages
    if #sub_packages > 0 then
      table.insert(package_items, {
        id = 'separator_sub',
        label = 'Subpackages',
        is_separator = true
      })

      for _, pkg_info in ipairs(sub_packages) do
        local depth = get_package_depth(pkg_info.name)
        local indent = string.rep('  ', depth - 1)

        local type_indicator = ''
        if pkg_info.types.main and pkg_info.types.test then
          type_indicator = 'main + test'
        elseif pkg_info.types.main then
          type_indicator = 'main'
        elseif pkg_info.types.test then
          type_indicator = 'test'
        end

        -- Get the last segment for display
        local segments = {}
        for segment in pkg_info.name:gmatch('[^.]+') do
          table.insert(segments, segment)
        end
        local display_name = segments[#segments]

        table.insert(package_items, {
          value = pkg_info.name,
          label = indent .. '└─ ' .. display_name,
          icon = '📂',
          desc = string.format('%s • %d files', type_indicator, pkg_info.file_count)
        })
      end
    end
  end

  -- Show the selector
  ui.select(package_items, {
    prompt = 'Select Package',
    enable_search = true,
    on_back = on_back,
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      callback(nil)
      return
    end

    if choice.value == '__CREATE_NEW__' then
      vim.cmd('stopinsert')
      vim.schedule(function()
        ui.input({
          prompt = 'New Package Name',
          default = default_package,
        }, function(new_package)
          if new_package and new_package ~= '' then
            callback(new_package)
          else
            callback(nil)
          end
        end)
      end)
    elseif choice.value == '__CREATE_SUB__' then
      vim.cmd('stopinsert')
      vim.schedule(function()
        ui.input({
          prompt = 'Subpackage Name',
          default = current_package .. '.',
        }, function(new_package)
          if new_package and new_package ~= '' then
            callback(new_package)
          else
            callback(nil)
          end
        end)
      end)
    else
      vim.cmd('stopinsert')
      vim.schedule(function()
        callback(choice.value)
      end)
    end
  end)
end

-- Create a new Java file with package selector
function M.create_file_interactive(type_name, options, menu_on_back)
  options = options or {}
  local templates = require('marvin.templates')
  local ui = require('marvin.ui')

  -- Step 1: Get class name
  ui.input({
    prompt = '☕ ' .. type_name .. ' Name',
  }, function(class_name)
    if not class_name or class_name == '' then
      return
    end

    -- Step 2: Select package - ensure we exit insert mode before opening select
    vim.cmd('stopinsert')
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
      end, function()
        -- Back callback - show the type menu again
        M.show_menu(menu_on_back)
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
function M.show_menu(on_back)
  local ui = require('marvin.ui')

  local types = {
    {
      id = 'separator_common',
      label = 'Common Types',
      is_separator = true
    },
    {
      id = 'class',
      label = 'Java Class',
      icon = '☕',
      desc = 'Standard class with fields and methods',
      shortcut = 'c'
    },
    {
      id = 'class_main',
      label = 'Main Class',
      icon = '🚀',
      desc = 'Executable class with main() method',
      shortcut = 'm'
    },
    {
      id = 'interface',
      label = 'Interface',
      icon = '📋',
      desc = 'Contract definition for classes',
      shortcut = 'i'
    },
    {
      id = 'enum',
      label = 'Enum',
      icon = '🔢',
      desc = 'Type-safe enumeration of constants',
      shortcut = 'e'
    },
    {
      id = 'record',
      label = 'Record',
      icon = '📦',
      desc = 'Immutable data carrier (Java 14+)',
      shortcut = 'r'
    },

    {
      id = 'separator_patterns',
      label = 'Design Patterns',
      is_separator = true
    },
    {
      id = 'builder',
      label = 'Builder Pattern',
      icon = '🏗️',
      desc = 'Fluent API for object construction',
      shortcut = 'b'
    },

    {
      id = 'separator_advanced',
      label = 'Advanced',
      is_separator = true
    },
    {
      id = 'abstract',
      label = 'Abstract Class',
      icon = '🎨',
      desc = 'Partial implementation base class',
      shortcut = 'a'
    },
    {
      id = 'exception',
      label = 'Custom Exception',
      icon = '❌',
      desc = 'Custom error type',
      shortcut = 'x'
    },

    {
      id = 'separator_testing',
      label = 'Testing',
      is_separator = true
    },
    {
      id = 'test',
      label = 'JUnit Test',
      icon = '🧪',
      desc = 'JUnit 5 test class',
      shortcut = 't'
    },
  }

  ui.select(types, {
    prompt = 'Create Java File',
    on_back = on_back,
  }, function(choice)
    if not choice then return end

    local options = {}

    if choice.id == 'class' then
      M.create_file_interactive('Class', options, on_back)
    elseif choice.id == 'class_main' then
      options.main = true
      M.create_file_interactive('Class', options, on_back)
    elseif choice.id == 'interface' then
      M.create_file_interactive('Interface', options, on_back)
    elseif choice.id == 'enum' then
      M.prompt_enum_values(function(values)
        if values then
          options.values = values
          M.create_file_interactive('Enum', options, on_back)
        end
      end)
    elseif choice.id == 'record' then
      M.prompt_fields(function(fields)
        if fields then
          options.fields = fields
          M.create_file_interactive('Record', options, on_back)
        end
      end, 'Record Fields (Type name, Type name, ...)')
    elseif choice.id == 'abstract' then
      M.create_file_interactive('Abstract Class', options, on_back)
    elseif choice.id == 'exception' then
      M.create_file_interactive('Exception', options, on_back)
    elseif choice.id == 'test' then
      M.create_file_interactive('Test', options, on_back)
    elseif choice.id == 'builder' then
      M.prompt_fields(function(fields)
        if fields then
          if #fields > 0 then
            fields[1].required = true
          end
          options.fields = fields
          M.create_file_interactive('Builder', options, on_back)
        end
      end, 'Builder Fields (Type name, Type name, ...)')
    end
  end)
end

return M
