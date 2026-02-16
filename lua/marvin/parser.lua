local M = {}

function M.parse_output(lines)
  local errors = {}

  for _, line in ipairs(lines) do
    local error = M.parse_compilation_error(line)
    if error then
      table.insert(errors, error)
    end

    local test_error = M.parse_test_failure(line)
    if test_error then
      table.insert(errors, test_error)
    end
  end

  if #errors > 0 then
    M.populate_quickfix(errors)
  end
end

function M.parse_compilation_error(line)
  -- Match: [ERROR] /path/file.java:[line,col] message
  local pattern = '%[ERROR%]%s+(.-):%[(%d+),(%d+)%]%s+(.+)'
  local file, lnum, col, message = line:match(pattern)

  if file then
    return {
      filename = file,
      lnum = tonumber(lnum),
      col = tonumber(col),
      text = message,
      type = 'E',
    }
  end

  return nil
end

function M.parse_test_failure(line)
  -- Match: [ERROR]   TestClass.testMethod:line message
  local pattern = '%[ERROR%]%s+(.-)%.(.-):(.-)[%s:]+(.*)'
  local class, method, lnum, message = line:match(pattern)

  if class and method then
    -- Try to find the source file
    local file = M.find_test_file(class)

    if file then
      return {
        filename = file,
        lnum = tonumber(lnum),
        text = string.format('%s.%s: %s', class, method, message),
        type = 'E',
      }
    end
  end

  return nil
end

function M.find_test_file(class_name)
  local project = require('marvin.project').get_project()
  if not project then return nil end

  -- Convert class name to file path
  local relative_path = class_name:gsub('%.', '/') .. '.java'
  local test_path = project.root .. '/src/test/java/' .. relative_path

  if vim.fn.filereadable(test_path) == 1 then
    return test_path
  end

  return nil
end

function M.populate_quickfix(errors)
  -- Set the quickfix list
  vim.fn.setqflist(errors, 'r')

  local config = require('marvin').config

  if config.quickfix.auto_open then
    -- Open quickfix window
    vim.cmd('copen ' .. config.quickfix.height)
  end

  -- Notify user
  local ui = require('marvin.ui')
  ui.notify(
    string.format('Found %d error(s). Use :cnext/:cprev to navigate.', #errors),
    vim.log.levels.WARN
  )
end

return M
