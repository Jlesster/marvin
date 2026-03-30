-- lua/marvin/dependencies.lua
-- All pom.xml manipulation: adding deps, plugins, setting properties.

local M = {}

-- ── POM I/O ───────────────────────────────────────────────────────────────────
local function pom_path() return vim.fn.getcwd() .. '/pom.xml' end

local function read_pom()
  local p = pom_path()
  if vim.fn.filereadable(p) == 0 then return nil, 'No pom.xml in current directory' end
  return vim.fn.readfile(p), nil
end

local function write_pom(lines)
  vim.fn.writefile(lines, pom_path())
end

local function notify(msg, level)
  require('marvin.ui').notify(msg, level)
end

-- ── XML helpers ───────────────────────────────────────────────────────────────
local function find_tag(lines, open, close)
  for i, line in ipairs(lines) do
    if line:match(open) then
      for j = i + 1, #lines do
        if lines[j]:match(close) then return i, j end
      end
    end
  end
  return nil, nil
end

local function ensure_section(lines, open_pat, close_pat, insert_before_pat, indent, open_tag, close_tag)
  local s, e = find_tag(lines, open_pat, close_pat)
  if s then return lines, s, e end
  for i = #lines, 1, -1 do
    if lines[i]:match(insert_before_pat) then
      table.insert(lines, i, indent .. close_tag)
      table.insert(lines, i, indent .. open_tag)
      table.insert(lines, i, '')
      return lines, i + 1, i + 2
    end
  end
  return lines, nil, nil
end

local function insert_before(lines, idx, new_lines)
  for i = #new_lines, 1, -1 do
    table.insert(lines, idx, new_lines[i])
  end
end

-- ── Properties ────────────────────────────────────────────────────────────────
local function ensure_properties(lines)
  return ensure_section(lines,
    '<%s*properties%s*>', '<%s*/properties%s*>',
    '<%s*/project%s*>', '  ', '<properties>', '</properties>')
end

local function set_property(lines, key, value)
  lines, s, e = ensure_properties(lines)
  if not s then return lines, false end
  local tag_o = '<' .. key .. '>'
  local tag_c = '</' .. key .. '>'
  for i = s + 1, e - 1 do
    if lines[i]:match(vim.pesc(tag_o)) then
      lines[i] = '    ' .. tag_o .. value .. tag_c
      return lines, true
    end
  end
  table.insert(lines, e, '    ' .. tag_o .. value .. tag_c)
  return lines, true
end

-- ── Dependencies section ──────────────────────────────────────────────────────
local function ensure_deps(lines)
  -- Skip dependencyManagement's <dependencies>
  local in_mgmt = false
  for i, line in ipairs(lines) do
    if line:match('<%s*dependencyManagement%s*>') then in_mgmt = true end
    if line:match('<%s*/dependencyManagement%s*>') then in_mgmt = false end
    if not in_mgmt and line:match('<%s*dependencies%s*>') then
      for j = i + 1, #lines do
        if lines[j]:match('<%s*/dependencies%s*>') then return lines, i, j end
      end
    end
  end
  return ensure_section(lines,
    '<%s*dependencies%s*>', '<%s*/dependencies%s*>',
    '<%s*/project%s*>', '  ', '<dependencies>', '</dependencies>')
end

local function add_deps(lines, dep_lines)
  lines, s, e = ensure_deps(lines)
  if not s then return lines, false end
  insert_before(lines, e, dep_lines)
  return lines, true
end

-- ── Dependency check helper ───────────────────────────────────────────────────
local function already_has(lines, artifact_id)
  local content = table.concat(lines, '\n')
  return content:match('<artifactId>%s*' .. vim.pesc(artifact_id) .. '%s*</artifactId>') ~= nil
end

-- ── Build plugins section ─────────────────────────────────────────────────────
local function ensure_build_plugins(lines)
  lines, bs, be = ensure_section(lines,
    '<%s*build%s*>', '<%s*/build%s*>',
    '<%s*/project%s*>', '  ', '<build>', '</build>')
  if not bs then return lines, nil, nil end
  return ensure_section(lines,
    '<%s*plugins%s*>', '<%s*/plugins%s*>',
    '<%s*/build%s*>', '    ', '<plugins>', '</plugins>')
end

-- ── Public: add dependencies ─────────────────────────────────────────────────
function M.add_jackson()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if already_has(lines, 'jackson-databind') then
    notify('Jackson already in pom.xml', vim.log.levels.WARN); return
  end
  lines, ok = add_deps(lines, {
    '',
    '    <!-- Jackson JSON -->',
    '    <dependency>',
    '      <groupId>com.fasterxml.jackson.core</groupId>',
    '      <artifactId>jackson-databind</artifactId>',
    '      <version>2.18.2</version>',
    '    </dependency>',
    '    <dependency>',
    '      <groupId>com.fasterxml.jackson.core</groupId>',
    '      <artifactId>jackson-core</artifactId>',
    '      <version>2.18.2</version>',
    '    </dependency>',
    '    <dependency>',
    '      <groupId>com.fasterxml.jackson.core</groupId>',
    '      <artifactId>jackson-annotations</artifactId>',
    '      <version>2.18.2</version>',
    '    </dependency>',
  })
  if ok then
    write_pom(lines); notify('✅ Jackson added', vim.log.levels.INFO)
  else
    notify('Failed to add Jackson', vim.log.levels.ERROR)
  end
end

function M.add_spring()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if already_has(lines, 'spring-boot-starter') then
    notify('Spring Boot already in pom.xml', vim.log.levels.WARN); return
  end
  -- Also add spring-boot-maven-plugin
  lines, ok = add_deps(lines, {
    '',
    '    <!-- Spring Boot -->',
    '    <dependency>',
    '      <groupId>org.springframework.boot</groupId>',
    '      <artifactId>spring-boot-starter</artifactId>',
    '      <version>3.4.1</version>',
    '    </dependency>',
    '    <dependency>',
    '      <groupId>org.springframework.boot</groupId>',
    '      <artifactId>spring-boot-starter-test</artifactId>',
    '      <version>3.4.1</version>',
    '      <scope>test</scope>',
    '    </dependency>',
  })
  if ok then
    write_pom(lines); notify('✅ Spring Boot added', vim.log.levels.INFO)
  else
    notify('Failed to add Spring Boot', vim.log.levels.ERROR)
  end
end

function M.add_lombok()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if already_has(lines, 'lombok') then
    notify('Lombok already in pom.xml', vim.log.levels.WARN); return
  end
  lines, ok = add_deps(lines, {
    '',
    '    <!-- Lombok -->',
    '    <dependency>',
    '      <groupId>org.projectlombok</groupId>',
    '      <artifactId>lombok</artifactId>',
    '      <version>1.18.36</version>',
    '      <scope>provided</scope>',
    '    </dependency>',
  })
  if ok then
    write_pom(lines); notify('✅ Lombok added', vim.log.levels.INFO)
  else
    notify('Failed to add Lombok', vim.log.levels.ERROR)
  end
end

function M.add_junit5()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if already_has(lines, 'junit-jupiter') then
    notify('JUnit 5 already in pom.xml', vim.log.levels.WARN); return
  end
  lines, ok = add_deps(lines, {
    '',
    '    <!-- JUnit 5 -->',
    '    <dependency>',
    '      <groupId>org.junit.jupiter</groupId>',
    '      <artifactId>junit-jupiter</artifactId>',
    '      <version>5.11.4</version>',
    '      <scope>test</scope>',
    '    </dependency>',
  })
  if ok then
    write_pom(lines); notify('✅ JUnit 5 added', vim.log.levels.INFO)
  else
    notify('Failed to add JUnit 5', vim.log.levels.ERROR)
  end
end

function M.add_mockito()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if already_has(lines, 'mockito-core') then
    notify('Mockito already in pom.xml', vim.log.levels.WARN); return
  end
  lines, ok = add_deps(lines, {
    '',
    '    <!-- Mockito -->',
    '    <dependency>',
    '      <groupId>org.mockito</groupId>',
    '      <artifactId>mockito-core</artifactId>',
    '      <version>5.15.2</version>',
    '      <scope>test</scope>',
    '    </dependency>',
  })
  if ok then
    write_pom(lines); notify('✅ Mockito added', vim.log.levels.INFO)
  else
    notify('Failed to add Mockito', vim.log.levels.ERROR)
  end
end

function M.add_lwjgl()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if already_has(lines, 'lwjgl-bom') or already_has(lines, 'lwjgl') then
    notify('LWJGL already in pom.xml', vim.log.levels.WARN); return
  end
  lines, ok = set_property(lines, 'lwjgl.version', '3.3.6')
  lines, ok = set_property(lines, 'joml.version', '1.10.8')
  -- BOM in dependencyManagement
  lines, s, e = ensure_section(lines,
    '<%s*dependencyManagement%s*>.*<%s*dependencies%s*>',
    '<%s*/dependencyManagement', '<%s*dependencies%s*>', '    ',
    '<dependencyManagement><dependencies>', '</dependencies></dependencyManagement>')
  if s then
    insert_before(lines, e, {
      '      <dependency>',
      '        <groupId>org.lwjgl</groupId>',
      '        <artifactId>lwjgl-bom</artifactId>',
      '        <version>${lwjgl.version}</version>',
      '        <scope>import</scope>',
      '        <type>pom</type>',
      '      </dependency>',
    })
  end
  -- Core + natives
  local native_classifiers = { 'natives-linux', 'natives-windows', 'natives-macos' }
  local modules = { 'lwjgl', 'lwjgl-glfw', 'lwjgl-opengl', 'lwjgl-stb' }
  local dep_lines = { '', '    <!-- LWJGL -->' }
  for _, mod in ipairs(modules) do
    dep_lines[#dep_lines + 1] = '    <dependency>'
    dep_lines[#dep_lines + 1] = '      <groupId>org.lwjgl</groupId>'
    dep_lines[#dep_lines + 1] = '      <artifactId>' .. mod .. '</artifactId>'
    dep_lines[#dep_lines + 1] = '    </dependency>'
    for _, cls in ipairs(native_classifiers) do
      dep_lines[#dep_lines + 1] = '    <dependency>'
      dep_lines[#dep_lines + 1] = '      <groupId>org.lwjgl</groupId>'
      dep_lines[#dep_lines + 1] = '      <artifactId>' .. mod .. '</artifactId>'
      dep_lines[#dep_lines + 1] = '      <classifier>' .. cls .. '</classifier>'
      dep_lines[#dep_lines + 1] = '    </dependency>'
    end
  end
  dep_lines[#dep_lines + 1] = '    <!-- JOML -->'
  dep_lines[#dep_lines + 1] = '    <dependency>'
  dep_lines[#dep_lines + 1] = '      <groupId>org.joml</groupId>'
  dep_lines[#dep_lines + 1] = '      <artifactId>joml</artifactId>'
  dep_lines[#dep_lines + 1] = '      <version>${joml.version}</version>'
  dep_lines[#dep_lines + 1] = '    </dependency>'
  lines, ok = add_deps(lines, dep_lines)
  if ok then
    write_pom(lines); notify('✅ LWJGL + JOML added (Linux/Windows/macOS natives)', vim.log.levels.INFO)
  else
    notify('Failed to add LWJGL', vim.log.levels.ERROR)
  end
end

function M.add_assembly_plugin()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if table.concat(lines, '\n'):match('maven%-assembly%-plugin') then
    notify('Assembly plugin already configured', vim.log.levels.WARN); return
  end
  local main_class = M.find_main_class() or 'com.example.Main'
  lines, ps, pe = ensure_build_plugins(lines)
  if not ps then
    notify('Failed to locate <plugins>', vim.log.levels.ERROR); return
  end
  insert_before(lines, pe, {
    '      <!-- Fat JAR -->',
    '      <plugin>',
    '        <groupId>org.apache.maven.plugins</groupId>',
    '        <artifactId>maven-assembly-plugin</artifactId>',
    '        <version>3.7.1</version>',
    '        <configuration>',
    '          <archive><manifest>',
    '            <mainClass>' .. main_class .. '</mainClass>',
    '          </manifest></archive>',
    '          <descriptorRefs><descriptorRef>jar-with-dependencies</descriptorRef></descriptorRefs>',
    '        </configuration>',
    '        <executions><execution>',
    '          <id>make-assembly</id><phase>package</phase>',
    '          <goals><goal>single</goal></goals>',
    '        </execution></executions>',
    '      </plugin>',
  })
  write_pom(lines)
  notify('✅ Assembly plugin added  (main class: ' .. main_class .. ')', vim.log.levels.INFO)
end

function M.add_spotless()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if table.concat(lines, '\n'):match('spotless') then
    notify('Spotless already configured', vim.log.levels.WARN); return
  end
  lines, ps, pe = ensure_build_plugins(lines)
  if not ps then
    notify('Failed to locate <plugins>', vim.log.levels.ERROR); return
  end
  insert_before(lines, pe, {
    '      <!-- Spotless formatter -->',
    '      <plugin>',
    '        <groupId>com.diffplug.spotless</groupId>',
    '        <artifactId>spotless-maven-plugin</artifactId>',
    '        <version>2.43.0</version>',
    '        <configuration>',
    '          <java><googleJavaFormat/></java>',
    '        </configuration>',
    '      </plugin>',
  })
  write_pom(lines)
  notify('✅ Spotless added  (run: mvn spotless:apply)', vim.log.levels.INFO)
end

-- ── Public: properties ────────────────────────────────────────────────────────
function M.set_java_version(version)
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  version = tostring(version)
  lines, _ = set_property(lines, 'maven.compiler.source', version)
  lines, _ = set_property(lines, 'maven.compiler.target', version)
  write_pom(lines)
  notify('✅ Java version set to ' .. version, vim.log.levels.INFO)
end

function M.set_encoding(enc)
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  lines, _ = set_property(lines, 'project.build.sourceEncoding', enc)
  lines, _ = set_property(lines, 'project.reporting.outputEncoding', enc)
  write_pom(lines)
  notify('✅ Encoding set to ' .. enc, vim.log.levels.INFO)
end

-- ── Util: find main class ─────────────────────────────────────────────────────
function M.find_main_class()
  local files = vim.fn.globpath(vim.fn.getcwd() .. '/src/main/java', '**/*.java', false, true)
  for _, file in ipairs(files) do
    local pkg, cls, has_main
    for _, line in ipairs(vim.fn.readfile(file)) do
      if line:match('^%s*package%s+') then pkg = line:match('package%s+([%w%.]+)') end
      if line:match('^%s*public%s+class%s+') then cls = line:match('class%s+(%w+)') end
      if line:match('public%s+static%s+void%s+main') then has_main = true end
      if pkg and cls and has_main then return pkg .. '.' .. cls end
    end
  end
end

return M
