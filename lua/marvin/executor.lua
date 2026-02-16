local M = {}

M.current_job = nil

-- Run a Maven goal
function M.run(goal, options)
  options = options or {}

  local project = require('marvin.project')

  if not project.validate_environment() then
    return
  end

  local proj = project.get_project()
  if not proj then
    vim.notify('No Maven project found', vim.log.levels.ERROR)
    return
  end

  local config = require('marvin').config
  local ui = require('marvin.ui')

  -- Build Maven command
  local cmd_parts = { config.maven_command }

  -- Add profile if specified
  if options.profile then
    table.insert(cmd_parts, '-P' .. options.profile)
  end

  -- Add the goal
  table.insert(cmd_parts, goal)

  local cmd = table.concat(cmd_parts, ' ')

  ui.notify('Running: ' .. cmd, vim.log.levels.INFO)

  -- Execute based on terminal configuration
  if config.terminal.position == 'background' then
    M.run_background(cmd, proj.root)
  else
    M.run_terminal(cmd, proj.root)
  end
end

-- Run in background and capture output
function M.run_background(cmd, cwd)
  local ui = require('marvin.ui')
  local output = {}

  M.current_job = vim.fn.jobstart(cmd, {
    cwd = cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      vim.list_extend(output, data)
    end,
    on_stderr = function(_, data, _)
      vim.list_extend(output, data)
    end,
    on_exit = function(_, exit_code, _)
      M.current_job = nil

      if exit_code == 0 then
        ui.notify('✅ Build successful!', vim.log.levels.INFO)
      else
        ui.notify('❌ Build failed!', vim.log.levels.ERROR)

        -- Parse errors and populate quickfix
        local parser = require('marvin.parser')
        parser.parse_output(output)
      end
    end,
  })
end

-- Run in terminal window
function M.run_terminal(cmd, cwd)
  local config = require('marvin').config
  local term_config = config.terminal

  -- Determine window configuration
  local win_config = M.get_window_config(term_config.position, term_config.size)

  -- Create terminal buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  -- Handle split/vsplit (they create their own window)
  local win
  if term_config.position == 'split' then
    vim.cmd('split')
    win = vim.api.nvim_get_current_win()
    local height = math.floor(vim.api.nvim_win_get_height(win) * term_config.size)
    vim.api.nvim_win_set_height(win, height)
    vim.api.nvim_win_set_buf(win, buf)
  elseif term_config.position == 'vsplit' then
    vim.cmd('vsplit')
    win = vim.api.nvim_get_current_win()
    local width = math.floor(vim.api.nvim_win_get_width(win) * term_config.size)
    vim.api.nvim_win_set_width(win, width)
    vim.api.nvim_win_set_buf(win, buf)
  else
    -- Float window
    win = vim.api.nvim_open_win(buf, true, win_config)
  end

  -- Set window options
  vim.api.nvim_win_set_option(win, 'number', false)
  vim.api.nvim_win_set_option(win, 'relativenumber', false)
  vim.api.nvim_win_set_option(win, 'signcolumn', 'no')

  -- Start terminal
  local output = {}
  M.current_job = vim.fn.termopen(cmd, {
    cwd = cwd,
    on_stdout = function(_, data, _)
      vim.list_extend(output, data)
    end,
    on_stderr = function(_, data, _)
      vim.list_extend(output, data)
    end,
    on_exit = function(_, exit_code, _)
      M.current_job = nil

      if exit_code == 0 then
        if term_config.close_on_success then
          vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
          end, 1000)
        end

        local ui = require('marvin.ui')
        ui.notify('✅ Build successful!', vim.log.levels.INFO)
      else
        local ui = require('marvin.ui')
        ui.notify('❌ Build failed!', vim.log.levels.ERROR)

        -- Parse errors
        local parser = require('marvin.parser')
        parser.parse_output(output)
      end
    end,
  })

  -- Enter insert mode in terminal
  vim.cmd('startinsert')

  -- Set up keymaps to close terminal
  local opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, opts)

  vim.keymap.set('t', '<Esc><Esc>', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, opts)
end

-- Get window configuration based on position
function M.get_window_config(position, size)
  if position == 'float' then
    local ui = vim.api.nvim_list_uis()[1]
    local width = math.floor(ui.width * 0.8)
    local height = math.floor(ui.height * size)
    local row = math.floor((ui.height - height) / 2)
    local col = math.floor((ui.width - width) / 2)

    return {
      relative = 'editor',
      width = width,
      height = height,
      row = row,
      col = col,
      style = 'minimal',
      border = 'rounded',
      title = ' Maven ',
      title_pos = 'center',
    }
  end

  return {}
end

-- Stop current Maven build
function M.stop()
  if M.current_job then
    vim.fn.jobstop(M.current_job)
    M.current_job = nil

    local ui = require('marvin.ui')
    ui.notify('Maven build stopped', vim.log.levels.WARN)
  else
    vim.notify('No Maven build running', vim.log.levels.WARN)
  end
end

return M
