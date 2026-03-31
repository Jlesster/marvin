-- lua/marvin/nix.lua
-- Nix/NixOS compatibility helpers.
--
-- On NixOS the FHS layout (/usr/include, /usr/local/lib, etc.) does NOT exist.
-- Everything lives under /nix/store/<hash>-<name>-<version>/.
--
-- Strategy:
--   1. Detect Nix via env vars and filesystem presence.
--   2. Resolve compilers through PATH only — never hardcode /usr/bin/*.
--      The cc-wrapper already has -I/-L flags baked in via NIX_CFLAGS_COMPILE
--      and NIX_LDFLAGS; we must use the wrapper, not a raw store path.
--   3. Expose system_inc_dirs() by parsing NIX_CFLAGS_COMPILE and, as a
--      fallback, querying the compiler directly.
--   4. Provide install_prefix() that returns ~/.local on Nix (no /usr/local).

local M = {}

-- ── Nix detection ─────────────────────────────────────────────────────────────
local _is_nix = nil
function M.is_nix()
	if _is_nix ~= nil then
		return _is_nix
	end
	-- Most reliable: set by stdenv cc-wrapper / nix develop
	if os.getenv("NIX_CC") or os.getenv("NIX_STORE") or os.getenv("IN_NIX_SHELL") then
		_is_nix = true
		return true
	end
	-- Filesystem presence (works even outside a shell)
	_is_nix = vim.fn.isdirectory("/nix/store") == 1
	return _is_nix
end

-- ── Tool resolution ───────────────────────────────────────────────────────────
-- Always resolve through PATH so we get the cc-wrapper, not a raw store path.
local _tool_cache = {}
function M.tool(name)
	if _tool_cache[name] then
		return _tool_cache[name]
	end
	local path = vim.fn.exepath(name)
	_tool_cache[name] = (path ~= "") and path or name
	return _tool_cache[name]
end

-- ── System include directories ────────────────────────────────────────────────
-- Returns a deduplicated list of -I dir strings the compiler/nix knows about.
-- On FHS systems this is empty (compiler finds /usr/include implicitly).
-- On Nix we parse NIX_CFLAGS_COMPILE and optionally query the compiler.
local _sys_incs = nil
function M.system_inc_dirs()
	if _sys_incs then
		return _sys_incs
	end
	_sys_incs = {}
	if not M.is_nix() then
		return _sys_incs
	end

	local seen = {}
	local function add(dir)
		if dir and dir ~= "" and not seen[dir] then
			seen[dir] = true
			_sys_incs[#_sys_incs + 1] = dir
		end
	end

	-- NIX_CFLAGS_COMPILE: space-separated; may contain -isystem, -I, and bare paths
	local nix_cflags = os.getenv("NIX_CFLAGS_COMPILE") or ""
	local tokens = {}
	for tok in nix_cflags:gmatch("%S+") do
		tokens[#tokens + 1] = tok
	end
	local i = 1
	while i <= #tokens do
		local tok = tokens[i]
		if tok == "-I" or tok == "-isystem" or tok == "-idirafter" then
			-- flag and dir are separate tokens
			i = i + 1
			if tokens[i] then
				add(tokens[i])
			end
		elseif tok:match("^%-I") then
			add(tok:sub(3))
		elseif tok:match("^%-isystem") then
			add(tok:sub(10))
		end
		i = i + 1
	end

	-- Fallback: ask the compiler (covers cases where NIX_CFLAGS_COMPILE is unset
	-- but the wrapper still knows its search path)
	if #_sys_incs == 0 then
		local cc = os.getenv("CC") or M.tool("cc")
		local h = io.popen(cc .. " -E -x c /dev/null -v 2>&1")
		if h then
			local in_inc = false
			for line in h:lines() do
				if line:match("#include <%.%.%.> search starts here") then
					in_inc = true
				end
				if line:match("End of search list") then
					in_inc = false
				end
				if in_inc then
					local dir = line:match("^%s+(.+)$")
					if dir then
						add(dir)
					end
				end
			end
			h:close()
		end
	end

	return _sys_incs
end

-- ── pkg-config include dirs ───────────────────────────────────────────────────
-- On Nix the wrapper sets PKG_CONFIG_PATH, so a plain `pkg-config --cflags`
-- already returns the correct /nix/store paths.
function M.pkg_cflags(pkg_names)
	if not pkg_names or #pkg_names == 0 then
		return {}
	end
	local h = io.popen("pkg-config --cflags " .. table.concat(pkg_names, " ") .. " 2>/dev/null")
	if not h then
		return {}
	end
	local out = h:read("*l") or ""
	h:close()
	local flags = {}
	for tok in out:gmatch("%S+") do
		flags[#flags + 1] = tok
	end
	return flags
end

-- ── Compiler default include dirs ─────────────────────────────────────────────
-- The dirs a plain invocation of cc/g++ would search without extra -I flags.
-- On Nix these point into /nix/store/…/include.
function M.compiler_inc_dirs(compiler)
	compiler = compiler or os.getenv("CC") or M.tool("cc")
	local cache_key = "cinc_" .. compiler
	if _tool_cache[cache_key] then
		return _tool_cache[cache_key]
	end

	local dirs = {}
	local seen = {}
	local h = io.popen(compiler .. " -E -x c /dev/null -v 2>&1")
	if h then
		local in_inc = false
		for line in h:lines() do
			if line:match("#include <%.%.%.> search starts here") then
				in_inc = true
			end
			if line:match("End of search list") then
				in_inc = false
				break
			end
			if in_inc then
				local d = line:match("^%s+(.+)$")
				if d and d ~= "" and not seen[d] then
					seen[d] = true
					dirs[#dirs + 1] = d
				end
			end
		end
		h:close()
	end

	_tool_cache[cache_key] = dirs
	return dirs
end

-- ── Install prefix ────────────────────────────────────────────────────────────
-- /usr/local does not exist on NixOS. Fall back to ~/.local, which is on PATH
-- when home-manager sets up the user environment.
function M.install_prefix()
	if M.is_nix() then
		-- Honour an explicit override from the nix devShell (e.g. $out or $prefix)
		local out = os.getenv("out") or os.getenv("prefix")
		if out and out ~= "" then
			return out
		end
		return vim.fn.expand("~/.local")
	end
	return "/usr/local"
end

-- ── Library search dirs ───────────────────────────────────────────────────────
-- Returns -L dirs the linker knows about (from NIX_LDFLAGS).
local _sys_libs = nil
function M.system_lib_dirs()
	if _sys_libs then
		return _sys_libs
	end
	_sys_libs = {}
	if not M.is_nix() then
		return _sys_libs
	end

	local seen = {}
	local flags = os.getenv("NIX_LDFLAGS") or ""
	local tokens = {}
	for tok in flags:gmatch("%S+") do
		tokens[#tokens + 1] = tok
	end
	local i = 1
	while i <= #tokens do
		local tok = tokens[i]
		if tok == "-L" then
			i = i + 1
			if tokens[i] and not seen[tokens[i]] then
				seen[tokens[i]] = true
				_sys_libs[#_sys_libs + 1] = tokens[i]
			end
		elseif tok:match("^%-L") then
			local d = tok:sub(3)
			if not seen[d] then
				seen[d] = true
				_sys_libs[#_sys_libs + 1] = d
			end
		end
		i = i + 1
	end
	return _sys_libs
end

-- ── Reset caches (useful after a nix-shell transition) ────────────────────────
function M.reset()
	_is_nix = nil
	_sys_incs = nil
	_sys_libs = nil
	_tool_cache = {}
end

return M
