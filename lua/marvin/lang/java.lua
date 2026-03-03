-- lua/marvin/lang/java.lua
-- Java language module for the Marvin unified dashboard.
-- Contributes menu sections for Maven and Gradle projects.

local M = {}

local function plain(it) return it.label end
local function det() return require('marvin.detector') end
local function ui() return require('marvin.ui') end
local function ex() return require('marvin.executor') end
local function deps() return require('marvin.deps.java') end
local function jc() return require('marvin.creator.java') end

local function sep(l) return { label = l, is_separator = true } end
local function item(id, i, l, d) return { id = id, _icon = i, label = l, desc = d } end
local function sub(id, i, l, d) return { id = id, label = i .. ' ' .. l, desc = d } end

-- ── Project header info ───────────────────────────────────────────────────────
function M.prompt_header(p)
  local info = p.info or {}
  if p.type == 'maven' then
    return string.format('%s:%s  v%s  [%s]',
      info.group_id or '?',
      info.artifact_id or '?',
      info.version or '?',
      info.packaging or 'jar')
  elseif p.type == 'gradle' then
    return string.format('%s  [Gradle%s]',
      info.name or p.name,
      info.has_wrapper and '+wrapper' or '')
  end
  return p.name
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end
  local info = p.info or {}
  local mvn  = p.type == 'maven'
  local tool = mvn and 'Maven' or 'Gradle'

  -- Create
  add(sep('Create'))
  add(item('new_file_menu', '󰬷', 'New Java File…', 'Class, Interface, Record, Enum, Builder…'))
  add(item('new_test', '󰙨', 'New JUnit Test', 'JUnit 5 test class'))
  if mvn then
    add(item('new_project', '󰏗', 'New Maven Project', 'Generate from archetype'))
  end

  -- Build / Lifecycle
  add(sep(tool .. ' Lifecycle'))
  add(item('compile', '󰑕', 'Compile', mvn and 'mvn compile' or './gradlew compileJava'))
  add(item('test', '󰙨', 'Test', mvn and 'mvn test' or './gradlew test'))
  add(item('package', '󰏗', 'Package', mvn and ('Build ' .. (info.artifact_id or '?') .. '.jar') or './gradlew jar'))
  add(item('build_opts', '󰒓', 'Build Options…', 'Skip tests, profiles, fat JAR'))
  add(item('clean', '󰃢', 'Clean', mvn and 'mvn clean' or './gradlew clean'))

  -- Submenus
  add(sep('Tools'))
  add(item('inspect_menu', '󰙅', 'Inspect…', 'Dep tree, effective POM, plugin help'))
  add(item('deps_menu', '󰘦', 'Dependencies…', 'Add, remove, audit, update'))
  add(item('graal_menu', '󰂮', 'GraalVM…', 'Native image, agent, info'))
  add(item('settings_menu', '󰒓', 'Settings…', 'Java version, encoding, formatter'))

  return items
end

-- ── Submenu: Dependencies ─────────────────────────────────────────────────────
function M.show_deps_menu(p, back)
  local items = {}
  for _, di in ipairs(deps().menu_items()) do items[#items + 1] = di end
  ui().select(items, { prompt = 'Dependencies', on_back = back, format_item = plain },
    function(ch) if ch then deps().handle(ch.id) end end)
end

-- ── Submenu: GraalVM ──────────────────────────────────────────────────────────
function M.show_graal_menu(p, back)
  local items = {
    { id = 'graal_build', label = '󰂮 Build Native Image', desc = 'Compile to native binary' },
    { id = 'graal_run', label = '󰐊 Run Native Binary', desc = 'Execute the native build' },
    { id = 'graal_agent', label = '󰋊 Run with Agent', desc = 'Collect reflection config' },
    { id = 'graal_info', label = '󰙅 GraalVM Info', desc = 'Status and install guide' },
  }
  ui().select(items, { prompt = 'GraalVM', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Settings ─────────────────────────────────────────────────────────
function M.show_settings_menu(p, back)
  local mvn = p.type == 'maven'
  local items = {
    { id = 'java_version', label = '󰬷 Set Java Version…', desc = 'maven.compiler.source / target' },
    { id = 'set_encoding', label = '󰉣 Set Encoding…', desc = 'project.build.sourceEncoding' },
  }
  if mvn then
    items[#items + 1] = { id = 'add_spotless', label = '󰉣 Add Spotless', desc = 'Code formatter plugin' }
  end
  ui().select(items, { prompt = 'Project Settings', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle(id, p, back)
  local info = p.info or {}
  local mvn  = p.type == 'maven'

  -- Sub-menu dispatchers
  if id == 'new_file_menu' then
    jc().show_menu(back)
  elseif id == 'new_test' then
    jc().create_file_interactive('Test', {}, back)
  elseif id == 'new_project' then
    require('marvin.generator').create_project()
  elseif id == 'deps_menu' then
    M.show_deps_menu(p, back)
  elseif id == 'graal_menu' then
    M.show_graal_menu(p, back)
  elseif id == 'settings_menu' then
    M.show_settings_menu(p, back)

    -- Lifecycle
  elseif id == 'compile' then
    if mvn then ex().run('compile') else M._gradle('compileJava', p) end
  elseif id == 'test' then
    if mvn then ex().run('test') else M._gradle('test', p) end
  elseif id == 'package' then
    if mvn then ex().run('package') else M._gradle('jar', p) end
  elseif id == 'clean' then
    if mvn then ex().run('clean') else M._gradle('clean', p) end
  elseif id == 'build_opts' then
    M.show_build_opts(p, back)
    -- Inspect
  elseif id == 'inspect_menu' then
    M.show_inspect_menu(p, back)
  elseif id == 'dep_tree' then
    if mvn then ex().run('dependency:tree') else M._gradle('dependencies', p) end
  elseif id == 'dep_analyze' then
    if mvn then ex().run('dependency:analyze') else M._gradle('dependencyInsight', p) end
  elseif id == 'dep_resolve' then
    if mvn then ex().run('dependency:resolve') else M._gradle('dependencies', p) end
  elseif id == 'effective_pom' then
    ex().run('help:effective-pom')
  elseif id == 'effective_settings' then
    ex().run('help:effective-settings')
  elseif id == 'help_describe' then
    M.prompt_describe()

    -- Deps (delegated)
  elseif id:match('^dep_') or id:match('^ws_') then
    deps().handle(id)

    -- GraalVM
  elseif id == 'graal_build' then
    require('marvin.graalvm').build_native(p)
  elseif id == 'graal_run' then
    require('marvin.graalvm').run_native(p)
  elseif id == 'graal_agent' then
    require('marvin.graalvm').run_with_agent(p)
  elseif id == 'graal_info' then
    require('marvin.graalvm').show_info()

    -- Settings
  elseif id == 'java_version' then
    M.prompt_java_version(p)
  elseif id == 'set_encoding' then
    M.prompt_encoding(p)
  elseif id == 'add_spotless' then
    deps().add_spotless(p.root)
  end
end

-- ── Build options sub-menu ────────────────────────────────────────────────────
function M.show_build_opts(p, back)
  local mvn   = p.type == 'maven'
  local info  = p.info or {}
  local items = {
    sub('clean_install', '󰑓', 'Clean & Install', mvn and 'mvn clean install' or './gradlew clean build'),
    sub('install', '󰇚', 'Install', mvn and 'mvn install' or './gradlew publishToMavenLocal'),
    sub('verify', '󰄬', 'Verify', mvn and 'mvn verify' or './gradlew check'),
    sub('skip_tests', '󰒭', 'Build (skip tests)', mvn and '-DskipTests' or '-x test'),
  }
  if mvn and info.has_assembly then
    items[#items + 1] = sub('package_fat', '󱊞', 'Package Fat JAR', 'assembly:single')
  end
  if mvn and info.profiles and #info.profiles > 0 then
    items[#items + 1] = sub('with_profile', '󰒓', 'Run with Profile…',
      #info.profiles .. ' profiles available')
  end

  ui().select(items, { prompt = 'Build Options', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Inspect sub-menu ──────────────────────────────────────────────────────────
function M.show_inspect_menu(p, back)
  local mvn = p.type == 'maven'
  local items = {
    sub('dep_tree', '󰙅', 'Dependency Tree', mvn and 'mvn dependency:tree' or 'gradle dependencies'),
    sub('dep_analyze', '󰍉', 'Dependency Analysis', 'Find unused / undeclared'),
    sub('dep_resolve', '󰚰', 'Resolve Deps', 'Download all dependencies'),
  }
  if mvn then
    items[#items + 1] = sub('effective_pom', '󰈙', 'Effective POM', 'Resolved configuration')
    items[#items + 1] = sub('effective_settings', '󰈙', 'Effective Settings', 'Maven settings')
    items[#items + 1] = sub('help_describe', '󰅾', 'Describe Plugin', 'mvn help:describe')
  end

  ui().select(items, { prompt = 'Inspect', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Profile picker ────────────────────────────────────────────────────────────
function M.show_profile_menu(p, back)
  local profiles = (p.info and p.info.profiles) or {}
  if #profiles == 0 then
    vim.notify('[Marvin] No profiles in pom.xml', vim.log.levels.INFO); return
  end
  local prof_items = {}
  for _, pid in ipairs(profiles) do
    prof_items[#prof_items + 1] = { id = pid, label = pid, desc = 'Maven profile' }
  end
  local goals = {
    { id = 'compile', label = 'compile' }, { id = 'test', label = 'test' },
    { id = 'package', label = 'package' }, { id = 'install', label = 'install' },
    { id = 'verify', label = 'verify' },
  }
  ui().select(goals, { prompt = 'Goal to run', on_back = back, format_item = plain },
    function(goal)
      if not goal then return end
      ui().select(prof_items, { prompt = 'Profile for: ' .. goal.id, format_item = plain },
        function(prof)
          if prof then ex().run(goal.id, { profile = prof.id }) end
        end)
    end)
end

-- ── Prompts ───────────────────────────────────────────────────────────────────
function M.prompt_java_version(p)
  ui().select({
    { version = '21', label = 'Java 21 (LTS)', desc = 'Virtual threads, pattern matching' },
    { version = '17', label = 'Java 17 (LTS)', desc = 'Sealed classes, records' },
    { version = '11', label = 'Java 11 (LTS)', desc = 'Widely adopted' },
    { version = '8', label = 'Java 8  (LTS)', desc = 'Maximum compatibility' },
    { version = '__custom__', label = 'Custom…' },
  }, { prompt = 'Java Version', format_item = plain }, function(ch)
    if not ch then return end
    if ch.version == '__custom__' then
      ui().input({ prompt = 'Java version' }, function(v)
        if v and v ~= '' then deps().set_java_version(v, p.root) end
      end)
    else
      deps().set_java_version(ch.version, p.root)
    end
  end)
end

function M.prompt_encoding(p)
  ui().select({
    { id = 'UTF-8',      label = 'UTF-8',      desc = 'Recommended' },
    { id = 'ISO-8859-1', label = 'ISO-8859-1', desc = 'Latin-1' },
    { id = 'US-ASCII',   label = 'US-ASCII',   desc = 'ASCII only' },
  }, { prompt = 'Source Encoding', format_item = plain }, function(ch)
    if ch then deps().set_encoding(ch.id, p.root) end
  end)
end

function M.prompt_describe()
  vim.ui.input({ prompt = 'Plugin (e.g. maven-compiler-plugin): ' }, function(plugin)
    if plugin and plugin ~= '' then
      ex().run('help:describe -Dplugin=' .. plugin)
    end
  end)
end

-- ── Internal ──────────────────────────────────────────────────────────────────
function M._gradle(task, p)
  local gcmd = vim.fn.filereadable(p.root .. '/gradlew') == 1 and './gradlew' or 'gradle'
  require('core.runner').execute({
    cmd      = gcmd .. ' ' .. task,
    cwd      = p.root,
    title    = 'Gradle ' .. task,
    term_cfg = require('marvin').config.terminal,
    plugin   = 'marvin',
  })
end

return M
