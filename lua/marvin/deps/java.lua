-- lua/marvin/deps/java.lua
-- Java dependency management for Maven and Gradle projects.
-- Actions: list, add, remove, update, check outdated, audit (OWASP), analyze.

local M = {}

local function ui() return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function ex() return require('marvin.executor') end
local function plain(it) return it.label end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function is_maven()
  local p = det().get(); return p and p.type == 'maven'
end

local function read_pom(root)
  local f = io.open(root .. '/pom.xml', 'r')
  if not f then return nil end
  local c = f:read('*all'); f:close(); return c
end

local function write_pom(root, content)
  local f = io.open(root .. '/pom.xml', 'w')
  if not f then
    vim.notify('[Marvin] Cannot write pom.xml', vim.log.levels.ERROR); return false
  end
  f:write(content); f:close(); return true
end

-- ── Maven: XML manipulation ───────────────────────────────────────────────────
local function maven_dep_xml(group, artifact, version, scope)
  local lines = {
    '        <dependency>',
    '            <groupId>' .. group .. '</groupId>',
    '            <artifactId>' .. artifact .. '</artifactId>',
  }
  if version and version ~= '' then
    lines[#lines + 1] = '            <version>' .. version .. '</version>'
  end
  if scope and scope ~= 'compile' then
    lines[#lines + 1] = '            <scope>' .. scope .. '</scope>'
  end
  lines[#lines + 1] = '        </dependency>'
  return table.concat(lines, '\n')
end

local function maven_insert_dep(root, group, artifact, version, scope)
  local content = read_pom(root)
  if not content then return false end

  -- Check already present
  if content:find('<artifactId>' .. artifact .. '</artifactId>', 1, true) then
    vim.notify('[Marvin] ' .. artifact .. ' is already in pom.xml', vim.log.levels.WARN)
    return false
  end

  local xml = maven_dep_xml(group, artifact, version, scope)
  -- Insert before closing </dependencies>
  local new, n = content:gsub('(</dependencies>)', xml .. '\n    %1', 1)
  if n == 0 then
    -- No <dependencies> block at all — create one before </project>
    new = content:gsub('(</project>)',
      '    <dependencies>\n' .. xml .. '\n    </dependencies>\n%1', 1)
  end
  if write_pom(root, new) then
    det().reload()
    vim.notify('[Marvin] Added ' .. group .. ':' .. artifact, vim.log.levels.INFO)
    return true
  end
  return false
end

local function maven_remove_dep(root, artifact)
  local content = read_pom(root)
  if not content then return false end
  -- Remove the whole <dependency>…</dependency> block containing this artifactId
  local new, n = content:gsub(
    '\n%s*<dependency>%s*\n[^<]*<groupId>[^<]*</groupId>%s*\n[^<]*<artifactId>'
    .. vim.pesc(artifact)
    .. '</artifactId>[^<]*\n.-</dependency>',
    '', 1)
  if n == 0 then
    vim.notify('[Marvin] ' .. artifact .. ' not found in pom.xml', vim.log.levels.WARN)
    return false
  end
  if write_pom(root, new) then
    det().reload()
    vim.notify('[Marvin] Removed ' .. artifact, vim.log.levels.INFO)
    return true
  end
  return false
end

-- ── Gradle: delegate to `gradle dependencies` for display, `build.gradle` edit ─
-- For Gradle we shell out to `gradle` commands rather than editing the file,
-- because Gradle DSL is far less regular than XML.
local function gradle_cmd(root)
  if vim.fn.filereadable(root .. '/gradlew') == 1 then return './gradlew' end
  return 'gradle'
end

-- ── Known dependency catalogue ─────────────────────────────────────────────────
-- Used for the quick-add menu. Users can also type any coordinate manually.
local CATALOGUE = {
  -- Testing
  { group = 'org.junit.jupiter',          artifact = 'junit-jupiter',                version = '5.10.2',     scope = 'test',     label = 'JUnit 5',               desc = 'Unit testing framework' },
  { group = 'org.mockito',                artifact = 'mockito-core',                 version = '5.11.0',     scope = 'test',     label = 'Mockito',               desc = 'Mocking framework' },
  { group = 'org.assertj',                artifact = 'assertj-core',                 version = '3.25.3',     scope = 'test',     label = 'AssertJ',               desc = 'Fluent assertions' },
  -- Spring
  { group = 'org.springframework.boot',   artifact = 'spring-boot-starter',          version = nil,          scope = 'compile',  label = 'Spring Boot Starter',   desc = 'Spring Boot base' },
  { group = 'org.springframework.boot',   artifact = 'spring-boot-starter-web',      version = nil,          scope = 'compile',  label = 'Spring Web',            desc = 'REST + MVC' },
  { group = 'org.springframework.boot',   artifact = 'spring-boot-starter-data-jpa', version = nil,          scope = 'compile',  label = 'Spring Data JPA',       desc = 'JPA / Hibernate' },
  { group = 'org.springframework.boot',   artifact = 'spring-boot-starter-test',     version = nil,          scope = 'test',     label = 'Spring Test',           desc = 'Spring testing' },
  -- Utilities
  { group = 'org.projectlombok',          artifact = 'lombok',                       version = '1.18.32',    scope = 'provided', label = 'Lombok',                desc = 'Annotation processor' },
  { group = 'com.fasterxml.jackson.core', artifact = 'jackson-databind',             version = '2.17.0',     scope = 'compile',  label = 'Jackson',               desc = 'JSON serialisation' },
  { group = 'com.google.guava',           artifact = 'guava',                        version = '33.1.0-jre', scope = 'compile',  label = 'Guava',                 desc = 'Google core libraries' },
  { group = 'org.apache.commons',         artifact = 'commons-lang3',                version = '3.14.0',     scope = 'compile',  label = 'Commons Lang',          desc = 'String/number helpers' },
  -- Database
  { group = 'com.h2database',             artifact = 'h2',                           version = '2.2.224',    scope = 'runtime',  label = 'H2 Database',           desc = 'In-memory database' },
  { group = 'org.postgresql',             artifact = 'postgresql',                   version = '42.7.3',     scope = 'runtime',  label = 'PostgreSQL Driver',     desc = 'PostgreSQL JDBC' },
  -- Logging
  { group = 'ch.qos.logback',             artifact = 'logback-classic',              version = '1.5.3',      scope = 'compile',  label = 'Logback',               desc = 'Logging framework' },
  -- Security / OWASP
  { group = 'org.owasp',                  artifact = 'dependency-check-maven',       version = '9.1.0',      scope = 'provided', label = 'OWASP Dep-Check',       desc = 'Vulnerability scanner plugin' },
  -- Fat jar
  { group = 'org.apache.maven.plugins',   artifact = '__shade__',                    version = nil,          scope = 'provided', label = 'Maven Shade (fat jar)', desc = 'Uber-jar plugin with ServicesResourceTransformer' },
  -- OpenGL / games
  { group = 'org.lwjgl',                  artifact = 'lwjgl',                        version = '3.4.1',      scope = 'compile',  label = 'LWJGL Core',            desc = 'OpenGL / Vulkan / GLFW' },
  { group = 'org.lwjgl',                  artifact = 'lwjgl-glfw',                   version = '3.4.1',      scope = 'compile',  label = 'LWJGL GLFW',            desc = 'Window / input' },
  { group = 'org.lwjgl',                  artifact = 'lwjgl-opengl',                 version = '3.4.1',      scope = 'compile',  label = 'LWJGL OpenGL',          desc = 'OpenGL bindings' },
  { group = 'org.lwjgl',                  artifact = '__lwjgl_full__',               version = '3.4.1',      scope = 'compile',  label = 'LWJGL Full Suite',      desc = 'BOM + all modules + natives profiles + JOML + extras' },
}

-- ── Public API ────────────────────────────────────────────────────────────────

-- Dashboard menu items for the Deps section
function M.menu_items()
  local p     = det().get()
  local mvn   = p and p.type == 'maven'
  local grad  = p and p.type == 'gradle'

  local items = {}
  local function add(t) items[#items + 1] = t end
  local function sep(l) add({ label = l, is_separator = true }) end
  local function it(id, icon, label, desc) add({ id = id, label = icon .. ' ' .. label, desc = desc }) end

  sep('Dependencies')
  it('dep_list', '󰘦', 'View Dependencies', 'All declared dependencies')
  it('dep_add', '󰐕', 'Add Dependency…', 'Quick-add from catalogue or enter coords')
  it('dep_remove', '󰍴', 'Remove Dependency…', 'Remove from manifest')
  it('dep_outdated', '󰦉', 'Check for Updates',
    mvn and 'versions:display-dependency-updates' or 'gradle dependencyUpdates')
  it('dep_analyze', '󰍉', 'Analyze Dependencies', 'Find unused / undeclared')

  sep('Security')
  it('dep_audit', '󰒃', 'Vulnerability Audit', mvn and 'OWASP dependency-check' or 'gradle dependencyCheckAnalyze')
  if mvn and det().info() and not det().info().has_owasp then
    it('dep_add_owasp', '󰒃', 'Enable OWASP Plugin', 'Add dependency-check-maven to pom.xml')
  end

  if mvn then
    sep('Maven')
    it('dep_purge', '󰃢', 'Purge Local Cache', 'mvn dependency:purge-local-repository')
    it('dep_resolve', '󰚰', 'Resolve All', 'mvn dependency:resolve')
    it('dep_tree', '󰙅', 'Dependency Tree', 'mvn dependency:tree')
  end

  if grad then
    sep('Gradle')
    it('dep_gradle_refresh', '󰚰', 'Refresh Dependencies', './gradlew --refresh-dependencies')
    it('dep_tree', '󰙅', 'Dependency Report', './gradlew dependencies')
  end

  return items
end

function M.handle(id)
  local p = det().get()
  if not p then return end
  local root = p.root
  local mvn  = p.type == 'maven'
  local gcmd = gradle_cmd(root)

  if id == 'dep_list' then
    M.show_dep_list(p)
  elseif id == 'dep_add' then
    M.show_add_menu(p)
  elseif id == 'dep_remove' then
    M.show_remove_menu(p)
  elseif id == 'dep_outdated' then
    if mvn then
      ex().run('versions:display-dependency-updates')
    else
      ex().run_raw(gcmd .. ' dependencyUpdates', root, 'Dependency Updates')
    end
  elseif id == 'dep_analyze' then
    if mvn then
      ex().run('dependency:analyze')
    else
      ex().run_raw(gcmd .. ' dependencies', root, 'Dependency Report')
    end
  elseif id == 'dep_audit' then
    if mvn then
      if not (det().info() or {}).has_owasp then
        vim.notify('[Marvin] Add the OWASP plugin first (Enable OWASP Plugin)', vim.log.levels.WARN)
        return
      end
      ex().run('dependency-check:check')
    else
      ex().run_raw(gcmd .. ' dependencyCheckAnalyze', root, 'OWASP Audit')
    end
  elseif id == 'dep_add_owasp' then
    maven_insert_dep(root, 'org.owasp', 'dependency-check-maven', '9.1.0', 'provided')
  elseif id == 'dep_purge' then
    ex().run('dependency:purge-local-repository')
  elseif id == 'dep_resolve' then
    ex().run('dependency:resolve')
  elseif id == 'dep_tree' then
    if mvn then
      ex().run('dependency:tree')
    else
      ex().run_raw(gcmd .. ' dependencies', root, 'Dependency Tree')
    end
  elseif id == 'dep_gradle_refresh' then
    ex().run_raw(gcmd .. ' --refresh-dependencies', root, 'Refresh Dependencies')
  end
end

-- ── Dep list viewer ───────────────────────────────────────────────────────────
function M.show_dep_list(p)
  local info = p.info
  local deps = info and info.deps or {}
  if #deps == 0 then
    vim.notify('[Marvin] No dependencies found in manifest', vim.log.levels.INFO); return
  end

  local items = {}
  for _, d in ipairs(deps) do
    local coord = p.type == 'go_mod'
        and d.path .. ' @ ' .. d.version
        or d.group .. ':' .. d.artifact .. ' @ ' .. d.version
    local scope = d.scope or (d.dev and 'dev' or (d.indirect and 'indirect' or 'direct'))
    items[#items + 1] = {
      id    = 'dep__' .. (d.artifact or d.path or d.name or '?'),
      label = coord,
      desc  = scope,
    }
  end

  ui().select(items, {
    prompt        = 'Dependencies (' .. #deps .. ')',
    enable_search = true,
    format_item   = plain,
  }, function(_) end) -- read-only view for now
end

-- ── Add dep menu ──────────────────────────────────────────────────────────────
function M.show_add_menu(p)
  local cat_items = {}
  for _, d in ipairs(CATALOGUE) do
    cat_items[#cat_items + 1] = {
      id    = 'cat__' .. d.artifact,
      label = d.label,
      desc  = d.desc .. (d.version and (' — ' .. d.version) or ''),
      _dep  = d,
    }
  end
  cat_items[#cat_items + 1] = {
    id = '__manual__', label = '󰏫 Enter coordinates manually…', desc = 'groupId:artifactId:version'
  }

  ui().select(cat_items, {
    prompt        = 'Add Dependency',
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then return end
    if choice.id == '__manual__' then
      M.prompt_manual_dep(p)
    elseif choice.id == 'cat____lwjgl_full__' then
      M.add_lwjgl_full(p.root)
    elseif choice.id == 'cat____shade__' then
      M.add_maven_shade(p.root)
    else
      local d = choice._dep
      if p.type == 'maven' then
        maven_insert_dep(p.root, d.group, d.artifact, d.version, d.scope)
      else
        -- Gradle: prompt for confirmation then run
        ex().run_raw(
          gradle_cmd(p.root) .. ' addDependency ' .. d.group .. ':' .. d.artifact,
          p.root, 'Add ' .. d.artifact)
      end
    end
  end)
end

function M.prompt_manual_dep(p)
  ui().input({ prompt = 'groupId:artifactId:version (version optional)' }, function(coord)
    if not coord or coord == '' then return end
    local parts    = vim.split(coord, ':')
    local group    = parts[1]
    local artifact = parts[2]
    local version  = parts[3] or ''
    if not group or not artifact then
      vim.notify('[Marvin] Invalid format. Use groupId:artifactId[:version]', vim.log.levels.ERROR)
      return
    end
    if p.type == 'maven' then
      ui().select({
        { id = 'compile',  label = 'compile  (default)' },
        { id = 'test',     label = 'test' },
        { id = 'provided', label = 'provided' },
        { id = 'runtime',  label = 'runtime' },
      }, { prompt = 'Scope', format_item = plain }, function(scope)
        if not scope then return end
        maven_insert_dep(p.root, group, artifact, version, scope.id)
      end)
    else
      ex().run_raw(
        gradle_cmd(p.root) .. " dependencies --configuration implementation",
        p.root, 'Dependency Info')
    end
  end)
end

-- ── Remove dep menu ───────────────────────────────────────────────────────────
function M.show_remove_menu(p)
  local deps = (p.info and p.info.deps) or {}
  if #deps == 0 then
    vim.notify('[Marvin] No dependencies to remove', vim.log.levels.INFO); return
  end
  local items = {}
  for _, d in ipairs(deps) do
    local label = p.type == 'maven'
        and (d.group .. ':' .. d.artifact)
        or d.path or d.name or '?'
    items[#items + 1] = { id = d.artifact or d.path or d.name or '?', label = label, desc = d.version or '', _dep = d }
  end
  ui().select(items, {
    prompt        = 'Remove Dependency',
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then return end
    if p.type == 'maven' then
      maven_remove_dep(p.root, choice.id)
    else
      ui().input({ prompt = 'Remove from Gradle config (implementation/testImplementation/etc.)' }, function(cfg)
        if cfg then
          ex().run_raw(
            "sed -i '/" .. vim.pesc(choice.id) .. "/d' build.gradle",
            p.root, 'Remove ' .. choice.id)
        end
      end)
    end
  end)
end

-- ── LWJGL full-suite installer ────────────────────────────────────────────────
-- Mirrors the official LWJGL customizer output:
--   • OS-activated <profiles> that set ${lwjgl.natives}
--   • <properties> for lwjgl, joml, joml-primitives, lwjgl3-awt, steamworks4j versions
--   • BOM import in <dependencyManagement>
--   • All compile + classifier-based native entries for every LWJGL module
--   • Extra libraries: joml-primitives, lwjgl3-awt, steamworks4j
function M.add_lwjgl_full(root)
  root = root or det().root()
  if not root then return end

  local content = read_pom(root)
  if not content then
    vim.notify('[Marvin] No pom.xml found', vim.log.levels.ERROR); return
  end

  -- Guard: already present?
  if content:find('<artifactId>lwjgl%-bom</artifactId>', 1, true)
      or content:find('<artifactId>lwjgl</artifactId>', 1, true) then
    vim.notify('[Marvin] LWJGL already in pom.xml', vim.log.levels.WARN); return
  end

  -- ── Version constants ──────────────────────────────────────────────────────
  local LWJGL_VERSION       = '3.4.1'
  local JOML_VERSION        = '1.10.8'
  local JOML_PRIMITIVES_VER = '1.10.0'
  local LWJGL3_AWT_VER      = '0.2.3'
  local STEAMWORKS4J_VER    = '1.10.0'

  -- ── Helper: replace or add a <property> ───────────────────────────────────
  local function replace_or_add_prop(c, prop, val)
    local new, n = c:gsub('<' .. prop .. '>[^<]+</' .. prop .. '>',
      '<' .. prop .. '>' .. val .. '</' .. prop .. '>')
    if n > 0 then return new end
    return c:gsub('(<properties>)',
      '%1\n        <' .. prop .. '>' .. val .. '</' .. prop .. '>')
  end

  -- ── 1. Properties ──────────────────────────────────────────────────────────
  if not content:find('<properties>', 1, true) then
    content = content:gsub('(</project>)',
      '    <properties>\n    </properties>\n%1', 1)
  end
  content = replace_or_add_prop(content, 'lwjgl.version', LWJGL_VERSION)
  content = replace_or_add_prop(content, 'joml.version', JOML_VERSION)
  content = replace_or_add_prop(content, 'joml-primitives.version', JOML_PRIMITIVES_VER)
  content = replace_or_add_prop(content, 'lwjgl3-awt.version', LWJGL3_AWT_VER)
  content = replace_or_add_prop(content, 'steamworks4j.version', STEAMWORKS4J_VER)

  -- ── 2. OS-activated profiles (set ${lwjgl.natives}) ────────────────────────
  local profiles_xml = [[
    <profiles>
        <profile>
            <id>lwjgl-natives-linux-amd64</id>
            <activation>
                <os>
                    <family>unix</family>
                    <name>linux</name>
                    <arch>amd64</arch>
                </os>
            </activation>
            <properties>
                <lwjgl.natives>natives-linux</lwjgl.natives>
            </properties>
        </profile>
        <profile>
            <id>lwjgl-natives-windows-amd64</id>
            <activation>
                <os>
                    <family>windows</family>
                    <arch>amd64</arch>
                </os>
            </activation>
            <properties>
                <lwjgl.natives>natives-windows</lwjgl.natives>
            </properties>
        </profile>
        <profile>
            <id>lwjgl-natives-windows-x86</id>
            <activation>
                <os>
                    <family>windows</family>
                    <arch>x86</arch>
                </os>
            </activation>
            <properties>
                <lwjgl.natives>natives-windows-x86</lwjgl.natives>
            </properties>
        </profile>
    </profiles>]]

  if not content:find('<profiles>', 1, true) then
    content = content:gsub('(</project>)', profiles_xml .. '\n%1', 1)
  end

  -- ── 3. BOM in <dependencyManagement> ───────────────────────────────────────
  local bom_xml = table.concat({
    '        <dependency>',
    '            <groupId>org.lwjgl</groupId>',
    '            <artifactId>lwjgl-bom</artifactId>',
    '            <version>${lwjgl.version}</version>',
    '            <scope>import</scope>',
    '            <type>pom</type>',
    '        </dependency>',
  }, '\n')

  if content:find('<dependencyManagement>', 1, true) then
    content = content:gsub(
      '(<dependencyManagement>.-</dependencies>)',
      function(block)
        return block:gsub('(</dependencies>)', bom_xml .. '\n    %1', 1)
      end, 1)
  else
    content = content:gsub('(</project>)',
      '    <dependencyManagement>\n'
      .. '        <dependencies>\n'
      .. bom_xml .. '\n'
      .. '        </dependencies>\n'
      .. '    </dependencyManagement>\n%1', 1)
  end

  -- ── 4. Module lists ────────────────────────────────────────────────────────
  -- All modules managed by the BOM (no version needed on compile entries).
  -- Classifier (native) entries also use ${lwjgl.natives} so the active profile
  -- selects the right artifact at build time.
  local BOM_MODULES    = {
    'lwjgl', 'lwjgl-assimp', 'lwjgl-bgfx', 'lwjgl-egl', 'lwjgl-fmod',
    'lwjgl-freetype', 'lwjgl-glfw', 'lwjgl-harfbuzz', 'lwjgl-hwloc',
    'lwjgl-jawt', 'lwjgl-jemalloc', 'lwjgl-ktx', 'lwjgl-llvm', 'lwjgl-lmdb',
    'lwjgl-lz4', 'lwjgl-meshoptimizer', 'lwjgl-msdfgen', 'lwjgl-nanovg',
    'lwjgl-nfd', 'lwjgl-nuklear', 'lwjgl-odbc', 'lwjgl-openal', 'lwjgl-opencl',
    'lwjgl-opengl', 'lwjgl-opengles', 'lwjgl-openxr', 'lwjgl-opus', 'lwjgl-par',
    'lwjgl-remotery', 'lwjgl-renderdoc', 'lwjgl-rpmalloc', 'lwjgl-sdl',
    'lwjgl-shaderc', 'lwjgl-spng', 'lwjgl-spvc', 'lwjgl-stb', 'lwjgl-tinyexr',
    'lwjgl-tinyfd', 'lwjgl-vma', 'lwjgl-vulkan', 'lwjgl-xxhash', 'lwjgl-yoga',
    'lwjgl-zstd',
  }

  -- Modules that ship native libraries (header-only / pure-Java ones excluded:
  -- egl, fmod, jawt, odbc, opencl, renderdoc, vulkan).
  -- Each gets explicit entries for EVERY target platform so the fat jar contains
  -- all natives regardless of which OS the build runs on.
  local NATIVE_MODULES = {
    'lwjgl', 'lwjgl-assimp', 'lwjgl-bgfx', 'lwjgl-freetype', 'lwjgl-glfw',
    'lwjgl-harfbuzz', 'lwjgl-hwloc', 'lwjgl-jemalloc', 'lwjgl-ktx', 'lwjgl-llvm',
    'lwjgl-lmdb', 'lwjgl-lz4', 'lwjgl-meshoptimizer', 'lwjgl-msdfgen',
    'lwjgl-nanovg', 'lwjgl-nfd', 'lwjgl-nuklear', 'lwjgl-openal', 'lwjgl-opengl',
    'lwjgl-opengles', 'lwjgl-openxr', 'lwjgl-opus', 'lwjgl-par', 'lwjgl-remotery',
    'lwjgl-rpmalloc', 'lwjgl-sdl', 'lwjgl-shaderc', 'lwjgl-spng', 'lwjgl-spvc',
    'lwjgl-stb', 'lwjgl-tinyexr', 'lwjgl-tinyfd', 'lwjgl-vma', 'lwjgl-xxhash',
    'lwjgl-yoga', 'lwjgl-zstd',
  }

  -- Per-module natives matrix. Not every module ships every platform classifier —
  -- missing ones simply don't exist in the LWJGL Maven repo and will error.
  -- Source of truth: https://repo1.maven.org/maven2/org/lwjgl/
  local WIN            = { 'natives-windows', 'natives-windows-x86', 'natives-windows-arm64' }
  local WIN_NO_ARM     = { 'natives-windows', 'natives-windows-x86' } -- bgfx, ktx
  local LIN            = { 'natives-linux', 'natives-linux-arm64', 'natives-linux-arm32' }
  local LIN_NO_ARM32   = { 'natives-linux', 'natives-linux-arm64' }
  local ALL_WIN_LIN    = {
    'natives-linux', 'natives-linux-arm64', 'natives-linux-arm32',
    'natives-windows', 'natives-windows-x86', 'natives-windows-arm64',
  }

  -- { artifact, { classifiers... } }
  local NATIVE_MATRIX  = {
    { 'lwjgl',               ALL_WIN_LIN },
    { 'lwjgl-assimp',        ALL_WIN_LIN },
    { 'lwjgl-bgfx',          { 'natives-linux', 'natives-linux-arm64', 'natives-linux-arm32', 'natives-windows', 'natives-windows-x86' } }, -- no windows-arm64
    { 'lwjgl-freetype',      ALL_WIN_LIN },
    { 'lwjgl-glfw',          ALL_WIN_LIN },
    { 'lwjgl-harfbuzz',      ALL_WIN_LIN },
    { 'lwjgl-hwloc',         ALL_WIN_LIN },
    { 'lwjgl-jemalloc',      ALL_WIN_LIN },
    { 'lwjgl-ktx',           { 'natives-linux', 'natives-linux-arm64', 'natives-windows' } }, -- no x86, no arm64-win, no arm32-lin
    { 'lwjgl-llvm',          { 'natives-linux', 'natives-windows' } },
    { 'lwjgl-lmdb',          ALL_WIN_LIN },
    { 'lwjgl-lz4',           ALL_WIN_LIN },
    { 'lwjgl-meshoptimizer', ALL_WIN_LIN },
    { 'lwjgl-msdfgen',       ALL_WIN_LIN },
    { 'lwjgl-nanovg',        ALL_WIN_LIN },
    { 'lwjgl-nfd',           ALL_WIN_LIN },
    { 'lwjgl-nuklear',       ALL_WIN_LIN },
    { 'lwjgl-openal',        ALL_WIN_LIN },
    { 'lwjgl-opengl',        ALL_WIN_LIN },
    { 'lwjgl-opengles',      ALL_WIN_LIN },
    { 'lwjgl-openxr',        { 'natives-linux', 'natives-windows' } },
    { 'lwjgl-opus',          ALL_WIN_LIN },
    { 'lwjgl-par',           ALL_WIN_LIN },
    { 'lwjgl-remotery',      { 'natives-linux', 'natives-windows' } }, -- no arm variants
    { 'lwjgl-rpmalloc',      ALL_WIN_LIN },
    { 'lwjgl-sdl',           ALL_WIN_LIN },
    { 'lwjgl-shaderc',       { 'natives-linux', 'natives-linux-arm64', 'natives-windows', 'natives-windows-arm64' } },
    { 'lwjgl-spng',          ALL_WIN_LIN },
    { 'lwjgl-spvc',          { 'natives-linux', 'natives-linux-arm64', 'natives-windows', 'natives-windows-arm64' } },
    { 'lwjgl-stb',           ALL_WIN_LIN },
    { 'lwjgl-tinyexr',       ALL_WIN_LIN },
    { 'lwjgl-tinyfd',        ALL_WIN_LIN },
    { 'lwjgl-vma',           ALL_WIN_LIN },
    { 'lwjgl-xxhash',        ALL_WIN_LIN },
    { 'lwjgl-yoga',          ALL_WIN_LIN },
    { 'lwjgl-zstd',          ALL_WIN_LIN },
  }

  -- ── 5. Build the full <dependencies> block ─────────────────────────────────
  local dep_parts      = { '\n        <!-- LWJGL ' .. LWJGL_VERSION .. ' -->' }

  -- Compile entries (BOM resolves version)
  for _, mod in ipairs(BOM_MODULES) do
    dep_parts[#dep_parts + 1] = table.concat({
      '        <dependency>',
      '            <groupId>org.lwjgl</groupId>',
      '            <artifactId>' .. mod .. '</artifactId>',
      '        </dependency>',
    }, '\n')
  end

  -- Native classifier entries — explicit version required (BOM doesn't cover classifier artifacts).
  for _, entry in ipairs(NATIVE_MATRIX) do
    local mod, classifiers = entry[1], entry[2]
    for _, cls in ipairs(classifiers) do
      dep_parts[#dep_parts + 1] = table.concat({
        '        <dependency>',
        '            <groupId>org.lwjgl</groupId>',
        '            <artifactId>' .. mod .. '</artifactId>',
        '            <version>${lwjgl.version}</version>',
        '            <classifier>' .. cls .. '</classifier>',
        '            <scope>runtime</scope>',
        '        </dependency>',
      }, '\n')
    end
  end

  -- JOML
  dep_parts[#dep_parts + 1] = table.concat({
    '        <!-- JOML -->',
    '        <dependency>',
    '            <groupId>org.joml</groupId>',
    '            <artifactId>joml</artifactId>',
    '            <version>${joml.version}</version>',
    '        </dependency>',
  }, '\n')

  -- JOML Primitives
  dep_parts[#dep_parts + 1] = table.concat({
    '        <dependency>',
    '            <groupId>org.joml</groupId>',
    '            <artifactId>joml-primitives</artifactId>',
    '            <version>${joml-primitives.version}</version>',
    '        </dependency>',
  }, '\n')

  -- lwjgl3-awt
  dep_parts[#dep_parts + 1] = table.concat({
    '        <!-- LWJGL extras -->',
    '        <dependency>',
    '            <groupId>org.lwjglx</groupId>',
    '            <artifactId>lwjgl3-awt</artifactId>',
    '            <version>${lwjgl3-awt.version}</version>',
    '        </dependency>',
  }, '\n')

  -- steamworks4j
  dep_parts[#dep_parts + 1] = table.concat({
    '        <dependency>',
    '            <groupId>com.code-disaster.steamworks4j</groupId>',
    '            <artifactId>steamworks4j</artifactId>',
    '            <version>${steamworks4j.version}</version>',
    '        </dependency>',
  }, '\n')

  local all_deps = table.concat(dep_parts, '\n')

  -- Insert into the main <dependencies> block (the last one before </project>)
  local inserted = false
  content = content:gsub('(</dependencies>%s*\n?%s*</project>)', function(tail)
    inserted = true
    return all_deps .. '\n    ' .. tail
  end, 1)

  if not inserted then
    content = content:gsub('(</project>)',
      '    <dependencies>\n' .. all_deps .. '\n    </dependencies>\n%1', 1)
  end

  -- ── 6. Write & report ──────────────────────────────────────────────────────
  if write_pom(root, content) then
    det().reload()
    vim.notify(
      '[Marvin] ✅ LWJGL ' .. LWJGL_VERSION
      .. ' full suite added ('
      .. #BOM_MODULES .. ' modules + natives via profile + JOML + joml-primitives + lwjgl3-awt + steamworks4j)',
      vim.log.levels.INFO)
  end
end

-- ── Maven Shade plugin installer ──────────────────────────────────────────────
-- Adds maven-shade-plugin to <build><plugins> with:
--   • ServicesResourceTransformer   (merges META-INF/services — needed by LWJGL)
--   • ManifestResourceTransformer   (sets Main-Class if the user provides one)
--   • shade bound to the package phase
function M.add_maven_shade(root)
  root = root or det().root()
  if not root then return end

  local content = read_pom(root)
  if not content then
    vim.notify('[Marvin] No pom.xml found', vim.log.levels.ERROR); return
  end

  if content:find('<artifactId>maven%-shade%-plugin</artifactId>', 1, true) then
    vim.notify('[Marvin] maven-shade-plugin already in pom.xml', vim.log.levels.WARN); return
  end

  -- Ask for Main-Class (optional)
  ui().input({ prompt = 'Main-Class (leave blank to skip)' }, function(main_class)
    local manifest_block = ''
    if main_class and main_class ~= '' then
      manifest_block = table.concat({
        '                            <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">',
        '                                <mainClass>' .. main_class .. '</mainClass>',
        '                            </transformer>',
      }, '\n') .. '\n'
    end

    local plugin_xml = table.concat({
      '            <plugin>',
      '                <groupId>org.apache.maven.plugins</groupId>',
      '                <artifactId>maven-shade-plugin</artifactId>',
      '                <version>3.6.0</version>',
      '                <executions>',
      '                    <execution>',
      '                        <phase>package</phase>',
      '                        <goals><goal>shade</goal></goals>',
      '                        <configuration>',
      '                            <createDependencyReducedPom>false</createDependencyReducedPom>',
      '                            <transformers>',
      '                                <transformer implementation="org.apache.maven.plugins.shade.resource.ServicesResourceTransformer"/>',
      manifest_block ~= '' and manifest_block or '',
      '                            </transformers>',
      '                        </configuration>',
      '                    </execution>',
      '                </executions>',
      '            </plugin>',
    }, '\n')

    -- Insert into <build><plugins> if it exists, otherwise create the block
    local new, n = content:gsub('(<build>%s*<plugins>)', '%1\n' .. plugin_xml)
    if n == 0 then
      -- Try <build> without <plugins>
      new, n = content:gsub('(<build>)', '%1\n            <plugins>\n' .. plugin_xml .. '\n            </plugins>')
    end
    if n == 0 then
      -- No <build> at all — create it before </project>
      new = content:gsub('(</project>)',
        '    <build>\n        <plugins>\n' .. plugin_xml .. '\n        </plugins>\n    </build>\n%1', 1)
    end

    if write_pom(root, new) then
      det().reload()
      vim.notify('[Marvin] ✅ maven-shade-plugin 3.6.0 added (bound to package phase)', vim.log.levels.INFO)
    end
  end)
end

-- ── Convenience functions (called from lang/java.lua) ─────────────────────────
function M.set_java_version(ver, root)
  root = root or det().root()
  if not root then return end
  local content = read_pom(root)
  if not content then return end

  local function replace_or_add_prop(c, prop, val)
    local new, n = c:gsub('<' .. prop .. '>[^<]+</' .. prop .. '>', '<' .. prop .. '>' .. val .. '</' .. prop .. '>')
    if n > 0 then return new end
    -- Add to <properties>
    return c:gsub('(<properties>)', '%1\n        <' .. prop .. '>' .. val .. '</' .. prop .. '>')
  end

  local new = replace_or_add_prop(content, 'maven.compiler.source', ver)
  new = replace_or_add_prop(new, 'maven.compiler.target', ver)
  new = replace_or_add_prop(new, 'java.version', ver)
  write_pom(root, new)
  vim.notify('[Marvin] Java version → ' .. ver, vim.log.levels.INFO)
end

function M.set_encoding(enc, root)
  root = root or det().root()
  if not root then return end
  local content = read_pom(root)
  if not content then return end
  local new, n = content:gsub('<project%.build%.sourceEncoding>[^<]+</project%.build%.sourceEncoding>',
    '<project.build.sourceEncoding>' .. enc .. '</project.build.sourceEncoding>')
  if n == 0 then
    new = content:gsub('(<properties>)',
      '%1\n        <project.build.sourceEncoding>' .. enc .. '</project.build.sourceEncoding>')
  end
  write_pom(root, new)
  vim.notify('[Marvin] Encoding → ' .. enc, vim.log.levels.INFO)
end

function M.add_spotless(root)
  root = root or det().root()
  maven_insert_dep(root, 'com.diffplug.spotless', 'spotless-maven-plugin', '2.43.0', 'provided')
end

return M
