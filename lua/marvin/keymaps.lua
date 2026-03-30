-- lua/marvin/keymaps.lua
local M = {}

function M.register(km)
  km = km or {}
  local function map(lhs, rhs, desc)
    if lhs and lhs ~= '' then
      vim.keymap.set('n', lhs, rhs, { silent = true, desc = desc })
    end
  end

  -- Marvin: project dashboard
  map(km.dashboard, function() require('marvin.dashboard').show() end,
    'Marvin: Project dashboard')

  -- Jason: task runner dashboard
  map(km.jason, function() require('marvin.jason_dashboard').show() end,
    'Jason: Task runner dashboard')

  -- Jason: direct actions
  map(km.jason_build,   function() require('marvin.build').build()         end, 'Jason: Build')
  map(km.jason_run,     function() require('marvin.build').run()           end, 'Jason: Run')
  map(km.jason_test,    function() require('marvin.build').test()          end, 'Jason: Test')
  map(km.jason_clean,   function() require('marvin.build').clean()         end, 'Jason: Clean')
  map(km.jason_console, function() require('marvin.console').toggle()      end, 'Jason: Console')
end

return M
