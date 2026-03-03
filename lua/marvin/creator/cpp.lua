-- lua/marvin/creator/cpp.lua
-- Interactive C/C++ file creation wizard.
-- Handles: class (header + source), header-only, interface (abstract base),
--          struct, enum, test file, and Makefile regeneration.

local M = {}

local function ui() return require('marvin.ui') end
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
  vim.notify('[Marvin] Created ' .. label .. ': ' .. vim.fn.fnamemodify(path, ':t'), vim.log.levels.INFO)
  return true
end

local function guard(name)
  return name:upper():gsub('[^A-Z0-9]', '_') .. '_H'
end

local function cfg()
  return require('marvin').config.cpp
end

-- ── Templates ─────────────────────────────────────────────────────────────────

local function class_header(name, opts)
  local g     = guard(name)
  local ns    = opts.ns
  local lines = {
    '#pragma once',
    '#ifndef ' .. g,
    '#define ' .. g,
    '',
  }
  if opts.includes and #opts.includes > 0 then
    for _, inc in ipairs(opts.includes) do
      lines[#lines + 1] = '#include ' .. inc
    end
    lines[#lines + 1] = ''
  end
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = 'class ' .. name .. (opts.base and (' : public ' .. opts.base) or '') .. ' {'
  lines[#lines + 1] = 'public:'
  lines[#lines + 1] = '    ' .. name .. '();'
  lines[#lines + 1] = '    ~' .. name .. (opts.base and '() override;' or '();')
  if opts.copy then
    lines[#lines + 1] = '    ' .. name .. '(const ' .. name .. '&) = default;'
    lines[#lines + 1] = '    ' .. name .. '& operator=(const ' .. name .. '&) = default;'
  end
  if opts.move then
    lines[#lines + 1] = '    ' .. name .. '(' .. name .. '&&) noexcept = default;'
    lines[#lines + 1] = '    ' .. name .. '& operator=(' .. name .. '&&) noexcept = default;'
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = 'private:'
  lines[#lines + 1] = '    // TODO: add members'
  lines[#lines + 1] = '};'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '#endif // ' .. g
  return lines
end

local function class_source(name, opts)
  local inc_path = opts.inc_dir and (opts.inc_dir .. '/' .. name .. '.h') or (name .. '.h')
  local ns = opts.ns
  local lines = {
    '#include "' .. inc_path .. '"',
    '',
  }
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = name .. '::' .. name .. '() {'
  lines[#lines + 1] = '    // TODO: constructor'
  lines[#lines + 1] = '}'
  lines[#lines + 1] = ''
  lines[#lines + 1] = name .. '::~' .. name .. '() {'
  lines[#lines + 1] = '    // TODO: destructor'
  lines[#lines + 1] = '}'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  return lines
end

local function abstract_header(name, opts)
  local g     = guard(name)
  local ns    = opts.ns
  local lines = {
    '#pragma once',
    '#ifndef ' .. g,
    '#define ' .. g,
    '',
  }
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = 'class ' .. name .. ' {'
  lines[#lines + 1] = 'public:'
  lines[#lines + 1] = '    virtual ~' .. name .. '() = default;'
  lines[#lines + 1] = ''
  if opts.methods and #opts.methods > 0 then
    for _, m in ipairs(opts.methods) do
      lines[#lines + 1] = '    virtual ' .. m .. ' = 0;'
    end
  else
    lines[#lines + 1] = '    // TODO: add pure virtual methods'
    lines[#lines + 1] = '    // virtual void doSomething() = 0;'
  end
  lines[#lines + 1] = '};'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '#endif // ' .. g
  return lines
end

local function struct_header(name, opts)
  local g     = guard(name)
  local ns    = opts.ns
  local lines = {
    '#pragma once',
    '#ifndef ' .. g,
    '#define ' .. g,
    '',
  }
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = 'struct ' .. name .. ' {'
  if opts.fields and #opts.fields > 0 then
    for _, f in ipairs(opts.fields) do
      lines[#lines + 1] = '    ' .. f.typ .. ' ' .. f.name .. ';'
    end
  else
    lines[#lines + 1] = '    // TODO: add fields'
  end
  lines[#lines + 1] = '};'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '#endif // ' .. g
  return lines
end

local function enum_header(name, opts)
  local g         = guard(name)
  local ns        = opts.ns
  local use_class = opts.scoped ~= false -- default to enum class
  local lines     = {
    '#pragma once',
    '#ifndef ' .. g,
    '#define ' .. g,
    '',
  }
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = (use_class and 'enum class ' or 'enum ') .. name .. ' {'
  if opts.values and #opts.values > 0 then
    for i, v in ipairs(opts.values) do
      local comma = i < #opts.values and ',' or ''
      lines[#lines + 1] = '    ' .. v .. comma
    end
  else
    lines[#lines + 1] = '    // TODO: add values'
  end
  lines[#lines + 1] = '};'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '#endif // ' .. g
  return lines
end

local function test_file(name, opts)
  -- Minimal catch2 / gtest scaffold based on user choice
  local subject = opts.subject or name
  if opts.framework == 'catch2' then
    return {
      '#include <catch2/catch_test_macros.hpp>',
      '',
      '// TODO: #include "' .. subject .. '.h"',
      '',
      'TEST_CASE("' .. subject .. ' basic", "[' .. subject .. ']") {',
      '    SECTION("placeholder") {',
      '        REQUIRE(true);',
      '    }',
      '}',
    }
  else -- gtest default
    return {
      '#include <gtest/gtest.h>',
      '',
      '// TODO: #include "' .. subject .. '.h"',
      '',
      'TEST(' .. subject .. 'Test, BasicAssertion) {',
      '    EXPECT_TRUE(true);',
      '}',
      '',
      'int main(int argc, char** argv) {',
      '    ::testing::InitGoogleTest(&argc, argv);',
      '    return RUN_ALL_TESTS();',
      '}',
    }
  end
end

-- ── Prompt helpers ────────────────────────────────────────────────────────────
local function prompt_ns(cb)
  ui().select({
    { id = '__none__', label = '(no namespace)' },
    { id = '__custom__', label = '󰏫 Enter namespace…' },
  }, { prompt = 'Namespace', format_item = plain }, function(choice)
    if not choice or choice.id == '__none__' then
      cb(nil); return
    end
    ui().input({ prompt = 'Namespace name' }, function(ns)
      cb(ns ~= '' and ns or nil)
    end)
  end)
end

local function prompt_fields(cb)
  ui().input({
    prompt  = 'Fields (type:name, …) e.g. int:age,std::string:name',
    default = '',
  }, function(input)
    if not input or input == '' then
      cb({}); return
    end
    local fields = {}
    for pair in input:gmatch('[^,]+') do
      local typ, nm = pair:match('%s*([^:]+):([^:]+)%s*')
      if typ and nm then
        fields[#fields + 1] = { typ = vim.trim(typ), name = vim.trim(nm) }
      end
    end
    cb(fields)
  end)
end

local function prompt_methods(cb)
  ui().input({
    prompt  = 'Method signatures (semicolon-separated)',
    default = 'void doSomething()',
  }, function(input)
    if not input or input == '' then
      cb({}); return
    end
    local methods = {}
    for m in input:gmatch('[^;]+') do
      local t = vim.trim(m); if t ~= '' then methods[#methods + 1] = t end
    end
    cb(methods)
  end)
end

-- ── Resolve source/include dirs from project ─────────────────────────────────
local function resolve_dirs(p)
  local src = vim.fn.isdirectory(p.root .. '/src') == 1 and 'src' or ''
  local inc = vim.fn.isdirectory(p.root .. '/include') == 1 and 'include' or src
  return src, inc
end

-- ── Entry points ──────────────────────────────────────────────────────────────

function M.create_class(on_back)
  local p = det().get()
  if not p then return end
  local src_dir, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰙲 Class name' }, function(name)
    if not name or name == '' then return end
    -- Ensure PascalCase
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_ns(function(ns)
        ui().select({
          { id = 'default',   label = 'Default (constructor + destructor)' },
          { id = 'copy',      label = '+ Copy semantics' },
          { id = 'move',      label = '+ Move semantics' },
          { id = 'rule_of_5', label = '+ Rule of 5 (copy + move)' },
        }, { prompt = 'Class type', format_item = plain }, function(kind)
          local opts = {
            ns      = ns,
            inc_dir = inc_dir ~= '' and inc_dir or nil,
            copy    = kind and (kind.id == 'copy' or kind.id == 'rule_of_5'),
            move    = kind and (kind.id == 'move' or kind.id == 'rule_of_5'),
          }
          local h_path = p.root
              .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
              .. '/' .. name .. '.h'
          local c_path = p.root
              .. (src_dir ~= '' and ('/' .. src_dir) or '')
              .. '/' .. name .. '.cpp'
          write(h_path, class_header(name, opts), 'Header')
          write(c_path, class_source(name, opts), 'Source')
        end)
      end)
    end)
  end)
end

function M.create_abstract(on_back)
  local p = det().get()
  if not p then return end
  local _, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰙲 Abstract class / interface name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_ns(function(ns)
        prompt_methods(function(methods)
          local opts = { ns = ns, methods = methods }
          local path = p.root
              .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
              .. '/' .. name .. '.h'
          write(path, abstract_header(name, opts), 'Abstract Class')
        end)
      end)
    end)
  end)
end

function M.create_struct(on_back)
  local p = det().get()
  if not p then return end
  local _, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰙲 Struct name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_ns(function(ns)
        prompt_fields(function(fields)
          local opts = { ns = ns, fields = fields }
          local path = p.root
              .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
              .. '/' .. name .. '.h'
          write(path, struct_header(name, opts), 'Struct')
        end)
      end)
    end)
  end)
end

function M.create_enum(on_back)
  local p = det().get()
  if not p then return end
  local _, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰒻 Enum name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      ui().input({ prompt = 'Values (comma-separated)', default = 'ValueA, ValueB, ValueC' }, function(raw)
        local values = {}
        for v in (raw or ''):gmatch('[^,]+') do
          values[#values + 1] = vim.trim(v)
        end
        prompt_ns(function(ns)
          local opts = { ns = ns, values = values }
          local path = p.root
              .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
              .. '/' .. name .. '.h'
          write(path, enum_header(name, opts), 'Enum')
        end)
      end)
    end)
  end)
end

function M.create_header_only(on_back)
  local p = det().get()
  if not p then return end
  local _, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰈙 Header-only file name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_ns(function(ns)
        local g = guard(name)
        local lines = {
          '#pragma once',
          '#ifndef ' .. g,
          '#define ' .. g,
          '',
        }
        if ns then
          lines[#lines + 1] = 'namespace ' .. ns .. ' {'
          lines[#lines + 1] = ''
        end
        lines[#lines + 1] = '// TODO: implement ' .. name
        if ns then
          lines[#lines + 1] = ''
          lines[#lines + 1] = '} // namespace ' .. ns
        end
        lines[#lines + 1] = ''
        lines[#lines + 1] = '#endif // ' .. g
        local path = p.root
            .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
            .. '/' .. name .. '.hpp'
        write(path, lines, 'Header-only')
      end)
    end)
  end)
end

function M.create_test(on_back)
  local p = det().get()
  if not p then return end

  ui().input({ prompt = '󰙨 Subject / class under test' }, function(subject)
    if not subject or subject == '' then return end
    vim.schedule(function()
      ui().select({
        { id = 'gtest',  label = 'GoogleTest (gtest)' },
        { id = 'catch2', label = 'Catch2' },
      }, { prompt = 'Test framework', format_item = plain }, function(fw)
        local framework = fw and fw.id or 'gtest'
        local lines = test_file(subject, { framework = framework, subject = subject })
        local test_dir = vim.fn.isdirectory(p.root .. '/tests') == 1 and 'tests'
            or (vim.fn.isdirectory(p.root .. '/test') == 1 and 'test' or 'tests')
        local path = p.root .. '/' .. test_dir .. '/' .. subject .. '_test.cpp'
        write(path, lines, 'Test')
      end)
    end)
  end)
end

function M.create_main(on_back)
  local p = det().get()
  if not p then return end
  local src_dir, _ = resolve_dirs(p)
  local c          = cfg()

  local is_cpp     = (c.compiler == 'g++' or c.compiler == 'clang++')
  local ext        = is_cpp and '.cpp' or '.c'

  local lines      = {
    is_cpp and '#include <iostream>' or '#include <stdio.h>',
    '',
    'int main(int argc, char* argv[]) {',
    is_cpp
    and '    std::cout << "Hello, World!" << std::endl;'
    or '    printf("Hello, World!\\n");',
    '    return 0;',
    '}',
  }

  local path       = p.root
      .. (src_dir ~= '' and ('/' .. src_dir) or '')
      .. '/main' .. ext
  write(path, lines, 'main' .. ext)
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items()
  local items = {}
  local function sep(l) items[#items + 1] = { label = l, is_separator = true } end
  local function it(id, icon, label, desc)
    items[#items + 1] = { id = id, label = icon .. ' ' .. label, desc = desc }
  end

  sep('Create')
  it('cr_class', '󰙲', 'New Class', 'Header + source file pair')
  it('cr_abstract', '󰦊', 'New Abstract Class', 'Pure virtual interface header')
  it('cr_struct', '󰙲', 'New Struct', 'POD struct header')
  it('cr_enum', '󰒻', 'New Enum', 'enum class header')
  it('cr_header_only', '󰈙', 'New Header-only', 'Single .hpp file')
  it('cr_test', '󰙨', 'New Test File', 'GoogleTest or Catch2 scaffold')
  it('cr_main', '󰐊', 'New main.cpp', 'Entry point file')
  it('cr_makefile', '󰈙', 'New/Regenerate Makefile', 'Makefile creation wizard')
  return items
end

function M.handle(id, on_back)
  if id == 'cr_class' then
    M.create_class(on_back)
  elseif id == 'cr_abstract' then
    M.create_abstract(on_back)
  elseif id == 'cr_struct' then
    M.create_struct(on_back)
  elseif id == 'cr_enum' then
    M.create_enum(on_back)
  elseif id == 'cr_header_only' then
    M.create_header_only(on_back)
  elseif id == 'cr_test' then
    M.create_test(on_back)
  elseif id == 'cr_main' then
    M.create_main(on_back)
  elseif id == 'cr_makefile' then
    local p = det().get()
    require('marvin.makefile_creator').create(p and p.root or vim.fn.getcwd(), on_back)
  else
    return false
  end
  return true
end

return M
