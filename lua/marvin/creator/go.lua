-- lua/marvin/creator/go.lua
-- Interactive Go code creation wizard.
-- Handles: struct (with methods), interface, package dir, _test.go,
--          cmd/name/main.go entry point, pkg/name/ package scaffold.

local M = {}

local function ui()  return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function plain(it) return it.label end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function write(path, lines, label)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local f = io.open(path, 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. path, vim.log.levels.ERROR); return false
  end
  for _, l in ipairs(lines) do f:write(l .. '\n') end
  f:close()
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.notify('[Marvin] Created ' .. label .. ': ' .. path, vim.log.levels.INFO)
  return true
end

local function module_path(p)
  return (p.info and p.info.module) or vim.fn.fnamemodify(p.root, ':t')
end

local function lower_first(s)
  return s:sub(1, 1):lower() .. s:sub(2)
end

-- ── Templates ─────────────────────────────────────────────────────────────────

local function struct_template(pkg, name, opts)
  local lines = {}
  lines[#lines + 1] = 'package ' .. pkg
  lines[#lines + 1] = ''

  -- Imports
  local imports = {}
  if opts.json_tags then imports[#imports + 1] = '"encoding/json"' end
  if #imports > 0 then
    lines[#lines + 1] = 'import ('
    for _, im in ipairs(imports) do lines[#lines + 1] = '\t' .. im end
    lines[#lines + 1] = ')'
    lines[#lines + 1] = ''
  end

  -- Struct
  lines[#lines + 1] = '// ' .. name .. ' ...'
  lines[#lines + 1] = 'type ' .. name .. ' struct {'
  if opts.fields and #opts.fields > 0 then
    for _, f in ipairs(opts.fields) do
      local tag = opts.json_tags
        and (' `json:"' .. lower_first(f.name) .. '"`')
        or ''
      lines[#lines + 1] = '\t' .. f.name .. ' ' .. f.typ .. tag
    end
  else
    lines[#lines + 1] = '\t// TODO: add fields'
  end
  lines[#lines + 1] = '}'
  lines[#lines + 1] = ''

  -- Constructor
  if opts.constructor then
    local params, assigns = {}, {}
    if opts.fields and #opts.fields > 0 then
      for _, f in ipairs(opts.fields) do
        params[#params + 1]  = lower_first(f.name) .. ' ' .. f.typ
        assigns[#assigns + 1] = '\t\t' .. f.name .. ': ' .. lower_first(f.name) .. ','
      end
    end
    lines[#lines + 1] = '// New' .. name .. ' creates a new ' .. name .. '.'
    lines[#lines + 1] = 'func New' .. name .. '(' .. table.concat(params, ', ') .. ') *' .. name .. ' {'
    lines[#lines + 1] = '\treturn &' .. name .. '{'
    for _, a in ipairs(assigns) do lines[#lines + 1] = a end
    lines[#lines + 1] = '\t}'
    lines[#lines + 1] = '}'
    lines[#lines + 1] = ''
  end

  -- Methods
  if opts.methods then
    for _, m in ipairs(opts.methods) do
      lines[#lines + 1] = 'func (r *' .. name .. ') ' .. m .. ' {'
      lines[#lines + 1] = '\t// TODO: implement'
      lines[#lines + 1] = '\tpanic("not implemented")'
      lines[#lines + 1] = '}'
      lines[#lines + 1] = ''
    end
  end

  return lines
end

local function interface_template(pkg, name, opts)
  local lines = {}
  lines[#lines + 1] = 'package ' .. pkg
  lines[#lines + 1] = ''
  lines[#lines + 1] = '// ' .. name .. ' defines the contract for ...'
  lines[#lines + 1] = 'type ' .. name .. ' interface {'
  if opts.methods and #opts.methods > 0 then
    for _, m in ipairs(opts.methods) do
      lines[#lines + 1] = '\t' .. m
    end
  else
    lines[#lines + 1] = '\t// TODO: define methods'
  end
  lines[#lines + 1] = '}'
  lines[#lines + 1] = ''

  if opts.mock then
    -- Simple mock struct
    lines[#lines + 1] = '// Mock' .. name .. ' is a test mock for ' .. name .. '.'
    lines[#lines + 1] = 'type Mock' .. name .. ' struct{}'
    lines[#lines + 1] = ''
    if opts.methods then
      for _, m in ipairs(opts.methods) do
        -- Extract method name
        local mname = m:match('^(%w+)')
        if mname then
          lines[#lines + 1] = 'func (m *Mock' .. name .. ') ' .. m .. ' {'
          lines[#lines + 1] = '\tpanic("mock not implemented")'
          lines[#lines + 1] = '}'
          lines[#lines + 1] = ''
        end
      end
    end
  end
  return lines
end

local function test_template(pkg, subject)
  local sname = subject or 'Example'
  return {
    'package ' .. pkg .. '_test',
    '',
    'import (',
    '\t"testing"',
    '',
    '\t"github.com/stretchr/testify/assert"',
    ')',
    '',
    'func Test' .. sname .. '(t *testing.T) {',
    '\t// Arrange',
    '\t',
    '\t// Act',
    '\t',
    '\t// Assert',
    '\tassert.True(t, true, "placeholder")',
    '}',
  }
end

local function cmd_main_template(mod_path, cmd_name)
  return {
    'package main',
    '',
    'import (',
    '\t"fmt"',
    '\t"os"',
    ')',
    '',
    'func main() {',
    '\tif err := run(); err != nil {',
    '\t\tfmt.Fprintf(os.Stderr, "error: %v\\n", err)',
    '\t\tos.Exit(1)',
    '\t}',
    '}',
    '',
    'func run() error {',
    '\tfmt.Println("' .. cmd_name .. ' starting...")',
    '\t// TODO: implement ' .. cmd_name,
    '\treturn nil',
    '}',
  }
end

local function pkg_template(pkg)
  return {
    '// Package ' .. pkg .. ' provides ...',
    'package ' .. pkg,
    '',
    '// TODO: implement package ' .. pkg,
  }
end

-- ── Prompt helpers ────────────────────────────────────────────────────────────
local function prompt_fields(cb)
  ui().input({
    prompt  = 'Fields (type:Name, …) e.g. string:Name,int:Age',
    default = '',
  }, function(input)
    if not input or input == '' then cb({}); return end
    local fields = {}
    for pair in input:gmatch('[^,]+') do
      local typ, name = pair:match('%s*([^:]+):([^:]+)%s*')
      if typ and name then
        -- Go convention: exported fields are PascalCase
        local n = vim.trim(name)
        n = n:sub(1,1):upper() .. n:sub(2)
        fields[#fields + 1] = { typ = vim.trim(typ), name = n }
      end
    end
    cb(fields)
  end)
end

local function prompt_methods(cb)
  ui().input({
    prompt  = 'Method signatures (semicolon-separated)',
    default = 'DoSomething() error',
  }, function(input)
    if not input or input == '' then cb({}); return end
    local methods = {}
    for m in input:gmatch('[^;]+') do
      local t = vim.trim(m)
      if t ~= '' then methods[#methods + 1] = t end
    end
    cb(methods)
  end)
end

local function pkg_name(p)
  -- Derive from last segment of module path
  local mod = module_path(p)
  return vim.fn.fnamemodify(mod, ':t'):gsub('-', '_')
end

-- ── Entry points ──────────────────────────────────────────────────────────────

function M.create_struct(on_back)
  local p = det().get()
  if not p then return end
  local pkg = pkg_name(p)

  ui().input({ prompt = '󰙲 Struct name' }, function(name)
    if not name or name == '' then return end
    -- Ensure PascalCase
    name = name:sub(1,1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_fields(function(fields)
        ui().select({
          { id = 'yes_ctor',  label = 'Yes — New' .. name .. '() constructor' },
          { id = 'yes_chain', label = 'Yes — builder-style with methods' },
          { id = 'no',        label = 'No' },
        }, { prompt = 'Generate constructor?', format_item = plain }, function(ctor)
          local gen_ctor = ctor and ctor.id ~= 'no'
          ui().select({
            { id = 'yes', label = 'Yes — JSON struct tags' },
            { id = 'no',  label = 'No' },
          }, { prompt = 'Add JSON tags?', format_item = plain }, function(json)
            local gen_json = json and json.id == 'yes'
            local methods  = {}
            if ctor and ctor.id == 'yes_chain' then
              for _, f in ipairs(fields) do
                methods[#methods + 1] = 'Set' .. f.name .. '(v ' .. f.typ .. ') *' .. name
              end
            end
            local lines = struct_template(pkg, name, {
              fields = fields, constructor = gen_ctor,
              json_tags = gen_json, methods = #methods > 0 and methods or nil,
            })
            local path = p.root .. '/' .. lower_first(name) .. '.go'
            write(path, lines, 'Struct')
          end)
        end)
      end)
    end)
  end)
end

function M.create_interface(on_back)
  local p = det().get()
  if not p then return end
  local pkg = pkg_name(p)

  ui().input({ prompt = '󰜰 Interface name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1,1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_methods(function(methods)
        ui().select({
          { id = 'yes', label = 'Yes — Mock' .. name .. ' struct' },
          { id = 'no',  label = 'No' },
        }, { prompt = 'Generate mock implementation?', format_item = plain }, function(mock)
          local lines = interface_template(pkg, name, {
            methods = methods, mock = mock and mock.id == 'yes'
          })
          local path = p.root .. '/' .. lower_first(name) .. '.go'
          write(path, lines, 'Interface')
        end)
      end)
    end)
  end)
end

function M.create_test(on_back)
  local p = det().get()
  if not p then return end
  local pkg = pkg_name(p)

  ui().input({ prompt = '󰙨 Test subject (function/type name)' }, function(subject)
    if not subject or subject == '' then return end
    subject = subject:sub(1,1):upper() .. subject:sub(2)
    local lines = test_template(pkg, subject)
    local path  = p.root .. '/' .. lower_first(subject) .. '_test.go'
    write(path, lines, 'Test')
  end)
end

function M.create_cmd(on_back)
  local p = det().get()
  if not p then return end

  ui().input({ prompt = '󰐊 Command name (e.g. serve, migrate)' }, function(name)
    if not name or name == '' then return end
    local path = p.root .. '/cmd/' .. name .. '/main.go'
    write(path, cmd_main_template(module_path(p), name), 'Command')
  end)
end

function M.create_pkg(on_back)
  local p = det().get()
  if not p then return end

  ui().input({ prompt = '󰉿 Package name (e.g. auth, storage)' }, function(name)
    if not name or name == '' then return end
    -- Create both the dir and a stub .go file
    local dir  = p.root .. '/pkg/' .. name
    local path = dir .. '/' .. name .. '.go'
    write(path, pkg_template(name), 'Package')
  end)
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items()
  local items = {}
  local function sep(l) items[#items + 1] = { label = l, is_separator = true } end
  local function it(id, icon, label, desc)
    items[#items + 1] = { id = id, label = icon .. ' ' .. label, desc = desc }
  end

  sep('Create')
  it('cr_struct',    '󰙲', 'New Struct',        'Struct with constructor, JSON tags, methods')
  it('cr_interface', '󰜰', 'New Interface',     'Interface with optional mock implementation')
  it('cr_test',      '󰙨', 'New Test File',     '<subject>_test.go with testify scaffold')
  it('cr_cmd',       '󰐊', 'New Command',       'cmd/<name>/main.go entry point')
  it('cr_pkg',       '󰉿', 'New Package',       'pkg/<name>/<name>.go scaffold')
  return items
end

function M.handle(id, on_back)
  if     id == 'cr_struct'    then M.create_struct(on_back)
  elseif id == 'cr_interface' then M.create_interface(on_back)
  elseif id == 'cr_test'      then M.create_test(on_back)
  elseif id == 'cr_cmd'       then M.create_cmd(on_back)
  elseif id == 'cr_pkg'       then M.create_pkg(on_back)
  end
end

return M
