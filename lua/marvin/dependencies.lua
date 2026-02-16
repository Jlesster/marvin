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

  -- Create it before regular <dependencies>
  for i, line in ipairs(lines) do
    if line:match('<%s*dependencies%s*>') and not line:match('<%s*dependencyManagement') then
      -- Insert dependencyManagement section before dependencies
      table.insert(lines, i, '')
      table.insert(lines, i, '  <dependencyManagement>')
      table.insert(lines, i + 1, '    <dependencies>')
      table.insert(lines, i + 2, '    </dependencies>')
      table.insert(lines, i + 3, '  </dependencyManagement>')
      table.insert(lines, i + 4, '')
      return lines, i + 2, i + 3
    end
  end

  return lines, nil, nil
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
      '<!-- LWJGL BOM -->',
      '<dependency>',
      '  <groupId>org.lwjgl</groupId>',
      '  <artifactId>lwjgl-bom</artifactId>',
      '  <version>${lwjgl.version}</version>',
      '  <scope>import</scope>',
      '  <type>pom</type>',
      '</dependency>',
      '',
    }

    -- Insert before the closing </dependencies> tag inside dependencyManagement
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
