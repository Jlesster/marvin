-- lua/marvin/nix.lua
-- Nix/NixOS compatibility helpers.
--
-- On NixOS (and nix-darwin / home-manager), the FHS layout that most Linux
-- software assumes (/usr/include, /usr/local/lib, etc.) does NOT exist.
-- Everything lives under /nix/store/<hash>-<name>-<version>/.
--
-- The canonical way to find include dirs and library paths on Nix is:
--   1. pkg-config  -- same as anywhere, but PKG_CONFIG_PATH is set by nix-shell
--   2. $CC / $CXX  -- the compiler wrapper emitted by stdenv already has the
--                     correct -I and -L flags baked in via NIX_CFLAGS_COMPILE
--                     and NIX_LDFLAGS; we just need to not override them.
--   3. nix-locate  -- can find headers by name, but is slow; skip for now.
--
-- Strategy implemented here:
--   • M.is_nix()        → detect whether we're running under Nix
--   • M.system_inc_dirs() → return the list of -I dirs the compiler knows about
--     (empty on non-Nix, so callers always treat it as additive)
--   • M.tool(name)      → resolve a tool through PATH, respecting Nix wrappers
--   • M.install_prefix() → return a sensible install prefix (not /usr/local)

local M = {}

-- ── Nix detection ─────────────────────────────────────────────────────────────
local _is_nix = nil
function M.is_nix()
	if _is_nix ~= nil then
		return _is_nix
	end
	-- Most reliable signal: NIX_CC is set in a nix-shell / dev-shell
	if os.getenv("NIX_CC") or os.getenv("NIX_STORE") then
		_is_nix = true
		return true
	end
	-- Also check if /nix/store exists
	_is_nix = vim.fn.isdirectory("/nix/store") == 1
	return _is_nix
end

-- ── Tool resolution ───────────────────────────────────────────────────────────
-- On Nix the cc-wrapper injects flags automatically. We must use the wrapper,
-- not a bare gcc/g++ from /nix/store/…/bin/gcc. vim.fn.exepath() will find
-- the wrapper if it's on PATH (which it is inside a dev-shell).
local _tool_cache = {}
function M.tool(name)
	if _tool_cache[name] then
		return _tool_cache[name]
	end
	local path = vim.fn.exepath(name)
	if path == "" then
		path = name
	end -- fall back to bare name
	_tool_cache[name] = path
	return path
end

-- ── System include directories ────────────────────────────────────────────────
-- On a normal FHS system the compiler already searches /usr/include implicitly.
-- On Nix the compiler wrapper sets NIX_CFLAGS_COMPILE which contains the -I
-- flags for all buildInputs. We parse that to give callers a list they can
-- pass to clangd / compile_commands.json.
local _sys_incs = nil
function M.system_inc_dirs()
	if _sys_incs then
		return _sys_incs
	end
	_sys_incs = {}
	if not M.is_nix() then
		return _sys_incs
	end

	-- NIX_CFLAGS_COMPILE is space-separated and may contain -isystem / -I flags
	local nix_cflags = os.getenv("NIX_CFLAGS_COMPILE") or ""
	local seen = {}
	for token in nix_cflags:gmatch("%S+") do
		if token:match("^%-[Ii]") then
			local dir = token:match("^%-[Ii](.+)") or token
			if dir and dir ~= "" and not seen[dir] then
				seen[dir] = true
				_sys_incs[#_sys_incs + 1] = dir
			end
		end
	end
	-- Also ask the compiler directly (cc -E -x c /dev/null -v 2>&1)
	if #_sys_incs == 0 then
		local cc = os.getenv("CC") or "cc"
		local h = io.popen(cc .. " -E -x c /dev/null -v 2>&1")
		if h then
			local in_inc = false
			for line in h:lines() do
				if line:match("#include <%.%.%.>") then
					in_inc = true
				end
				if in_inc and line:match("^End of search list") then
					in_inc = false
				end
				if in_inc then
					local dir = line:match("^%s+(/nix/.+)") or line:match("^%s+(/usr/.+)")
					if dir and not seen[dir] then
						seen[dir] = true
						_sys_incs[#_sys_incs + 1] = dir
					end
				end
			end
			h:close()
		end
	end
	return _sys_incs
end

-- ── Install prefix ────────────────────────────────────────────────────────────
-- /usr/local/bin doesn't exist on NixOS. Use ~/.local/bin instead, or let
-- the user override via config.
function M.install_prefix()
	if M.is_nix() then
		return vim.fn.expand("~/.local")
	end
	return "/usr/local"
end

-- ── pkg-config include dirs ───────────────────────────────────────────────────
-- Returns -I flags for a list of pkg-config package names.
-- On Nix this properly follows the /nix/store paths.
function M.pkg_cflags(pkg_names)
	if #pkg_names == 0 then
		return {}
	end
	local h = io.popen("pkg-config --cflags " .. table.concat(pkg_names, " ") .. " 2>/dev/null")
	if not h then
		return {}
	end
	local out = h:read("*l") or ""
	h:close()
	local flags = {}
	for token in out:gmatch("%S+") do
		flags[#flags + 1] = token
	end
	return flags
end

-- ── Compiler default include dirs ─────────────────────────────────────────────
-- These are the dirs a plain `cc` / `g++` invocation would search without
-- any extra -I flags. On Nix these point into /nix/store.
function M.compiler_inc_dirs(compiler)
	compiler = compiler or os.getenv("CC") or "cc"
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
			if line:match("#include <%.%.%.>") then
				in_inc = true
			end
			if in_inc and line:match("End of search list") then
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

return M
