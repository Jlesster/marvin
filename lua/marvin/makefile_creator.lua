-- lua/marvin/makefile_creator.lua
-- Universal interactive Makefile wizard.
-- Supports: C, C++, Go, Rust, and Generic projects.

local M = {}

local ui = function()
	return require("marvin.ui")
end

-- ── POSIX detection ───────────────────────────────────────────────────────────
local _posix_hdr_set = {
	["unistd.h"] = true,
	["pthread.h"] = true,
	["sys/types.h"] = true,
	["sys/stat.h"] = true,
	["sys/wait.h"] = true,
	["sys/file.h"] = true,
	["sys/socket.h"] = true,
	["sys/mman.h"] = true,
	["dirent.h"] = true,
	["fcntl.h"] = true,
	["signal.h"] = true,
	["termios.h"] = true,
	["netinet/in.h"] = true,
	["arpa/inet.h"] = true,
	["netdb.h"] = true,
	["openssl/ssl.h"] = true,
	["curl/curl.h"] = true,
	["readline/readline.h"] = true,
}

local _posix_fn_set = {}
for _, fn in ipairs({
	"strtok_r",
	"strndup",
	"strdup",
	"getline",
	"getdelim",
	"dprintf",
	"asprintf",
	"vasprintf",
	"fdopen",
	"fileno",
	"popen",
	"pclose",
	"ftruncate",
	"fchmod",
	"fsync",
	"fdatasync",
	"openat",
	"mkstemp",
	"mkdtemp",
	"fork",
	"vfork",
	"execvp",
	"execve",
	"execle",
	"execl",
	"execv",
	"setsid",
	"setpgid",
	"waitpid",
	"wait3",
	"wait4",
	"flock",
	"lockf",
	"opendir",
	"readdir",
	"closedir",
	"scandir",
	"nftw",
	"symlink",
	"readlink",
	"realpath",
	"dirname",
	"basename",
	"socket",
	"bind",
	"listen",
	"accept",
	"connect",
	"send",
	"recv",
	"getaddrinfo",
	"freeaddrinfo",
	"getnameinfo",
	"clock_gettime",
	"nanosleep",
	"timer_create",
	"gethostname",
	"sysconf",
	"mmap",
	"munmap",
	"pipe",
	"dup",
	"dup2",
	"dup3",
	"usleep",
	"truncate",
	"chown",
	"chmod",
	"lstat",
	"getcwd",
	"chdir",
	"unlink",
	"rmdir",
	"setenv",
	"unsetenv",
	"dlopen",
	"dlsym",
	"sem_open",
	"sem_wait",
	"sem_post",
	"shm_open",
	"pthread_create",
	"pthread_join",
	"pthread_mutex_lock",
}) do
	_posix_fn_set[fn] = true
end

local function project_needs_posix(root)
	local patterns = { "*.c", "*.cpp", "*.h", "*.hpp", "*.cxx", "*.hxx" }
	for _, pat in ipairs(patterns) do
		local files = vim.fn.globpath(root, "**/" .. pat, false, true)
		for _, f in ipairs(files) do
			local ok, lines = pcall(vim.fn.readfile, f)
			if ok then
				for _, line in ipairs(lines) do
					local hdr = line:match('#%s*include%s*[<"]([^>"]+)[>"]')
					if hdr and _posix_hdr_set[hdr] then
						return true
					end
					for fn in line:gmatch("([%a_][%w_]*)%s*%(") do
						if _posix_fn_set[fn] then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

-- ── Dynamic pkg-config reverse map ───────────────────────────────────────────
-- Uses compiler-derived include roots so Nix store paths are covered.
local _hdr_pkg_map_cache = nil
local function get_hdr_pkg_map()
	if _hdr_pkg_map_cache then
		return _hdr_pkg_map_cache
	end
	local map = {}
	local nix = require("marvin.nix")

	-- FHS defaults + compiler-derived (Nix /nix/store/... paths)
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

local function include_to_pkg(inc)
	local map = get_hdr_pkg_map()
	if map[inc] then
		return map[inc]
	end
	local fname = inc:match("([^/]+)$")
	return fname and map[fname] or nil
end

local _pkg_resolve_cache = {}
local function resolve_pkg(base)
	if _pkg_resolve_cache[base] ~= nil then
		return _pkg_resolve_cache[base] or nil
	end
	if os.execute("pkg-config --exists " .. base .. " 2>/dev/null") == 0 then
		_pkg_resolve_cache[base] = base
		return base
	end
	local h = io.popen(
		"pkg-config --list-all 2>/dev/null | grep -E '^" .. base .. "[-[:space:]]' | head -1 | awk '{print $1}'"
	)
	if h then
		local found = vim.trim(h:read("*l") or "")
		h:close()
		if found ~= "" then
			_pkg_resolve_cache[base] = found
			return found
		end
	end
	_pkg_resolve_cache[base] = false
	return nil
end

local function detect_pkg_deps(root)
	local patterns = { "*.c", "*.cpp", "*.h", "*.hpp", "*.cxx", "*.hxx" }
	local found, ordered = {}, {}
	for _, pat in ipairs(patterns) do
		for _, f in ipairs(vim.fn.globpath(root, "**/" .. pat, false, true)) do
			if not f:find("/build", 1, true) and not f:find("/builddir", 1, true) then
				local ok, lines = pcall(vim.fn.readfile, f)
				if ok then
					for _, line in ipairs(lines) do
						local inc = line:match('#%s*include%s*[<"]([^>"]+)[>"]')
						if inc then
							local pkg = include_to_pkg(inc)
							if pkg and not found[pkg] then
								local resolved = resolve_pkg(pkg)
								if resolved then
									found[pkg] = true
									ordered[#ordered + 1] = resolved
								end
							end
						end
					end
				end
			end
		end
	end
	return ordered
end

local function scan_needs_wlr_unstable(root)
	for _, pat in ipairs({ "**/*.c", "**/*.cpp", "**/*.cxx", "**/*.h", "**/*.hpp" }) do
		for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
			if not f:find("/build", 1, true) and not f:find("/builddir", 1, true) then
				local ok, lines = pcall(vim.fn.readfile, f)
				if ok then
					for _, line in ipairs(lines) do
						if line:match('#%s*include%s*[<"]wlr/') then
							return true
						end
						if line:match("WLR_USE_UNSTABLE") then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

local function infer_lang(root)
	if vim.fn.filereadable(root .. "/Cargo.toml") == 1 then
		return "rust"
	end
	if vim.fn.filereadable(root .. "/go.mod") == 1 then
		return "go"
	end
	local cpp_files = vim.fn.globpath(root, "**/*.cpp", false, true)
	local cxx_files = vim.fn.globpath(root, "**/*.cxx", false, true)
	local c_files = vim.fn.globpath(root, "**/*.c", false, true)
	if #cpp_files > 0 or #cxx_files > 0 then
		return "cpp"
	end
	if #c_files > 0 then
		return "c"
	end
	return nil
end

local function auto_detect_flags(root)
	local ldflags, iflags = "", ""
	local ok_cr, cr = pcall(require, "marvin.creator.cpp")
	local ok_det, det = pcall(require, "marvin.detector")
	if ok_cr and ok_det then
		local p = det.get()
		if p then
			local links = cr.detect_links(p)
			if links then
				ldflags = links.ldflags or ""
			end
		end
	end
	local ok_ll, ll = pcall(require, "marvin.local_libs")
	if ok_ll then
		local lf = ll.build_flags(root)
		if lf.lflags ~= "" then
			ldflags = vim.trim(ldflags .. " " .. lf.lflags)
		end
		if lf.iflags ~= "" then
			iflags = vim.trim(iflags .. " " .. lf.iflags)
		end
	end
	local pkg_deps, wlr_guard = {}, false
	local ok_b, build = pcall(require, "marvin.build")
	if ok_b and build.cpp and build.cpp.pkg_config_flags then
		local ok_f, flags = pcall(build.cpp.pkg_config_flags, root)
		if ok_f then
			pkg_deps = flags.pkg_names or {}
			for _, f in ipairs(flags.iflags or {}) do
				if f == "-DWLR_USE_UNSTABLE" then
					wlr_guard = true
				end
			end
		end
	end
	if not wlr_guard then
		wlr_guard = scan_needs_wlr_unstable(root)
	end
	return { ldflags = ldflags, iflags = iflags, pkg_deps = pkg_deps, wlr_guard = wlr_guard }
end

-- ── Install prefix (Nix-aware) ────────────────────────────────────────────────
local function install_prefix()
	return require("marvin.nix").install_prefix()
end

-- ── Shared helpers ────────────────────────────────────────────────────────────
local function write_makefile(path, content, name)
	local f = io.open(path, "w")
	if not f then
		vim.notify("[Marvin] Failed to write Makefile: " .. path, vim.log.levels.ERROR)
		return false
	end
	f:write(content)
	f:close()
	vim.cmd("edit " .. vim.fn.fnameescape(path))
	vim.notify("[Marvin] Makefile created for: " .. name, vim.log.levels.INFO)
	return true
end

local function check_existing(path, content, opts, root)
	if vim.fn.filereadable(path) == 1 then
		ui().select({
			{ id = "overwrite", label = "Overwrite", desc = "Replace the existing Makefile" },
			{ id = "cancel", label = "Cancel", desc = "Keep the existing file" },
		}, {
			prompt = "Makefile already exists",
			format_item = function(it)
				return it.label
			end,
		}, function(choice)
			if choice and choice.id == "overwrite" then
				write_makefile(path, content, opts.name)
			end
		end)
		return
	end
	write_makefile(path, content, opts.name)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- TEMPLATES
-- ══════════════════════════════════════════════════════════════════════════════

local function c_template(opts)
	local name = opts.name
	local cc = opts.compiler or "gcc"
	local std = opts.std or "c11"
	local src = opts.src or "src"
	local inc = opts.inc or "include"
	local out = opts.out or name
	local extra = opts.cflags or ""
	local lflags = vim.trim((opts.ldflags or "") .. " " .. (opts.libs or ""))
	local iflags = opts.iflags or ""
	local pkg_deps = opts.pkg_deps or {}
	local wlr_guard = opts.wlr_guard or false
	local prefix = install_prefix()

	local cflags_parts = { "-std=" .. std, "-Wall -Wextra -pedantic" }
	if opts.needs_posix then
		cflags_parts[#cflags_parts + 1] = "-D_POSIX_C_SOURCE=200809L"
	end
	if wlr_guard then
		cflags_parts[#cflags_parts + 1] = "-DWLR_USE_UNSTABLE"
	end
	if extra ~= "" then
		cflags_parts[#cflags_parts + 1] = extra
	end
	if iflags ~= "" then
		cflags_parts[#cflags_parts + 1] = iflags
	end
	local cflags_str = table.concat(cflags_parts, " ")

	local has_pkg = #pkg_deps > 0
	local pkg_line = has_pkg and table.concat(pkg_deps, " ") or ""

	local lines = {
		"# " .. name .. " — generated by Marvin",
		"",
		"CC      := " .. cc,
	}
	if has_pkg then
		lines[#lines + 1] = "PKG_DEPS    := " .. pkg_line
		lines[#lines + 1] = "PKG_CFLAGS  := $(shell pkg-config --cflags $(PKG_DEPS))"
		lines[#lines + 1] = "PKG_LIBS    := $(shell pkg-config --libs   $(PKG_DEPS))"
		lines[#lines + 1] = ""
		lines[#lines + 1] = "CFLAGS  := " .. cflags_str .. " $(PKG_CFLAGS)"
		lines[#lines + 1] = "LDFLAGS := " .. lflags .. " $(PKG_LIBS)"
	else
		lines[#lines + 1] = "CFLAGS  := " .. cflags_str
		lines[#lines + 1] = "LDFLAGS := " .. lflags
	end

	local proto_deps = ""
	if opts.protocol_xmls and #opts.protocol_xmls > 0 then
		local ph = {}
		for _, xml in ipairs(opts.protocol_xmls) do
			ph[#ph + 1] = "include/protocols/" .. xml:gsub("%.xml$", "") .. "-protocol.h"
		end
		proto_deps = " " .. table.concat(ph, " ")
	end

	local rest = {
		"",
		"SRC_DIR := " .. src,
		"INC_DIR := " .. inc,
		"OBJ_DIR := build/obj",
		"BIN_DIR := build/bin",
		"",
		"TARGET  := $(BIN_DIR)/" .. out,
		"SRCS    := $(wildcard $(SRC_DIR)/*.c)",
		"OBJS    := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRCS))",
		"DEPS    := $(OBJS:.o=.d)",
		"",
		".PHONY: all clean test install dist",
		"",
		"all:" .. proto_deps .. " $(TARGET)",
		"",
		"$(TARGET): $(OBJS) | $(BIN_DIR)",
		"\t$(CC) $^ -o $@ $(LDFLAGS)",
		"",
		"$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)",
		"\t$(CC) $(CFLAGS) -I$(INC_DIR) -MMD -MP -c $< -o $@",
		"",
		"-include $(DEPS)",
		"",
		"$(OBJ_DIR) $(BIN_DIR):",
		"\t@mkdir -p $@",
		"",
		"clean:",
		"\t@rm -rf build/",
		'\t@echo "Cleaned."',
		"",
		"test:",
		'\t@echo "No test runner configured."',
		"",
		"install: $(TARGET)",
		-- Use nix.install_prefix() so this works on NixOS too
		"\t@install -m 755 $(TARGET) " .. prefix .. "/bin/" .. out,
		'\t@echo "Installed → ' .. prefix .. "/bin/" .. out .. '"',
		"",
		"dist: all",
		"\t@mkdir -p dist",
		"\t@cp $(TARGET) dist/",
		'\t@echo "Distribution ready in dist/"',
		"",
	}
	for _, l in ipairs(rest) do
		lines[#lines + 1] = l
	end

	if opts.protocol_xmls and #opts.protocol_xmls > 0 then
		lines[#lines + 1] =
			"# ── Wayland protocol generation ──────────────────────────────"
		for _, xml in ipairs(opts.protocol_xmls) do
			local stem = xml:gsub("%.xml$", "")
			local xml_path = "include/protocols/" .. xml
			local hdr_path = "include/protocols/" .. stem .. "-protocol.h"
			local src_path = "include/protocols/" .. stem .. "-protocol.c"
			lines[#lines + 1] = hdr_path .. " " .. src_path .. ": " .. xml_path
			lines[#lines + 1] = "\t@wayland-scanner client-header $< " .. hdr_path
			lines[#lines + 1] = "\t@wayland-scanner private-code  $< " .. src_path
			lines[#lines + 1] = ""
		end
		local proto_headers = {}
		for _, xml in ipairs(opts.protocol_xmls) do
			proto_headers[#proto_headers + 1] = "include/protocols/" .. xml:gsub("%.xml$", "") .. "-protocol.h"
		end
		lines[#lines + 1] = "PROTO_HEADERS := " .. table.concat(proto_headers, " ")
		lines[#lines + 1] = "$(OBJS): $(PROTO_HEADERS)"
		lines[#lines + 1] = ""
	end

	return table.concat(lines, "\n")
end

local function cpp_template(opts)
	local name = opts.name
	local cxx = opts.compiler or "g++"
	local std = opts.std or "c++17"
	local src = opts.src or "src"
	local inc = opts.inc or "include"
	local out = opts.out or name
	local extra = opts.cflags or ""
	local lflags = vim.trim((opts.ldflags or "") .. " " .. (opts.libs or ""))
	local iflags = opts.iflags or ""
	local pkg_deps = opts.pkg_deps or {}
	local wlr_guard = opts.wlr_guard or false
	local prefix = install_prefix()

	local san_flags = ""
	if opts.sanitizer == "asan" then
		san_flags = " -fsanitize=address -fno-omit-frame-pointer"
	elseif opts.sanitizer == "tsan" then
		san_flags = " -fsanitize=thread"
	elseif opts.sanitizer == "ubsan" then
		san_flags = " -fsanitize=undefined"
	end

	local cflags_parts = { "-std=" .. std, "-Wall -Wextra -pedantic" }
	if opts.needs_posix then
		cflags_parts[#cflags_parts + 1] = "-D_POSIX_C_SOURCE=200809L"
	end
	if wlr_guard then
		cflags_parts[#cflags_parts + 1] = "-DWLR_USE_UNSTABLE"
	end
	if extra ~= "" then
		cflags_parts[#cflags_parts + 1] = extra
	end
	if san_flags ~= "" then
		cflags_parts[#cflags_parts + 1] = vim.trim(san_flags)
	end
	if iflags ~= "" then
		cflags_parts[#cflags_parts + 1] = iflags
	end
	local cflags_str = table.concat(cflags_parts, " ")

	local has_pkg = #pkg_deps > 0
	local pkg_line = has_pkg and table.concat(pkg_deps, " ") or ""

	local cc_json_section = opts.compile_commands
			and table.concat({
				"",
				"compile_commands:",
				"\t@if command -v bear >/dev/null 2>&1; then \\",
				"\t  bear -- $(MAKE) all; \\",
				"\telse \\",
				'\t  echo "install bear for compile_commands.json"; \\',
				"\tfi",
			}, "\n")
		or ""

	local lines = {
		"# " .. name .. " — generated by Marvin",
		"",
		"CXX      := " .. cxx,
	}

	if has_pkg then
		lines[#lines + 1] = "PKG_DEPS    := " .. pkg_line
		lines[#lines + 1] = "PKG_CFLAGS  := $(shell pkg-config --cflags $(PKG_DEPS))"
		lines[#lines + 1] = "PKG_LIBS    := $(shell pkg-config --libs   $(PKG_DEPS))"
		lines[#lines + 1] = ""
		lines[#lines + 1] = "CXXFLAGS := " .. cflags_str .. " $(PKG_CFLAGS)"
		lines[#lines + 1] = "LDFLAGS  := " .. lflags .. " $(PKG_LIBS)"
	else
		lines[#lines + 1] = "CXXFLAGS := " .. cflags_str
		lines[#lines + 1] = "LDFLAGS  := " .. lflags
	end

	local proto_deps = ""
	if opts.protocol_xmls and #opts.protocol_xmls > 0 then
		local ph = {}
		for _, xml in ipairs(opts.protocol_xmls) do
			ph[#ph + 1] = "include/protocols/" .. xml:gsub("%.xml$", "") .. "-protocol.h"
		end
		proto_deps = " " .. table.concat(ph, " ")
	end

	local rest = {
		"",
		"SRC_DIR  := " .. src,
		"INC_DIR  := " .. inc,
		"OBJ_DIR  := build/obj",
		"BIN_DIR  := build/bin",
		"",
		"TARGET   := $(BIN_DIR)/" .. out,
		"SRCS     := $(wildcard $(SRC_DIR)/*.cpp)",
		"OBJS     := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(SRCS))",
		"DEPS     := $(OBJS:.o=.d)",
		"",
		".PHONY: all clean test install dist" .. (opts.compile_commands and " compile_commands" or ""),
		"",
		"all:" .. proto_deps .. " $(TARGET)",
		"",
		"$(TARGET): $(OBJS) | $(BIN_DIR)",
		"\t$(CXX) $^ -o $@ $(LDFLAGS)",
		"",
		"$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp | $(OBJ_DIR)",
		"\t$(CXX) $(CXXFLAGS) -I$(INC_DIR) -MMD -MP -c $< -o $@",
		"",
		"-include $(DEPS)",
		"",
		"$(OBJ_DIR) $(BIN_DIR):",
		"\t@mkdir -p $@",
		"",
		"clean:",
		"\t@rm -rf build/",
		'\t@echo "Cleaned."',
		"",
		"test:",
		'\t@echo "No test runner configured."',
		"",
		"install: $(TARGET)",
		"\t@install -m 755 $(TARGET) " .. prefix .. "/bin/" .. out,
		'\t@echo "Installed → ' .. prefix .. "/bin/" .. out .. '"',
		"",
		"dist: all",
		"\t@mkdir -p dist",
		"\t@cp $(TARGET) dist/",
		'\t@echo "Distribution ready in dist/"',
		cc_json_section,
		"",
	}
	for _, l in ipairs(rest) do
		lines[#lines + 1] = l
	end

	if opts.protocol_xmls and #opts.protocol_xmls > 0 then
		lines[#lines + 1] =
			"# ── Wayland protocol generation ──────────────────────────────"
		for _, xml in ipairs(opts.protocol_xmls) do
			local stem = xml:gsub("%.xml$", "")
			local xml_path = "include/protocols/" .. xml
			local hdr_path = "include/protocols/" .. stem .. "-protocol.h"
			local src_path = "include/protocols/" .. stem .. "-protocol.c"
			lines[#lines + 1] = hdr_path .. " " .. src_path .. ": " .. xml_path
			lines[#lines + 1] = "\t@wayland-scanner client-header $< " .. hdr_path
			lines[#lines + 1] = "\t@wayland-scanner private-code  $< " .. src_path
			lines[#lines + 1] = ""
		end
		local proto_headers = {}
		for _, xml in ipairs(opts.protocol_xmls) do
			proto_headers[#proto_headers + 1] = "include/protocols/" .. xml:gsub("%.xml$", "") .. "-protocol.h"
		end
		lines[#lines + 1] = "PROTO_HEADERS := " .. table.concat(proto_headers, " ")
		lines[#lines + 1] = "$(OBJS): $(PROTO_HEADERS)"
		lines[#lines + 1] = ""
	end

	return table.concat(lines, "\n")
end

local function go_template(opts)
	local name = opts.name
	local mod = opts.module or "."
	local out = opts.out or name
	local gofmt = opts.formatter or "gofmt"
	local linter = opts.linter or "golangci-lint"
	return table.concat({
		"# " .. name .. " — generated by Marvin (Go)",
		"",
		"BINARY   := " .. out,
		"MODULE   := " .. mod,
		"GOFLAGS  :=",
		'LDFLAGS  := -ldflags="-s -w"',
		"BUILD_DIR := build",
		"",
		".PHONY: all build test lint fmt clean install tidy race cover",
		"",
		"all: build",
		"",
		"build:",
		"\t@mkdir -p $(BUILD_DIR)",
		"\tgo build $(GOFLAGS) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY) .",
		"",
		"test:",
		"\tgo test ./...",
		"",
		"race:",
		"\tgo test -race ./...",
		"",
		"cover:",
		"\tgo test -cover -coverprofile=coverage.out ./...",
		"\tgo tool cover -html=coverage.out -o coverage.html",
		"",
		"lint:",
		"\t" .. linter .. " run ./...",
		"",
		"fmt:",
		"\t" .. gofmt .. " -w .",
		"",
		"tidy:",
		"\tgo mod tidy",
		"",
		"clean:",
		"\t@rm -rf $(BUILD_DIR) coverage.out coverage.html",
		'\t@echo "Cleaned."',
		"",
		"install:",
		"\tgo install .",
		"",
	}, "\n")
end

local function rust_template(opts)
	local name = opts.name
	local profile = opts.profile or "dev"
	local out = opts.out or name
	local pflag = profile == "release" and "--release" or ""
	local pdir = profile == "release" and "release" or "debug"
	return table.concat({
		"# " .. name .. " — generated by Marvin (Rust/Cargo)",
		"",
		"CARGO    := cargo",
		"PROFILE  := " .. profile,
		"PFLAG    := " .. pflag,
		"BIN      := target/" .. pdir .. "/" .. out,
		"",
		".PHONY: all build test clippy fmt clean release run doc bench",
		"",
		"all: build",
		"",
		"build:",
		"\t$(CARGO) build $(PFLAG)",
		"",
		"run: build",
		"\t./$(BIN)",
		"",
		"test:",
		"\t$(CARGO) test",
		"",
		"clippy:",
		"\t$(CARGO) clippy -- -D warnings",
		"",
		"fmt:",
		"\t$(CARGO) fmt",
		"",
		"doc:",
		"\t$(CARGO) doc --open",
		"",
		"bench:",
		"\t$(CARGO) bench",
		"",
		"clean:",
		"\t$(CARGO) clean",
		"",
		"release:",
		"\t$(CARGO) build --release",
		"",
		"install:",
		"\t$(CARGO) install --path .",
		"",
	}, "\n")
end

local function generic_template(opts)
	local name = opts.name
	return table.concat({
		"# " .. name .. " — generated by Marvin",
		"",
		".PHONY: all build test clean install dist",
		"",
		"all: build",
		"",
		"build:",
		'\t@echo "Add your build command here"',
		"",
		"test:",
		'\t@echo "Add your test command here"',
		"",
		"clean:",
		'\t@echo "Add your clean command here"',
		"",
		"install:",
		'\t@echo "Add your install command here"',
		"",
		"dist:",
		'\t@echo "Add your dist command here"',
		"",
	}, "\n")
end

-- ══════════════════════════════════════════════════════════════════════════════
-- WIZARD STEPS
-- ══════════════════════════════════════════════════════════════════════════════

local function step_cflags(opts, root, lang, flags)
	local default = opts.debug and "-g -O0" or "-O2"
	ui().input({ prompt = "Extra compiler flags (optional)", default = default }, function(extra)
		opts.cflags = (extra and extra ~= "") and extra or nil
		opts.ldflags = flags.ldflags
		opts.iflags = flags.iflags
		opts.needs_posix = flags.needs_posix
		opts.pkg_deps = flags.pkg_deps
		opts.wlr_guard = flags.wlr_guard

		if lang == "cpp" then
			ui().select({
				{ id = "none", label = "None" },
				{ id = "asan", label = "AddressSanitizer", desc = "-fsanitize=address" },
				{ id = "tsan", label = "ThreadSanitizer", desc = "-fsanitize=thread" },
				{ id = "ubsan", label = "UBSanitizer", desc = "-fsanitize=undefined" },
			}, {
				prompt = "Sanitizer (optional)",
				format_item = function(it)
					return it.label
				end,
			}, function(san)
				opts.sanitizer = (san and san.id ~= "none") and san.id or nil
				ui().select({
					{ id = "yes", label = "Yes — add compile_commands target", desc = "requires bear" },
					{ id = "no", label = "No" },
				}, {
					prompt = "Add compile_commands.json target?",
					format_item = function(it)
						return it.label
					end,
				}, function(cc)
					opts.compile_commands = cc and cc.id == "yes"
					check_existing(root .. "/Makefile", cpp_template(opts), opts, root)
				end)
			end)
		else
			check_existing(root .. "/Makefile", c_template(opts), opts, root)
		end
	end)
end

local function step_c_std(opts, root, flags)
	ui().select({
		{ id = "c11", label = "C11", desc = "Recommended modern standard" },
		{ id = "c17", label = "C17", desc = "Latest stable" },
		{ id = "c99", label = "C99", desc = "Wide compatibility" },
		{ id = "c89", label = "C89", desc = "Maximum compatibility" },
	}, {
		prompt = "C Standard",
		format_item = function(it)
			return it.label
		end,
	}, function(choice)
		if not choice then
			return
		end
		opts.std = choice.id
		step_cflags(opts, root, "c", flags)
	end)
end

local function step_cpp_std(opts, root, flags)
	ui().select({
		{ id = "c++17", label = "C++17", desc = "Recommended" },
		{ id = "c++20", label = "C++20", desc = "Concepts, ranges, coroutines" },
		{ id = "c++23", label = "C++23", desc = "Latest (compiler support varies)" },
		{ id = "c++14", label = "C++14", desc = "Lambdas, auto" },
		{ id = "c++11", label = "C++11", desc = "Move semantics, smart pointers" },
	}, {
		prompt = "C++ Standard",
		format_item = function(it)
			return it.label
		end,
	}, function(choice)
		if not choice then
			return
		end
		opts.std = choice.id
		step_cflags(opts, root, "cpp", flags)
	end)
end

local function step_compiler(opts, root, lang, flags)
	local compilers = lang == "c"
			and {
				{ id = "gcc", label = "gcc", desc = "GNU C Compiler (recommended)" },
				{ id = "clang", label = "clang", desc = "LLVM Clang" },
				{ id = "cc", label = "cc", desc = "System default" },
			}
		or {
			{ id = "g++", label = "g++", desc = "GNU C++ Compiler (recommended)" },
			{ id = "clang++", label = "clang++", desc = "LLVM Clang++" },
			{ id = "c++", label = "c++", desc = "System default" },
		}
	ui().select(compilers, {
		prompt = "Compiler",
		format_item = function(it)
			return it.label
		end,
	}, function(choice)
		if not choice then
			return
		end
		opts.compiler = choice.id
		if lang == "c" then
			step_c_std(opts, root, flags)
		else
			step_cpp_std(opts, root, flags)
		end
	end)
end

local function step_name_binary(lang, root, src, inc, on_back)
	local default = vim.fn.fnamemodify(root, ":t")
	ui().input({ prompt = "󰬷 Project Name", default = default }, function(name)
		if not name or name == "" then
			return
		end
		ui().input({ prompt = "󰐊 Output Binary Name", default = name }, function(out)
			if not out or out == "" then
				out = name
			end
			local opts = { name = name, out = out, src = src, inc = inc }

			if lang == "generic" then
				check_existing(root .. "/Makefile", generic_template(opts), opts, root)
			elseif lang == "go" then
				local mod_default = "github.com/yourname/" .. name
				local go_mod = root .. "/go.mod"
				if vim.fn.filereadable(go_mod) == 1 then
					for _, line in ipairs(vim.fn.readfile(go_mod)) do
						local m = line:match("^module%s+(%S+)")
						if m then
							mod_default = m
							break
						end
					end
				end
				ui().input({ prompt = "Module path", default = mod_default }, function(mod)
					opts.module = mod
					ui().select({
						{ id = "gofmt", label = "gofmt" },
						{ id = "goimports", label = "goimports" },
					}, {
						prompt = "Formatter",
						format_item = function(it)
							return it.label
						end,
					}, function(fmt)
						opts.formatter = fmt and fmt.id or "gofmt"
						check_existing(root .. "/Makefile", go_template(opts), opts, root)
					end)
				end)
			elseif lang == "rust" then
				local cargo_toml = root .. "/Cargo.toml"
				if vim.fn.filereadable(cargo_toml) == 1 then
					for _, line in ipairs(vim.fn.readfile(cargo_toml)) do
						local n = line:match('^name%s*=%s*"([^"]+)"')
						if n then
							opts.out = n
							break
						end
					end
				end
				ui().select({
					{ id = "dev", label = "dev (debug)" },
					{ id = "release", label = "release" },
				}, {
					prompt = "Default profile",
					format_item = function(it)
						return it.label
					end,
				}, function(prof)
					opts.profile = prof and prof.id or "dev"
					check_existing(root .. "/Makefile", rust_template(opts), opts, root)
				end)
			else
				-- C / C++: run full detection pipeline
				local flags = auto_detect_flags(root)
				flags.needs_posix = project_needs_posix(root)

				local notice = {}
				if #(flags.pkg_deps or {}) > 0 then
					notice[#notice + 1] = "PKG_DEPS:  " .. table.concat(flags.pkg_deps, " ")
				end
				if flags.wlr_guard then
					notice[#notice + 1] = "CFLAGS:    -DWLR_USE_UNSTABLE"
				end
				if flags.ldflags ~= "" then
					notice[#notice + 1] = "LDFLAGS:   " .. flags.ldflags
				end
				if flags.iflags ~= "" then
					notice[#notice + 1] = "CFLAGS:    " .. flags.iflags
				end
				if flags.needs_posix then
					notice[#notice + 1] = "CFLAGS:    -D_POSIX_C_SOURCE=200809L"
				end
				if require("marvin.nix").is_nix() then
					notice[#notice + 1] = "Nix:       detected — compiler resolved via PATH"
				end
				if #notice > 0 then
					vim.notify("[Marvin] Auto-injecting:\n  " .. table.concat(notice, "\n  "), vim.log.levels.INFO)
				end

				local ok_wp, wl_proto = pcall(require, "marvin.wayland_protocols")
				local protocol_xmls = {}
				if ok_wp and wl_proto then
					local ok_r, proto_entries = pcall(wl_proto.resolve, root)
					if ok_r then
						for _, e in ipairs(proto_entries) do
							if e.in_root then
								protocol_xmls[#protocol_xmls + 1] = e.xml
							end
						end
					end
				end
				opts.protocol_xmls = protocol_xmls

				step_compiler(opts, root, lang, flags)
			end
		end)
	end)
end

local function step_dirs(lang, root, on_back)
	if lang ~= "c" and lang ~= "cpp" then
		step_name_binary(lang, root, nil, nil, on_back)
		return
	end
	local has_src = vim.fn.isdirectory(root .. "/src") == 1
	local has_inc = vim.fn.isdirectory(root .. "/include") == 1
	local src_default = has_src and "src" or "."
	local inc_default = has_inc and "include" or (has_src and "src" or ".")
	ui().input({ prompt = "Source directory", default = src_default }, function(src)
		src = (src and src ~= "") and src or src_default
		ui().input({ prompt = "Include directory", default = inc_default }, function(inc_d)
			inc_d = (inc_d and inc_d ~= "") and inc_d or inc_default
			step_name_binary(lang, root, src, inc_d, on_back)
		end)
	end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- ENTRY POINT
-- ══════════════════════════════════════════════════════════════════════════════

function M.create(root, on_back)
	root = root or vim.fn.getcwd()
	local detected_lang = infer_lang(root)

	local lang_items = {
		{ id = "cpp", label = "󰙲 C++", desc = "g++/clang++, wildcard *.cpp sources" },
		{ id = "c", label = "󰙱 C", desc = "gcc/clang, wildcard *.c sources" },
		{ id = "go", label = "󰟓 Go", desc = "go build wrapper" },
		{ id = "rust", label = "󱘗 Rust", desc = "cargo wrapper" },
		{ id = "generic", label = "󰈙 Generic", desc = "Minimal skeleton" },
	}

	local prompt = "Makefile Type"
	if detected_lang then
		prompt = "Makefile Type  (detected: " .. detected_lang .. ")"
		for i, it in ipairs(lang_items) do
			if it.id == detected_lang then
				table.remove(lang_items, i)
				table.insert(lang_items, 1, vim.tbl_extend("force", it, { label = it.label .. "  ✓ detected" }))
				break
			end
		end
	end

	ui().select(lang_items, {
		prompt = prompt,
		on_back = on_back,
		format_item = function(it)
			return it.label
		end,
	}, function(choice)
		if not choice then
			return
		end
		vim.cmd("stopinsert")
		vim.schedule(function()
			step_dirs(choice.id, root, on_back)
		end)
	end)
end

return M
