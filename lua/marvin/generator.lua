-- lua/marvin/generator.lua
local M = {}

local function ui() return require('marvin.ui') end

function M.create_project()
  M.scan_local_archetypes()
end

function M.scan_local_archetypes()
  ui().notify('Scanning local Maven repository…', vim.log.levels.INFO)

  local home             = os.getenv('HOME') or os.getenv('USERPROFILE')
  local m2_repo          = home .. '/.m2/repository'
  local cmd              = string.format(
    'find "%s" -type f -name "*archetype*.jar" 2>/dev/null | grep -v "maven-archetype-plugin"',
    m2_repo)

  local archetypes, seen = {}, {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= '' then
          local parts    = vim.split(line, '/')
          local repo_idx = nil
          for i, p in ipairs(parts) do
            if p == 'repository' then
              repo_idx = i; break
            end
          end
          if repo_idx and #parts >= repo_idx + 3 then
            local version     = parts[#parts - 1]
            local artifact_id = parts[#parts - 2]
            local gparts      = {}
            for i = repo_idx + 1, #parts - 3 do gparts[#gparts + 1] = parts[i] end
            local group_id = table.concat(gparts, '.')
            if group_id ~= '' and artifact_id ~= '' and version ~= '' then
              local key = group_id .. ':' .. artifact_id .. ':' .. version
              if not seen[key] then
                seen[key] = true
                archetypes[#archetypes + 1] = {
                  group_id    = group_id,
                  artifact_id = artifact_id,
                  version     = version,
                  label       = artifact_id,
                  desc        = 'v' .. version .. '  ' .. group_id,
                }
              end
            end
          end
        end
      end
    end,
    on_exit = function()
      vim.schedule(function()
        if #archetypes == 0 then
          ui().notify('No local archetypes found in ' .. m2_repo, vim.log.levels.WARN)
        else
          M.show_archetype_menu(archetypes)
        end
      end)
    end,
  })
end

-- ── Archetype picker ──────────────────────────────────────────────────────────
function M.show_archetype_menu(archetypes)
  local items = {}
  for _, a in ipairs(archetypes) do
    items[#items + 1] = {
      label      = a.label,
      desc       = a.desc,
      icon       = '󰏗',
      _archetype = a,
    }
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
  local details = {
    group_id    = 'com.example',
    artifact_id = 'my-app',
    version     = '1.0-SNAPSHOT',
  }

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
    on_back     = function() M.show_archetype_menu_cached(archetype) end,
    format_item = function(it) return it.label end,
  }, function(choice)
    if not choice or choice.id == 'cancel' then return end

    if choice.id == 'confirm' then
      ui().input({ prompt = '󰉋 Output Directory', default = vim.fn.getcwd() }, function(dir)
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
  local cmd    = string.format(
    '%s archetype:generate -B ' ..
    '-DarchetypeGroupId=%s -DarchetypeArtifactId=%s -DarchetypeVersion=%s ' ..
    '-DgroupId=%s -DartifactId=%s -Dversion=%s -Dpackage=%s',
    maven_cmd,
    archetype.group_id, archetype.artifact_id, archetype.version,
    details.group_id, details.artifact_id, details.version, details.group_id)

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
          }, function(choice)
            if choice and choice.id == 'yes' then
              vim.cmd('cd ' .. vim.fn.fnameescape(proj_path))
              vim.cmd('edit ' .. vim.fn.fnameescape(proj_path .. '/pom.xml'))
            end
          end)
        else
          ui().notify('❌ Generation failed (exit ' .. code .. ')', vim.log.levels.ERROR)
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
          lines[i] = line:gsub(vim.pesc(version), '1.0'); fixed = true
        end
      end
      if fixed then vim.fn.writefile(lines, fp) end
    end
  end
end

return M
