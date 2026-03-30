-- marvin/wayland_protocols.lua
-- Shared Wayland protocol XML → header generation logic.
-- Used by meson_creator, cmake_creator, and makefile_creator.
--
-- Workflow:
--   1. Scan all source/header files for #include "*-protocol.h" patterns
--   2. Map each needed header to its source XML
--   3. For wayland-protocols entries: resolve to system pkgdatadir path (no copy)
--   4. For wlroots-specific entries: resolve from installed wlroots pkgdatadir,
--      fall back to downloading into include/protocols/ only if not on system
--   5. Return resolved entries with xml_path (abs), xml_ref (meson expression),
--      in_root (true only if XML lives inside project tree)
--
-- The key difference from the old approach:
--   • wayland-protocols XMLs are NEVER copied — Meson references them by
--     absolute system path via wayland_protocols_dep.get_variable('pkgdatadir')
--   • wlroots protocol XMLs are resolved from the installed wlroots pkgdatadir,
--     and only downloaded/vendored as a last resort
--   • No .h/.c files are pre-generated — that is entirely Meson's job

local M = {}

-- ── Protocol → XML source map ─────────────────────────────────────────────────
-- source:
--   'wayland-protocols'  → system pkgdatadir, never copy into project
--   'wlroots'            → wlroots pkgdatadir (installed), download if missing
-- subpath: path under pkgdatadir

local PROTO_MAP = {
  -- ── stable ──────────────────────────────────────────────────────────────────
  {
    header  = 'xdg-shell-protocol.h',
    xml     = 'xdg-shell.xml',
    source  = 'wayland-protocols',
    subpath = 'stable/xdg-shell/xdg-shell.xml',
  },
  {
    header  = 'tablet-v2-protocol.h',
    xml     = 'tablet-v2.xml',
    source  = 'wayland-protocols',
    subpath = 'stable/tablet/tablet-v2.xml',
  },
  {
    header  = 'presentation-time-protocol.h',
    xml     = 'presentation-time.xml',
    source  = 'wayland-protocols',
    subpath = 'stable/presentation-time/presentation-time.xml',
  },
  {
    header  = 'viewporter-protocol.h',
    xml     = 'viewporter.xml',
    source  = 'wayland-protocols',
    subpath = 'stable/viewporter/viewporter.xml',
  },

  -- ── staging ─────────────────────────────────────────────────────────────────
  {
    header  = 'content-type-v1-protocol.h',
    xml     = 'content-type-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'staging/content-type/content-type-v1.xml',
  },
  {
    header  = 'cursor-shape-v1-protocol.h',
    xml     = 'cursor-shape-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'staging/cursor-shape/cursor-shape-v1.xml',
  },
  {
    header  = 'tearing-control-v1-protocol.h',
    xml     = 'tearing-control-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'staging/tearing-control/tearing-control-v1.xml',
  },
  {
    header  = 'ext-session-lock-v1-protocol.h',
    xml     = 'ext-session-lock-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'staging/ext-session-lock/ext-session-lock-v1.xml',
  },
  {
    header  = 'xdg-activation-v1-protocol.h',
    xml     = 'xdg-activation-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'staging/xdg-activation/xdg-activation-v1.xml',
  },

  -- ── unstable ────────────────────────────────────────────────────────────────
  {
    header  = 'fullscreen-shell-unstable-v1-protocol.h',
    xml     = 'fullscreen-shell-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/fullscreen-shell/fullscreen-shell-unstable-v1.xml',
  },
  {
    header  = 'pointer-constraints-unstable-v1-protocol.h',
    xml     = 'pointer-constraints-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/pointer-constraints/pointer-constraints-unstable-v1.xml',
  },
  {
    header  = 'relative-pointer-unstable-v1-protocol.h',
    xml     = 'relative-pointer-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/relative-pointer/relative-pointer-unstable-v1.xml',
  },
  {
    header  = 'xdg-output-unstable-v1-protocol.h',
    xml     = 'xdg-output-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/xdg-output/xdg-output-unstable-v1.xml',
  },
  {
    header  = 'idle-inhibit-unstable-v1-protocol.h',
    xml     = 'idle-inhibit-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/idle-inhibit/idle-inhibit-unstable-v1.xml',
  },
  {
    header  = 'linux-dmabuf-unstable-v1-protocol.h',
    xml     = 'linux-dmabuf-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/linux-dmabuf/linux-dmabuf-unstable-v1.xml',
  },
  {
    header      = 'xdg-decoration-unstable-v1-protocol.h',
    xml         = 'xdg-decoration-unstable-v1.xml',
    source      = 'wayland-protocols',
    subpath     = 'unstable/xdg-decoration/xdg-decoration-unstable-v1.xml',
    subpath_alt = 'staging/xdg-decoration/xdg-decoration-unstable-v1.xml',
  },
  {
    header  = 'input-method-unstable-v1-protocol.h',
    xml     = 'input-method-unstable-v1.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/input-method/input-method-unstable-v1.xml',
  },
  {
    header  = 'text-input-unstable-v3-protocol.h',
    xml     = 'text-input-unstable-v3.xml',
    source  = 'wayland-protocols',
    subpath = 'unstable/text-input/text-input-unstable-v3.xml',
  },

  -- ── wlroots-specific ────────────────────────────────────────────────────────
  -- These live in the wlroots package's own pkgdatadir/protocols/.
  -- If wlroots is not installed with protocol XMLs (some distros strip them),
  -- we fall back to downloading from gitlab.
  {
    header  = 'wlr-layer-shell-unstable-v1-protocol.h',
    xml     = 'wlr-layer-shell-unstable-v1.xml',
    source  = 'wlroots',
    subpath = 'wlr-layer-shell-unstable-v1.xml',
    gitlab  = 'protocol/wlr-layer-shell-unstable-v1.xml',
  },
  {
    header  = 'wlr-output-power-management-unstable-v1-protocol.h',
    xml     = 'wlr-output-power-management-unstable-v1.xml',
    source  = 'wlroots',
    subpath = 'wlr-output-power-management-unstable-v1.xml',
    gitlab  = 'protocol/wlr-output-power-management-unstable-v1.xml',
  },
  {
    header  = 'wlr-screencopy-unstable-v1-protocol.h',
    xml     = 'wlr-screencopy-unstable-v1.xml',
    source  = 'wlroots',
    subpath = 'wlr-screencopy-unstable-v1.xml',
    gitlab  = 'protocol/wlr-screencopy-unstable-v1.xml',
  },
  {
    header  = 'wlr-data-control-unstable-v1-protocol.h',
    xml     = 'wlr-data-control-unstable-v1.xml',
    source  = 'wlroots',
    subpath = 'wlr-data-control-unstable-v1.xml',
    gitlab  = 'protocol/wlr-data-control-unstable-v1.xml',
  },
  {
    header  = 'wlr-foreign-toplevel-management-unstable-v1-protocol.h',
    xml     = 'wlr-foreign-toplevel-management-unstable-v1.xml',
    source  = 'wlroots',
    subpath = 'wlr-foreign-toplevel-management-unstable-v1.xml',
    gitlab  = 'protocol/wlr-foreign-toplevel-management-unstable-v1.xml',
  },
  {
    header  = 'wlr-input-inhibitor-unstable-v1-protocol.h',
    xml     = 'wlr-input-inhibitor-unstable-v1.xml',
    source  = 'wlroots',
    subpath = 'wlr-input-inhibitor-unstable-v1.xml',
    gitlab  = 'protocol/wlr-input-inhibitor-unstable-v1.xml',
  },
  {
    header  = 'wlr-output-management-unstable-v1-protocol.h',
    xml     = 'wlr-output-management-unstable-v1.xml',
    source  = 'wlroots',
    subpath = 'wlr-output-management-unstable-v1.xml',
    gitlab  = 'protocol/wlr-output-management-unstable-v1.xml',
  },
  {
    header  = 'wlr-virtual-pointer-unstable-v1-protocol.h',
    xml     = 'wlr-virtual-pointer-unstable-v1.xml',
    source  = 'wlroots',
    subpath = 'wlr-virtual-pointer-unstable-v1.xml',
    gitlab  = 'protocol/wlr-virtual-pointer-unstable-v1.xml',
  },
  {
    header  = 'wlr-gamma-control-unstable-v1-protocol.h',
    xml     = 'wlr-gamma-control-unstable-v1.xml',
    source  = 'wlroots',
    subpath = 'wlr-gamma-control-unstable-v1.xml',
    gitlab  = 'protocol/wlr-gamma-control-unstable-v1.xml',
  },
  {
    header  = 'wlr-export-dmabuf-unstable-v1-protocol.h',
    xml     = 'wlr-export-dmabuf-unstable-v1.xml',
    source  = 'wlroots',
    subpath = 'wlr-export-dmabuf-unstable-v1.xml',
    gitlab  = 'protocol/wlr-export-dmabuf-unstable-v1.xml',
  },
}

local WLROOTS_GITLAB = 'https://gitlab.freedesktop.org/wlroots/wlroots/-/raw/master/'

-- Headers that wlroots itself requires unconditionally when used as a dep.
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

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function run(cmd)
  local h = io.popen(cmd .. ' 2>&1')
  if not h then return nil end
  local out = h:read('*a'); h:close()
  return out
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

-- Query a pkg-config variable. Returns nil if package not found.
local function pkg_variable(pkg, var)
  local h = io.popen('pkg-config --variable=' .. var .. ' ' .. pkg .. ' 2>/dev/null')
  if not h then return nil end
  local d = vim.trim(h:read('*l') or ''); h:close()
  return d ~= '' and d or nil
end

-- Directory where vendored (wlroots-specific) XMLs are stored when we must
-- fall back to downloading. wayland-protocols XMLs are NEVER put here.
local function vendor_dir(root)
  local d = root .. '/include/protocols'
  if vim.fn.isdirectory(d) == 0 then vim.fn.mkdir(d, 'p') end
  return d
end

local function download_xml(url, dest)
  vim.notify('[Marvin] Downloading ' .. vim.fn.fnamemodify(dest, ':t') .. ' …', vim.log.levels.INFO)
  run('curl -fsSL ' .. vim.fn.shellescape(url) .. ' -o ' .. vim.fn.shellescape(dest))
  if file_exists(dest) then return dest end
  vim.notify('[Marvin] Download failed: ' .. dest, vim.log.levels.WARN)
  return nil
end

-- ── Scan source tree for needed protocol headers ──────────────────────────────

local function scan_needed_protocols(root)
  local needed = {}
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

  -- Fallback: Lua scan
  for _, subdir in ipairs({ '', 'src', 'include', 'include/protocols' }) do
    local base = subdir == '' and root or (root .. '/' .. subdir)
    for _, pat in ipairs({ '*.c', '*.cpp', '*.h', '*.hpp' }) do
      for _, f in ipairs(vim.fn.globpath(base, pat, false, true)) do
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

local function uses_wlroots(root)
  for _, fname in ipairs({ 'meson.build', 'Makefile', 'CMakeLists.txt' }) do
    local ok, lines = pcall(vim.fn.readfile, root .. '/' .. fname)
    if ok then
      for _, line in ipairs(lines) do
        if line:match('wlroots') then return true end
      end
    end
  end
  local h = io.popen('grep -rl "wlr/" ' .. vim.fn.shellescape(root)
    .. ' --include="*.c" --include="*.h" --include="*.cpp" --include="*.hpp"'
    .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git 2>/dev/null | head -1')
  if h then
    local found = h:read('*l'); h:close()
    if found and found ~= '' then return true end
  end
  return false
end

-- ── Resolve a single protocol entry ──────────────────────────────────────────
--
-- Returns:
--   xml_path  : absolute path to XML (system or vendored)
--   xml_ref   : how to reference it in meson.build
--                 'system_wp'  → use wp_dir / 'subpath'   (wayland-protocols)
--                 'system_wlr' → use wlr_dir / 'subpath'  (wlroots pkgdatadir)
--                 'vendored'   → files('include/protocols/<xml>') in meson
--   in_root   : true if the XML is inside the project tree (vendored)

local function resolve_entry(root, entry, wp_dir, wlr_proto_dir)
  if entry.source == 'wayland-protocols' then
    -- Prefer system install — never copy into project
    if wp_dir then
      local sys = wp_dir .. '/' .. entry.subpath
      if not file_exists(sys) and entry.subpath_alt then
        sys = wp_dir .. '/' .. entry.subpath_alt
      end
      if file_exists(sys) then
        return sys, 'system_wp', entry.subpath, false
      end
    end
    -- wayland-protocols not installed: vendor as last resort with a warning
    vim.notify(
      '[Marvin] wayland-protocols not found on system, vendoring ' .. entry.xml
      .. ' (install wayland-protocols for cleaner builds)',
      vim.log.levels.WARN)
    local dest = vendor_dir(root) .. '/' .. entry.xml
    if not file_exists(dest) then
      local url = 'https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/' .. entry.subpath
      download_xml(url, dest)
    end
    return file_exists(dest) and dest or nil, 'vendored', nil, true
  elseif entry.source == 'wlroots' then
    -- 1. wlroots pkgdatadir (installed protocols dir)
    if wlr_proto_dir then
      local sys = wlr_proto_dir .. '/' .. entry.subpath
      if file_exists(sys) then
        return sys, 'system_wlr', entry.subpath, false
      end
    end
    -- 2. Already vendored in project
    local vendored = vendor_dir(root) .. '/' .. entry.xml
    if file_exists(vendored) then
      return vendored, 'vendored', nil, true
    end
    -- 3. Download from gitlab (last resort)
    vim.notify(
      '[Marvin] wlroots protocol XMLs not found in pkgdatadir, downloading ' .. entry.xml,
      vim.log.levels.INFO)
    local url  = WLROOTS_GITLAB .. entry.gitlab
    local path = download_xml(url, vendored)
    return path, 'vendored', nil, true
  end

  return nil, nil, nil, false
end

-- ── Public API ────────────────────────────────────────────────────────────────
--
-- Scan the project, resolve all needed protocol XMLs.
-- Does NOT pre-generate .h/.c files — that is entirely the build system's job.
--
-- Returns a list of resolved protocol entries:
--   {
--     xml         = 'xdg-shell.xml',
--     xml_path    = '/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml',
--     xml_ref     = 'system_wp' | 'system_wlr' | 'vendored',
--     xml_subpath = 'stable/xdg-shell/xdg-shell.xml',  -- set when xml_ref == system_*
--     header      = 'xdg-shell-protocol.h',
--     in_root     = false,   -- false for system refs, true for vendored
--   }

function M.resolve(root)
  local needed        = scan_needed_protocols(root)
  local wp_dir        = pkg_variable('wayland-protocols', 'pkgdatadir')
  -- wlroots may install protocol XMLs into its own pkgdatadir/protocols/
  local wlr_pkg_dir   = pkg_variable('wlroots-0.18', 'pkgdatadir')
      or pkg_variable('wlroots', 'pkgdatadir')
  local wlr_proto_dir = wlr_pkg_dir and (wlr_pkg_dir .. '/protocols') or nil

  -- Add wlroots-required protocols when project uses wlroots
  if uses_wlroots(root) then
    for _, hdr in ipairs(WLROOTS_REQUIRED) do
      needed[hdr] = true
    end
  end

  local results    = {}
  local header_map = {}

  for hdr in pairs(needed) do
    if not header_map[hdr] then
      local entry = nil
      for _, e in ipairs(PROTO_MAP) do
        if e.header == hdr then
          entry = e; break
        end
      end

      if entry then
        local xml_path, xml_ref, xml_subpath, in_root =
            resolve_entry(root, entry, wp_dir, wlr_proto_dir)

        if xml_path then
          results[#results + 1] = {
            xml         = entry.xml,
            xml_path    = xml_path,
            xml_ref     = xml_ref,
            xml_subpath = xml_subpath,
            header      = hdr,
            in_root     = in_root,
            source      = entry.source,
          }
          header_map[hdr] = true
        end
      else
        vim.notify('[Marvin] Unknown protocol header: ' .. hdr
          .. ' (add to wayland_protocols.lua)', vim.log.levels.WARN)
      end
    end
  end

  return results
end

-- Convenience: list of XML basenames for protocols vendored in the project tree.
function M.project_xmls(root)
  local xmls = {}
  for _, f in ipairs(vim.fn.globpath(root .. '/include/protocols', '*.xml', false, true)) do
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
