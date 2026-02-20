-- lua/jason/compiler.lua
-- Sets vim's makeprg + errorformat per project type on BufEnter.
-- Makes :make work correctly for every supported language/build tool.
-- Replaces compiler.nvim entirely.

local M = {}

local EF = {
  java_javac = '%f:%l: error: %m,%-G%.%#',
  java_maven = table.concat({
    '%E[ERROR] %f:[%l\\,%c] %m',
    '%E[ERROR] %f:%l: %m',
    '%W[WARNING] %f:[%l\\,%c] %m',
    '%-G%.%#',
  }, ','),
  rust       = table.concat({
    '%Eerror%s%m',
    '%Cerror[E%n]: %m',
    '%Z%\\s%#-->%\\s%f:%l:%c',
    '%Wwarning: %m',
    '%Z%\\s%#-->%\\s%f:%l:%c',
    '%-G%.%#',
  }, ','),
  go         = table.concat({
    '%f:%l:%c: %m',
    '%f:%l: %m',
    '%-G%.%#',
  }, ','),
  cpp        = table.concat({
    '%f:%l:%c: %trror: %m',
    '%f:%l:%c: %tarning: %m',
    '%f:%l:%c: %tote: %m',
    '%-G%.%#',
  }, ','),
  make       = '%f:%l:%c: %m,%-G%.%#',
  cmake      = '%f:%l:%c: %m,%-G%.%#',
}

local function cargo_cmd()
  local p = require('jason').config.rust.profile
  return p == 'release' and 'cargo build --release 2>&1' or 'cargo build 2>&1'
end

local CONFIGS = {
  maven       = function() return { makeprg = 'mvn compile', errorformat = EF.java_maven } end,
  gradle      = function() return { makeprg = './gradlew build', errorformat = EF.java_maven } end,
  cargo       = function() return { makeprg = cargo_cmd(), errorformat = EF.rust } end,
  go_mod      = function() return { makeprg = 'go build ./... 2>&1', errorformat = EF.go } end,
  cmake       = function() return { makeprg = 'cmake --build build 2>&1', errorformat = EF.cmake } end,
  makefile    = function() return { makeprg = 'make 2>&1', errorformat = EF.make } end,
  single_file = function(p)
    local ft   = p.language
    local file = p.file or vim.fn.expand('%:p')
    local base = vim.fn.fnamemodify(file, ':t:r')
    if ft == 'java' then
      return { makeprg = 'javac ' .. vim.fn.shellescape(file), errorformat = EF.java_javac }
    elseif ft == 'rust' then
      return { makeprg = 'rustc ' .. vim.fn.shellescape(file) .. ' 2>&1', errorformat = EF.rust }
    elseif ft == 'go' then
      return { makeprg = 'go build ' .. vim.fn.shellescape(file) .. ' 2>&1', errorformat = EF.go }
    elseif ft == 'cpp' then
      local cfg = require('jason').config
      return {
        makeprg = string.format('%s -std=%s %s -o %s 2>&1',
          cfg.cpp.compiler, cfg.cpp.standard,
          vim.fn.shellescape(file), vim.fn.shellescape(base)),
        errorformat = EF.cpp,
      }
    elseif ft == 'c' then
      return {
        makeprg = string.format('gcc %s -o %s 2>&1',
          vim.fn.shellescape(file), vim.fn.shellescape(base)),
        errorformat = EF.cpp
      }
    end
  end,
}

function M.apply(project)
  if not project then return end
  local fn = CONFIGS[project.type]
  if not fn then return end
  local cfg = fn(project)
  if not cfg then return end
  vim.bo.makeprg     = cfg.makeprg
  vim.bo.errorformat = cfg.errorformat
end

-- Called from autocommand in init.lua
function M.setup_buf()
  local ok, det = pcall(require, 'jason.detector')
  if not ok then return end
  M.apply(det.get_project())
end

return M
