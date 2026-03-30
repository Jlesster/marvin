-- lua/marvin/cmake_creator.lua
-- Interactive CMakeLists.txt wizard.
-- Generates a well-structured CMakeLists.txt for C or C++ projects,
-- with optional auto-link detection, pkg-config detection, test target
-- (CTest + gtest/catch2), and install rules.

local M = {}

local function ui()
	return require("marvin.ui")
end
local function det()
	return require("marvin.detector")
end
local function plain(it)
	return it.label
end

-- ── pkg-config header → package name map ──────────────────────────────────────
-- Mirrors the map in makefile_creator.lua exactly.

-- ── pkg-config scan ───────────────────────────────────────────────────────────
-- ── Dynamic pkg-config dependency detection ──────────────────────────────────
-- Builds a header→package reverse map from whatever is installed on this system.
-- No hardcoded list needed — works for any library with a .pc file.

local _hdr_pkg_map_cache = nil
local function get_hdr_pkg_map()
	if _hdr_pkg_map_cache then
		return _hdr_pkg_map_cache
	end
	local map = {}
	local nix = require("marvin.nix")

	-- FHS defaults + compiler-derived dirs (covers /nix/store/... on NixOS)
	local bases = { "/usr/include", "/usr/local/include" }
	for _, d in ipairs(nix.compiler_inc_dirs()) do
		bases[#bases + 1] = d
	end

	local h = io.popen("pkg-config --list-all 2>/dev/null")
	if not h then
		_hdr_pkg_map_cache = map
		return map
	end
	local pkgs = {}
	for line in h:lines() do
		local name = line:match("^(%S+)")
		if name then
			pkgs[#pkgs + 1] = name
		end
	end
	h:close()

	local scanned = {}
	for _, pkg in ipairs(pkgs) do
		local dirs = {}
		local ch = io.popen("pkg-config --cflags-only-I " .. pkg .. " 2>/dev/null")
		if ch then
			local out = ch:read("*a")
			ch:close()
			for token in out:gmatch("%S+") do
				if token:sub(1, 2) == "-I" then
					dirs[#dirs + 1] = token:sub(3)
				end
			end
		end
		local ih = io.popen("pkg-config --variable=includedir " .. pkg .. " 2>/dev/null")
		if ih then
			local d = vim.trim(ih:read("*l") or "")
			ih:close()
			if d ~= "" then
				dirs[#dirs + 1] = d
			end
		end
		-- Stem-based guess using all known bases (not just /usr/include)
		local stem = pkg:match("^([%a%d]+)")
		if stem then
			for _, base in ipairs(bases) do
				if vim.fn.isdirectory(base .. "/" .. stem) == 1 then
					dirs[#dirs + 1] = base
					dirs[#dirs + 1] = base .. "/" .. stem
				end
			end
		end
		for _, dir in ipairs(dirs) do
			if not scanned[dir] and vim.fn.isdirectory(dir) == 1 then
				scanned[dir] = true
				local fh = io.popen("ls " .. vim.fn.shellescape(dir) .. " 2>/dev/null")
				if fh then
					for entry in fh:lines() do
						if entry:match("%.h$") then
							if not map[entry] then
								map[entry] = pkg
							end
						elseif vim.fn.isdirectory(dir .. "/" .. entry) == 1 then
							local sh = io.popen("ls " .. vim.fn.shellescape(dir .. "/" .. entry) .. " 2>/dev/null")
							if sh then
								for hdr in sh:lines() do
									if hdr:match("%.h$") then
										local key = entry .. "/" .. hdr
										if not map[key] then
											map[key] = pkg
										end
									end
								end
								sh:close()
							end
						end
					end
					fh:close()
				end
			end
		end
	end
	_hdr_pkg_map_cache = map
	return map
end

return M
