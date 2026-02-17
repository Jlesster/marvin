-- lua/marvin/java_creator.lua
local M = {}

local function scan_packages()
  local project = require('marvin.project').get_project()
  if not project then return {} end

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
                packages[package] = { name = package, types = {}, file_count = 0 }
              end
              packages[package].types[src_info.type] = true
              local java_files = vim.fn.glob(dir .. '/*.java', false, true)
              packages[package].file_count = packages[package].file_count + #java_files
            end
          end
        end
        handle:close()
      end
    end
  end

  local package_list = {}
  for _, pkg_info in pairs(packages) do
    package_list[#package_list + 1] = pkg_info
  end
  table.sort(package_list, function(a, b)
    local ad = select(2, a.name:gsub('%.', '.'))
    local bd = select(2, b.name:gsub('%.', '.'))
    if ad == bd then return a.name < b.name end
    return ad < bd
  end)
  return package_list
end

local function get_package_depth(name)
  return select(2, name:gsub('%.', '.'))
end

function M.select_package(callback, on_back)
  local templates = require('marvin.templates')
  local ui        = require('marvin.ui')
  local packages  = scan_packages()
  local cur_pkg   = templates.get_package_from_path()
  local def_pkg   = cur_pkg or templates.get_default_package()
  local items     = {}
  local function add(t) items[#items + 1] = t end

  add({ label = 'Current Location', is_separator = true })
  if cur_pkg then
    add({ value = cur_pkg, label = cur_pkg, icon = '󰉋', desc = 'Current file location' })
  end
  if def_pkg ~= cur_pkg then
    add({ value = def_pkg, label = def_pkg, icon = '󱂵', desc = 'Project default package' })
  end

  add({ label = 'Quick Actions', is_separator = true })
  add({ value = '__CREATE_NEW__', label = 'Create New Package', icon = '󰜄', desc = 'Enter custom package name' })
  if cur_pkg then
    add({ value = '__CREATE_SUB__', label = 'Create Subpackage', icon = '󰉋', desc = 'Create under ' .. cur_pkg })
  end

  if #packages > 0 then
    local root_pkgs, sub_pkgs = {}, {}
    for _, pkg in ipairs(packages) do
      if pkg.name ~= cur_pkg and pkg.name ~= def_pkg then
        if get_package_depth(pkg.name) == 0 then
          root_pkgs[#root_pkgs + 1] = pkg
        else
          sub_pkgs[#sub_pkgs + 1] = pkg
        end
      end
    end

    if #root_pkgs > 0 then
      add({ label = 'Root Packages', is_separator = true })
      for _, pkg in ipairs(root_pkgs) do
        local ti = (pkg.types.main and pkg.types.test) and 'main + test'
            or pkg.types.main and 'main' or 'test'
        add({
          value = pkg.name,
          label = pkg.name,
          icon = '󰏗',
          desc = string.format('%d files * %s', pkg.file_count, ti)
        })
      end
    end

    if #sub_pkgs > 0 then
      add({ label = 'Subpackages', is_separator = true })
      for _, pkg in ipairs(sub_pkgs) do
        local depth = get_package_depth(pkg.name)
        local indent = string.rep('  ', depth - 1)
        local ti = (pkg.types.main and pkg.types.test) and 'main + test'
            or pkg.types.main and 'main' or 'test'
        local segs = {}
        for s in pkg.name:gmatch('[^.]+') do segs[#segs + 1] = s end
        add({
          value = pkg.name,
          label = indent .. '`- ' .. segs[#segs],
          icon = '󰉓',
          desc = string.format('%s * %d files', ti, pkg.file_count)
        })
      end
    end
  end

  ui.select(items, {
    prompt        = 'Select Package',
    enable_search = true,
    on_back       = on_back,
    format_item   = function(it) return it.label end,
  }, function(choice)
    if not choice then
      callback(nil); return
    end

    if choice.value == '__CREATE_NEW__' then
      vim.cmd('stopinsert')
      vim.schedule(function()
        ui.input({ prompt = 'New Package Name', default = def_pkg }, function(pkg)
          callback(pkg ~= '' and pkg or nil)
        end)
      end)
    elseif choice.value == '__CREATE_SUB__' then
      vim.cmd('stopinsert')
      vim.schedule(function()
        ui.input({ prompt = 'Subpackage Name', default = cur_pkg .. '.' }, function(pkg)
          callback(pkg ~= '' and pkg or nil)
        end)
      end)
    else
      vim.cmd('stopinsert')
      vim.schedule(function() callback(choice.value) end)
    end
  end)
end

function M.create_file_interactive(type_name, options, menu_on_back)
  options         = options or {}
  local templates = require('marvin.templates')
  local ui        = require('marvin.ui')

  ui.input({ prompt = '󰬷 ' .. type_name .. ' Name' }, function(class_name)
    if not class_name or class_name == '' then return end
    vim.cmd('stopinsert')
    vim.schedule(function()
      M.select_package(function(package_name)
        if not package_name then return end

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
          vim.notify('Unknown type: ' .. type_name, vim.log.levels.ERROR); return
        end

        local file_path = M.get_file_path(class_name, package_name, type_name)
        if not file_path then return end

        vim.fn.mkdir(vim.fn.fnamemodify(file_path, ':h'), 'p')
        M.write_file(file_path, lines)
        vim.cmd('edit ' .. file_path)
        ui.notify('󰄬 Created ' .. type_name .. ': ' .. class_name, vim.log.levels.INFO)
      end, function()
        M.show_menu(menu_on_back)
      end)
    end)
  end)
end

function M.get_file_path(class_name, package_name, type_name)
  local project = require('marvin.project').get_project()
  if not project then
    vim.notify('Not in a Maven project', vim.log.levels.ERROR); return nil
  end
  local base = type_name == 'Test'
      and project.root .. '/src/test/java/'
      or project.root .. '/src/main/java/'
  return base .. package_name:gsub('%.', '/') .. '/' .. class_name .. '.java'
end

function M.write_file(file_path, lines)
  local file = io.open(file_path, 'w')
  if not file then
    vim.notify('Failed to create file: ' .. file_path, vim.log.levels.ERROR); return
  end
  for _, line in ipairs(lines) do file:write(line .. '\n') end
  file:close()
end

function M.prompt_enum_values(callback)
  require('marvin.ui').input({
    prompt  = '󰒻 Enum Values (comma-separated)',
    default = 'VALUE1, VALUE2, VALUE3',
  }, function(input)
    if not input or input == '' then
      callback(nil); return
    end
    local values = {}
    for v in input:gmatch('[^,]+') do values[#values + 1] = vim.trim(v):upper() end
    callback(values)
  end)
end

function M.prompt_fields(callback, prompt_text)
  require('marvin.ui').input({
    prompt  = prompt_text or '󰠱 Fields (Type name, ...)',
    default = 'String name, int value',
  }, function(input)
    if not input or input == '' then
      callback(nil); return
    end
    local fields = {}
    for fd in input:gmatch('[^,]+') do
      local tn, fn = vim.trim(fd):match('(%S+)%s+(%S+)')
      if tn and fn then fields[#fields + 1] = { type = tn, name = fn } end
    end
    callback(#fields > 0 and fields or nil)
  end)
end

function M.show_menu(on_back)
  local ui = require('marvin.ui')

  local types = {
    { label = 'Common Types', is_separator = true },
    { id = 'class', icon = '󰬷', label = 'Java Class', desc = 'Standard class with fields and methods' },
    { id = 'class_main', icon = '󰁔', label = 'Main Class', desc = 'Executable class with main() method' },
    { id = 'interface', icon = '󰜰', label = 'Interface', desc = 'Contract definition for classes' },
    { id = 'enum', icon = '󰒻', label = 'Enum', desc = 'Type-safe enumeration of constants' },
    { id = 'record', icon = '󰏗', label = 'Record', desc = 'Immutable data carrier (Java 14+)' },

    { label = 'Design Patterns', is_separator = true },
    { id = 'builder', icon = '󰒓', label = 'Builder Pattern', desc = 'Fluent API for object construction' },

    { label = 'Advanced', is_separator = true },
    { id = 'abstract', icon = '󰦊', label = 'Abstract Class', desc = 'Partial implementation base class' },
    { id = 'exception', icon = '󰅖', label = 'Custom Exception', desc = 'Custom error type' },

    { label = 'Testing', is_separator = true },
    { id = 'test', icon = '󰙨', label = 'JUnit Test', desc = 'JUnit 5 test class' },
  }

  ui.select(types, {
    prompt      = 'Create Java File',
    on_back     = on_back,
    format_item = function(it) return it.label end,
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
          options.values = values; M.create_file_interactive('Enum', options, on_back)
        end
      end)
    elseif choice.id == 'record' then
      M.prompt_fields(function(fields)
        if fields then
          options.fields = fields; M.create_file_interactive('Record', options, on_back)
        end
      end, '󰏗 Record Fields (Type name, Type name, ...)')
    elseif choice.id == 'abstract' then
      M.create_file_interactive('Abstract Class', options, on_back)
    elseif choice.id == 'exception' then
      M.create_file_interactive('Exception', options, on_back)
    elseif choice.id == 'test' then
      M.create_file_interactive('Test', options, on_back)
    elseif choice.id == 'builder' then
      M.prompt_fields(function(fields)
        if fields then
          if #fields > 0 then fields[1].required = true end
          options.fields = fields
          M.create_file_interactive('Builder', options, on_back)
        end
      end, '󰒓 Builder Fields (Type name, Type name, ...)')
    end
  end)
end

return M
