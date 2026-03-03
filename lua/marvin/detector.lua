-- lua/marvin/detector.lua
-- Unified project detection and deep manifest parsing for Marvin + Jason.
-- Understands: Maven, Gradle, Cargo (+ workspaces), go.mod (+ go.work),
--              CMake, Makefile, and single-file fallback.
-- All code in one place — project.lua is retired.

local M         = {}

M._project      = nil -- currently active project
M._sub_projects = nil -- populated for monorepos/workspaces

-- ── Manifest markers ──────────────────────────────────────────────────────────
local MARKERS   = {
  maven    = { file = 'pom.xml', lang = 'java' },
  gradle   = { files = { 'build.gradle', 'build.gradle.kts' }, lang = 'java' },
  cargo    = { file = 'Cargo.toml', lang = 'rust' },
  go_mod   = { file = 'go.mod', lang = 'go' },
  cmake    = { file = 'CMakeLists.txt', lang = 'cpp' },
  makefile = { files = { 'Makefile', 'makefile' }, lang = 'cpp' },
}

-- ── Tool availability ─────────────────────────────────────────────────────────
local TOOLS     = {
  maven    = { cmd = 'mvn', name = 'Maven', url = 'https://maven.apache.org/install.html' },
  gradle   = { cmd = 'gradle', name = 'Gradle', url = 'https://gradle.org/install/' },
  cargo    = { cmd = 'cargo', name = 'Cargo', url = 'https://rustup.rs' },
  go_mod   = { cmd = 'go', name = 'Go', url = 'https://go.dev/dl/' },
  cmake    = { cmd = 'cmake', name = 'CMake', url = 'https://cmake.org/download/' },
  makefile = { cmd = 'make', name = 'Make', url = 'sudo apt install build-essential' },
}

-- ── Low-level file helpers ────────────────────────────────────────────────────
local function read_file(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local c = f:read('*all'); f:close(); return c
end

local function probe(dir, marker)
  if marker.file then
    return vim.fn.filereadable(dir .. '/' .. marker.file) == 1
  end
  for _, f in ipairs(marker.files or {}) do
    if vim.fn.filereadable(dir .. '/' .. f) == 1 then return true end
  end
  return false
end

local function exec(cmd)
  local h = io.popen(cmd .. ' 2>/dev/null')
  if not h then return nil end
  local out = h:read('*all'); h:close()
  return vim.trim(out)
end

-- ── Manifest parsers ──────────────────────────────────────────────────────────

-- Java / Maven -----------------------------------------------------------
local function parse_pom(root)
  local content = read_file(root .. '/pom.xml')
  if not content then return {} end

  local function tag(t) return content:match('<' .. t .. '>(.-)</' .. t .. '>') end

  -- Dependencies
  local deps = {}
  for block in content:gmatch('<dependency>(.-)</dependency>') do
    local g = block:match('<groupId>(.-)</groupId>')
    local a = block:match('<artifactId>(.-)</artifactId>')
    local v = block:match('<version>(.-)</version>') or 'managed'
    local s = block:match('<scope>(.-)</scope>') or 'compile'
    if g and a then
      deps[#deps + 1] = { group = g, artifact = a, version = v, scope = s }
    end
  end

  -- Profiles
  local profiles = {}
  for block in content:gmatch('<profile>(.-)</profile>') do
    local id = block:match('<id>(.-)</id>')
    if id then profiles[#profiles + 1] = id end
  end

  -- Modules (multi-module project)
  local modules = {}
  for m in content:gmatch('<module>(.-)</module>') do
    modules[#modules + 1] = m
  end

  -- Plugins
  local plugins = {}
  for block in content:gmatch('<plugin>(.-)</plugin>') do
    local a = block:match('<artifactId>(.-)</artifactId>')
    if a then plugins[#plugins + 1] = a end
  end

  return {
    type         = 'maven',
    lang         = 'java',
    group_id     = tag('groupId'),
    artifact_id  = tag('artifactId'),
    version      = tag('version') or '0.0.1',
    packaging    = tag('packaging') or 'jar',
    java_ver     = tag('java.version') or tag('maven.compiler.source'),
    deps         = deps,
    profiles     = profiles,
    modules      = modules,
    plugins      = plugins,
    has_spring   = content:match('spring%-boot') ~= nil,
    has_assembly = content:match('maven%-assembly%-plugin') ~= nil,
    has_owasp    = content:match('dependency%-check') ~= nil,
  }
end

-- Java / Gradle ----------------------------------------------------------
local function parse_gradle(root)
  -- Try build.gradle first, then .kts
  local content = read_file(root .. '/build.gradle')
      or read_file(root .. '/build.gradle.kts')
  if not content then return { type = 'gradle', lang = 'java' } end

  local deps = {}
  -- Groovy DSL: implementation 'group:artifact:version'
  for scope, coord in content:gmatch("(%w+)%s+['\"]([^'\"]+)['\"]") do
    local g, a, v = coord:match('([^:]+):([^:]+):?(.*)')
    if g and a then
      deps[#deps + 1] = { group = g, artifact = a, version = v ~= '' and v or 'dynamic', scope = scope }
    end
  end

  local name = content:match("rootProject%.name%s*=%s*['\"]([^'\"]+)['\"]")
      or vim.fn.fnamemodify(root, ':t')

  return {
    type        = 'gradle',
    lang        = 'java',
    name        = name,
    deps        = deps,
    has_wrapper = vim.fn.filereadable(root .. '/gradlew') == 1,
  }
end

-- Rust / Cargo -----------------------------------------------------------
local function parse_toml_section(content, section)
  -- Extract key = "value" or key = { ... } pairs under [section]
  local result = {}
  local in_section = false
  for line in (content .. '\n'):gmatch('([^\n]*)\n') do
    local sec = line:match('^%[([^%]]+)%]')
    if sec then
      in_section = (sec == section or sec:match('^' .. vim.pesc(section)))
    elseif in_section then
      -- key = "value"
      local k, v = line:match('^([%w_%-]+)%s*=%s*"([^"]*)"')
      if k then result[k] = v end
      -- key = { version = "x", features = [...] }
      if not k then
        k = line:match('^([%w_%-]+)%s*=')
        if k then result[k] = line:match('{(.+)}') or true end
      end
    end
  end
  return result
end

local function parse_cargo(root)
  local content = read_file(root .. '/Cargo.toml')
  if not content then return { type = 'cargo', lang = 'rust' } end

  local pkg      = parse_toml_section(content, 'package')
  local deps     = parse_toml_section(content, 'dependencies')
  local dev_deps = parse_toml_section(content, 'dev-dependencies')
  local features = parse_toml_section(content, 'features')

  -- Workspace members
  local members  = {}
  local in_ws    = false
  for line in (content .. '\n'):gmatch('([^\n]*)\n') do
    if line:match('^%[workspace') then in_ws = true end
    if in_ws then
      local m = line:match('^%s*"([^"]+)"')
      if m then members[#members + 1] = m end
    end
    if in_ws and line:match('^%[') and not line:match('%[workspace') then in_ws = false end
  end

  -- [[bin]] targets
  local bins = {}
  for block in content:gmatch('%[%[bin%]%](.-)\n%[') do
    local n = block:match('name%s*=%s*"([^"]+)"')
    local p = block:match('path%s*=%s*"([^"]+)"')
    if n then bins[#bins + 1] = { name = n, path = p } end
  end

  -- Normalise deps into list form
  local dep_list = {}
  for k, v in pairs(deps) do
    if k ~= 'default' then
      dep_list[#dep_list + 1] = {
        name    = k,
        version = type(v) == 'string' and v or (type(v) == 'table' and v.version or '?'),
        dev     = false,
      }
    end
  end
  for k, v in pairs(dev_deps) do
    dep_list[#dep_list + 1] = {
      name    = k,
      version = type(v) == 'string' and v or '?',
      dev     = true,
    }
  end
  table.sort(dep_list, function(a, b) return a.name < b.name end)

  return {
    type         = 'cargo',
    lang         = 'rust',
    name         = pkg.name or vim.fn.fnamemodify(root, ':t'),
    version      = pkg.version or '0.1.0',
    edition      = pkg.edition or '2021',
    deps         = dep_list,
    features     = features,
    bins         = bins,
    members      = members,
    is_workspace = #members > 0,
    is_lib       = vim.fn.filereadable(root .. '/src/lib.rs') == 1,
    is_bin       = vim.fn.filereadable(root .. '/src/main.rs') == 1,
  }
end

-- Go / go.mod ------------------------------------------------------------
local function parse_go_mod(root)
  local content = read_file(root .. '/go.mod')
  if not content then return { type = 'go_mod', lang = 'go' } end

  local module = content:match('^module%s+(%S+)')
  local go_ver = content:match('\ngo%s+(%S+)')
  local deps   = {}

  -- require blocks (both single and block form)
  for block in content:gmatch('require%s*%((.-)%)') do
    for path, ver in block:gmatch('%s+(%S+)%s+(%S+)') do
      if not path:match('^//') then
        deps[#deps + 1] = { path = path, version = ver, indirect = block:match(path .. '.+// indirect') ~= nil }
      end
    end
  end
  -- single-line require
  for path, ver in content:gmatch('\nrequire%s+(%S+)%s+(%S+)') do
    deps[#deps + 1] = { path = path, version = ver, indirect = false }
  end
  table.sort(deps, function(a, b) return a.path < b.path end)

  -- go.work workspace
  local work_content = read_file(root .. '/go.work')
  local workspace_uses = {}
  if work_content then
    for u in work_content:gmatch('\nuse%s+(%S+)') do
      workspace_uses[#workspace_uses + 1] = u
    end
  end

  -- Detect cmd/ entrypoints
  local cmds = {}
  local cmd_dir = root .. '/cmd'
  if vim.fn.isdirectory(cmd_dir) == 1 then
    local ok, entries = pcall(vim.fn.readdir, cmd_dir)
    if ok then
      for _, e in ipairs(entries) do
        if vim.fn.isdirectory(cmd_dir .. '/' .. e) == 1 then
          cmds[#cmds + 1] = e
        end
      end
    end
  end

  return {
    type         = 'go_mod',
    lang         = 'go',
    module       = module or vim.fn.fnamemodify(root, ':t'),
    name         = module and vim.fn.fnamemodify(module, ':t') or vim.fn.fnamemodify(root, ':t'),
    go_version   = go_ver or '1.21',
    deps         = deps,
    cmds         = cmds,
    workspace    = workspace_uses,
    is_workspace = #workspace_uses > 0,
  }
end

-- ── Detection core ────────────────────────────────────────────────────────────
local function parse_manifest(root, ptype)
  if ptype == 'maven' then return parse_pom(root) end
  if ptype == 'gradle' then return parse_gradle(root) end
  if ptype == 'cargo' then return parse_cargo(root) end
  if ptype == 'go_mod' then return parse_go_mod(root) end
  return { type = ptype, lang = MARKERS[ptype] and MARKERS[ptype].lang or 'unknown' }
end

function M.detect()
  -- Resolve a real starting directory: prefer the current buffer's location,
  -- fall back to cwd.  fnamemodify('', ':h') returns '.' which is safe but
  -- we normalise it to an absolute path so the loop termination check works.
  local buf_name = vim.api.nvim_buf_get_name(0)
  local curr
  if buf_name ~= '' then
    curr = vim.fn.fnamemodify(buf_name, ':h')
  end
  if not curr or curr == '' or curr == '.' then
    curr = vim.fn.getcwd()
  end
  curr       = vim.fn.fnamemodify(curr, ':p'):gsub('/+$', '') -- absolute, no trailing slash

  local dir  = curr
  local prev = nil
  while dir ~= '' and dir ~= prev do
    for ptype, marker in pairs(MARKERS) do
      if probe(dir, marker) then
        local info = parse_manifest(dir, ptype)
        M._project = {
          root = dir,
          type = ptype,
          lang = marker.lang,
          name = info.name or vim.fn.fnamemodify(dir, ':t'),
          info = info,
        }
        M._sub_projects = nil
        return M._project
      end
    end
    prev = dir
    dir  = vim.fn.fnamemodify(dir, ':h'):gsub('/+$', '')
  end

  -- Single-file fallback — only when a real named buffer is open
  local ft = buf_name ~= '' and vim.bo.filetype or ''
  if vim.tbl_contains({ 'java', 'rust', 'go', 'c', 'cpp' }, ft) then
    local file = vim.fn.expand('%:p')
    M._project = {
      root = vim.fn.fnamemodify(file, ':h'),
      type = 'single_file',
      lang = ft,
      name = vim.fn.fnamemodify(file, ':t'),
      info = { type = 'single_file', lang = ft, file = file },
    }
    return M._project
  end

  M._project = nil
  return nil
end

function M.get()
  if not M._project then M.detect() end
  return M._project
end

-- Force a re-parse of the manifest (e.g. after adding a dependency)
function M.reload()
  if not M._project then return M.detect() end
  M._project.info = parse_manifest(M._project.root, M._project.type)
  -- Refresh name in case it changed
  M._project.name = M._project.info.name or M._project.name
  return M._project
end

function M.set(p) M._project = p end

-- ── Sub-project / workspace detection ────────────────────────────────────────
function M.detect_sub_projects(root)
  root = root or vim.fn.getcwd()
  local found = {}
  local function scan(dir, depth)
    if depth > 2 then return end
    local ok, entries = pcall(vim.fn.readdir, dir)
    if not ok then return end
    for _, name in ipairs(entries) do
      local full = dir .. '/' .. name
      if vim.fn.isdirectory(full) == 1 then
        for ptype, marker in pairs(MARKERS) do
          if probe(full, marker) then
            local info = parse_manifest(full, ptype)
            found[#found + 1] = {
              root = full,
              type = ptype,
              lang = marker.lang,
              name = info.name or name,
              info = info,
            }
            goto continue
          end
        end
        scan(full, depth + 1)
        ::continue::
      end
    end
  end
  scan(root, 1)
  M._sub_projects = #found > 0 and found or nil
  return M._sub_projects
end

function M.get_sub_projects() return M._sub_projects end

function M.is_monorepo()
  local subs = M.detect_sub_projects(vim.fn.getcwd())
  return subs and #subs > 1
end

-- ── Tool validation ───────────────────────────────────────────────────────────
function M.tool_available(ptype)
  if ptype == 'gradle' and vim.fn.filereadable('./gradlew') == 1 then return true end
  local tool = TOOLS[ptype]
  if not tool then return true end
  return vim.fn.executable(tool.cmd) == 1
end

function M.require_tool(ptype)
  if M.tool_available(ptype) then return true end
  local tool = TOOLS[ptype]
  if tool then
    vim.notify(
      string.format('[Marvin] %s not found.\nInstall: %s', tool.name, tool.url),
      vim.log.levels.ERROR)
  end
  return false
end

-- ── Convenience accessors ─────────────────────────────────────────────────────
-- These let callers do  detector.info()  instead of  detector.get().info
function M.info()
  local p = M.get(); return p and p.info
end

function M.lang()
  local p = M.get(); return p and p.lang
end

function M.root()
  local p = M.get(); return p and p.root
end

function M.ptype()
  local p = M.get(); return p and p.type
end

return M
