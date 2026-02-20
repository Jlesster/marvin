-- lua/jason/detector.lua
local M = {}

M.current_project = nil

-- Project type detectors
local detectors = {
  -- Java projects
  maven = function(dir)
    return vim.fn.filereadable(dir .. '/pom.xml') == 1
  end,

  gradle = function(dir)
    return vim.fn.filereadable(dir .. '/build.gradle') == 1
        or vim.fn.filereadable(dir .. '/build.gradle.kts') == 1
  end,

  -- Rust projects
  cargo = function(dir)
    return vim.fn.filereadable(dir .. '/Cargo.toml') == 1
  end,

  -- Go projects
  go_mod = function(dir)
    return vim.fn.filereadable(dir .. '/go.mod') == 1
  end,

  -- C/C++ projects
  cmake = function(dir)
    return vim.fn.filereadable(dir .. '/CMakeLists.txt') == 1
  end,

  makefile = function(dir)
    return vim.fn.filereadable(dir .. '/Makefile') == 1
        or vim.fn.filereadable(dir .. '/makefile') == 1
  end,
}

-- Detect project type and root
function M.detect()
  local curr_file = vim.api.nvim_buf_get_name(0)
  local curr_dir = vim.fn.fnamemodify(curr_file, ':h')

  -- Search upwards for project markers
  while curr_dir ~= '/' do
    for project_type, detector_fn in pairs(detectors) do
      if detector_fn(curr_dir) then
        M.current_project = {
          root = curr_dir,
          type = project_type,
          language = M.get_language(project_type),
        }
        return true
      end
    end

    curr_dir = vim.fn.fnamemodify(curr_dir, ':h')
  end

  -- Fallback: single file detection
  local ft = vim.bo.filetype
  if ft == 'java' or ft == 'rust' or ft == 'go' or ft == 'c' or ft == 'cpp' then
    M.current_project = {
      root = vim.fn.expand('%:p:h'),
      type = 'single_file',
      language = ft,
      file = vim.fn.expand('%:p'),
    }
    return true
  end

  M.current_project = nil
  return false
end

function M.get_language(project_type)
  local type_to_lang = {
    maven = 'java',
    gradle = 'java',
    cargo = 'rust',
    go_mod = 'go',
    cmake = 'cpp',
    makefile = 'cpp',
    single_file = vim.bo.filetype,
  }

  return type_to_lang[project_type] or 'unknown'
end

function M.get_project()
  if not M.current_project then
    M.detect()
  end
  return M.current_project
end

function M.validate_environment(project_type)
  local validators = {
    maven = function()
      return M.check_command('mvn', 'Maven')
    end,

    gradle = function()
      return M.check_command('gradle', 'Gradle')
          or M.check_command('./gradlew', 'Gradle Wrapper')
    end,

    cargo = function()
      return M.check_command('cargo', 'Cargo')
    end,

    go_mod = function()
      return M.check_command('go', 'Go')
    end,

    cmake = function()
      return M.check_command('cmake', 'CMake')
    end,

    makefile = function()
      return M.check_command('make', 'Make')
    end,

    single_file = function()
      local ft = vim.bo.filetype
      if ft == 'java' then
        return M.check_command('javac', 'Java Compiler')
      elseif ft == 'rust' then
        return M.check_command('rustc', 'Rust Compiler')
      elseif ft == 'go' then
        return M.check_command('go', 'Go')
      elseif ft == 'cpp' or ft == 'c' then
        return M.check_command('g++', 'G++') or M.check_command('gcc', 'GCC')
      end
      return false
    end,
  }

  local validator = validators[project_type]
  if not validator then
    vim.notify('Unknown project type: ' .. project_type, vim.log.levels.ERROR)
    return false
  end

  return validator()
end

function M.check_command(cmd, name)
  local handle = io.popen(cmd .. ' --version 2>&1')
  if not handle then
    vim.notify(name .. ' is not installed or not in PATH', vim.log.levels.ERROR)
    return false
  end

  local result = handle:read('*all')
  handle:close()

  if result == '' then
    vim.notify(name .. ' is not installed or not in PATH', vim.log.levels.ERROR)
    return false
  end

  return true
end

return M
