-- lua/jason/detector.lua
-- Project detection with monorepo / multi-root support.

local M           = {}

M.current_project = nil
M._sub_projects   = nil -- populated when monorepo is detected

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

-- ── Single-project detect ─────────────────────────────────────────────────────
function M.detect()
  local curr_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':h')
  if curr_dir == '' then curr_dir = vim.fn.getcwd() end

  while curr_dir ~= '/' do
    for ptype, marker in pairs(MARKERS) do
      if probe(curr_dir, marker) then
        M.current_project = {
          root     = curr_dir,
          type     = ptype,
          language = marker.language,
          name     = vim.fn.fnamemodify(curr_dir, ':t'),
        }
        M._sub_projects = nil
        return true
      end
    end
    curr_dir = vim.fn.fnamemodify(curr_dir, ':h')
  end

  -- Single-file fallback
  local ft = vim.bo.filetype
  if vim.tbl_contains({ 'java', 'rust', 'go', 'c', 'cpp' }, ft) then
    local file = vim.fn.expand('%:p')
    M.current_project = {
      root     = vim.fn.fnamemodify(file, ':h'),
      type     = 'single_file',
      language = ft,
      file     = file,
      name     = vim.fn.fnamemodify(file, ':t'),
    }
    return true
  end

  M.current_project = nil
  return false
end

-- ── Monorepo / multi-root detect ─────────────────────────────────────────────
-- Scans up to 2 directory levels under `root` for sub-projects.
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
            found[#found + 1] = {
              root     = full,
              type     = ptype,
              language = marker.language,
              name     = name,
            }
            -- Don't descend into a found project
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

-- Returns true if the cwd looks like a monorepo (>1 sub-projects at shallow depth).
function M.is_monorepo()
  local subs = M.detect_sub_projects(vim.fn.getcwd())
  return subs and #subs > 1
end

function M.get_sub_projects() return M._sub_projects end

-- ── Public ────────────────────────────────────────────────────────────────────
function M.get_project()
  if not M.current_project then M.detect() end
  return M.current_project
end

function M.set_project(p)
  M.current_project = p
end

function M.get_language(ptype)
  return (MARKERS[ptype] or {}).language or vim.bo.filetype or 'unknown'
end

-- ── Tool validators ───────────────────────────────────────────────────────────
local TOOLS = {
  maven       = { cmd = 'mvn', name = 'Maven', install = 'https://maven.apache.org/install.html' },
  gradle      = { cmd = 'gradle', name = 'Gradle', install = 'https://gradle.org/install/' },
  cargo       = { cmd = 'cargo', name = 'Cargo', install = 'https://rustup.rs' },
  go_mod      = { cmd = 'go', name = 'Go', install = 'https://go.dev/dl/' },
  cmake       = { cmd = 'cmake', name = 'CMake', install = 'https://cmake.org/download/' },
  makefile    = { cmd = 'make', name = 'Make', install = 'sudo apt install build-essential' },
  single_file = nil,
}

function M.validate_environment(ptype)
  -- Gradle wrapper doesn't need system gradle
  if ptype == 'gradle' and vim.fn.filereadable('./gradlew') == 1 then return true end

  local tool = TOOLS[ptype]
  if not tool then return true end -- single_file or unknown, let it try

  if vim.fn.executable(tool.cmd) == 0 then
    vim.notify(
      string.format('[jason] %s not found.\nInstall: %s', tool.name, tool.install),
      vim.log.levels.ERROR)
    return false
  end
  return true
end

function M.check_command(cmd, name)
  if vim.fn.executable(cmd) == 0 then
    vim.notify(name .. ' not found in PATH', vim.log.levels.ERROR)
    return false
  end
  return true
end

return M
