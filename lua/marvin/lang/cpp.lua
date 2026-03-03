-- lua/marvin/lang/cpp.lua
-- C/C++ language module for the Marvin unified dashboard.

local M = {}

local function plain(it) return it.label end
local function ui() return require('marvin.ui') end
local function cr() return require('marvin.creator.cpp') end

local function sep(l) return { label = l, is_separator = true } end
local function item(id, i, l, d) return { id = id, _icon = i, label = l, desc = d } end

-- ── Project header ────────────────────────────────────────────────────────────
function M.prompt_header(p)
  local info = p.info or {}
  local kind = p.type == 'cmake' and '[CMake]' or '[Makefile]'
  return string.format('%s  %s', info.name or p.name, kind)
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end

  -- Create
  for _, ci in ipairs(cr().menu_items()) do add(ci) end

  -- Build
  add(sep('Build'))
  local tool = p.type == 'cmake' and 'CMake' or 'Make'
  add(item('build_menu', '󰑕', tool .. '…', 'Configure, build, test, install, clean'))

  return items
end

-- ── Submenu: Build ───────────────────────────────────────────────────────────
function M.show_build_menu(p, back)
  local items = {}
  if p.type == 'cmake' then
    items = {
      { id = 'cmake_cfg', label = '󰒓 Configure', desc = 'cmake -B build -S .' },
      { id = 'cmake_build', label = '󰑕 Build', desc = 'cmake --build build' },
      { id = 'cmake_test', label = '󰙨 Test', desc = 'ctest --test-dir build' },
      { id = 'cmake_install', label = '󰇚 Install', desc = 'cmake --install build' },
      { id = 'cmake_clean', label = '󰃢 Clean', desc = 'cmake --build build --target clean' },
    }
  else
    items = {
      { id = 'make_build', label = '󰑕 Build', desc = 'make' },
      { id = 'make_test', label = '󰙨 Test', desc = 'make test' },
      { id = 'make_install', label = '󰇚 Install', desc = 'make install' },
      { id = 'make_clean', label = '󰃢 Clean', desc = 'make clean' },
    }
  end
  ui().select(items, { prompt = 'Build', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle(id, p, back)
  if cr().handle(id, back) then return end

  if id == 'build_menu' then
    M.show_build_menu(p, back)
    return
  end

  local function run(cmd, title)
    require('core.runner').execute({
      cmd      = cmd,
      cwd      = p.root,
      title    = title,
      term_cfg = require('marvin').config.terminal,
      plugin   = 'marvin',
    })
  end

  if id == 'cmake_cfg' then
    run('cmake -B build -S .', 'CMake Configure')
  elseif id == 'cmake_build' then
    run('cmake --build build', 'CMake Build')
  elseif id == 'cmake_test' then
    run('ctest --test-dir build', 'CTest')
  elseif id == 'cmake_clean' then
    run('cmake --build build --target clean', 'CMake Clean')
  elseif id == 'cmake_install' then
    run('cmake --install build', 'CMake Install')
  elseif id == 'make_build' then
    run('make', 'Make')
  elseif id == 'make_test' then
    run('make test', 'Make Test')
  elseif id == 'make_clean' then
    run('make clean', 'Make Clean')
  elseif id == 'make_install' then
    run('make install', 'Make Install')
  end
end

return M
