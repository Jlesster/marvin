local M = {}

-- Create a new Java file
function M.create_file(type_name, options)
  options = options or {}
  local templates = require('marvin.templates')
  local ui = require('marvin.ui')

  -- Get class name
  ui.input({
    prompt = type_name .. ' name: ',
  }, function(class_name)
    if not class_name or class_name == '' then
      return
    end

    -- Determine package
    local current_package = templates.get_package_from_path()
    local default_package = current_package or templates.get_default_package()

    ui.input({
      prompt = 'Package (leave empty for default): ',
      default = default_package,
    }, function(package_name)
      package_name = package_name or default_package

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

      ui.notify('Created ' .. type_name .. ': ' .. class_name, vim.log.levels.INFO)
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

-- Show creation menu
function M.show_menu()
  local ui = require('marvin.ui')

  local types = {
    { id = 'class', label = '☕ Java Class', desc = 'Standard Java class' },
    { id = 'class_main', label = '🚀 Main Class', desc = 'Class with main method' },
    { id = 'interface', label = '📋 Interface', desc = 'Java interface' },
    { id = 'enum', label = '🔢 Enum', desc = 'Enumeration type' },
    { id = 'record', label = '📦 Record', desc = 'Java record (14+)' },
    { id = 'abstract', label = '🎨 Abstract Class', desc = 'Abstract class' },
    { id = 'exception', label = '❌ Exception', desc = 'Custom exception class' },
    { id = 'test', label = '🧪 JUnit Test', desc = 'JUnit test class' },
    { id = 'builder', label = '🏗️  Builder Pattern', desc = 'Class with builder pattern' },
  }

  ui.select(types, {
    prompt = '☕ Create Java File:',
    format_item = function(item)
      return item.label .. ' - ' .. item.desc
    end,
  }, function(choice)
    if not choice then return end

    local options = {}

    if choice.id == 'class' then
      M.create_file('Class', options)
    elseif choice.id == 'class_main' then
      options.main = true
      M.create_file('Class', options)
    elseif choice.id == 'interface' then
      M.create_file('Interface', options)
    elseif choice.id == 'enum' then
      M.prompt_enum_values(function(values)
        options.values = values
        M.create_file('Enum', options)
      end)
    elseif choice.id == 'record' then
      M.prompt_record_fields(function(fields)
        options.fields = fields
        M.create_file('Record', options)
      end)
    elseif choice.id == 'abstract' then
      M.create_file('Abstract Class', options)
    elseif choice.id == 'exception' then
      M.create_file('Exception', options)
    elseif choice.id == 'test' then
      M.create_file('Test', options)
    elseif choice.id == 'builder' then
      M.prompt_builder_fields(function(fields)
        options.fields = fields
        M.create_file('Builder', options)
      end)
    end
  end)
end

-- Prompt for enum values
function M.prompt_enum_values(callback)
  local ui = require('marvin.ui')

  ui.input({
    prompt = 'Enum values (comma-separated): ',
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

-- Prompt for record fields
function M.prompt_record_fields(callback)
  local ui = require('marvin.ui')

  ui.input({
    prompt = 'Record fields (type name, ...): ',
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

-- Prompt for builder fields
function M.prompt_builder_fields(callback)
  M.prompt_record_fields(function(fields)
    if not fields then
      callback(nil)
      return
    end

    -- Mark first field as required by default
    if #fields > 0 then
      fields[1].required = true
    end

    callback(fields)
  end)
end

return M
