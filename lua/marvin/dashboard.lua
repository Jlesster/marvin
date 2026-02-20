-- lua/marvin/dashboard.lua
-- Marvin: Java / Maven specialist.
-- Owns: POM manipulation, file generation, archetype generation,
--       dependency inspection, Maven lifecycle with profiles.

local M = {}

-- ── Formatting helpers ────────────────────────────────────────────────────────
-- format_item embeds the icon into the display string.
-- We do NOT store icon as a table field, so marvin.ui cannot double-render it.
local function plain_fmt(it) return it.label end

local function sep(label) return { label = label, is_separator = true } end

-- Top-level item: _icon is private (not used by marvin.ui), embedded by format_item.
local function item(id, icon, label, desc, badge)
  return { id = id, _icon = icon, label = label, desc = desc, badge = badge }
end

-- Sub-menu item: icon is baked into the label string, no separate field.
local function sub(id, icon, label, desc, badge)
  return { id = id, label = icon .. ' ' .. label, desc = desc, badge = badge }
end

local function get_summary()
  local p = require('marvin.project').get_project()
  if not p or not p.info then return nil end
  return {
    artifact  = p.info.artifact_id or 'unknown',
    group     = p.info.group_id or 'unknown',
    version   = p.info.version or 'unknown',
    packaging = p.info.packaging or 'jar',
    profiles  = p.info.profiles or {},
  }
end

local function has_assembly()
  local pom = vim.fn.getcwd() .. '/pom.xml'
  if vim.fn.filereadable(pom) == 0 then return false end
  return table.concat(vim.fn.readfile(pom), '\n'):match('maven%-assembly%-plugin') ~= nil
end

-- ── Menu builder ──────────────────────────────────────────────────────────────
function M.build_menu(in_maven, summary)
  local items = {}
  local function add(t) items[#items + 1] = t end

  add(sep('Create'))
  add(item('new_project', '󰏗', 'New Maven Project', 'Generate from archetype'))
  if in_maven then
    add(item('new_file_menu', '󰬷', 'New Java File…', 'Class, Interface, Record, Enum…'))
    add(item('new_test', '󰙨', 'New JUnit Test', 'JUnit 5 test class'))

    add(sep('Build'))
    add(item('compile', '󰑕', 'Compile', 'mvn compile'))
    add(item('test', '󰙨', 'Test', 'mvn test'))
    add(item('package', '󰏗', 'Package',
      summary and ('Build ' .. summary.artifact .. '-' .. summary.version .. '.jar') or 'mvn package'))
    add(item('build_menu', '󰒓', 'Build Options…', 'Skip tests, fat JAR, profiles, more'))

    add(sep('Inspect'))
    add(item('inspect_menu', '󰙅', 'Inspect…', 'Dep tree, effective POM, plugin help'))

    add(sep('Dependencies'))
    add(item('dep_menu', '󰘦', 'Manage Dependencies…', 'Add, update, purge'))

    add(sep('Configure'))
    add(item('config_menu', '󰒓', 'Project Settings…', 'Java version, encoding, plugins'))
  end

  return items
end

-- ── Show ──────────────────────────────────────────────────────────────────────
function M.show()
  local project  = require('marvin.project')
  local in_maven = project.detect()
  local summary  = in_maven and get_summary() or nil

  local prompt   = summary
      and ('Marvin  ' .. summary.group .. ':' .. summary.artifact .. '  v' .. summary.version)
      or 'Marvin  (no Maven project)'

  require('marvin.ui').select(M.build_menu(in_maven, summary), {
    prompt        = prompt,
    enable_search = true,
    format_item   = function(it)
      if it.is_separator then return it.label end
      return (it._icon and (it._icon .. ' ') or '') .. it.label
    end,
  }, function(choice)
    if choice then M.handle_action(choice.id) end
  end)
end

-- ── Sub-menus ─────────────────────────────────────────────────────────────────

function M.show_new_file_menu()
  require('marvin.ui').select({
      sub('new_class', '󰬷', 'Class', 'public class …'),
      sub('new_main', '󰁔', 'Main Class', 'Class with main()'),
      sub('new_interface', '󰜰', 'Interface', 'Contract definition'),
      sub('new_enum', '󰒻', 'Enum', 'Type-safe constants'),
      sub('new_record', '󰏗', 'Record', 'Immutable data carrier'),
      sub('new_abstract', '󰦊', 'Abstract Class', 'Partial implementation'),
      sub('new_exception', '󰅖', 'Exception', 'Custom error type'),
      sub('new_builder', '󰒓', 'Builder', 'Builder pattern class'),
    }, { prompt = 'New Java File', format_item = plain_fmt },
    function(choice) if choice then M.handle_action(choice.id) end end)
end

function M.show_build_menu(summary)
  local items = {
    sub('clean_install', '󰑓', 'Clean & Install', 'Full rebuild + install'),
    sub('install', '󰇚', 'Install', 'mvn install → ~/.m2'),
    sub('verify', '󰄬', 'Verify', 'Run integration tests'),
    sub('skip_tests', '󰒭', 'Build (skip tests)', 'mvn package -DskipTests'),
  }
  if has_assembly() then
    items[#items + 1] = sub('package_fat', '󱊞', 'Package Fat JAR', 'JAR with all dependencies')
  end
  if #(summary and summary.profiles or {}) > 0 then
    items[#items + 1] = sub('with_profile', '󰒓', 'Run with Profile…',
      #summary.profiles .. ' profiles available')
  end

  require('marvin.ui').select(items,
    { prompt = 'Build Options', format_item = plain_fmt },
    function(choice) if choice then M.handle_action(choice.id) end end)
end

function M.show_inspect_menu()
  require('marvin.ui').select({
      sub('dep_tree', '󰙅', 'Dependency Tree', 'mvn dependency:tree'),
      sub('dep_analyze', '󰍉', 'Dependency Analysis', 'Find unused / undeclared deps'),
      sub('dep_resolve', '󰚰', 'Resolve Deps', 'Download all dependencies'),
      sub('effective_pom', '󰈙', 'Effective POM', 'Show resolved configuration'),
      sub('effective_settings', '󰈙', 'Effective Settings', 'Show Maven settings'),
      sub('help_describe', '󰅾', 'Describe Plugin', 'mvn help:describe'),
    }, { prompt = 'Inspect', format_item = plain_fmt },
    function(choice) if choice then M.handle_action(choice.id) end end)
end

function M.show_dep_menu()
  local items = {
    sub('add_jackson', '󰘦', 'Add Jackson JSON', 'com.fasterxml.jackson'),
    sub('add_lwjgl', '󰊗', 'Add LWJGL', 'OpenGL / Vulkan / GLFW'),
    sub('add_spring', '󰋊', 'Add Spring Boot', 'spring-boot-starter'),
    sub('add_lombok', '󰬷', 'Add Lombok', 'Annotation processor'),
    sub('add_junit5', '󰙨', 'Add JUnit 5', 'org.junit.jupiter'),
    sub('add_mockito', '󰙨', 'Add Mockito', 'Mocking framework'),
    sub('check_updates', '󰦉', 'Check for Updates', 'Display newer versions'),
    sub('purge_cache', '󰃢', 'Purge Local Cache', 'mvn dependency:purge-local-repository'),
  }
  if not has_assembly() then
    items[#items + 1] = sub('add_assembly', '󰒓', 'Enable Fat JAR', 'Add maven-assembly-plugin')
  end
  require('marvin.ui').select(items,
    { prompt = 'Manage Dependencies', enable_search = true, format_item = plain_fmt },
    function(choice) if choice then M.handle_action(choice.id) end end)
end

function M.show_config_menu()
  require('marvin.ui').select({
      sub('java_version_menu', '󰬷', 'Set Java Version…', 'Compiler source/target'),
      sub('set_encoding', '󰉣', 'Set Encoding…', 'project.build.sourceEncoding'),
      sub('add_spotless', '󰉣', 'Add Spotless', 'Code formatter plugin'),
    }, { prompt = 'Project Settings', format_item = plain_fmt },
    function(choice) if choice then M.handle_action(choice.id) end end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle_action(id)
  local ex = require('marvin.executor')
  local md = function() return require('marvin.dependencies') end

  -- Submenu dispatchers
  if id == 'new_file_menu' then
    M.show_new_file_menu(); return
  elseif id == 'build_menu' then
    M.show_build_menu(get_summary()); return
  elseif id == 'inspect_menu' then
    M.show_inspect_menu(); return
  elseif id == 'dep_menu' then
    M.show_dep_menu(); return
  elseif id == 'config_menu' then
    M.show_config_menu(); return
  elseif id == 'java_version_menu' then
    M.prompt_java_version(); return

    -- Create
  elseif id == 'new_project' then
    require('marvin.generator').create_project(); return
  elseif id == 'new_class' then
    M._new_file('Class', {})
  elseif id == 'new_main' then
    M._new_file('Class', { main = true })
  elseif id == 'new_interface' then
    M._new_file('Interface', {})
  elseif id == 'new_enum' then
    M._new_file_enum()
  elseif id == 'new_record' then
    M._new_file_record()
  elseif id == 'new_abstract' then
    M._new_file('Abstract Class', {})
  elseif id == 'new_exception' then
    M._new_file('Exception', {})
  elseif id == 'new_test' then
    M._new_file('Test', {})
  elseif id == 'new_builder' then
    M._new_file_builder()

    -- Build
  elseif id == 'compile' then
    ex.run('compile')
  elseif id == 'test' then
    ex.run('test')
  elseif id == 'package' then
    ex.run('package')
  elseif id == 'package_fat' then
    ex.run('package assembly:single')
  elseif id == 'install' then
    ex.run('install')
  elseif id == 'clean_install' then
    ex.run('clean install')
  elseif id == 'verify' then
    ex.run('verify')
  elseif id == 'skip_tests' then
    ex.run('package -DskipTests')
  elseif id == 'with_profile' then
    M.show_profile_menu()

    -- Inspect
  elseif id == 'dep_tree' then
    ex.run('dependency:tree')
  elseif id == 'dep_analyze' then
    ex.run('dependency:analyze')
  elseif id == 'dep_resolve' then
    ex.run('dependency:resolve')
  elseif id == 'effective_pom' then
    ex.run('help:effective-pom')
  elseif id == 'effective_settings' then
    ex.run('help:effective-settings')
  elseif id == 'help_describe' then
    M.prompt_describe()

    -- Dependencies
  elseif id == 'add_jackson' then
    md().add_jackson()
  elseif id == 'add_lwjgl' then
    md().add_lwjgl()
  elseif id == 'add_spring' then
    md().add_spring()
  elseif id == 'add_lombok' then
    md().add_lombok()
  elseif id == 'add_junit5' then
    md().add_junit5()
  elseif id == 'add_mockito' then
    md().add_mockito()
  elseif id == 'add_assembly' then
    md().add_assembly_plugin()
  elseif id == 'check_updates' then
    ex.run('versions:display-dependency-updates')
  elseif id == 'purge_cache' then
    ex.run('dependency:purge-local-repository')

    -- Configuration
  elseif id == 'set_java_11' then
    md().set_java_version('11')
  elseif id == 'set_java_17' then
    md().set_java_version('17')
  elseif id == 'set_java_21' then
    md().set_java_version('21')
  elseif id == 'set_java_custom' then
    M.prompt_java_version_input()
  elseif id == 'set_encoding' then
    M.prompt_encoding()
  elseif id == 'add_spotless' then
    md().add_spotless()
  end
end

-- ── File creation helpers ─────────────────────────────────────────────────────
function M._new_file(type_name, opts)
  local ok, jc = pcall(require, 'marvin.java_creator')
  if not ok then
    vim.notify('marvin.java_creator not found', vim.log.levels.ERROR); return
  end
  jc.create_file_interactive(type_name, opts, function() M.show() end)
end

function M._new_file_enum()
  local jc = require('marvin.java_creator')
  jc.prompt_enum_values(function(values)
    if values then jc.create_file_interactive('Enum', { values = values }, function() M.show() end) end
  end)
end

function M._new_file_record()
  local jc = require('marvin.java_creator')
  jc.prompt_fields(function(fields)
    if fields then
      jc.create_file_interactive('Record', { fields = fields }, function() M.show() end)
    end
  end, '󰏗 Record fields (Type name, …)')
end

function M._new_file_builder()
  local jc = require('marvin.java_creator')
  jc.prompt_fields(function(fields)
    if fields then
      if #fields > 0 then fields[1].required = true end
      jc.create_file_interactive('Builder', { fields = fields }, function() M.show() end)
    end
  end, '󰒓 Builder fields (Type name, …)')
end

-- ── Profile picker ────────────────────────────────────────────────────────────
function M.show_profile_menu()
  local proj     = require('marvin.project').get_project()
  local profiles = proj and proj.info and proj.info.profiles or {}
  if #profiles == 0 then
    vim.notify('No profiles found in pom.xml', vim.log.levels.INFO); return
  end
  local prof_items = {}
  for _, pid in ipairs(profiles) do
    prof_items[#prof_items + 1] = { id = pid, label = pid, desc = 'Maven profile' }
  end

  require('marvin.ui').select({
      { id = 'compile', label = 'compile' },
      { id = 'test',    label = 'test' },
      { id = 'package', label = 'package' },
      { id = 'install', label = 'install' },
      { id = 'verify',  label = 'verify' },
    }, { prompt = 'Goal to run', format_item = plain_fmt },
    function(goal)
      if not goal then return end
      require('marvin.ui').select(prof_items,
        { prompt = 'Profile for: ' .. goal.id, format_item = plain_fmt },
        function(prof)
          if prof then require('marvin.executor').run(goal.id, { profile = prof.id }) end
        end)
    end)
end

-- ── Prompts ───────────────────────────────────────────────────────────────────
function M.prompt_java_version()
  require('marvin.ui').select({
      { version = '21', label = 'Java 21 (LTS)', desc = 'Virtual threads, pattern matching' },
      { version = '17', label = 'Java 17 (LTS)', desc = 'Sealed classes, records' },
      { version = '11', label = 'Java 11 (LTS)', desc = 'Widely adopted' },
      { version = '8', label = 'Java 8  (LTS)', desc = 'Maximum compatibility' },
      { version = '__custom__', label = 'Custom…', desc = 'Enter version number' },
    }, { prompt = 'Java Version', format_item = plain_fmt },
    function(choice)
      if not choice then return end
      if choice.version == '__custom__' then
        M.prompt_java_version_input()
      else
        require('marvin.dependencies').set_java_version(choice.version)
      end
    end)
end

function M.prompt_java_version_input()
  vim.ui.input({ prompt = 'Java version: ' }, function(v)
    if v and v ~= '' then require('marvin.dependencies').set_java_version(v) end
  end)
end

function M.prompt_encoding()
  require('marvin.ui').select({
      { id = 'UTF-8',      label = 'UTF-8',      desc = 'Recommended' },
      { id = 'ISO-8859-1', label = 'ISO-8859-1', desc = 'Latin-1' },
      { id = 'US-ASCII',   label = 'US-ASCII',   desc = 'ASCII only' },
    }, { prompt = 'Source Encoding', format_item = plain_fmt },
    function(choice)
      if choice then
        local ok, md = pcall(require, 'marvin.dependencies')
        if ok then md.set_encoding(choice.id) end
      end
    end)
end

function M.prompt_describe()
  vim.ui.input({ prompt = 'Plugin (e.g. maven-compiler-plugin): ' }, function(plugin)
    if plugin and plugin ~= '' then
      require('marvin.executor').run('help:describe -Dplugin=' .. plugin)
    end
  end)
end

return M
