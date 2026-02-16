local M = {}

M.current_job = nil

function M.run(goal, opts)
  opts = opts or {}
  local project = require('marvin.project').get_project()
  if not project then
    vim.notify('No Maven project detected', vim.log.levels.ERROR) -- FIXED: Was 'viim'
    return
  end

  local cmd = M.build_command(goal, opts)

  local ui = require('marvin.ui')
  ui.notify('Running: ' .. goal, vim.log.levels.INFO)

  if M.should_use_terminal() then
    M.run_in_terminal(cmd, project.root)
  else
    M.run_in_background(cmd, project.root)
  end
end

function M.build_command(goal, opts)
  local config = require('marvin').config
  local parts = { config.maven_command, goal }

  if opts.profile then -- FIXED: Was 'profine'
    table.insert(parts, '-P' .. opts.profile)
  end

  if opts.extra then
    table.insert(parts, opts.extra)
  end

  return table.concat(parts, ' ')
end

function M.should_use_terminal()
  local config = require('marvin').config
  -- FIXED: Better logic
  return config.terminal.position ~= 'background'
end

function M.run_in_terminal(cmd, cwd)
  local ui = require('marvin.ui')

  if ui.backend == 'snacks' then
    M.run_in_snacks_terminal(cmd, cwd)
  else
    M.run_in_basic_terminal(cmd, cwd)
  end
end

function M.run_in_snacks_terminal(cmd, cwd)
  local snacks = require('snacks')
  local config = require('marvin').config

  snacks.terminal.open(cmd, {
    cwd = cwd,
    win = {
      position = config.terminal.position,
      height = config.terminal.size,
    },
    on_exit = function(job, exit_code)
      M.on_command_complete(exit_code)
    end,
  })
end

function M.run_in_basic_terminal(cmd, cwd)
  local buf = vim.api.nvim_create_buf(false, true)

  local config = require('marvin').config
  local height = math.floor(vim.o.lines * config.terminal.size)

  vim.cmd('botright ' .. height .. 'split')
  vim.api.nvim_win_set_buf(0, buf)

  vim.fn.termopen(cmd, {
    cwd = cwd,
    on_exit = function(_, exit_code)
      M.on_command_complete(exit_code)
    end,
  })

  vim.cmd('startinsert')
end

function M.run_in_background(cmd, cwd)
  local output = {}
  local parser = require('marvin.parser') -- FIXED: Was 'pasrser'

  M.current_job = vim.fn.jobstart(cmd, {
    cwd = cwd,
    stdout_buffered = false,
    stderr_buffered = false,

    on_stdout = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= '' then
          table.insert(output, line)
          print(line)
        end
      end
    end,

    on_exit = function(_, exit_code, _)
      M.current_job = nil

      parser.parse_output(output)

      M.on_command_complete(exit_code)
    end,
  })

  if M.current_job <= 0 then
    vim.notify('Failed to start Maven', vim.log.levels.ERROR)
    M.current_job = nil
  end
end

function M.stop()
  if M.current_job then
    vim.fn.jobstop(M.current_job)
    M.current_job = nil
    vim.notify('Maven build cancelled', vim.log.levels.WARN)
  else
    vim.notify('No maven build running', vim.log.levels.INFO)
  end
end

function M.on_command_complete(exit_code)
  local ui = require('marvin.ui')

  -- FIXED: Was '00' and wrong log level
  if exit_code == 0 then
    ui.notify('Build Successful!', vim.log.levels.INFO)
  else
    ui.notify('Build failed', vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_user_command('MavenStop', function()
  require('marvin.executor').stop()
end, { desc = 'Stop running Maven Build' })

return M
