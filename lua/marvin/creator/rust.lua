-- lua/marvin/creator/rust.lua
-- Interactive Rust code creation wizard.
-- Handles: struct, trait, impl, module file, integration test,
--          [[bin]] target, new library crate, new binary crate.

local M = {}

local function ui()  return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function plain(it) return it.label end

-- ── File writing ──────────────────────────────────────────────────────────────
local function write(path, lines, label)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local f = io.open(path, 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. path, vim.log.levels.ERROR); return false
  end
  for _, l in ipairs(lines) do f:write(l .. '\n') end
  f:close()
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.notify('[Marvin] Created ' .. label .. ': ' .. vim.fn.fnamemodify(path, ':t'), vim.log.levels.INFO)
  return true
end

local function snake(name)
  -- PascalCase → snake_case
  return name:gsub('(%u)', function(c) return '_' .. c:lower() end):gsub('^_', '')
end

-- ── Templates ─────────────────────────────────────────────────────────────────

local function struct_template(name, opts)
  local lines = {}
  if opts.derives and #opts.derives > 0 then
    lines[#lines + 1] = '#[derive(' .. table.concat(opts.derives, ', ') .. ')]'
  end
  lines[#lines + 1] = 'pub struct ' .. name .. ' {'
  if opts.fields and #opts.fields > 0 then
    for _, f in ipairs(opts.fields) do
      lines[#lines + 1] = '    pub ' .. f.name .. ': ' .. f.typ .. ','
    end
  else
    lines[#lines + 1] = '    // TODO: add fields'
  end
  lines[#lines + 1] = '}'
  lines[#lines + 1] = ''

  if opts.impl then
    lines[#lines + 1] = 'impl ' .. name .. ' {'
    if opts.fields and #opts.fields > 0 then
      -- new() constructor
      local params = {}
      for _, f in ipairs(opts.fields) do
        params[#params + 1] = f.name .. ': ' .. f.typ
      end
      lines[#lines + 1] = '    pub fn new(' .. table.concat(params, ', ') .. ') -> Self {'
      lines[#lines + 1] = '        Self {'
      for _, f in ipairs(opts.fields) do
        lines[#lines + 1] = '            ' .. f.name .. ','
      end
      lines[#lines + 1] = '        }'
      lines[#lines + 1] = '    }'
    else
      lines[#lines + 1] = '    pub fn new() -> Self {'
      lines[#lines + 1] = '        Self {}'
      lines[#lines + 1] = '    }'
    end
    lines[#lines + 1] = '}'
    lines[#lines + 1] = ''
  end

  if opts.tests then
    lines[#lines + 1] = '#[cfg(test)]'
    lines[#lines + 1] = 'mod tests {'
    lines[#lines + 1] = '    use super::*;'
    lines[#lines + 1] = ''
    lines[#lines + 1] = '    #[test]'
    lines[#lines + 1] = '    fn test_' .. snake(name) .. '() {'
    lines[#lines + 1] = '        // TODO: write test'
    lines[#lines + 1] = '        todo!()'
    lines[#lines + 1] = '    }'
    lines[#lines + 1] = '}'
  end
  return lines
end

local function trait_template(name, opts)
  local lines = {}
  lines[#lines + 1] = 'pub trait ' .. name .. ' {'
  if opts.methods and #opts.methods > 0 then
    for _, m in ipairs(opts.methods) do
      lines[#lines + 1] = '    fn ' .. m .. ';'
    end
  else
    lines[#lines + 1] = '    // TODO: define methods'
  end
  lines[#lines + 1] = '}'
  lines[#lines + 1] = ''
  if opts.default_impl then
    lines[#lines + 1] = '// Default implementation'
    lines[#lines + 1] = 'pub struct Default' .. name .. ';'
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'impl ' .. name .. ' for Default' .. name .. ' {'
    if opts.methods and #opts.methods > 0 then
      for _, m in ipairs(opts.methods) do
        -- Strip signature noise for body stub
        local fname = m:match('fn%s+(%w+)') or m
        lines[#lines + 1] = '    fn ' .. m .. ' {'
        lines[#lines + 1] = '        todo!("implement ' .. fname .. '")'
        lines[#lines + 1] = '    }'
      end
    end
    lines[#lines + 1] = '}'
  end
  return lines
end

local function impl_template(trait_name, type_name)
  return {
    'use crate::' .. snake(trait_name) .. '::' .. trait_name .. ';',
    '',
    'impl ' .. trait_name .. ' for ' .. type_name .. ' {',
    '    // TODO: implement methods',
    '}',
  }
end

local function module_template(name)
  return {
    '//! ' .. name .. ' module',
    '',
    '// TODO: implement ' .. name,
    '',
    '#[cfg(test)]',
    'mod tests {',
    '    use super::*;',
    '',
    '    #[test]',
    '    fn test_placeholder() {',
    '        // TODO',
    '    }',
    '}',
  }
end

local function integration_test_template(name)
  return {
    'use ' .. name .. '::*;',
    '',
    '#[test]',
    'fn integration_test() {',
    '    // TODO: write integration test',
    '    todo!()',
    '}',
  }
end

local function bin_template(name)
  return {
    'fn main() {',
    '    println!("' .. name .. ' starting...");',
    '    // TODO: implement ' .. name,
    '}',
  }
end

-- ── Prompt helpers ────────────────────────────────────────────────────────────
local function prompt_fields(cb)
  ui().input({
    prompt  = 'Fields (type:name, …) e.g. String:name,u32:age',
    default = '',
  }, function(input)
    if not input or input == '' then cb({}); return end
    local fields = {}
    for pair in input:gmatch('[^,]+') do
      local typ, name = pair:match('%s*([^:]+):([^:]+)%s*')
      if typ and name then
        fields[#fields + 1] = { typ = vim.trim(typ), name = vim.trim(name) }
      end
    end
    cb(fields)
  end)
end

local function prompt_methods(cb)
  ui().input({
    prompt  = 'Method signatures (semicolon-separated)',
    default = 'fn do_something(&self)',
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

local COMMON_DERIVES = { 'Debug', 'Clone', 'PartialEq', 'Eq', 'Hash', 'Serialize', 'Deserialize' }

local function prompt_derives(cb)
  local items = {}
  for _, d in ipairs(COMMON_DERIVES) do
    items[#items + 1] = { id = d, label = d }
  end
  items[#items + 1] = { id = '__none__', label = '(none)' }
  items[#items + 1] = { id = '__custom__', label = '󰏫 Custom…' }

  -- multi-select simulation via repeated selection
  -- For simplicity, offer a preset selection
  ui().select({
    { id = 'debug_clone',     label = 'Debug, Clone' },
    { id = 'debug_clone_eq',  label = 'Debug, Clone, PartialEq, Eq' },
    { id = 'serde',           label = 'Debug, Clone, Serialize, Deserialize (+ serde dep)' },
    { id = 'none',            label = '(no derives)' },
    { id = 'custom',          label = '󰏫 Custom…' },
  }, { prompt = 'Derives', format_item = plain }, function(choice)
    if not choice then cb({}); return end
    if choice.id == 'debug_clone'    then cb({ 'Debug', 'Clone' })
    elseif choice.id == 'debug_clone_eq' then cb({ 'Debug', 'Clone', 'PartialEq', 'Eq' })
    elseif choice.id == 'serde'      then cb({ 'Debug', 'Clone', 'Serialize', 'Deserialize' })
    elseif choice.id == 'none'       then cb({})
    elseif choice.id == 'custom'     then
      ui().input({ prompt = 'Derives (comma-separated)', default = 'Debug, Clone' }, function(raw)
        if not raw then cb({}); return end
        local d = {}
        for s in raw:gmatch('[^,]+') do d[#d + 1] = vim.trim(s) end
        cb(d)
      end)
    end
  end)
end

-- ── Source path resolution ────────────────────────────────────────────────────
local function src_path(root, name, subdir)
  local sn = snake(name)
  local base = root .. '/src' .. (subdir and ('/' .. subdir) or '')
  return base .. '/' .. sn .. '.rs'
end

-- ── Entry points ──────────────────────────────────────────────────────────────

function M.create_struct(on_back)
  local p = det().get()
  if not p then return end
  ui().input({ prompt = '󰙲 Struct name' }, function(name)
    if not name or name == '' then return end
    vim.schedule(function()
      prompt_derives(function(derives)
        ui().select({
          { id = 'yes', label = 'Yes — generate impl { new() }' },
          { id = 'no',  label = 'No' },
        }, { prompt = 'Generate impl block?', format_item = plain }, function(impl_choice)
          local gen_impl = impl_choice and impl_choice.id == 'yes'
          if gen_impl then
            prompt_fields(function(fields)
              ui().select({
                { id = 'yes', label = 'Yes — add #[cfg(test)] block' },
                { id = 'no',  label = 'No' },
              }, { prompt = 'Include unit tests?', format_item = plain }, function(tc)
                local lines = struct_template(name, {
                  derives = derives, fields = fields,
                  impl = true, tests = tc and tc.id == 'yes',
                })
                write(src_path(p.root, name), lines, 'Struct')
              end)
            end)
          else
            local lines = struct_template(name, { derives = derives })
            write(src_path(p.root, name), lines, 'Struct')
          end
        end)
      end)
    end)
  end)
end

function M.create_trait(on_back)
  local p = det().get()
  if not p then return end
  ui().input({ prompt = '󰙲 Trait name' }, function(name)
    if not name or name == '' then return end
    vim.schedule(function()
      prompt_methods(function(methods)
        ui().select({
          { id = 'yes', label = 'Yes — generate default impl struct' },
          { id = 'no',  label = 'No' },
        }, { prompt = 'Generate default implementation?', format_item = plain }, function(di)
          local lines = trait_template(name, {
            methods = methods, default_impl = di and di.id == 'yes'
          })
          write(src_path(p.root, name), lines, 'Trait')
        end)
      end)
    end)
  end)
end

function M.create_impl(on_back)
  local p = det().get()
  if not p then return end
  ui().input({ prompt = '󰙲 Trait name to implement' }, function(trait_name)
    if not trait_name or trait_name == '' then return end
    vim.schedule(function()
      ui().input({ prompt = '󰙲 Type to implement it for' }, function(type_name)
        if not type_name or type_name == '' then return end
        local lines = impl_template(trait_name, type_name)
        write(src_path(p.root, snake(trait_name) .. '_impl_' .. snake(type_name)), lines, 'Impl')
      end)
    end)
  end)
end

function M.create_module(on_back)
  local p = det().get()
  if not p then return end
  ui().input({ prompt = '󰙲 Module name' }, function(name)
    if not name or name == '' then return end
    local lines = module_template(name)
    write(src_path(p.root, name), lines, 'Module')
    -- Prompt to add `pub mod name;` to lib.rs / main.rs
    local lib = p.root .. '/src/lib.rs'
    local main = p.root .. '/src/main.rs'
    local target = vim.fn.filereadable(lib) == 1 and lib or (vim.fn.filereadable(main) == 1 and main or nil)
    if target then
      local f = io.open(target, 'r')
      if f then
        local content = f:read('*all'); f:close()
        local decl = 'pub mod ' .. snake(name) .. ';'
        if not content:find(decl, 1, true) then
          f = io.open(target, 'a')
          if f then f:write('\n' .. decl .. '\n'); f:close() end
        end
      end
    end
  end)
end

function M.create_integration_test(on_back)
  local p = det().get()
  if not p then return end
  ui().input({ prompt = '󰙨 Integration test name' }, function(name)
    if not name or name == '' then return end
    local sn    = snake(name)
    local path  = p.root .. '/tests/' .. sn .. '.rs'
    -- Determine crate name from Cargo.toml
    local crate = (p.info and p.info.name) or vim.fn.fnamemodify(p.root, ':t')
    crate = crate:gsub('-', '_')
    write(path, integration_test_template(crate), 'Integration Test')
  end)
end

function M.create_bin(on_back)
  local p = det().get()
  if not p then return end
  ui().input({ prompt = '󰐊 Binary name' }, function(name)
    if not name or name == '' then return end
    local sn   = snake(name)
    local path = p.root .. '/src/bin/' .. sn .. '.rs'
    write(path, bin_template(name), 'Binary')
    vim.notify('[Marvin] Add [[bin]] to Cargo.toml:\n  name = "' .. sn .. '"\n  path = "src/bin/' .. sn .. '.rs"',
      vim.log.levels.INFO)
  end)
end

function M.create_crate(on_back)
  local p = det().get()
  if not p then return end

  ui().select({
    { id = 'bin', label = '󰐊 Binary crate',  desc = 'cargo new <name> — executable' },
    { id = 'lib', label = '󰙲 Library crate', desc = 'cargo new --lib <name> — library' },
  }, { prompt = 'New Crate Type', on_back = on_back, format_item = plain }, function(kind)
    if not kind then return end
    vim.schedule(function()
      ui().input({ prompt = 'Crate name' }, function(name)
        if not name or name == '' then return end
        local flag = kind.id == 'lib' and ' --lib' or ''
        local cwd  = vim.fn.fnamemodify(p.root, ':h') -- create alongside, not inside
        require('core.runner').execute({
          cmd      = 'cargo new' .. flag .. ' ' .. name,
          cwd      = cwd,
          title    = 'New Crate: ' .. name,
          term_cfg = require('marvin').config.terminal,
          plugin   = 'marvin',
        })
      end)
    end)
  end)
end

-- ── Menu items (returned to lang/rust.lua → dashboard) ────────────────────────
function M.menu_items()
  local items = {}
  local function sep(l) items[#items + 1] = { label = l, is_separator = true } end
  local function it(id, icon, label, desc)
    items[#items + 1] = { id = id, label = icon .. ' ' .. label, desc = desc }
  end

  sep('Create')
  it('cr_struct',  '󰙲', 'New Struct',            'Struct with optional derives, impl, tests')
  it('cr_trait',   '󰜰', 'New Trait',             'Trait with method signatures')
  it('cr_impl',    '󰙲', 'New Impl',              'Implement a trait for a type')
  it('cr_module',  '󰉿', 'New Module',            'New .rs module file + pub mod declaration')
  it('cr_test',    '󰙨', 'New Integration Test',  'tests/<name>.rs')
  it('cr_bin',     '󰐊', 'New Binary Target',     'src/bin/<name>.rs')
  it('cr_crate',   '󰏗', 'New Crate',             'cargo new (bin or lib)')
  return items
end

function M.handle(id, on_back)
  if     id == 'cr_struct' then M.create_struct(on_back)
  elseif id == 'cr_trait'  then M.create_trait(on_back)
  elseif id == 'cr_impl'   then M.create_impl(on_back)
  elseif id == 'cr_module' then M.create_module(on_back)
  elseif id == 'cr_test'   then M.create_integration_test(on_back)
  elseif id == 'cr_bin'    then M.create_bin(on_back)
  elseif id == 'cr_crate'  then M.create_crate(on_back)
  end
end

return M
