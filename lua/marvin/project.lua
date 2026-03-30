-- lua/marvin/project.lua
-- Marvin side: Maven-specific detection, POM parsing, environment validation.
-- Jason side:  Multi-language project detection with monorepo support.
--              Exposed as M.detector (mirrors the old jason.detector API).

local M = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- MARVIN — Maven project detection
-- ══════════════════════════════════════════════════════════════════════════════

M.current_project = nil

function M.detect()
  local pom_path = M.find_pom()
  if pom_path then
    M.current_project = {
      root     = vim.fn.fnamemodify(pom_path, ':h'),
      pom_path = pom_path,
      info     = M.parse_pom(pom_path),
    }
    return true
  end
  M.current_project = nil
  return false
end

function M.find_pom()
  local curr_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':h')
  while curr_dir ~= '/' do
    local pom_path = curr_dir .. '/pom.xml'
    if vim.fn.filereadable(pom_path) == 1 then return pom_path end
    curr_dir = vim.fn.fnamemodify(curr_dir, ':h')
  end
  return nil
end

function M.get()
  if not M.current_project then M.detect() end
  return M.current_project
end

function M.parse_pom(pom_path)
  local content = M.read_file(pom_path)
  if not content then return nil end
  return {
    group_id    = M.extract_xml_tag(content, 'groupId'),
    artifact_id = M.extract_xml_tag(content, 'artifactId'),
    version     = M.extract_xml_tag(content, 'version'),
    packaging   = M.extract_xml_tag(content, 'packaging') or 'jar',
    profiles    = M.extract_profiles(content),
  }
end

function M.read_file(path)
  local file = io.open(path, 'r')
  if not file then return nil end
  local content = file:read('*all')
  file:close()
  return content
end

function M.extract_xml_tag(content, tag)
  return content:match('<' .. tag .. '>(.-)</' .. tag .. '>')
end

function M.extract_profiles(content)
  local profiles = {}
  for block in content:gmatch('<profile>(.-)</profile>') do
    local id = block:match('<id>(.-)</id>')
    if id then profiles[#profiles + 1] = id end
  end
  return profiles
end

function M.is_maven_available()
  local maven_cmd = (require('marvin').config.maven and require('marvin').config.maven.cmd) or 'mvn'
  local handle    = io.popen(maven_cmd .. ' --version 2>&1')
  if not handle then return false end
  local result = handle:read('*all')
  handle:close()
  return result:match('Apache Maven') ~= nil
end

function M.validate_environment()
  if not M.is_maven_available() then
    vim.notify('Maven is not installed', vim.log.levels.ERROR)
    return false
  end
  if not M.get() then
    vim.notify('Not in a maven project (pom.xml not found)', vim.log.levels.WARN)
    return false
  end
  return true
end

-- ══════════════════════════════════════════════════════════════════════════════
-- JASON — Multi-language project detection  (was jason.detector)
-- Access via  require('marvin.detector')  or the alias  M.detector  below.
-- ══════════════════════════════════════════════════════════════════════════════

local D           = {} -- Jason detector namespace
D.current_project = nil
D._sub_projects   = nil

local MARKERS     = {
  maven    = { file = 'pom.xml', language = 'java' },
  gradle   = { files = { 'build.gradle', 'build.gradle.kts' }, language = 'java' },
  cargo    = { file = 'Cargo.toml', language = 'rust' },
  go_mod   = { file = 'go.mod', language = 'go' },
  cmake    = { file = 'CMakeLists.txt', language = 'cpp' },
  makefile = { files = { 'Makefile', 'makefile' }, language = 'cpp' },
}

local function probe(dir, marker)
  if marker.file then
    return vim.fn.filereadable(dir .. '/' .. marker.file) == 1
  end
  for _, f in ipairs(marker.files or {}) do
    if vim.fn.filereadable(dir .. '/' .. f) == 1 then return true end
  end
  return false
end

function D.detect()
  local curr_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':h')
  if curr_dir == '' then curr_dir = vim.fn.getcwd() end

  while curr_dir ~= '/' do
    for ptype, marker in pairs(MARKERS) do
      if probe(curr_dir, marker) then
        D.current_project = {
          root     = curr_dir,
          type     = ptype,
          language = marker.language,
          name     = vim.fn.fnamemodify(curr_dir, ':t'),
        }
        D._sub_projects = nil
        return true
      end
    end
    curr_dir = vim.fn.fnamemodify(curr_dir, ':h')
  end

  -- Single-file fallback
  local ft = vim.bo.filetype
  if vim.tbl_contains({ 'java', 'rust', 'go', 'c', 'cpp' }, ft) then
    local file = vim.fn.expand('%:p')
    D.current_project = {
      root     = vim.fn.fnamemodify(file, ':h'),
      type     = 'single_file',
      language = ft,
      file     = file,
      name     = vim.fn.fnamemodify(file, ':t'),
    }
    return true
  end

  D.current_project = nil
  return false
end

function D.detect_sub_projects(root)
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
            found[#found + 1] = {
              root = full,
              type = ptype,
              language = marker.language,
              name = name,
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
  D._sub_projects = #found > 0 and found or nil
  return D._sub_projects
end

function D.is_monorepo()
  local subs = D.detect_sub_projects(vim.fn.getcwd())
  return subs and #subs > 1
end

function D.get_sub_projects() return D._sub_projects end

function D.get_project()
  if not D.current_project then D.detect() end
  return D.current_project
end

function D.set(p) D.current_project = p end

function D.get_language(ptype)
  return (MARKERS[ptype] or {}).language or vim.bo.filetype or 'unknown'
end

-- Tool validators
local TOOLS = {
  maven       = { cmd = 'mvn', name = 'Maven', install = 'https://maven.apache.org/install.html' },
  gradle      = { cmd = 'gradle', name = 'Gradle', install = 'https://gradle.org/install/' },
  cargo       = { cmd = 'cargo', name = 'Cargo', install = 'https://rustup.rs' },
  go_mod      = { cmd = 'go', name = 'Go', install = 'https://go.dev/dl/' },
  cmake       = { cmd = 'cmake', name = 'CMake', install = 'https://cmake.org/download/' },
  makefile    = { cmd = 'make', name = 'Make', install = 'sudo apt install build-essential' },
  single_file = nil,
}

function D.validate_environment(ptype)
  if ptype == 'gradle' and vim.fn.filereadable('./gradlew') == 1 then return true end
  local tool = TOOLS[ptype]
  if not tool then return true end
  if vim.fn.executable(tool.cmd) == 0 then
    vim.notify(
      string.format('[jason] %s not found.\nInstall: %s', tool.name, tool.install),
      vim.log.levels.ERROR)
    return false
  end
  return true
end

function D.check_command(cmd, name)
  if vim.fn.executable(cmd) == 0 then
    vim.notify(name .. ' not found in PATH', vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Expose the detector sub-namespace so callers can do:
--   require('marvin.detector')   (via the module alias file)
--   require('marvin.project').detector
M.detector = D

return M
