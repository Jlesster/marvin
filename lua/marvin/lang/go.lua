-- lua/marvin/lang/go.lua
-- Go language module for the Marvin unified dashboard.

local M = {}

local function plain(it) return it.label end
local function ui() return require('marvin.ui') end
local function deps() return require('marvin.deps.go') end
local function cr() return require('marvin.creator.go') end

local function sep(l) return { label = l, is_separator = true } end
local function item(id, i, l, d) return { id = id, _icon = i, label = l, desc = d } end

-- ── Project header ────────────────────────────────────────────────────────────
function M.prompt_header(p)
  local info = p.info or {}
  local kind = info.is_workspace and '[go.work workspace]' or '[module]'
  local cmds_label = (info.cmds and #info.cmds > 0)
      and ('  cmds: ' .. table.concat(info.cmds, ', '))
      or ''
  return string.format('%s  go%s  %s%s',
    info.module or p.name,
    info.go_version or '?',
    kind,
    cmds_label)
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end
  local info = p.info or {}

  -- Create
  for _, ci in ipairs(cr().menu_items()) do add(ci) end

  -- Go
  add(sep('Go'))
  add(item('test', '󰙨', 'Test…', 'Run tests'))
  add(item('lifecycle_menu', '󰑕', 'Build & Run…', 'Build, run, vet, fmt, lint, clean, doc'))

  -- Tools
  add(sep('Tools'))
  add(item('deps_menu', '󰘦', 'Dependencies…', 'Tidy, vendor, audit, update'))
  if info.cmds and #info.cmds > 1 then
    add(item('cmds_menu', '󰐊', 'Commands…',
      #info.cmds .. ' entry points'))
  end
  if info.is_workspace then
    add(item('ws_menu', '󰙅', 'Workspace…', 'go.work sync & members'))
  end

  return items
end

-- ── Submenu: Build & Run (lifecycle) ─────────────────────────────────────────
function M.show_lifecycle_menu(p, back)
  local info       = p.info or {}
  local run_target = (info.cmds and #info.cmds == 1)
      and 'go run ./cmd/' .. info.cmds[1]
      or 'go run .'
  local items      = {
    { id = 'build', label = '󰑕 Build', desc = 'go build ./...' },
    { id = 'run', label = '󰐊 Run', desc = run_target },
    { id = 'vet', label = '󰅾 Vet', desc = 'go vet ./...' },
    { id = 'fmt', label = '󰉣 Format', desc = 'gofmt -w .' },
    { id = 'lint', label = '󰅾 Lint', desc = 'golangci-lint run' },
    { id = 'clean', label = '󰃢 Clean', desc = 'go clean ./...' },
    { id = 'doc', label = '󰈙 godoc', desc = 'godoc -http=:6060' },
  }
  ui().select(items, { prompt = 'Build & Run', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Commands ────────────────────────────────────────────────────────
function M.show_cmds_menu(p, back)
  local info  = p.info or {}
  local items = {}
  for _, cmd in ipairs(info.cmds or {}) do
    items[#items + 1] = {
      id    = 'run_cmd__' .. cmd,
      label = '󰐊 ' .. cmd,
      desc  = 'go run ./cmd/' .. cmd,
    }
  end
  ui().select(items, { prompt = 'Run Command', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Workspace ───────────────────────────────────────────────────────
function M.show_ws_menu(p, back)
  local items = {
    { id = 'ws_sync', label = '󰚰 Sync Workspace', desc = 'go work sync' },
    { id = 'ws_members', label = '󰙅 Members', desc = 'go.work uses' },
  }
  ui().select(items, { prompt = 'Workspace', on_back = back, format_item = plain },
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
    { id = 'test_all', label = '󰙨 All packages', desc = 'go test ./...' },
    { id = 'test_filter', label = '󰍉 Filter…', desc = 'go test -run <pattern>' },
    { id = 'test_pkg', label = '󰉿 Current package', desc = 'go test .' },
    { id = 'test_race', label = '󰍉 Race detector', desc = 'go test -race ./...' },
    { id = 'test_cover', label = '󰙨 Coverage', desc = 'go test -cover ./...' },
    { id = 'test_bench', label = '󰙨 Benchmarks', desc = 'go test -bench=. ./...' },
    { id = 'test_short', label = '󰒭 Short (skip slow)', desc = 'go test -short ./...' },
  }, { prompt = 'Run Tests', on_back = back, format_item = plain }, function(ch)
    if not ch then return end
    if ch.id == 'test_all' then
      M._run('go test ./...', p, 'Test All')
    elseif ch.id == 'test_pkg' then
      M._run('go test .', p, 'Test Package')
    elseif ch.id == 'test_race' then
      M._run('go test -race ./...', p, 'Test (race)')
    elseif ch.id == 'test_cover' then
      M._run('go test -cover -coverprofile=coverage.out ./...', p, 'Test + Cover')
    elseif ch.id == 'test_bench' then
      M._run('go test -bench=. ./...', p, 'Benchmarks')
    elseif ch.id == 'test_short' then
      M._run('go test -short ./...', p, 'Test Short')
    elseif ch.id == 'test_filter' then
      ui().input({ prompt = 'Test name pattern' }, function(f)
        if f and f ~= '' then M._run('go test -run ' .. f .. ' ./...', p, 'Test: ' .. f) end
      end)
    end
  end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle(id, p, back)
  local info = p.info or {}

  if cr().handle(id, back) then return end

  -- Top-level submenus
  if id == 'lifecycle_menu' then
    M.show_lifecycle_menu(p, back)
  elseif id == 'test' then
    M.show_test_menu(p, back)
  elseif id == 'cmds_menu' then
    M.show_cmds_menu(p, back)
  elseif id == 'ws_menu' then
    M.show_ws_menu(p, back)
  elseif id == 'deps_menu' then
    M.show_deps_menu(p, back)

    -- Lifecycle
  elseif id == 'build' then
    M._run('go build ./...', p, 'Build')
  elseif id == 'run' then
    local target = (info.cmds and #info.cmds == 1)
        and ('go run ./cmd/' .. info.cmds[1])
        or 'go run .'
    M._run(target, p, 'Run')
  elseif id == 'vet' then
    M._run('go vet ./...', p, 'Vet')
  elseif id == 'fmt' then
    M._run('gofmt -w .', p, 'Format')
  elseif id == 'lint' then
    M._run('golangci-lint run', p, 'Lint')
  elseif id == 'clean' then
    M._run('go clean ./...', p, 'Clean')
  elseif id == 'doc' then
    M._run('godoc -http=:6060', p, 'godoc')

    -- Specific command
  elseif id:match('^run_cmd__') then
    local cmd = id:sub(10)
    M._run('go run ./cmd/' .. cmd, p, 'Run ' .. cmd)

    -- Workspace
  elseif id == 'ws_sync' then
    M._run('go work sync', p, 'Workspace Sync')
  elseif id == 'ws_members' then
    deps().show_workspace_members(p)

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
