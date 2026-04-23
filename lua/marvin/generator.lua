-- lua/marvin/generator.lua
local M = {}

local function ui() return require('marvin.ui') end

local BUILTIN_ARCHETYPES = {
  { group_id = 'org.apache.maven.archetypes', artifact_id = 'maven-archetype-quickstart',  version = '1.4', label = 'maven-archetype-quickstart',  desc = 'Simple Java project with JUnit' },
  { group_id = 'org.apache.maven.archetypes', artifact_id = 'maven-archetype-webapp',      version = '1.4', label = 'maven-archetype-webapp',      desc = 'Java web application (WAR)' },
  { group_id = 'org.apache.maven.archetypes', artifact_id = 'maven-archetype-simple',      version = '1.4', label = 'maven-archetype-simple',      desc = 'Minimal Maven project' },
  { group_id = 'org.apache.maven.archetypes', artifact_id = 'maven-archetype-j2ee-simple', version = '1.4', label = 'maven-archetype-j2ee-simple', desc = 'Simple J2EE application' },
}

-- ── Local repo root ───────────────────────────────────────────────────────────
local function local_repo_root()
  -- 1. Respect <localRepository> in settings.xml (best-effort, no XML parser)
  local settings_candidates = {
    (os.getenv('HOME') or '') .. '/.m2/settings.xml',
    (os.getenv('MAVEN_HOME') or '') .. '/conf/settings.xml',
    (os.getenv('M2_HOME') or '') .. '/conf/settings.xml',
  }
  for _, sp in ipairs(settings_candidates) do
    local f = io.open(sp, 'r')
    if f then
      local txt = f:read('*all'); f:close()
      local lr = txt:match('<localRepository>%s*([^<]+)%s*</localRepository>')
      if lr and vim.trim(lr) ~= '' then return vim.trim(lr) end
    end
  end
  -- 2. Conventional default
  return (os.getenv('HOME') or '') .. '/.m2/repository'
end

-- ── archetype-catalog.xml parser ─────────────────────────────────────────────
local function parse_catalog(path)
  local f = io.open(path, 'r')
  if not f then return {} end
  local txt = f:read('*all'); f:close()

  local results = {}
  for block in txt:gmatch('<archetype>(.-)</archetype>') do
    local g = block:match('<groupId>%s*([^<]+)%s*</groupId>')
    local a = block:match('<artifactId>%s*([^<]+)%s*</artifactId>')
    local v = block:match('<version>%s*([^<]+)%s*</version>')
    local d = block:match('<description>%s*([^<]+)%s*</description>') or ''
    if g and a and v then
      results[#results + 1] = {
        group_id    = vim.trim(g),
        artifact_id = vim.trim(a),
        version     = vim.trim(v),
        label       = vim.trim(a),
        desc        = vim.trim(d) ~= '' and (vim.trim(d) .. '  · ' .. vim.trim(g))
            or vim.trim(g) .. ':' .. vim.trim(v),
      }
    end
  end
  return results
end

-- ── Main entry ───────────────────────────────────────────────────────────────
function M.create_project()
  M.scan_local_archetypes()
end

function M.scan_local_archetypes()
  ui().notify('Scanning local Maven repository…', vim.log.levels.INFO)

  local repo = local_repo_root()

  -- Find every archetype-catalog.xml anywhere in the local repo.
  -- This catches:
  --   ~/.m2/repository/archetype-catalog.xml          (top-level aggregate)
  --   ~/.m2/repository/<g>/<a>/<v>/<a>-<v>-...xml    (per-artifact catalogs)
  --   Nix store symlinks that Maven has resolved into ~/.m2
  local cmd = string.format(
    'find "%s" -maxdepth 8 -name "archetype-catalog.xml" 2>/dev/null', repo)

  local catalog_paths = {}

  vim.fn.jobstart({ 'sh', '-c', cmd }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        line = vim.trim(line)
        if line ~= '' then catalog_paths[#catalog_paths + 1] = line end
      end
    end,
    on_exit = function()
      vim.schedule(function()
        -- Parse every catalog found
        local seen       = {}
        local archetypes = {}

        local function add(a)
          local key = a.group_id .. ':' .. a.artifact_id .. ':' .. a.version
          if not seen[key] then
            seen[key] = true
            archetypes[#archetypes + 1] = a
          end
        end

        for _, path in ipairs(catalog_paths) do
          for _, a in ipairs(parse_catalog(path)) do add(a) end
        end

        -- Also scan for .jar files whose POM declares <packaging>maven-archetype</packaging>.
        -- This catches locally-installed archetypes that were never listed in a catalog.
        -- We do this synchronously on the already-found repo tree — fast enough.
        M._scan_jar_poms(repo, seen, archetypes, function(extras)
          for _, a in ipairs(extras) do archetypes[#archetypes + 1] = a end
          M._finish(archetypes, repo)
        end)
      end)
    end,
  })
end

-- Scan POMs inside the local repo for <packaging>maven-archetype</packaging>.
-- Uses a second async find so we don't block the UI.
function M._scan_jar_poms(repo, seen, _, callback)
  local pom_cmd = string.format(
    'grep -rl "<packaging>maven-archetype</packaging>" "%s" --include="*.pom" 2>/dev/null', repo)

  local extras = {}

  vim.fn.jobstart({ 'sh', '-c', pom_cmd }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      for _, pom_path in ipairs(data) do
        pom_path = vim.trim(pom_path)
        if pom_path == '' then goto continue end

        local f = io.open(pom_path, 'r')
        if not f then goto continue end
        local txt = f:read('*all'); f:close()

        local g = txt:match('<groupId>%s*([^<]+)%s*</groupId>')
        local a = txt:match('<artifactId>%s*([^<]+)%s*</artifactId>')
        local v = txt:match('<version>%s*([^<]+)%s*</version>')
        local d = txt:match('<description>%s*([^<]+)%s*</description>') or ''

        -- parent groupId/version fallback
        if not g then g = txt:match('<parent>.-<groupId>%s*([^<]+)') end
        if not v then v = txt:match('<parent>.-<version>%s*([^<]+)') end

        if g and a and v then
          g, a, v = vim.trim(g), vim.trim(a), vim.trim(v)
          local key = g .. ':' .. a .. ':' .. v
          if not seen[key] then
            seen[key] = true
            extras[#extras + 1] = {
              group_id    = g,
              artifact_id = a,
              version     = v,
              label       = a,
              desc        = (vim.trim(d) ~= '' and vim.trim(d) or g) .. '  · v' .. v,
            }
          end
        end
        ::continue::
      end
    end,
    on_exit = function()
      vim.schedule(function() callback(extras) end)
    end,
  })
end

function M._finish(archetypes, repo)
  -- Sort: shorter (simpler) artifact IDs first, then alphabetically
  table.sort(archetypes, function(a, b)
    if a.artifact_id ~= b.artifact_id then return a.artifact_id < b.artifact_id end
    return a.group_id < b.group_id
  end)

  if #archetypes == 0 then
    vim.notify(
      '[Marvin] No cached archetypes found in ' .. repo ..
      '\nShowing built-ins — Maven will download on first use.',
      vim.log.levels.INFO)
    M.show_archetype_menu(BUILTIN_ARCHETYPES)
    return
  end

  -- Merge: built-ins always present at the top, de-duplicated
  local merged      = {}
  local merged_seen = {}
  for _, a in ipairs(BUILTIN_ARCHETYPES) do
    local k = a.group_id .. ':' .. a.artifact_id
    merged_seen[k] = true
    merged[#merged + 1] = a
  end
  for _, a in ipairs(archetypes) do
    local k = a.group_id .. ':' .. a.artifact_id
    if not merged_seen[k] then
      merged[#merged + 1] = a
    end
  end

  M.show_archetype_menu(merged)
end

-- ── Archetype picker ──────────────────────────────────────────────────────────
function M.show_archetype_menu(archetypes)
  local items = {}
  for _, a in ipairs(archetypes) do
    items[#items + 1] = { label = a.label, desc = a.desc, icon = '󰏗', _archetype = a }
  end

  ui().select(items, {
    prompt        = 'New Maven Project  — Select Archetype',
    enable_search = true,
    format_item   = function(it) return it.label end,
  }, function(choice)
    if choice then M.show_project_wizard(choice._archetype) end
  end)
end

-- ── Project wizard ────────────────────────────────────────────────────────────
function M.show_project_wizard(archetype)
  local details = { group_id = 'com.example', artifact_id = 'my-app', version = '1.0-SNAPSHOT' }

  local function ask_version()
    ui().input({ prompt = '󰏷 Version', default = details.version }, function(v)
      if not v then return end
      details.version = v
      M.confirm_and_generate(archetype, details)
    end)
  end

  local function ask_artifact()
    ui().input({ prompt = '󰏗 Artifact ID', default = details.artifact_id }, function(a)
      if not a then return end
      details.artifact_id = a
      ask_version()
    end)
  end

  ui().input({ prompt = '󰬷 Group ID', default = details.group_id }, function(g)
    if not g then return end
    details.group_id = g
    ask_artifact()
  end)
end

-- ── Confirmation / edit menu ──────────────────────────────────────────────────
function M.confirm_and_generate(archetype, details)
  local coord = details.group_id .. ':' .. details.artifact_id .. ':' .. details.version

  ui().select({
    { id = 'confirm', icon = '󰄬', label = 'Generate Project', desc = coord },
    { id = 'edit_group', icon = '󰬷', label = 'Change Group ID', desc = details.group_id },
    { id = 'edit_artifact', icon = '󰏗', label = 'Change Artifact ID', desc = details.artifact_id },
    { id = 'edit_version', icon = '󰏷', label = 'Change Version', desc = details.version },
    { id = 'cancel', icon = '󰅖', label = 'Cancel', desc = '' },
  }, {
    prompt      = 'New Maven Project  — ' .. archetype.artifact_id .. ' v' .. archetype.version,
    on_back     = function() M.show_archetype_menu(BUILTIN_ARCHETYPES) end,
    format_item = function(it) return it.label end,
  }, function(choice)
    if not choice or choice.id == 'cancel' then return end

    if choice.id == 'confirm' then
      ui().input({ prompt = '󰉋 Output Directory', default = vim.fn.expand('~/Code/java') }, function(dir)
        if dir then M.generate_project(archetype, details, dir) end
      end)
    elseif choice.id == 'edit_group' then
      ui().input({ prompt = '󰬷 Group ID', default = details.group_id }, function(v)
        if v then details.group_id = v end
        M.confirm_and_generate(archetype, details)
      end)
    elseif choice.id == 'edit_artifact' then
      ui().input({ prompt = '󰏗 Artifact ID', default = details.artifact_id }, function(v)
        if v then details.artifact_id = v end
        M.confirm_and_generate(archetype, details)
      end)
    elseif choice.id == 'edit_version' then
      ui().input({ prompt = '󰏷 Version', default = details.version }, function(v)
        if v then details.version = v end
        M.confirm_and_generate(archetype, details)
      end)
    end
  end)
end

-- ── Maven execution ───────────────────────────────────────────────────────────
function M.generate_project(archetype, details, directory)
  local maven_cmd = require('marvin').get_mvn_cmd()

  local cmd = string.format(
    '%s org.apache.maven.plugins:maven-archetype-plugin:3.2.1:generate -B -DinteractiveMode=false'
    .. ' -DarchetypeGroupId=%s -DarchetypeArtifactId=%s -DarchetypeVersion=%s'
    .. ' -DgroupId=%s -DartifactId=%s -Dversion=%s -Dpackage=%s',
    maven_cmd,
    archetype.group_id, archetype.artifact_id, archetype.version,
    details.group_id, details.artifact_id, details.version, details.group_id)

  directory = vim.fn.expand(directory)

  if vim.fn.isdirectory(directory) == 0 then
    if vim.fn.mkdir(directory, 'p') == 0 then
      ui().notify('❌ Cannot create directory: ' .. directory, vim.log.levels.ERROR)
      return
    end
  end

  ui().notify('Generating ' .. details.artifact_id .. '…', vim.log.levels.INFO)

  local output = {}
  vim.fn.jobstart(cmd, {
    cwd             = directory,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout       = function(_, data)
      for _, l in ipairs(data) do if l ~= '' then output[#output + 1] = l end end
    end,
    on_stderr       = function(_, data)
      for _, l in ipairs(data) do if l ~= '' then output[#output + 1] = l end end
    end,
    on_exit         = function(_, code)
      vim.schedule(function()
        if code == 0 then
          local proj_path = directory .. '/' .. details.artifact_id
          M.fix_eclipse_files(proj_path, details.version)
          ui().notify('✅ Project created: ' .. details.artifact_id, vim.log.levels.INFO)

          ui().select({
            { id = 'yes', icon = '󰄬', label = 'Open project', desc = proj_path },
            { id = 'no', icon = '󰅖', label = 'Stay here', desc = '' },
          }, {
            prompt      = 'Project ready!',
            format_item = function(it) return it.label end,
          }, function(ch)
            if ch and ch.id == 'yes' then
              vim.cmd('cd ' .. vim.fn.fnameescape(proj_path))
              vim.cmd('edit ' .. vim.fn.fnameescape(proj_path .. '/pom.xml'))
            end
          end)
        else
          local tail = {}
          for i = math.max(1, #output - 15), #output do tail[#tail + 1] = output[i] end
          ui().notify(
            '❌ Generation failed (exit ' .. code .. ')\n' .. table.concat(tail, '\n'),
            vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

-- ── Eclipse fix ───────────────────────────────────────────────────────────────
function M.fix_eclipse_files(project_path, version)
  for _, fp in ipairs({ project_path .. '/.classpath', project_path .. '/.project' }) do
    if vim.fn.filereadable(fp) == 1 then
      local lines, fixed = vim.fn.readfile(fp), false
      for i, line in ipairs(lines) do
        if line:match('<?xml version="' .. vim.pesc(version) .. '"') then
          lines[i] = line:gsub(vim.pesc(version), '1.0')
          fixed = true
        end
      end
      if fixed then vim.fn.writefile(lines, fp) end
    end
  end
end

return M
