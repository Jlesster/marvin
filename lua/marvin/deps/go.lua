-- lua/marvin/deps/go.lua
-- Go dependency management via the go toolchain.
-- Actions: list, add, remove, update, tidy, outdated (go list -u), audit (govulncheck).

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

-- ── Known package catalogue ───────────────────────────────────────────────────
local CATALOGUE = {
  -- Web / HTTP
  { path = 'github.com/gin-gonic/gin',              label = 'Gin',            desc = 'Fast HTTP web framework' },
  { path = 'github.com/gofiber/fiber/v2',           label = 'Fiber',          desc = 'Express-inspired framework' },
  { path = 'github.com/labstack/echo/v4',           label = 'Echo',           desc = 'Minimalist web framework' },
  { path = 'net/http',                              label = 'net/http',       desc = 'Standard library HTTP (no import needed)' },
  -- Router
  { path = 'github.com/gorilla/mux',                label = 'Gorilla Mux',    desc = 'Powerful URL router' },
  { path = 'github.com/go-chi/chi/v5',              label = 'Chi',            desc = 'Lightweight composable router' },
  -- Database
  { path = 'gorm.io/gorm',                          label = 'GORM',           desc = 'ORM for Go' },
  { path = 'gorm.io/driver/postgres',               label = 'GORM Postgres',  desc = 'GORM PostgreSQL driver' },
  { path = 'gorm.io/driver/sqlite',                 label = 'GORM SQLite',    desc = 'GORM SQLite driver' },
  { path = 'github.com/jmoiron/sqlx',               label = 'sqlx',           desc = 'Extensions to database/sql' },
  { path = 'github.com/lib/pq',                     label = 'lib/pq',         desc = 'PostgreSQL driver' },
  { path = 'github.com/mattn/go-sqlite3',           label = 'go-sqlite3',     desc = 'SQLite3 driver (CGO)' },
  -- Config
  { path = 'github.com/spf13/viper',                label = 'Viper',          desc = 'Configuration management' },
  { path = 'github.com/joho/godotenv',              label = 'godotenv',       desc = '.env file loading' },
  -- CLI
  { path = 'github.com/spf13/cobra',                label = 'Cobra',          desc = 'CLI framework' },
  { path = 'github.com/urfave/cli/v2',              label = 'urfave/cli',     desc = 'Simple CLI framework' },
  -- Logging
  { path = 'go.uber.org/zap',                       label = 'Zap',            desc = 'Blazing fast structured logger' },
  { path = 'github.com/rs/zerolog',                 label = 'Zerolog',        desc = 'Zero-allocation JSON logger' },
  { path = 'github.com/sirupsen/logrus',            label = 'Logrus',         desc = 'Structured logger' },
  -- Serialisation
  { path = 'encoding/json',                         label = 'encoding/json',  desc = 'Standard library JSON (no import needed)' },
  { path = 'github.com/bytedance/sonic',            label = 'Sonic',          desc = 'High-perf JSON encoder/decoder' },
  -- Testing
  { path = 'github.com/stretchr/testify',           label = 'Testify',        desc = 'Assertion + mocking library' },
  { path = 'github.com/golang/mock/gomock',         label = 'GoMock',         desc = 'Mocking framework' },
  { path = 'github.com/vektra/mockery/v2',          label = 'Mockery',        desc = 'Mock code generator' },
  -- Observability
  { path = 'go.opentelemetry.io/otel',              label = 'OpenTelemetry',  desc = 'Distributed tracing' },
  { path = 'github.com/prometheus/client_golang',   label = 'Prometheus',     desc = 'Metrics exposition' },
  -- Utility
  { path = 'github.com/google/uuid',                label = 'uuid',           desc = 'UUID generation' },
  { path = 'github.com/samber/lo',                  label = 'lo',             desc = 'Lodash-style generic helpers' },
  { path = 'golang.org/x/sync',                     label = 'x/sync',         desc = 'errgroup, semaphore, singleflight' },
}

-- ── Public API ────────────────────────────────────────────────────────────────

function M.menu_items()
  local items = {}
  local function add(t) items[#items + 1] = t end
  local function sep(l) add({ label = l, is_separator = true }) end
  local function it(id, icon, label, desc) add({ id=id, label=icon..' '..label, desc=desc }) end
  local p = det().get()

  sep('Dependencies')
  it('dep_list',     '󰘦', 'View Dependencies',    'All modules in go.mod')
  it('dep_add',      '󰐕', 'Add Package…',         'go get from catalogue or manual entry')
  it('dep_remove',   '󰍴', 'Remove Package…',      'go get pkg@none + go mod tidy')
  it('dep_update',   '󰚰', 'Update All',           'go get -u ./...')
  it('dep_tidy',     '󰃢', 'Tidy',                 'go mod tidy — remove unused')
  it('dep_outdated', '󰦉', 'Check Outdated',       'go list -u -m all')
  it('dep_download', '󰇚', 'Download All',         'go mod download')

  sep('Security')
  it('dep_audit',    '󰒃', 'Vulnerability Audit',  'govulncheck ./... (requires govulncheck)')

  sep('Modules')
  it('dep_why',      '󰍉', 'Why is this needed?',  'go mod why <module>')
  it('dep_verify',   '󰄬', 'Verify',               'go mod verify')
  it('dep_graph',    '󰙅', 'Dependency Graph',     'go mod graph')
  if p and p.info and p.info.is_workspace then
    it('ws_members', '󰙅', 'Workspace Members',    'go.work uses')
    it('ws_sync',    '󰚰', 'Workspace Sync',       'go work sync')
  end

  return items
end

function M.handle(id)
  local p = det().get()
  if not p then return end
  local root = p.root

  if id == 'dep_list' then
    M.show_dep_list(p)
  elseif id == 'dep_add' then
    M.show_add_menu(p)
  elseif id == 'dep_remove' then
    M.show_remove_menu(p)
  elseif id == 'dep_update' then
    run('go get -u ./...', root, 'Update All')
  elseif id == 'dep_tidy' then
    run('go mod tidy', root, 'Go Mod Tidy')
  elseif id == 'dep_outdated' then
    run('go list -u -m all', root, 'Outdated Modules')
  elseif id == 'dep_download' then
    run('go mod download', root, 'Download Modules')
  elseif id == 'dep_audit' then
    run('govulncheck ./...', root, 'Vulnerability Audit')
  elseif id == 'dep_why' then
    ui().input({ prompt = 'Module path to explain' }, function(mod)
      if mod and mod ~= '' then run('go mod why ' .. mod, root, 'Why ' .. mod) end
    end)
  elseif id == 'dep_verify' then
    run('go mod verify', root, 'Verify Modules')
  elseif id == 'dep_graph' then
    run('go mod graph', root, 'Module Graph')
  elseif id == 'ws_members' then
    M.show_workspace_members(p)
  elseif id == 'ws_sync' then
    run('go work sync', root, 'Workspace Sync')
  end
end

function M.show_dep_list(p)
  local deps = (p.info and p.info.deps) or {}
  if #deps == 0 then
    vim.notify('[Marvin] No dependencies in go.mod', vim.log.levels.INFO); return
  end
  local items = {}
  for _, d in ipairs(deps) do
    items[#items + 1] = {
      id    = d.path,
      label = d.path .. ' @ ' .. d.version,
      desc  = d.indirect and 'indirect' or 'direct',
    }
  end
  ui().select(items, {
    prompt        = 'Go Modules (' .. #deps .. ')',
    enable_search = true,
    format_item   = plain,
  }, function(_) end)
end

function M.show_add_menu(p)
  local cat_items = {}
  for _, c in ipairs(CATALOGUE) do
    -- Skip stdlib pseudo-entries (no import needed)
    if not c.path:match('^encoding/') and not c.path:match('^net/') then
      cat_items[#cat_items + 1] = {
        id     = 'cat__' .. c.path,
        label  = c.label,
        desc   = c.desc .. ' — ' .. c.path,
        _pkg   = c,
      }
    end
  end
  cat_items[#cat_items + 1] = {
    id = '__manual__', label = '󰏫 Enter module path manually…', desc = 'e.g. github.com/foo/bar@latest'
  }

  ui().select(cat_items, {
    prompt        = 'Add Go Module',
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then return end
    if choice.id == '__manual__' then
      ui().input({ prompt = 'Module path[@version]', default = '' }, function(path)
        if path and path ~= '' then
          -- Append @latest if no version given
          if not path:match('@') then path = path .. '@latest' end
          run('go get ' .. path, p.root, 'go get ' .. path)
          vim.defer_fn(function() det().reload() end, 3000)
        end
      end)
    else
      local pkg  = choice._pkg
      local path = pkg.path .. '@latest'
      run('go get ' .. path, p.root, 'go get ' .. pkg.label)
      vim.defer_fn(function() det().reload() end, 3000)
    end
  end)
end

function M.show_remove_menu(p)
  local deps = (p.info and p.info.deps) or {}
  local direct = {}
  for _, d in ipairs(deps) do
    if not d.indirect then direct[#direct + 1] = d end
  end
  if #direct == 0 then
    vim.notify('[Marvin] No direct dependencies to remove', vim.log.levels.INFO); return
  end
  local items = {}
  for _, d in ipairs(direct) do
    items[#items + 1] = { id = d.path, label = d.path, desc = d.version }
  end
  ui().select(items, {
    prompt        = 'Remove Module',
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then return end
    -- go get pkg@none removes it; then tidy cleans go.mod
    run('go get ' .. choice.id .. '@none && go mod tidy', p.root, 'Remove ' .. choice.id)
    vim.defer_fn(function() det().reload() end, 3000)
  end)
end

function M.show_workspace_members(p)
  local members = (p.info and p.info.workspace) or {}
  if #members == 0 then
    vim.notify('[Marvin] No go.work workspace members found', vim.log.levels.INFO); return
  end
  local items = {}
  for _, m in ipairs(members) do
    items[#items + 1] = { id = m, label = m }
  end
  ui().select(items, { prompt = 'Workspace Members', format_item = plain }, function(_) end)
end

return M
