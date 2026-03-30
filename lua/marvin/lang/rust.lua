-- lua/marvin/lang/rust.lua
-- Rust language module for the Marvin unified dashboard.

local M = {}

local function plain(it) return it.label end
local function ui() return require('marvin.ui') end
local function deps() return require('marvin.deps.rust') end
local function cr() return require('marvin.creator.rust') end

local function sep(l) return { label = l, is_separator = true } end
local function item(id, i, l, d) return { id = id, _icon = i, label = l, desc = d } end

-- ── Project header ────────────────────────────────────────────────────────────
function M.prompt_header(p)
  local info = p.info or {}
  local kind = info.is_workspace and '[workspace]'
      or (info.is_lib and info.is_bin) and '[bin+lib]'
      or info.is_lib and '[lib]'
      or info.is_bin and '[bin]'
      or '[?]'
  return string.format('%s  v%s  edition %s  %s',
    info.name or p.name,
    info.version or '?',
    info.edition or '2021',
    kind)
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end
  local info    = p.info or {}
  local profile = require('marvin').config.rust.profile

  -- Create
  for _, ci in ipairs(cr().menu_items()) do add(ci) end

  -- Cargo
  add(sep('Cargo'))
  add(item('test', '󰙨', 'Test…', 'Run tests'))
  add(item('lifecycle_menu', '󰑕', 'Build & Run…', 'Build, run, clean, fmt, clippy, doc'))
  add(item('toggle_profile', '󰒓',
    'Switch to ' .. (profile == 'release' and 'dev' or 'release'),
    'Currently: ' .. profile))

  -- Submenus
  add(sep('Tools'))
  add(item('deps_menu', '󰘦', 'Dependencies…', 'Add, remove, audit, update'))
  if info.is_workspace and info.members and #info.members > 0 then
    add(item('ws_menu', '󰙅', 'Workspace…',
      #info.members .. ' members'))
  end
  if info.bins and #info.bins > 0 then
    add(item('bins_menu', '󰐊', 'Binaries…',
      #info.bins .. ' binaries'))
  end

  return items
end

-- ── Submenu: Build & Run (lifecycle) ─────────────────────────────────────────
function M.show_lifecycle_menu(p, back)
  local profile = require('marvin').config.rust.profile
  local pflag   = profile == 'release' and ' --release' or ''
  local plab    = profile == 'release' and '(release)' or '(dev)'
  local items   = {
    { id = 'build', label = '󰑕 Build ' .. plab, desc = 'cargo build' .. pflag },
    { id = 'run', label = '󰐊 Run ' .. plab, desc = 'cargo run' .. pflag },
    { id = 'clean', label = '󰃢 Clean', desc = 'cargo clean' },
    { id = 'fmt', label = '󰉣 Format', desc = 'cargo fmt' },
    { id = 'clippy', label = '󰅾 Clippy', desc = 'cargo clippy' },
    { id = 'doc', label = '󰈙 Doc', desc = 'cargo doc --open' },
    { id = 'bench', label = '󰙨 Benchmark', desc = 'cargo bench' },
  }
  ui().select(items, { prompt = 'Build & Run', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Workspace ────────────────────────────────────────────────────────
function M.show_ws_menu(p, back)
  local items = {
    { id = 'ws_members', label = '󰙅 Switch Member', desc = 'Focus a workspace member' },
    { id = 'ws_build_all', label = '󰑕 Build All', desc = 'cargo build --workspace' },
    { id = 'ws_test_all', label = '󰙨 Test All', desc = 'cargo test --workspace' },
  }
  ui().select(items, { prompt = 'Workspace', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Binaries ────────────────────────────────────────────────────────
function M.show_bins_menu(p, back)
  local info    = p.info or {}
  local profile = require('marvin').config.rust.profile
  local pflag   = profile == 'release' and ' --release' or ''
  local items   = {}
  for _, b in ipairs(info.bins or {}) do
    items[#items + 1] = {
      id    = 'run_bin__' .. b.name,
      label = '󰐊 ' .. b.name,
      desc  = 'cargo run' .. pflag .. ' --bin ' .. b.name,
    }
  end
  ui().select(items, { prompt = 'Run Binary', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Dependencies ────────────────────────────────────────────────────
function M.show_deps_menu(p, back)
  local items = {}
  for _, di in ipairs(deps().menu_items()) do items[#items + 1] = di end
  ui().select(items, { prompt = 'Dependencies', on_back = back, format_item = plain },
    function(ch) if ch then deps().handle(ch.id) end end)
end

-- ── Submenu: Tests ───────────────────────────────────────────────────────────
function M.show_test_menu(p, back)
  ui().select({
    { id = 'test_all', label = '󰙨 All tests', desc = 'cargo test' },
    { id = 'test_filter', label = '󰍉 Filter…', desc = 'cargo test <name>' },
    { id = 'test_doc', label = '󰈙 Doc tests only', desc = 'cargo test --doc' },
    { id = 'test_ignored', label = '󰒭 Run ignored tests', desc = 'cargo test -- --ignored' },
  }, { prompt = 'Run Tests', on_back = back, format_item = plain }, function(ch)
    if not ch then return end
    if ch.id == 'test_all' then
      M._run('cargo test', p, 'Test')
    elseif ch.id == 'test_doc' then
      M._run('cargo test --doc', p, 'Doc Tests')
    elseif ch.id == 'test_ignored' then
      M._run('cargo test -- --ignored', p, 'Ignored Tests')
    elseif ch.id == 'test_filter' then
      ui().input({ prompt = 'Test name filter' }, function(f)
        if f and f ~= '' then M._run('cargo test ' .. f, p, 'Test: ' .. f) end
      end)
    end
  end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle(id, p, back)
  local profile = require('marvin').config.rust.profile
  local pflag   = profile == 'release' and ' --release' or ''

  if cr().handle(id, back) then return end

  -- Top-level submenus
  if id == 'lifecycle_menu' then
    M.show_lifecycle_menu(p, back)
  elseif id == 'test' then
    M.show_test_menu(p, back)
  elseif id == 'ws_menu' then
    M.show_ws_menu(p, back)
  elseif id == 'bins_menu' then
    M.show_bins_menu(p, back)
  elseif id == 'deps_menu' then
    M.show_deps_menu(p, back)

    -- Lifecycle
  elseif id == 'build' then
    M._run('cargo build' .. pflag, p, 'Build')
  elseif id == 'run' then
    M._run('cargo run' .. pflag, p, 'Run')
  elseif id == 'clean' then
    M._run('cargo clean', p, 'Clean')
  elseif id == 'fmt' then
    M._run('cargo fmt', p, 'Format')
  elseif id == 'clippy' then
    M._run('cargo clippy', p, 'Clippy')
  elseif id == 'doc' then
    M._run('cargo doc --open', p, 'Doc')
  elseif id == 'bench' then
    M._run('cargo bench', p, 'Bench')

    -- Profile toggle
  elseif id == 'toggle_profile' then
    local cfg = require('marvin').config
    cfg.rust.profile = cfg.rust.profile == 'release' and 'dev' or 'release'
    vim.notify('[Marvin] Rust profile → ' .. cfg.rust.profile, vim.log.levels.INFO)
    require('marvin.dashboard').show()

    -- Workspace
  elseif id == 'ws_members' then
    deps().show_workspace_members(p)
  elseif id == 'ws_build_all' then
    M._run('cargo build --workspace', p, 'Build All')
  elseif id == 'ws_test_all' then
    M._run('cargo test --workspace', p, 'Test All')

    -- Specific binary
  elseif id:match('^run_bin__') then
    local bin = id:sub(10)
    M._run('cargo run' .. pflag .. ' --bin ' .. bin, p, 'Run ' .. bin)

    -- Deps (delegated)
  elseif id:match('^dep_') or id:match('^ws_') then
    deps().handle(id)
  end
end

function M._run(cmd, p, title)
  require('core.runner').execute({
    cmd = cmd,
    cwd = p.root,
    title = title,
    term_cfg = require('marvin').config.terminal,
    plugin   = 'marvin',
  })
end

return M
