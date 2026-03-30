-- lua/marvin/deps/rust.lua
-- Rust dependency management via Cargo.
-- Actions: list, add, remove, update, outdated (cargo-outdated), audit (cargo-audit).

local M = {}

local function ui()  return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function run(cmd, root, title)
  require('core.runner').execute({
    cmd      = cmd, cwd = root, title = title,
    term_cfg = require('marvin').config.terminal,
    plugin   = 'marvin',
  })
end
local function plain(it) return it.label end

-- ── Known crate catalogue ─────────────────────────────────────────────────────
local CATALOGUE = {
  -- Async
  { name = 'tokio',       features = 'full',    label = 'Tokio',        desc = 'Async runtime' },
  { name = 'async-trait', features = nil,        label = 'async-trait',  desc = 'Async trait methods' },
  { name = 'futures',     features = nil,        label = 'futures',      desc = 'Async combinators' },
  -- Web
  { name = 'axum',        features = nil,        label = 'Axum',         desc = 'Web framework (Tower-based)' },
  { name = 'actix-web',   features = nil,        label = 'Actix-web',    desc = 'High-perf web framework' },
  { name = 'reqwest',     features = 'json',     label = 'Reqwest',      desc = 'HTTP client' },
  { name = 'hyper',       features = 'full',     label = 'Hyper',        desc = 'Low-level HTTP' },
  -- Serialisation
  { name = 'serde',       features = 'derive',   label = 'Serde',        desc = 'Serialisation framework' },
  { name = 'serde_json',  features = nil,        label = 'serde_json',   desc = 'JSON support' },
  { name = 'toml',        features = nil,        label = 'toml',         desc = 'TOML parsing' },
  -- Database
  { name = 'sqlx',        features = 'runtime-tokio,postgres,macros', label = 'SQLx', desc = 'Async SQL (Postgres/MySQL/SQLite)' },
  { name = 'diesel',      features = 'postgres', label = 'Diesel',       desc = 'ORM / query builder' },
  -- Error handling
  { name = 'anyhow',      features = nil,        label = 'anyhow',       desc = 'Flexible error handling' },
  { name = 'thiserror',   features = nil,        label = 'thiserror',    desc = 'Derive Error implementations' },
  -- CLI
  { name = 'clap',        features = 'derive',   label = 'clap',         desc = 'CLI argument parsing' },
  -- Logging
  { name = 'tracing',     features = nil,        label = 'tracing',      desc = 'Structured logging' },
  { name = 'tracing-subscriber', features = 'env-filter', label = 'tracing-subscriber', desc = 'Tracing output' },
  { name = 'log',         features = nil,        label = 'log',          desc = 'Logging facade' },
  { name = 'env_logger',  features = nil,        label = 'env_logger',   desc = 'Simple env-based logger' },
  -- Utilities
  { name = 'rayon',       features = nil,        label = 'rayon',        desc = 'Data parallelism' },
  { name = 'itertools',   features = nil,        label = 'itertools',    desc = 'Iterator extras' },
  { name = 'uuid',        features = 'v4,serde', label = 'uuid',         desc = 'UUID generation' },
  { name = 'chrono',      features = 'serde',    label = 'chrono',       desc = 'Date and time' },
  { name = 'rand',        features = nil,        label = 'rand',         desc = 'Random number generation' },
  -- Testing
  { name = 'mockall',     features = nil,        label = 'mockall',      desc = 'Mocking framework', dev = true },
  { name = 'criterion',   features = nil,        label = 'criterion',    desc = 'Benchmarking', dev = true },
  { name = 'proptest',    features = nil,        label = 'proptest',     desc = 'Property-based testing', dev = true },
  { name = 'tokio-test',  features = nil,        label = 'tokio-test',   desc = 'Tokio test utilities', dev = true },
}

-- ── Public API ────────────────────────────────────────────────────────────────

function M.menu_items()
  local items = {}
  local function add(t) items[#items + 1] = t end
  local function sep(l) add({ label = l, is_separator = true }) end
  local function it(id, icon, label, desc) add({ id=id, label=icon..' '..label, desc=desc }) end

  sep('Dependencies')
  it('dep_list',     '󰘦', 'View Dependencies',    'All crates in Cargo.toml')
  it('dep_add',      '󰐕', 'Add Crate…',           'cargo add from catalogue or manual entry')
  it('dep_add_dev',  '󰐕', 'Add Dev Crate…',       'cargo add --dev')
  it('dep_remove',   '󰍴', 'Remove Crate…',        'cargo remove')
  it('dep_update',   '󰚰', 'Update All',           'cargo update')
  it('dep_outdated', '󰦉', 'Check Outdated',       'cargo outdated (requires cargo-outdated)')

  sep('Security')
  it('dep_audit',    '󰒃', 'Vulnerability Audit',  'cargo audit (requires cargo-audit)')
  it('dep_audit_fix','󰒃', 'Audit + Auto-fix',     'cargo audit --fix')
  it('dep_deny',     '󰒃', 'Check Deny Rules',     'cargo deny check (requires cargo-deny)')

  sep('Workspace')
  local p = det().get()
  if p and p.info and p.info.is_workspace then
    it('ws_members', '󰙅', 'Workspace Members', 'List crates in workspace')
  end
  it('dep_tree', '󰙅', 'Dependency Tree', 'cargo tree')

  return items
end

function M.handle(id)
  local p = det().get()
  if not p then return end
  local root = p.root

  if id == 'dep_list' then
    M.show_dep_list(p)
  elseif id == 'dep_add' then
    M.show_add_menu(p, false)
  elseif id == 'dep_add_dev' then
    M.show_add_menu(p, true)
  elseif id == 'dep_remove' then
    M.show_remove_menu(p)
  elseif id == 'dep_update' then
    run('cargo update', root, 'Cargo Update')
  elseif id == 'dep_outdated' then
    run('cargo outdated', root, 'Outdated Crates')
  elseif id == 'dep_audit' then
    run('cargo audit', root, 'Cargo Audit')
  elseif id == 'dep_audit_fix' then
    run('cargo audit --fix', root, 'Cargo Audit Fix')
  elseif id == 'dep_deny' then
    run('cargo deny check', root, 'Cargo Deny')
  elseif id == 'dep_tree' then
    run('cargo tree', root, 'Dependency Tree')
  elseif id == 'ws_members' then
    M.show_workspace_members(p)
  end
end

function M.show_dep_list(p)
  local deps = (p.info and p.info.deps) or {}
  if #deps == 0 then
    vim.notify('[Marvin] No dependencies in Cargo.toml', vim.log.levels.INFO); return
  end
  local items = {}
  for _, d in ipairs(deps) do
    items[#items + 1] = {
      id    = d.name,
      label = d.name .. ' @ ' .. (d.version or '?'),
      desc  = d.dev and '[dev]' or '[dep]',
    }
  end
  ui().select(items, {
    prompt        = 'Cargo Dependencies (' .. #deps .. ')',
    enable_search = true,
    format_item   = plain,
  }, function(_) end)
end

function M.show_add_menu(p, is_dev)
  local cat_items = {}
  for _, c in ipairs(CATALOGUE) do
    -- For dev menu show all; for normal menu skip dev-only
    if is_dev or not c.dev then
      cat_items[#cat_items + 1] = {
        id = 'cat__' .. c.name,
        label = c.label,
        desc  = c.desc,
        _crate = c,
      }
    end
  end
  cat_items[#cat_items + 1] = {
    id = '__manual__', label = '󰏫 Enter crate name manually…', desc = 'name[@version]'
  }

  ui().select(cat_items, {
    prompt        = is_dev and 'Add Dev Dependency' or 'Add Dependency',
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then return end
    local dev_flag = is_dev and ' --dev' or ''
    if choice.id == '__manual__' then
      ui().input({ prompt = 'Crate name[@version]' }, function(name)
        if name and name ~= '' then
          run('cargo add' .. dev_flag .. ' ' .. name, p.root, 'Add ' .. name)
          vim.defer_fn(function() det().reload() end, 2000)
        end
      end)
    else
      local c = choice._crate
      local feat = c.features and (' --features ' .. c.features) or ''
      run('cargo add' .. dev_flag .. feat .. ' ' .. c.name, p.root, 'Add ' .. c.name)
      vim.defer_fn(function() det().reload() end, 2000)
    end
  end)
end

function M.show_remove_menu(p)
  local deps = (p.info and p.info.deps) or {}
  if #deps == 0 then
    vim.notify('[Marvin] No dependencies to remove', vim.log.levels.INFO); return
  end
  local items = {}
  for _, d in ipairs(deps) do
    items[#items + 1] = { id = d.name, label = d.name, desc = d.version or '?' }
  end
  ui().select(items, {
    prompt        = 'Remove Crate',
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then return end
    run('cargo remove ' .. choice.id, p.root, 'Remove ' .. choice.id)
    vim.defer_fn(function() det().reload() end, 2000)
  end)
end

function M.show_workspace_members(p)
  local members = (p.info and p.info.members) or {}
  if #members == 0 then
    vim.notify('[Marvin] No workspace members found', vim.log.levels.INFO); return
  end
  local items = {}
  for _, m in ipairs(members) do
    items[#items + 1] = { id = m, label = m, desc = p.root .. '/' .. m }
  end
  ui().select(items, {
    prompt      = 'Workspace Members',
    format_item = plain,
  }, function(choice)
    if choice then
      -- Switch active project to this member
      local member_root = p.root .. '/' .. choice.id
      local sub_info    = require('marvin.detector').detect_sub_projects(p.root)
      for _, sp in ipairs(sub_info or {}) do
        if sp.root == member_root then
          require('marvin.detector').set(sp)
          vim.notify('[Marvin] Switched to workspace member: ' .. choice.id, vim.log.levels.INFO)
          return
        end
      end
    end
  end)
end

return M
