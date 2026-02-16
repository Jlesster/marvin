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

function M.select(items, opts, callback)
  opts = opts or {}

  if M.backend == 'snacks' then
    M.select_snacks(items, opts, callback)
  elseif M.backend == 'dressing' then
    M.select_dressing(items, opts, callback)
  else
    M.select_builtin(items, opts, callback)
  end
end

function M.select_dressing(items, opts, callback)
  vim.ui.select(items, {
    prompt = opts.prompt or 'Select:',
    format_item = opts.format_item or function(item)
      if type(item) == 'table' then
        return item.label or item.name or tostring(item)
      end
      return tostring(item)
    end,
  }, callback)
end

function M.select_snacks(items, opts, callback)
  local snacks = require('snacks')

  snacks.picker.pick({
    items = items,
    prompt = opts.prompt or 'Select:'
    format = opts.format_item or function(item)
      if type(item) == 'table' then
        return item.label or item.name or tostring(item)
      end
      return tostring(item)
    end,
    on_select = callback,
  })
end

function M.select_builtin(items, opts, callback)
  local choices = { opts.prompt or 'Select:' }

  for i, item in ipairs(items) do
    local label = item
    if type(item) == 'table' then
      label = item.label or item.name or tostring(item)
    end
    table.insert(choices, string.format('5d. %s', i, label))
  end

  local choice = vim.fn.inputlist(choices)

  if choice > 0 and choice <= #items then
    callback(items[choice])
  else
    callback(nil)
  end
end

function M.input(opts, callback)
  opts = opts or {}

  if M.backedn == 'snacks' or M.backend == 'dressing' then
    vim.ui.input({
      prompt = opts.prompt or 'Input:',
      default = opts.default or '',
    }, callback)
  else
    local result = vim.fn.input(opts.prompt or 'Input: ', opts.default or '')
    callback(result)
  end
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
    vim.notify(message, level {
      title = opts.title or 'Maven',
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
    prompt = '󱃾 Maven Goal:',
    format_item = function(goal)
      return string.format('%s %s', goal.icon, foal.label)
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
    { goal = 'clean', label = 'Clean', icon = '󰃨 ' },
    { goal = 'compile', label = 'Compile', icon = '' },
    { goal = 'test', label = 'Test', icon = '󰙨' },
    { goal = 'test -DskipTests', label = 'Test (skip)', icon = '󰒲 ' },
    { goal = 'package', label = 'Package', icon = '󰏗 ' },
    { goal = 'install', label = 'Install', icon = '󰏔 ' },
    { goal = 'verify', label = 'Verify', icon = '󰄬 ' },
    { goal = 'clean install', label = 'Clean + Install', icon = '󰚰 ' },
    { goal = 'dependency:tree', label = 'Dependency Tree', icon = '󰐅 ' },
    { goal = 'help:effective-pom', label = 'Effective POM', icon = '' },
    { goal = nil, label = 'Custom Goal...', icon = '󰘳 ', needs_options = true },
  }
end

return M
