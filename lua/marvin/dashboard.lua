-- lua/marvin/dashboard.lua
-- Marvin: Java / Maven specialist.
-- Owns: POM manipulation, file generation, archetype generation,
--       dependency inspection, Maven lifecycle with profiles.

local M = {}

local function sep(label) return { label = label, is_separator = true } end
local function item(id, icon, label, desc, badge)
  return { id = id, icon = icon, label = label, desc = desc, badge = badge }
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

  -- ── Create ────────────────────────────────────────────────────────────────
  add(sep('Create'))
  add(item('new_project', '󰏗', 'New Maven Project', 'Generate from archetype'))
  if in_maven then
    add(item('new_class', '󰬷', 'New Class', 'public class …'))
    add(item('new_main', '󰁔', 'New Main Class', 'Class with main()'))
    add(item('new_interface', '󰜰', 'New Interface', 'Contract definition'))
    add(item('new_enum', '󰒻', 'New Enum', 'Type-safe constants'))
    add(item('new_record', '󰏗', 'New Record', 'Immutable data carrier'))
    add(item('new_abstract', '󰦊', 'New Abstract Class', 'Partial implementation'))
    add(item('new_exception', '󰅖', 'New Exception', 'Custom error type'))
    add(item('new_test', '󰙨', 'New JUnit Test', 'JUnit 5 test class'))
    add(item('new_builder', '󰒓', 'New Builder', 'Builder pattern class'))
  end

  if in_maven then
    -- ── Build lifecycle ─────────────────────────────────────────────────────
    add(sep('Build'))
    add(item('compile', '󰑕', 'Compile', 'mvn compile'))
    add(item('test', '󰙨', 'Test', 'mvn test'))
    add(item('package', '󰏗', 'Package',
      summary and ('Build ' .. summary.artifact .. '-' .. summary.version .. '.jar') or 'mvn package'))
    if has_assembly() then
      add(item('package_fat', '󱊞', 'Package Fat JAR', 'JAR with all dependencies'))
    end
    add(item('install', '󰇚', 'Install', 'mvn install → ~/.m2'))
    add(item('clean_install', '󰑓', 'Clean & Install', 'Full rebuild + install'))
    add(item('verify', '󰄬', 'Verify', 'Run integration tests'))
    add(item('skip_tests', '󰒭', 'Build (skip tests)', 'mvn package -DskipTests'))
    if #(summary and summary.profiles or {}) > 0 then
      add(item('with_profile', '󰒓', 'Run with Profile…', #summary.profiles .. ' profiles available'))
    end

    -- ── Inspect ──────────────────────────────────────────────────────────────
    add(sep('Inspect'))
    add(item('dep_tree', '󰙅', 'Dependency Tree', 'mvn dependency:tree'))
    add(item('dep_analyze', '󰍉', 'Dependency Analysis', 'Find unused / undeclared deps'))
    add(item('dep_resolve', '󰚰', 'Resolve Deps', 'Download all dependencies'))
    add(item('effective_pom', '󰈙', 'Effective POM', 'Show resolved configuration'))
    add(item('effective_settings', '󰈙', 'Effective Settings', 'Show Maven settings'))
    add(item('help_describe', '󰅾', 'Describe Plugin', 'mvn help:describe'))

    -- ── Dependencies ─────────────────────────────────────────────────────────
    add(sep('Dependencies'))
    add(item('add_jackson', '󰘦', 'Add Jackson JSON', 'com.fasterxml.jackson'))
    add(item('add_lwjgl', '󰊗', 'Add LWJGL', 'OpenGL / Vulkan / GLFW'))
    add(item('add_spring', '󰋊', 'Add Spring Boot', 'spring-boot-starter'))
    add(item('add_lombok', '󰬷', 'Add Lombok', 'Annotation processor'))
    add(item('add_junit5', '󰙨', 'Add JUnit 5', 'org.junit.jupiter'))
    add(item('add_mockito', '󰙨', 'Add Mockito', 'Mocking framework'))
    add(item('check_updates', '󰦉', 'Check for Updates', 'Display newer versions'))
    add(item('purge_cache', '󰃢', 'Purge Local Cache', 'mvn dependency:purge-local-repository'))
    if not has_assembly() then
      add(item('add_assembly', '󰒓', 'Enable Fat JAR', 'Add maven-assembly-plugin'))
    end

    -- ── Configuration ────────────────────────────────────────────────────────
    add(sep('Configuration'))
    add(item('set_java_11', '󰬷', 'Java 11  (LTS)', 'Set compiler source/target'))
    add(item('set_java_17', '󰬷', 'Java 17  (LTS)', 'Set compiler source/target'))
    add(item('set_java_21', '󰬷', 'Java 21  (LTS)', 'Set compiler source/target'))
    add(item('set_java_custom', '󰬷', 'Custom Java Version', 'Enter a version number'))
    add(item('set_encoding', '󰉣', 'Set Encoding', 'Set project.build.sourceEncoding'))
    add(item('add_spotless', '󰉣', 'Add Spotless', 'Code formatter plugin'))
  end

  return items
end

-- ── Show ──────────────────────────────────────────────────────────────────────
function M.show()
  local project  = require('marvin.project')
  local in_maven = project.detect()
  local summary  = in_maven and get_summary() or nil

  local prompt
  if summary then
    prompt = 'Marvin  ' .. summary.group .. ':' .. summary.artifact
        .. '  v' .. summary.version
  else
    prompt = 'Marvin  (no Maven project)'
  end

  require('marvin.ui').select(M.build_menu(in_maven, summary), {
    prompt        = prompt,
    enable_search = true,
    format_item   = function(it)
      if it.is_separator then return it.label end
      return (it.icon and it.icon .. ' ' or '') .. it.label
    end,
  }, function(choice)
    if choice then M.handle_action(choice.id) end
  end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle_action(id)
  local ex = require('marvin.executor')
  local md = function() return require('marvin.dependencies') end

  -- Create
  if id == 'new_project' then
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
    M.prompt_java_version()
  elseif id == 'set_encoding' then
    M.prompt_encoding()
  elseif id == 'add_spotless' then
    md().add_spotless()
  end
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
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
    if fields then jc.create_file_interactive('Record', { fields = fields }, function() M.show() end) end
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

function M.show_profile_menu()
  local proj = require('marvin.project').get_project()
  local profiles = proj and proj.info and proj.info.profiles or {}
  if #profiles == 0 then
    vim.notify('No profiles found in pom.xml', vim.log.levels.INFO); return
  end
  local items = {}
  for _, pid in ipairs(profiles) do
    items[#items + 1] = { id = pid, label = pid, desc = 'Maven profile' }
  end

  -- Also offer which lifecycle goal to run with the profile
  require('marvin.ui').select({
      { id = 'compile', label = 'compile' },
      { id = 'test',    label = 'test' },
      { id = 'package', label = 'package' },
      { id = 'install', label = 'install' },
      { id = 'verify',  label = 'verify' },
    }, { prompt = 'Goal to run', format_item = function(it) return it.label end },
    function(goal_choice)
      if not goal_choice then return end
      require('marvin.ui').select(items, {
        prompt = 'Profile for: ' .. goal_choice.id,
        format_item = function(it) return it.label end,
      }, function(profile_choice)
        if profile_choice then
          require('marvin.executor').run(goal_choice.id, { profile = profile_choice.id })
        end
      end)
    end)
end

function M.prompt_java_version()
  require('marvin.ui').select({
    { version = '21', label = 'Java 21 (LTS)', desc = 'Virtual threads, pattern matching' },
    { version = '17', label = 'Java 17 (LTS)', desc = 'Sealed classes, records' },
    { version = '11', label = 'Java 11 (LTS)', desc = 'Widely adopted' },
    { version = '8', label = 'Java 8  (LTS)', desc = 'Maximum compatibility' },
    { version = '__custom__', label = 'Custom…', desc = 'Enter version number' },
  }, {
    prompt = 'Java Version',
    format_item = function(it) return it.label end,
  }, function(choice)
    if not choice then return end
    if choice.version == '__custom__' then
      vim.ui.input({ prompt = 'Java version: ' }, function(v)
        if v and v ~= '' then require('marvin.dependencies').set_java_version(v) end
      end)
    else
      require('marvin.dependencies').set_java_version(choice.version)
    end
  end)
end

function M.prompt_encoding()
  require('marvin.ui').select({
      { id = 'UTF-8',      label = 'UTF-8',      desc = 'Recommended' },
      { id = 'ISO-8859-1', label = 'ISO-8859-1', desc = 'Latin-1' },
      { id = 'US-ASCII',   label = 'US-ASCII',   desc = 'ASCII only' },
    }, { prompt = 'Source Encoding', format_item = function(it) return it.label end },
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
