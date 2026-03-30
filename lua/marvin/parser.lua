-- lua/marvin/parser.lua
-- Marvin side: Maven compilation errors and test failures.
-- Jason side:  Java (javac), Rust, Go, C/C++ error patterns.

local M = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- Shared: populate quickfix and dispatch
-- ══════════════════════════════════════════════════════════════════════════════

function M.parse_output(lines)
  local errors = {}
  for _, line in ipairs(lines) do
    local err = M.parse_compilation_error(line) -- Marvin: Maven [ERROR]
        or M.parse_java_error(line)             -- Jason: javac style
        or M.parse_rust_error(line)
        or M.parse_go_error(line)
        or M.parse_cpp_error(line)
    if err then errors[#errors + 1] = err end

    local test_err = M.parse_test_failure(line) -- Marvin: Maven test
    if test_err then errors[#errors + 1] = test_err end
  end
  if #errors > 0 then M.populate_quickfix(errors) end
end

function M.populate_quickfix(errors)
  vim.fn.setqflist(errors, 'r')
  local config = require('marvin').config
  if config.quickfix.auto_open then
    vim.cmd('copen ' .. config.quickfix.height)
  end
  require('marvin.ui').notify(
    string.format('Found %d error(s). Use :cnext/:cprev to navigate.', #errors),
    vim.log.levels.WARN)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- MARVIN — Maven-specific patterns
-- ══════════════════════════════════════════════════════════════════════════════

-- [ERROR] /path/file.java:[line,col] message
function M.parse_compilation_error(line)
  local file, lnum, col, message =
      line:match('%[ERROR%]%s+(.-):%[(%d+),(%d+)%]%s+(.+)')
  if file then
    return { filename = file, lnum = tonumber(lnum), col = tonumber(col), text = message, type = 'E' }
  end
end

-- [ERROR]   TestClass.testMethod:line message
function M.parse_test_failure(line)
  local class, method, lnum, message =
      line:match('%[ERROR%]%s+(.-)%.(.-):(.-)[%s:]+(.*)')
  if class and method then
    local file = M.find_test_file(class)
    if file then
      return {
        filename = file,
        lnum     = tonumber(lnum),
        text     = string.format('%s.%s: %s', class, method, message),
        type     = 'E',
      }
    end
  end
end

function M.find_test_file(class_name)
  local project = require('marvin.project').get()
  if not project then return nil end
  local rel  = class_name:gsub('%.', '/') .. '.java'
  local path = project.root .. '/src/test/java/' .. rel
  if vim.fn.filereadable(path) == 1 then return path end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- JASON — Multi-language patterns
-- ══════════════════════════════════════════════════════════════════════════════

-- Java (javac): /path/File.java:10: error: message
-- Also catches Maven [ERROR] /path/File.java:[l,c] (duplicate with above, but
-- the combined dispatcher tries parse_compilation_error first, so no double-hit).
function M.parse_java_error(line)
  local file, lnum, message = line:match('([^:]+%.java):(%d+):%s*error:%s*(.+)')
  if file and lnum then
    return { filename = file, lnum = tonumber(lnum), col = 1, text = message, type = 'E' }
  end
  local mf, ml, mc, mm = line:match('%[ERROR%]%s+(.-):%[(%d+),(%d+)%]%s+(.+)')
  if mf then
    return { filename = mf, lnum = tonumber(ml), col = tonumber(mc), text = mm, type = 'E' }
  end
end

-- Rust: multi-line (stash the error line, resolve on the --> line)
function M.parse_rust_error(line)
  if line:match('^error%[') then
    M._rust_error_msg = line; return nil
  end
  if M._rust_error_msg then
    local file, lnum, col = line:match('%-%->%s+([^:]+):(%d+):(%d+)')
    if file and lnum then
      local err = {
        filename = file,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = M._rust_error_msg,
        type = 'E'
      }
      M._rust_error_msg = nil
      return err
    end
  end
end

-- Go: ./main.go:10:5: message
function M.parse_go_error(line)
  local file, lnum, col, message = line:match('([^:]+%.go):(%d+):(%d+):%s*(.+)')
  if file and lnum then
    return { filename = file, lnum = tonumber(lnum), col = tonumber(col) or 1, text = message, type = 'E' }
  end
end

-- C/C++: file.cpp:10:5: error/warning: message
function M.parse_cpp_error(line)
  local file, lnum, col, level, message =
      line:match('([^:]+%.[ch]p?p?):(%d+):(%d+):%s*(%w+):%s*(.+)')
  if file and lnum then
    return {
      filename = file,
      lnum     = tonumber(lnum),
      col      = tonumber(col) or 1,
      text     = message,
      type     = level == 'warning' and 'W' or 'E',
    }
  end
end

return M
