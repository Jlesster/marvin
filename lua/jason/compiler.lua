-- lua/jason/compiler.lua
-- Sets vim's makeprg + errorformat based on detected project type.
-- Replaces compiler.nvim for Jason-managed projects.
-- Called automatically on BufEnter for supported filetypes (see init.lua).

local M = {}

-- errorformat fragments
local EF = {
  java_javac = '%f:%l: error: %m,%-G%.%#',
  java_maven = '%E[ERROR] %f:[%l\\,%c] %m,%-G%.%#',
  rust       = '%Eerror%s%m,' ..
      '%Cerror[%t%.%#]: %m,' ..
      '%Z%\\s%#-->%\\s%f:%l:%c,' ..
      '%Cwarning%s%m,' ..
      '%-G%.%#',
  go         = '%f:%l:%c: %m,%-G%.%#',
  cpp_gcc    = '%f:%l:%c: %trror: %m,' ..
      '%f:%l:%c: %tarning: %m,' ..
      '%-G%.%#',
  cmake      = '%f:%l:%c: %m,%-G%.%#',
  make       = '%f:%l:%c: %m,%-G%.%#',
}

local CONFIGS = {
  maven = {
    makeprg     = 'mvn compile',
    errorformat = EF.java_maven,
  },
  gradle = {
    makeprg     = './gradlew build',
    errorformat = EF.java_maven,
  },
  cargo = {
    makeprg     = 'cargo build 2>&1',
    errorformat = EF.rust,
  },
  go_mod = {
    makeprg     = 'go build ./... 2>&1',
    errorformat = EF.go,
  },
  cmake = {
    makeprg     = 'cmake --build build 2>&1',
    errorformat = EF.cmake,
  },
  makefile = {
    makeprg     = 'make 2>&1',
    errorformat = EF.make,
  },
  single_file = function(project)
    local ft   = project.language
    local file = project.file or vim.fn.expand('%:p')
    local base = vim.fn.fnamemodify(file, ':t:r')
    if ft == 'java' then
      return { makeprg = 'javac ' .. vim.fn.shellescape(file), errorformat = EF.java_javac }
    elseif ft == 'rust' then
      return { makeprg = 'rustc ' .. vim.fn.shellescape(file), errorformat = EF.rust }
    elseif ft == 'go' then
      return { makeprg = 'go build ' .. vim.fn.shellescape(file), errorformat = EF.go }
    elseif ft == 'cpp' then
      local cfg = require('jason').config
      return {
        makeprg     = string.format('%s -std=%s %s -o %s 2>&1',
          cfg.cpp.compiler, cfg.cpp.standard,
          vim.fn.shellescape(file), vim.fn.shellescape(base)),
        errorformat = EF.cpp_gcc,
      }
    elseif ft == 'c' then
      return {
        makeprg     = string.format('gcc %s -o %s 2>&1',
          vim.fn.shellescape(file), vim.fn.shellescape(base)),
        errorformat = EF.cpp_gcc,
      }
    end
  end,
}

-- Apply makeprg / errorformat to the current buffer (local to buffer).
function M.apply(project)
  if not project then return end

  local cfg_entry = CONFIGS[project.type]
  if not cfg_entry then return end

  local cfg = type(cfg_entry) == 'function' and cfg_entry(project) or cfg_entry
  if not cfg then return end

  -- cargo profile awareness
  if project.type == 'cargo' then
    local profile = require('jason').config.rust.profile
    if profile == 'release' then
      cfg.makeprg = 'cargo build --release 2>&1'
    end
  end

  vim.bo.makeprg     = cfg.makeprg
  vim.bo.errorformat = cfg.errorformat
end

-- Hook: call from autocommand on BufEnter/FileType
function M.setup_buf()
  local ok, detector = pcall(require, 'jason.detector')
  if not ok then return end
  local project = detector.get_project()
  M.apply(project)
end

return M
