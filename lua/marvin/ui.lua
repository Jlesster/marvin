local M = {}

M.backend = nil

function M.init()
  local config = require('marvin').config

  if config.ui_backend == 'auto' then
    M.backend = M.detect_backend()
  else
    M.backend = config.ui_backend
  end
end

function M.detect_backend()
  if pcall(require, 'snacks') then
    return 'snacks'
  elseif pcall(require, 'dressing') then
    return 'dressing'
  else
    return 'builtin'
  end
end

-- Create centered popup
local function create_popup(title, width, height)
  local buf = vim.api.nvim_create_buf(false, true)
  local ui = vim.api.nvim_list_uis()[1]

  local win_width = width > 1 and width or math.floor(width * ui.width)
  local win_height = height > 1 and height or math.floor(height * ui.height)
  local row = math.floor((ui.height - win_height) / 2)
  local col = math.floor((ui.width - win_width) / 2)

  local opts = {
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = 'minimal',
    border = {
      { '╭', 'FloatBorder' },
      { '─', 'FloatBorder' },
      { '╮', 'FloatBorder' },
      { '│', 'FloatBorder' },
      { '╯', 'FloatBorder' },
      { '─', 'FloatBorder' },
      { '╰', 'FloatBorder' },
      { '│', 'FloatBorder' },
    },
    title = title and { { ' ' .. title .. ' ', 'FloatTitle' } } or nil,
    title_pos = 'center',
  }

  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')

  return buf, win
end

-- Integrated popup input
function M.popup_input(opts, callback)
  opts = opts or {}
  local prompt = opts.prompt or 'Input: '
  local default = opts.default or ''

  local width = opts.width or 60
  local buf, win = create_popup(prompt, width, 3)

  -- Make buffer modifiable for input
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'prompt')

  -- Set the prompt
  vim.fn.prompt_setprompt(buf, '> ')

  -- Pre-fill default value
  if default and default ~= '' then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { default })
    vim.api.nvim_win_set_cursor(win, { 1, #default })
  end

  -- Start insert mode
  vim.cmd('startinsert!')

  -- Handle submission
  vim.fn.prompt_setcallback(buf, function(text)
    vim.api.nvim_win_close(win, true)
    callback(text)
  end)

  -- Handle cancel
  local opts_map = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set({ 'n', 'i' }, '<Esc>', function()
    vim.api.nvim_win_close(win, true)
    callback(nil)
  end, opts_map)

  vim.keymap.set({ 'n', 'i' }, '<C-c>', function()
    vim.api.nvim_win_close(win, true)
    callback(nil)
  end, opts_map)
end

-- Enhanced select with search
function M.popup_select(items, opts, callback)
  opts = opts or {}
  local prompt = opts.prompt or 'Select: '
  local format_fn = opts.format_item or function(item)
    if type(item) == 'table' then
      return item.label or item.name or tostring(item)
    end
    return tostring(item)
  end

  local formatted_items = {}
  for i, item in ipairs(items) do
    table.insert(formatted_items, {
      index = i,
      item = item,
      display = format_fn(item),
      desc = type(item) == 'table' and item.desc or nil,
    })
  end

  local filtered_items = vim.deepcopy(formatted_items)
  local search_term = ''

  local function render_menu()
    local lines = {}
    local height = math.min(#filtered_items + 4, 30)

    -- Header with search
    table.insert(lines, '')
    table.insert(lines, '  🔍 ' .. (search_term ~= '' and search_term or '(type to search)'))
    table.insert(lines, '  ' .. string.rep('─', 68))
    table.insert(lines, '')

    -- Menu items
    local selectable = {}
    local item_map = {}

    for i, formatted in ipairs(filtered_items) do
      local line_num = #lines + 1
      table.insert(lines, '    ' .. formatted.display)
      if formatted.desc then
        table.insert(lines, '      ' .. formatted.desc)
      end
      table.insert(lines, '')
      table.insert(selectable, line_num)
      item_map[line_num] = formatted
    end

    if #filtered_items == 0 then
      table.insert(lines, '  No matches found')
      table.insert(lines, '')
    end

    table.insert(lines, '  ' .. string.rep('─', 68))
    table.insert(lines, '  ↑/↓ Navigate  │  Enter Select  │  Esc Cancel  │  Type to search')
    table.insert(lines, '')

    return lines, selectable, item_map, height
  end

  local lines, selectable, item_map, height = render_menu()
  local buf, win = create_popup(prompt, 76, height)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  -- Highlighting
  local ns = vim.api.nvim_create_namespace('marvin_select_menu')
  for i, line in ipairs(lines) do
    if line:match('🔍') then
      vim.api.nvim_buf_add_highlight(buf, ns, '@lsp.type.namespace', i - 1, 0, -1)
    elseif line:match('─') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'LineNr', i - 1, 0, -1)
    elseif line:match('^%s%s%s%s%s%s%S') then
      vim.api.nvim_buf_add_highlight(buf, ns, '@comment', i - 1, 0, -1)
    elseif line:match('Navigate') then
      vim.api.nvim_buf_add_highlight(buf, ns, 'LineNr', i - 1, 0, -1)
    end
  end

  -- Selection state
  local current_idx = 1
  local highlight_ns = vim.api.nvim_create_namespace('marvin_select_highlight')

  local function update_highlight()
    vim.api.nvim_buf_clear_namespace(buf, highlight_ns, 0, -1)
    if #selectable > 0 and current_idx <= #selectable then
      local line_num = selectable[current_idx]
      vim.api.nvim_buf_add_highlight(buf, highlight_ns, 'Visual', line_num - 1, 0, -1)
      vim.api.nvim_win_set_cursor(win, { line_num, 0 })
    end
  end

  local function update_search(char)
    if char == '<BS>' then
      search_term = search_term:sub(1, -2)
    else
      search_term = search_term .. char
    end

    -- Filter items
    filtered_items = {}
    for _, formatted in ipairs(formatted_items) do
      if search_term == '' or formatted.display:lower():find(search_term:lower(), 1, true) then
        table.insert(filtered_items, formatted)
      end
    end

    -- Re-render
    current_idx = 1
    lines, selectable, item_map, height = render_menu()

    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Re-highlight
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for i, line in ipairs(lines) do
      if line:match('🔍') then
        vim.api.nvim_buf_add_highlight(buf, ns, '@lsp.type.namespace', i - 1, 0, -1)
      elseif line:match('─') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'LineNr', i - 1, 0, -1)
      elseif line:match('^%s%s%s%s%s%s%S') then
        vim.api.nvim_buf_add_highlight(buf, ns, '@comment', i - 1, 0, -1)
      elseif line:match('Navigate') then
        vim.api.nvim_buf_add_highlight(buf, ns, 'LineNr', i - 1, 0, -1)
      end
    end

    update_highlight()
  end

  update_highlight()

  local function select()
    if #selectable == 0 then return end
    local line_num = selectable[current_idx]
    local formatted = item_map[line_num]
    if formatted then
      vim.api.nvim_win_close(win, true)
      callback(formatted.item)
    end
  end

  -- Keymaps
  local map_opts = { noremap = true, silent = true, buffer = buf }

  vim.keymap.set('n', 'j', function()
    if current_idx < #selectable then
      current_idx = current_idx + 1
      update_highlight()
    end
  end, map_opts)

  vim.keymap.set('n', 'k', function()
    if current_idx > 1 then
      current_idx = current_idx - 1
      update_highlight()
    end
  end, map_opts)

  vim.keymap.set('n', '<Down>', function()
    if current_idx < #selectable then
      current_idx = current_idx + 1
      update_highlight()
    end
  end, map_opts)

  vim.keymap.set('n', '<Up>', function()
    if current_idx > 1 then
      current_idx = current_idx - 1
      update_highlight()
    end
  end, map_opts)

  vim.keymap.set('n', '<CR>', select, map_opts)

  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
    callback(nil)
  end, map_opts)

  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
    callback(nil)
  end, map_opts)

  vim.keymap.set('n', '<BS>', function()
    update_search('<BS>')
  end, map_opts)

  -- Type to search
  for i = 32, 126 do
    local char = string.char(i)
    vim.keymap.set('n', char, function()
      update_search(char)
    end, map_opts)
  end
end

function M.select(items, opts, callback)
  opts = opts or {}

  -- Use popup select for better UX
  M.popup_select(items, opts, callback)
end

function M.input(opts, callback)
  opts = opts or {}

  -- Use popup input for better UX
  M.popup_input(opts, callback)
end

function M.notify(message, level, opts)
  opts = opts or {}
  level = level or vim.log.levels.INFO

  if M.backend == 'snacks' then
    local snacks = require('snacks')
    snacks.notify(message, {
      level = M.level_to_snacks(level),
      title = opts.title or 'Marvin',
    })
  else
    vim.notify(message, level, {
      title = opts.title or 'Marvin',
    })
  end
end

function M.level_to_snacks(level)
  if level == vim.log.levels.ERROR then return 'error' end
  if level == vim.log.levels.WARN then return 'warn' end
  if level == vim.log.levels.INFO then return 'info' end
  return 'debug'
end

function M.show_goal_menu()
  local project = require('marvin.project')

  if not project.validate_environment() then
    return
  end

  local goals = M.get_common_goals()

  M.select(goals, {
    prompt = 'Maven Goal:',
    format_item = function(goal)
      return string.format('%s %s', goal.icon, goal.label)
    end,
  }, function(choice)
    if not choice then return end
    if choice.needs_profile then
      M.show_profile_menu(choice.goal)
    elseif choice.needs_options then
      M.show_options_menu(choice.goal)
    else
      local executor = require('marvin.executor')
      executor.run(choice.goal)
    end
  end)
end

function M.get_common_goals()
  return {
    { goal = 'clean', label = 'Clean', icon = '🧹' },
    { goal = 'compile', label = 'Compile', icon = '🔨' },
    { goal = 'test', label = 'Test', icon = '🧪' },
    { goal = 'test -DskipTests', label = 'Test (skip)', icon = '⏭️' },
    { goal = 'package', label = 'Package', icon = '📦' },
    { goal = 'install', label = 'Install', icon = '💾' },
    { goal = 'verify', label = 'Verify', icon = '✅' },
    { goal = 'clean install', label = 'Clean + Install', icon = '🔄' },
    { goal = 'dependency:tree', label = 'Dependency Tree', icon = '🌳' },
    { goal = 'dependency:resolve', label = 'Resolve Dependencies', icon = '📥' },
    { goal = 'help:effective-pom', label = 'Effective POM', icon = '📄' },
    { goal = nil, label = 'Custom Goal...', icon = '⚙️', needs_options = true },
  }
end

function M.show_profile_menu(goal)
  local project = require('marvin.project').get_project()

  if not project or not project.info or #project.info.profiles == 0 then
    vim.notify('No profiles found in pom.xml', vim.log.levels.WARN)
    local executor = require('marvin.executor')
    executor.run(goal)
    return
  end

  local profiles = {}
  table.insert(profiles, { id = nil, label = '(default)' })

  for _, profile_id in ipairs(project.info.profiles) do
    table.insert(profiles, { id = profile_id, label = profile_id })
  end

  M.select(profiles, {
    prompt = '📋 Select Profile:',
  }, function(choice)
    if not choice then return end

    local executor = require('marvin.executor')
    executor.run(goal, { profile = choice.id })
  end)
end

function M.show_options_menu(goal)
  local ui = require('marvin.ui')

  ui.input({
    prompt = 'Maven goal(s): ',
    default = '',
  }, function(custom_goal)
    if not custom_goal or custom_goal == '' then
      return
    end

    -- Ask for additional options
    ui.input({
      prompt = 'Additional options (optional): ',
      default = '',
    }, function(extra_opts)
      local executor = require('marvin.executor')

      local full_goal = custom_goal
      if extra_opts and extra_opts ~= '' then
        full_goal = full_goal .. ' ' .. extra_opts
      end

      executor.run(full_goal)
    end)
  end)
end

function M.show_advanced_menu()
  local options = {
    { goal = 'clean install -DskipTests=true',       label = 'Clean Install (skip tests)' },
    { goal = 'clean install -U',                     label = 'Clean Install (force update)' },
    { goal = 'clean package -Dmaven.test.skip=true', label = 'Package (skip tests)' },
    { goal = 'dependency:tree -Dverbose',            label = 'Verbose Dependency Tree' },
    { goal = 'dependency:analyze',                   label = 'Analyze Dependencies' },
    { goal = 'versions:display-dependency-updates',  label = 'Check for Updates' },
    { goal = 'help:effective-settings',              label = 'Show Effective Settings' },
  }

  M.select(options, {
    prompt = 'Advanced Options:',
  }, function(choice)
    if not choice then return end

    local executor = require('marvin.executor')
    executor.run(choice.goal)
  end)
end

return M
