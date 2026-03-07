-- marvin/wayland_protocols.lua
-- Shared Wayland protocol XML → header generation logic.
-- Used by meson_creator, cmake_creator, and makefile_creator.
--
-- Workflow:
--   1. Scan all source/header files for #include "*-protocol.h" patterns
--   2. Map each needed header to its source XML (wayland-protocols or wlroots gitlab)
--   3. Ensure the XML exists locally (download wlr-* ones if missing)
--   4. Run wayland-scanner to generate the .h (and .c) files in the project root
--   5. Return a list of {xml, header, c_file} for the generators to embed

local M                 = {}

-- ── Protocol → XML source map ─────────────────────────────────────────────────
-- Each entry:
--   header  : the #include'd filename (e.g. "xdg-shell-protocol.h")
--   xml     : basename of the XML file
--   source  : 'wayland-protocols' | 'wlroots-gitlab' | 'project'
--   subpath : relative path under pkgdatadir (for wayland-protocols entries)
--             or path under wlroots protocol/ dir (for wlroots-gitlab entries)

local PROTO_MAP         = {
  -- ── stable ──────────────────────────────────────────────────────────────────
  {
    header  = 'xdg-shell-protocol.h',
    xml     = 'xdg-shell.xml',
    source  = 'wayland-protocols',
    subpath = 'stable/xdg-shell/xdg-shell.xml'
  },

  {
    header  = 'tablet-v2-protocol.h',
    xml     = 'tablet-v2.xml',
    source  = 'wayland-protocols',
    subpath = 'stable/tablet/tablet-v2.xml'
  },

  {
    header  = 'presentation-time-protocol.h',
    xml     = 'presentation-time.xml',
    source  = 'wayland-protocols',
    subpath = 'stable/presentation-time/presentation-time.xml'
  },

  {
    header  = 'viewporter-protocol.h',
    xml     = 'viewporter.xml',
    source  = 'wayland-protocols',
    subpath = 'stable/viewporter/viewporter.xml'
  },

  -- ── staging ─────────────────────────────────────────────────────────────────
  {
    header  = 'content-type-v1-protocol.h',
    xml     = 'content-type-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'staging/content-type/content-type-v1.xml'
  },

  {
    header  = 'cursor-shape-v1-protocol.h',
    xml     = 'cursor-shape-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'staging/cursor-shape/cursor-shape-v1.xml'
  },

  {
    header  = 'tearing-control-v1-protocol.h',
    xml     = 'tearing-control-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'staging/tearing-control/tearing-control-v1.xml'
  },

  {
    header  = 'ext-session-lock-v1-protocol.h',
    xml     = 'ext-session-lock-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'staging/ext-session-lock/ext-session-lock-v1.xml'
  },

  {
    header  = 'xdg-activation-v1-protocol.h',
    xml     = 'xdg-activation-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'staging/xdg-activation/xdg-activation-v1.xml'
  },

  -- ── unstable ────────────────────────────────────────────────────────────────
  {
    header  = 'fullscreen-shell-unstable-v1-protocol.h',
    xml     = 'fullscreen-shell-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/fullscreen-shell/fullscreen-shell-unstable-v1.xml'
  },

  {
    header  = 'pointer-constraints-unstable-v1-protocol.h',
    xml     = 'pointer-constraints-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/pointer-constraints/pointer-constraints-unstable-v1.xml'
  },

  {
    header  = 'relative-pointer-unstable-v1-protocol.h',
    xml     = 'relative-pointer-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/relative-pointer/relative-pointer-unstable-v1.xml'
  },

  {
    header  = 'xdg-output-unstable-v1-protocol.h',
    xml     = 'xdg-output-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/xdg-output/xdg-output-unstable-v1.xml'
  },

  {
    header  = 'idle-inhibit-unstable-v1-protocol.h',
    xml     = 'idle-inhibit-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/idle-inhibit/idle-inhibit-unstable-v1.xml'
  },

  {
    header  = 'linux-dmabuf-unstable-v1-protocol.h',
    xml     = 'linux-dmabuf-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/linux-dmabuf/linux-dmabuf-unstable-v1.xml'
  },

  {
    header      = 'xdg-decoration-unstable-v1-protocol.h',
    xml         = 'xdg-decoration-unstable-v1.xml',
    source      = 'wayland-protocols',
    -- try staging first, fall back to unstable
    subpath     = 'unstable/xdg-decoration/xdg-decoration-unstable-v1.xml',
    subpath_alt = 'staging/xdg-decoration/xdg-decoration-unstable-v1.xml'
  },

  {
    header  = 'input-method-unstable-v1-protocol.h',
    xml     = 'input-method-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/input-method/input-method-unstable-v1.xml'
  },

  {
    header  = 'text-input-unstable-v3-protocol.h',
    xml     = 'text-input-unstable-v3.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/text-input/text-input-unstable-v3.xml'
  },

  -- ── wlroots-specific (downloaded from gitlab if not in project) ─────────────
  {
    header  = 'wlr-layer-shell-unstable-v1-protocol.h',
    xml     = 'wlr-layer-shell-unstable-v1.xml',
    source  = 'wlroots-gitlab',
    subpath = 'protocol/wlr-layer-shell-unstable-v1.xml'
  },

  {
    header  = 'wlr-output-power-management-unstable-v1-protocol.h',
    xml     = 'wlr-output-power-management-unstable-v1.xml',
    source  = 'wlroots-gitlab',
    subpath = 'protocol/wlr-output-power-management-unstable-v1.xml'
  },

  {
    header  = 'wlr-screencopy-unstable-v1-protocol.h',
    xml     = 'wlr-screencopy-unstable-v1.xml',
    source  = 'wlroots-gitlab',
    subpath = 'protocol/wlr-screencopy-unstable-v1.xml'
  },

  {
    header  = 'wlr-data-control-unstable-v1-protocol.h',
    xml     = 'wlr-data-control-unstable-v1.xml',
    source  = 'wlroots-gitlab',
    subpath = 'protocol/wlr-data-control-unstable-v1.xml'
  },

  {
    header  = 'wlr-foreign-toplevel-management-unstable-v1-protocol.h',
    xml     = 'wlr-foreign-toplevel-management-unstable-v1.xml',
    source  = 'wlroots-gitlab',
    subpath = 'protocol/wlr-foreign-toplevel-management-unstable-v1.xml'
  },

  {
    header  = 'wlr-input-inhibitor-unstable-v1-protocol.h',
    xml     = 'wlr-input-inhibitor-unstable-v1.xml',
    source  = 'wlroots-gitlab',
    subpath = 'protocol/wlr-input-inhibitor-unstable-v1.xml'
  },

  {
    header  = 'wlr-output-management-unstable-v1-protocol.h',
    xml     = 'wlr-output-management-unstable-v1.xml',
    source  = 'wlroots-gitlab',
    subpath = 'protocol/wlr-output-management-unstable-v1.xml'
  },

  {
    header  = 'wlr-virtual-pointer-unstable-v1-protocol.h',
    xml     = 'wlr-virtual-pointer-unstable-v1.xml',
    source  = 'wlroots-gitlab',
    subpath = 'protocol/wlr-virtual-pointer-unstable-v1.xml'
  },

  {
    header  = 'wlr-gamma-control-unstable-v1-protocol.h',
    xml     = 'wlr-gamma-control-unstable-v1.xml',
    source  = 'wlroots-gitlab',
    subpath = 'protocol/wlr-gamma-control-unstable-v1.xml'
  },

  {
    header  = 'wlr-export-dmabuf-unstable-v1-protocol.h',
    xml     = 'wlr-export-dmabuf-unstable-v1.xml',
    source  = 'wlroots-gitlab',
    subpath = 'protocol/wlr-export-dmabuf-unstable-v1.xml'
  },
}

local WLROOTS_GITLAB    = 'https://gitlab.freedesktop.org/wlroots/wlroots/-/raw/master/'
local WAYLAND_PROTO_URL = 'https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/'

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function run(cmd)
  local h = io.popen(cmd .. ' 2>&1'); if not h then return nil, 'popen failed' end
  local out = h:read('*a'); h:close()
  return out
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function get_wl_proto_dir()
  local h = io.popen('pkg-config --variable=pkgdatadir wayland-protocols 2>/dev/null')
  if not h then return nil end
  local d = vim.trim(h:read('*l') or ''); h:close()
  return d ~= '' and d or nil
end

-- ── Scan source tree for needed protocol headers ──────────────────────────────

local function scan_needed_protocols(root)
  local needed = {} -- header_name → true

  -- Use grep for speed — avoids slow Lua globpath '**' traversal
  -- Falls back to Lua glob if grep is unavailable
  local grep_pattern = [=[#\s*include\s*[<"][^>"]*-protocol\.h[>"]=]
  local grep_cmd = 'grep -rh'
      .. ' --include="*.c" --include="*.cpp" --include="*.h" --include="*.hpp"'
      .. ' -E ' .. vim.fn.shellescape(grep_pattern)
      .. ' ' .. vim.fn.shellescape(root)
      .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
      .. ' 2>/dev/null'

  local h = io.popen(grep_cmd)
  if h then
    for line in h:lines() do
      local hdr = line:match('#%s*include%s*[<"]([^>"]+%-protocol%.h)[>"]')
      if hdr then needed[hdr] = true end
    end
    h:close()
    return needed
  end

  -- Fallback: Lua-based scan (slower but always works)
  local skip = { build = true, builddir = true, ['.git'] = true }
  for _, pat in ipairs({ '*.c', '*.cpp', '*.h', '*.hpp' }) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do -- non-recursive, just top level
      local ok, lines = pcall(vim.fn.readfile, f)
      if ok then
        for _, line in ipairs(lines) do
          local hdr = line:match('#%s*include%s*[<"]([^>"]+%-protocol%.h)[>"]')
          if hdr then needed[hdr] = true end
        end
      end
    end
    -- also scan src/ and include/ one level deep
    for _, subdir in ipairs({ 'src', 'include', 'include/protocols' }) do
      for _, f in ipairs(vim.fn.globpath(root .. '/' .. subdir, pat, false, true)) do
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            local hdr = line:match('#%s*include%s*[<"]([^>"]+%-protocol%.h)[>"]')
            if hdr then needed[hdr] = true end
          end
        end
      end
    end
  end
  return needed
end

-- ── Ensure XML exists locally, downloading if needed ─────────────────────────

-- Directory where downloaded XMLs and generated headers/sources are stored.
-- Using include/protocols/ keeps generated files out of the project root.
local function proto_dir(root)
  local d = root .. '/include/protocols'
  if vim.fn.isdirectory(d) == 0 then
    vim.fn.mkdir(d, 'p')
  end
  return d
end

local function download_xml(url, dest)
  vim.notify('[Marvin] Downloading ' .. vim.fn.fnamemodify(dest, ':t') .. ' …', vim.log.levels.INFO)
  local out = run('curl -fsSL ' .. vim.fn.shellescape(url) .. ' -o ' .. vim.fn.shellescape(dest))
  if file_exists(dest) then
    return dest
  else
    vim.notify('[Marvin] Download failed: ' .. (out or ''), vim.log.levels.WARN)
    return nil
  end
end

local function ensure_xml(root, entry, wl_proto_dir)
  local pdir = proto_dir(root)
  local dest = pdir .. '/' .. entry.xml

  -- 1. Already in include/protocols/
  if file_exists(dest) then return dest, true end

  -- 2. In project root (legacy) — copy into include/protocols/
  local proj_xml = root .. '/' .. entry.xml
  if file_exists(proj_xml) then
    vim.fn.system('cp ' .. vim.fn.shellescape(proj_xml) .. ' ' .. vim.fn.shellescape(dest))
    return dest, true
  end

  -- 3. System wayland-protocols install — copy into include/protocols/
  if entry.source == 'wayland-protocols' and wl_proto_dir then
    local sys = wl_proto_dir .. '/' .. entry.subpath
    if not file_exists(sys) and entry.subpath_alt then
      sys = wl_proto_dir .. '/' .. entry.subpath_alt
    end
    if file_exists(sys) then
      vim.fn.system('cp ' .. vim.fn.shellescape(sys) .. ' ' .. vim.fn.shellescape(dest))
      if file_exists(dest) then return dest, true end
    end
    -- System package not installed: download from wayland-protocols gitlab
    return download_xml(WAYLAND_PROTO_URL .. entry.subpath, dest), true
  end

  -- 4. wlroots-specific: download from wlroots gitlab
  if entry.source == 'wlroots-gitlab' then
    return download_xml(WLROOTS_GITLAB .. entry.subpath, dest), true
  end

  return nil, false
end

-- ── Generate a single protocol header via wayland-scanner ────────────────────

local function generate_header(xml_path, root, header_name)
  local pdir = proto_dir(root)
  -- prefer include/protocols/, fall back to root for legacy compat
  local dest = pdir .. '/' .. header_name
  if file_exists(dest) then return dest end
  -- also check root in case user generated it manually before
  if file_exists(root .. '/' .. header_name) then return root .. '/' .. header_name end

  local cmd = 'wayland-scanner client-header '
      .. vim.fn.shellescape(xml_path) .. ' '
      .. vim.fn.shellescape(dest)
  local out = run(cmd)
  if file_exists(dest) then
    vim.notify('[Marvin] Generated ' .. header_name, vim.log.levels.INFO)
    return dest
  else
    vim.notify('[Marvin] wayland-scanner failed for ' .. header_name .. ': ' .. (out or ''), vim.log.levels.WARN)
    return nil
  end
end

local function generate_c_source(xml_path, root, header_name)
  local pdir   = proto_dir(root)
  local c_name = header_name:gsub('%-protocol%.h$', '-protocol.c')
  local dest   = pdir .. '/' .. c_name
  if file_exists(dest) then return dest, c_name end
  if file_exists(root .. '/' .. c_name) then return root .. '/' .. c_name, c_name end

  local cmd = 'wayland-scanner private-code '
      .. vim.fn.shellescape(xml_path) .. ' '
      .. vim.fn.shellescape(dest)
  run(cmd)
  return file_exists(dest) and dest or nil, c_name
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Scan the project, resolve all needed protocol XMLs, generate headers + C sources.
--
-- XMLs are resolved in this order:
--   1. include/protocols/<name>.xml  (already in repo)
--   2. <project_root>/<name>.xml     (legacy location)
--   3. System wayland-protocols install (/usr/share/wayland-protocols/...)
--   4. Downloaded from wayland-protocols gitlab → include/protocols/
--   5. Downloaded from wlroots gitlab           → include/protocols/
--
-- Generated headers and C sources go into include/protocols/.
--
-- Returns a list of resolved protocol entries:
--   { xml      = 'xdg-shell.xml',               -- XML basename
--     xml_path = '/abs/path/to/xdg-shell.xml',  -- absolute path to XML source
--     header   = 'xdg-shell-protocol.h',        -- generated header filename
--     c_file   = 'xdg-shell-protocol.c',        -- generated C source filename (or nil)
--     in_root  = true/false,                    -- whether XML is inside the project tree
--   }
-- Headers that wlroots-0.x itself requires unconditionally.
-- When wlroots is detected as a dependency we generate all of these.
local WLROOTS_REQUIRED = {
  'xdg-shell-protocol.h',
  'wlr-layer-shell-unstable-v1-protocol.h',
  'wlr-output-power-management-unstable-v1-protocol.h',
  'tablet-v2-protocol.h',
  'content-type-v1-protocol.h',
  'cursor-shape-v1-protocol.h',
  'tearing-control-v1-protocol.h',
  'fullscreen-shell-unstable-v1-protocol.h',
  'pointer-constraints-unstable-v1-protocol.h',
}

local function uses_wlroots(root)
  -- check meson.build, Makefile, CMakeLists.txt, or pkg-config map for wlroots dep
  for _, fname in ipairs({ 'meson.build', 'Makefile', 'CMakeLists.txt' }) do
    local ok, lines = pcall(vim.fn.readfile, root .. '/' .. fname)
    if ok then
      for _, line in ipairs(lines) do
        if line:match('wlroots') then return true end
      end
    end
  end
  -- also check if any source includes a wlr/ header
  local h = io.popen('grep -rl "wlr/" ' .. vim.fn.shellescape(root)
    .. ' --include="*.c" --include="*.h" --include="*.cpp" --include="*.hpp"'
    .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git 2>/dev/null | head -1')
  if h then
    local found = h:read('*l'); h:close()
    if found and found ~= '' then return true end
  end
  return false
end

function M.resolve(root)
  local needed     = scan_needed_protocols(root)
  local wl_dir     = get_wl_proto_dir()
  local results    = {}
  local header_map = {} -- deduplicate

  -- if project uses wlroots, add all headers wlroots itself requires
  if uses_wlroots(root) then
    for _, hdr in ipairs(WLROOTS_REQUIRED) do
      needed[hdr] = true
    end
  end

  -- pick up any .xml already in project root or include/protocols/
  for _, glob_root in ipairs({ root, root .. '/include/protocols' }) do
    for _, f in ipairs(vim.fn.globpath(glob_root, '*.xml', false, true)) do
      local ok, lines = pcall(vim.fn.readfile, f)
      if ok then
        for _, line in ipairs(lines) do
          if line:match('<protocol') then
            local xml_base = vim.fn.fnamemodify(f, ':t')
            local hdr      = xml_base:gsub('%.xml$', '-protocol.h')
            needed[hdr]    = true
            break
          end
        end
      end
    end
  end

  for hdr in pairs(needed) do
    if not header_map[hdr] then
      -- find matching PROTO_MAP entry
      local entry = nil
      for _, e in ipairs(PROTO_MAP) do
        if e.header == hdr then
          entry = e; break
        end
      end

      if entry then
        local xml_path, xml_in_proj = ensure_xml(root, entry, wl_dir)
        if xml_path then
          local hdr_path        = generate_header(xml_path, root, hdr)
          local c_path, c_name  = generate_c_source(xml_path, root, hdr)
          results[#results + 1] = {
            xml      = entry.xml,
            xml_path = xml_path,
            header   = hdr,
            c_file   = c_name,
            -- in_root: true means the XML is inside the project tree
            -- (either pre-committed or downloaded into include/protocols/)
            in_root  = xml_in_proj,
          }
          header_map[hdr]       = true
        end
      else
        -- unknown protocol header — warn but don't crash
        vim.notify('[Marvin] Unknown protocol header: ' .. hdr
          .. ' (add manually to wayland_protocols.lua)', vim.log.levels.WARN)
      end
    end
  end

  return results
end

-- Convenience: just return list of XML basenames found in project root
-- (for generators that only need the xml names to embed in build files)
function M.project_xmls(root)
  local xmls = {}
  for _, f in ipairs(vim.fn.globpath(root, '*.xml', false, true)) do
    local ok, lines = pcall(vim.fn.readfile, f)
    if ok then
      for _, line in ipairs(lines) do
        if line:match('<protocol') then
          xmls[#xmls + 1] = vim.fn.fnamemodify(f, ':t')
          break
        end
      end
    end
  end
  return xmls
end

return M
