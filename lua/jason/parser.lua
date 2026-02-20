-- lua/jason/parser.lua
local M = {}

function M.parse_output(lines)
  local errors = {}

  for _, line in ipairs(lines) do
    local error = M.parse_java_error(line)
        or M.parse_rust_error(line)
        or M.parse_go_error(line)
        or M.parse_cpp_error(line)

    if error then
      table.insert(errors, error)
    end
  end

  if #errors > 0 then
    M.populate_quickfix(errors)
  end
end

-- Java error patterns
function M.parse_java_error(line)
  -- Pattern: /path/File.java:10: error: message
  local file, lnum, message = line:match('([^:]+%.java):(%d+):%s*error:%s*(.+)')

  if file and lnum then
    return {
      filename = file,
      lnum = tonumber(lnum),
      col = 1,
      text = message,
      type = 'E',
    }
  end

  -- Maven error pattern
  local maven_file, maven_lnum, maven_col, maven_msg =
      line:match('%[ERROR%]%s+(.-):%[(%d+),(%d+)%]%s+(.+)')

  if maven_file then
    return {
      filename = maven_file,
      lnum = tonumber(maven_lnum),
      col = tonumber(maven_col),
      text = maven_msg,
      type = 'E',
    }
  end

  return nil
end

-- Rust error patterns
function M.parse_rust_error(line)
  -- Pattern: error[E0308]: mismatched types
  --   --> src/main.rs:10:5
  if line:match('^error%[') then
    -- Store for next line which has location
    M.rust_error_msg = line
    return nil
  end

  if M.rust_error_msg then
    local file, lnum, col = line:match('%-%->%s+([^:]+):(%d+):(%d+)')

    if file and lnum then
      local error = {
        filename = file,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = M.rust_error_msg,
        type = 'E',
      }
      M.rust_error_msg = nil
      return error
    end
  end

  return nil
end

-- Go error patterns
function M.parse_go_error(line)
  -- Pattern: ./main.go:10:5: error message
  local file, lnum, col, message = line:match('([^:]+%.go):(%d+):(%d+):%s*(.+)')

  if file and lnum then
    return {
      filename = file,
      lnum = tonumber(lnum),
      col = tonumber(col) or 1,
      text = message,
      type = 'E',
    }
  end

  return nil
end

-- C/C++ error patterns
function M.parse_cpp_error(line)
  -- GCC/Clang pattern: file.cpp:10:5: error: message
  local file, lnum, col, level, message =
      line:match('([^:]+%.[ch]p?p?):(%d+):(%d+):%s*(%w+):%s*(.+)')

  if file and lnum then
    local err_type = 'E'
    if level == 'warning' then
      err_type = 'W'
    end

    return {
      filename = file,
      lnum = tonumber(lnum),
      col = tonumber(col) or 1,
      text = message,
      type = err_type,
    }
  end

  return nil
end

function M.populate_quickfix(errors)
  vim.fn.setqflist(errors, 'r')

  local config = require('jason').config

  if config.quickfix.auto_open then
    vim.cmd('copen ' .. config.quickfix.height)
  end

  vim.notify(
    string.format('Found %d error(s). Use :cnext/:cprev to navigate.', #errors),
    vim.log.levels.WARN
  )
end

return M
