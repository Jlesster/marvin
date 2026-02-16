local M = {}

-- Read entire POM file
local function read_pom()
  local pom_path = vim.fn.getcwd() .. '/pom.xml'
  if vim.fn.filereadable(pom_path) == 0 then
    return nil, "No pom.xml found in current directory"
  end
  return vim.fn.readfile(pom_path), nil
end

-- Write POM file
local function write_pom(lines)
  local pom_path = vim.fn.getcwd() .. '/pom.xml'
  vim.fn.writefile(lines, pom_path)
  return true
end

-- Find insertion point for properties
local function find_properties_section(lines)
  for i, line in ipairs(lines) do
    if line:match('<%s*properties%s*>') then
      -- Find closing tag
      for j = i + 1, #lines do
        if lines[j]:match('<%s*/properties%s*>') then
          return i, j
        end
      end
    end
  end
  return nil, nil
end

-- Find or create properties section
local function ensure_properties_section(lines)
  local start_idx, end_idx = find_properties_section(lines)

  if start_idx then
    return lines, start_idx, end_idx
  end

  -- Create properties section after <version>
  for i, line in ipairs(lines) do
    if line:match('<%s*version%s*>') and not line:match('<%s*parent%s*>') then
      table.insert(lines, i + 1, '')
      table.insert(lines, i + 2, '  <properties>')
      table.insert(lines, i + 3, '    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>')
      table.insert(lines, i + 4, '  </properties>')
      return lines, i + 2, i + 4
    end
  end

  return lines, nil, nil
end

-- Add properties
local function add_properties(lines, properties)
  lines, start_idx, end_idx = ensure_properties_section(lines)

  if not start_idx then
    return lines, false
  end

  -- Insert properties before closing tag
  for i = #properties, 1, -1 do
    table.insert(lines, end_idx, '    ' .. properties[i])
  end

  return lines, true
end

-- Find dependencies section
local function find_dependencies_section(lines)
  local in_dep_mgmt = false
  local depth = 0

  for i, line in ipairs(lines) do
    if line:match('<%s*dependencyManagement%s*>') then
      in_dep_mgmt = true
      depth = depth + 1
    elseif line:match('<%s*/dependencyManagement%s*>') then
      depth = depth - 1
      if depth == 0 then
        in_dep_mgmt = false
      end
    elseif line:match('<%s*dependencies%s*>') and not in_dep_mgmt then
      -- Find closing tag
      for j = i + 1, #lines do
        if lines[j]:match('<%s*/dependencies%s*>') then
          return i, j
        end
      end
    end
  end
  return nil, nil
end

-- Create dependencies section
local function ensure_dependencies_section(lines)
  local start_idx, end_idx = find_dependencies_section(lines)

  if start_idx then
    return lines, start_idx, end_idx
  end

  -- Create dependencies section before </project>
  for i = #lines, 1, -1 do
    if lines[i]:match('<%s*/project%s*>') then
      table.insert(lines, i, '')
      table.insert(lines, i, '  </dependencies>')
      table.insert(lines, i, '  <dependencies>')
      table.insert(lines, i, '')
      return lines, i + 2, i + 3
    end
  end

  return lines, nil, nil
end

-- Add dependencies
local function add_dependencies(lines, dependencies)
  lines, start_idx, end_idx = ensure_dependencies_section(lines)

  if not start_idx then
    return lines, false
  end

  -- Insert dependencies before closing tag
  for i = #dependencies, 1, -1 do
    table.insert(lines, end_idx, '    ' .. dependencies[i])
  end

  return lines, true
end

-- Find or create dependencyManagement section
local function ensure_dependency_management(lines)
  for i, line in ipairs(lines) do
    if line:match('<%s*dependencyManagement%s*>') then
      for j = i + 1, #lines do
        if lines[j]:match('<%s*dependencies%s*>') then
          for k = j + 1, #lines do
            if lines[k]:match('<%s*/dependencies%s*>') then
              return lines, j, k
            end
          end
        end
      end
    end
  end

  -- Create it before <dependencies>
  for i, line in ipairs(lines) do
    if line:match('<%s*dependencies%s*>') then
      table.insert(lines, i, '')
      table.insert(lines, i, '  </dependencyManagement>')
      table.insert(lines, i, '    </dependencies>')
      table.insert(lines, i, '')
      table.insert(lines, i, '    <dependencies>')
      table.insert(lines, i, '  <dependencyManagement>')
      table.insert(lines, i, '')
      return lines, i + 2, i + 3
    end
  end

  return lines, nil, nil
end

-- Add Jackson JSON library
function M.add_jackson()
  local ui = require('marvin.ui')
  local lines, err = read_pom()

  if not lines then
    ui.notify(err, vim.log.levels.ERROR)
    return false
  end

  -- Check if already exists
  local content = table.concat(lines, '\n')
  if content:match('jackson%-databind') then
    ui.notify('Jackson is already in pom.xml', vim.log.levels.WARN)
    return false
  end

  ui.notify('Adding Jackson JSON library...', vim.log.levels.INFO)

  local deps = {
    '',
    '<!-- Jackson JSON Library -->',
    '<dependency>',
    '  <groupId>com.fasterxml.jackson.core</groupId>',
    '  <artifactId>jackson-databind</artifactId>',
    '  <version>2.18.2</version>',
    '</dependency>',
    '<dependency>',
    '  <groupId>com.fasterxml.jackson.core</groupId>',
    '  <artifactId>jackson-core</artifactId>',
    '  <version>2.18.2</version>',
    '</dependency>',
    '<dependency>',
    '  <groupId>com.fasterxml.jackson.core</groupId>',
    '  <artifactId>jackson-annotations</artifactId>',
    '  <version>2.18.2</version>',
    '</dependency>',
  }

  lines, success = add_dependencies(lines, deps)

  if success then
    write_pom(lines)
    ui.notify('✅ Jackson JSON library added successfully!', vim.log.levels.INFO)
    return true
  else
    ui.notify('Failed to add Jackson', vim.log.levels.ERROR)
    return false
  end
end

-- Add LWJGL library
function M.add_lwjgl()
  local ui = require('marvin.ui')
  local lines, err = read_pom()

  if not lines then
    ui.notify(err, vim.log.levels.ERROR)
    return false
  end

  -- Check if already exists
  local content = table.concat(lines, '\n')
  if content:match('lwjgl%-bom') or content:match('lwjgl</artifactId>') then
    ui.notify('LWJGL is already in pom.xml', vim.log.levels.WARN)
    return false
  end

  ui.notify('Adding LWJGL library with full platform support...', vim.log.levels.INFO)

  -- Add properties
  local props = {
    '<lwjgl.version>3.3.6</lwjgl.version>',
    '<joml.version>1.10.8</joml.version>',
  }

  lines, success = add_properties(lines, props)
  if not success then
    ui.notify('Failed to add LWJGL properties', vim.log.levels.ERROR)
    return false
  end

  -- Add dependency management
  lines, start_idx, end_idx = ensure_dependency_management(lines)
  if start_idx then
    local mgmt = {
      '',
      '<!-- LWJGL BOM -->',
      '<dependency>',
      '  <groupId>org.lwjgl</groupId>',
      '  <artifactId>lwjgl-bom</artifactId>',
      '  <version>${lwjgl.version}</version>',
      '  <scope>import</scope>',
      '  <type>pom</type>',
      '</dependency>',
    }

    for i = #mgmt, 1, -1 do
      table.insert(lines, end_idx, '      ' .. mgmt[i])
    end
  end

  -- Add core dependencies
  local deps = {
    '',
    '<!-- LWJGL Core Modules -->',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl</artifactId>',
    '</dependency>',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl-glfw</artifactId>',
    '</dependency>',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl-opengl</artifactId>',
    '</dependency>',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl-stb</artifactId>',
    '</dependency>',
    '',
    '<!-- LWJGL Natives - Linux -->',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl</artifactId>',
    '  <classifier>natives-linux</classifier>',
    '</dependency>',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl-glfw</artifactId>',
    '  <classifier>natives-linux</classifier>',
    '</dependency>',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl-opengl</artifactId>',
    '  <classifier>natives-linux</classifier>',
    '</dependency>',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl-stb</artifactId>',
    '  <classifier>natives-linux</classifier>',
    '</dependency>',
    '',
    '<!-- LWJGL Natives - Windows -->',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl</artifactId>',
    '  <classifier>natives-windows</classifier>',
    '</dependency>',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl-glfw</artifactId>',
    '  <classifier>natives-windows</classifier>',
    '</dependency>',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl-opengl</artifactId>',
    '  <classifier>natives-windows</classifier>',
    '</dependency>',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl-stb</artifactId>',
    '  <classifier>natives-windows</classifier>',
    '</dependency>',
    '',
    '<!-- LWJGL Natives - macOS -->',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl</artifactId>',
    '  <classifier>natives-macos</classifier>',
    '</dependency>',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl-glfw</artifactId>',
    '  <classifier>natives-macos</classifier>',
    '</dependency>',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl-opengl</artifactId>',
    '  <classifier>natives-macos</classifier>',
    '</dependency>',
    '<dependency>',
    '  <groupId>org.lwjgl</groupId>',
    '  <artifactId>lwjgl-stb</artifactId>',
    '  <classifier>natives-macos</classifier>',
    '</dependency>',
    '',
    '<!-- JOML Math Library -->',
    '<dependency>',
    '  <groupId>org.joml</groupId>',
    '  <artifactId>joml</artifactId>',
    '  <version>${joml.version}</version>',
    '</dependency>',
  }

  lines, success = add_dependencies(lines, deps)

  if success then
    write_pom(lines)
    ui.notify('✅ LWJGL library added with Linux, Windows, and macOS support!', vim.log.levels.INFO)
    return true
  else
    ui.notify('Failed to add LWJGL', vim.log.levels.ERROR)
    return false
  end
end

-- Add Maven Assembly Plugin for Fat JARs
function M.add_assembly_plugin()
  local ui = require('marvin.ui')
  local lines, err = read_pom()

  if not lines then
    ui.notify(err, vim.log.levels.ERROR)
    return false
  end

  -- Check if already exists
  local content = table.concat(lines, '\n')
  if content:match('maven%-assembly%-plugin') then
    ui.notify('Maven Assembly Plugin is already configured', vim.log.levels.WARN)
    return false
  end

  ui.notify('Adding Maven Assembly Plugin...', vim.log.levels.INFO)

  -- Find main class
  local main_class = M.find_main_class() or 'com.example.Main'

  -- Find or create build section
  local build_start, build_end = nil, nil
  for i, line in ipairs(lines) do
    if line:match('<%s*build%s*>') then
      build_start = i
      for j = i + 1, #lines do
        if lines[j]:match('<%s*/build%s*>') then
          build_end = j
          break
        end
      end
      break
    end
  end

  -- Create build section if it doesn't exist
  if not build_start then
    for i = #lines, 1, -1 do
      if lines[i]:match('<%s*/project%s*>') then
        table.insert(lines, i, '')
        table.insert(lines, i, '  </build>')
        table.insert(lines, i, '  <build>')
        table.insert(lines, i, '')
        build_start = i + 2
        build_end = i + 3
        break
      end
    end
  end

  -- Find or create plugins section
  local plugins_start, plugins_end = nil, nil
  for i = build_start, build_end do
    if lines[i]:match('<%s*plugins%s*>') then
      plugins_start = i
      for j = i + 1, build_end do
        if lines[j]:match('<%s*/plugins%s*>') then
          plugins_end = j
          break
        end
      end
      break
    end
  end

  if not plugins_start then
    table.insert(lines, build_end, '    </plugins>')
    table.insert(lines, build_end, '    <plugins>')
    plugins_start = build_end
    plugins_end = build_end + 1
  end

  -- Add assembly plugin
  local plugin = {
    '',
    '  <!-- Maven Assembly Plugin for Fat JAR -->',
    '  <plugin>',
    '    <groupId>org.apache.maven.plugins</groupId>',
    '    <artifactId>maven-assembly-plugin</artifactId>',
    '    <version>3.7.1</version>',
    '    <configuration>',
    '      <archive>',
    '        <manifest>',
    '          <mainClass>' .. main_class .. '</mainClass>',
    '        </manifest>',
    '      </archive>',
    '      <descriptorRefs>',
    '        <descriptorRef>jar-with-dependencies</descriptorRef>',
    '      </descriptorRefs>',
    '    </configuration>',
    '    <executions>',
    '      <execution>',
    '        <id>make-assembly</id>',
    '        <phase>package</phase>',
    '        <goals>',
    '          <goal>single</goal>',
    '        </goals>',
    '      </execution>',
    '    </executions>',
    '  </plugin>',
  }

  for i = #plugin, 1, -1 do
    table.insert(lines, plugins_end, '      ' .. plugin[i])
  end

  write_pom(lines)
  ui.notify('✅ Maven Assembly Plugin added! Main class: ' .. main_class, vim.log.levels.INFO)
  return true
end

-- Find main class in project
function M.find_main_class()
  local java_files = vim.fn.globpath(vim.fn.getcwd() .. '/src/main/java', '**/*.java', false, true)

  for _, file in ipairs(java_files) do
    local lines = vim.fn.readfile(file)
    local package_name = nil
    local class_name = nil
    local has_main = false

    for _, line in ipairs(lines) do
      if line:match('^%s*package%s+') then
        package_name = line:match('package%s+([%w%.]+)')
      end
      if line:match('^%s*public%s+class%s+') then
        class_name = line:match('class%s+(%w+)')
      end
      if line:match('public%s+static%s+void%s+main') then
        has_main = true
      end

      if package_name and class_name and has_main then
        return package_name .. '.' .. class_name
      end
    end
  end

  return nil
end

return M
