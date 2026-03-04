-- lua/marvin/build.lua
-- Jason's multi-language build executor.
--
-- C/C++ PHILOSOPHY:
--   The plugin owns the entire build pipeline for C/C++ projects. It does NOT
--   rely on the Makefile to know what to compile — it scans the source tree
--   itself, finds every file with "int main(", picks the right entry point,
--   compiles all other .c/.cpp files as library objects, links everything, and
--   produces a binary. The Makefile (if present) is only used as a fallback
--   for actions the plugin doesn't handle natively (make install, make dist,
--   custom targets).

local M = {}

-- ── Per-project run-args memory ───────────────────────────────────────────────
M._run_args = {}

function M.get_args(root, action)
  return (M._run_args[root] or {})[action] or ''
end

function M.set_args(root, action, args)
  M._run_args[root]         = M._run_args[root] or {}
  M._run_args[root][action] = args
end

-- ══════════════════════════════════════════════════════════════════════════════
-- C/C++ CORE ENGINE
-- ══════════════════════════════════════════════════════════════════════════════

local CPP = {}

-- ── Path helpers ──────────────────────────────────────────────────────────────
local function abs(path)
  if not path or path == '' then return '' end
  return vim.fn.expand(vim.fn.fnamemodify(path, ':p')):gsub('/+$', '')
end

-- Shell-escape a single argument for /bin/sh (used via io.popen / execute).
local function esc(s) return vim.fn.shellescape(tostring(s)) end

-- Join a list of strings with spaces, skipping blanks.
local function join(t)
  local out = {}
  for _, v in ipairs(t) do
    if v and v ~= '' then out[#out + 1] = v end
  end
  return table.concat(out, ' ')
end

-- Single-quote a path for /bin/sh (io.popen always uses /bin/sh).
local function sh_path(p)
  return "'" .. p:gsub("'", "'\\''") .. "'"
end

-- ── Compiler config ───────────────────────────────────────────────────────────
local function cpp_cfg()
  return require('marvin').config.cpp or {}
end

local function compiler(lang)
  local cfg = cpp_cfg()
  if lang == 'cpp' then
    return (cfg.compiler == 'clang++') and 'clang++' or 'g++'
  else
    if cfg.compiler == 'clang' then return 'clang' end
    return 'gcc'
  end
end

local function std_flag(lang)
  local cfg = cpp_cfg()
  if cfg.standard then
    -- cfg.standard might be 'c++17', 'c11', 'c17', 'c++20' etc.
    -- If it's a C++ standard but we're compiling C, ignore it and use a
    -- sensible C default instead. A C++ standard contains '+'.
    local is_cpp_std = cfg.standard:find('+', 1, true)
    if lang == 'c' and is_cpp_std then
      return 'c11'
    end
    if lang == 'cpp' and not is_cpp_std then
      return 'c++17'
    end
    return cfg.standard
  end
  return lang == 'cpp' and 'c++17' or 'c11'
end

local function extra_cflags()
  return cpp_cfg().cflags or '-Wall -Wextra -Wpedantic'
end

-- ── Source file language detection ────────────────────────────────────────────
local function file_lang(path)
  local ext = path:match('%.(%w+)$') or ''
  return (ext == 'cpp' or ext == 'cxx' or ext == 'cc' or ext == 'C') and 'cpp' or 'c'
end

-- ── Include directory detection ───────────────────────────────────────────────
function CPP.include_flags(root)
  local r    = abs(root)
  local dirs = {}
  for _, d in ipairs({ 'include', 'src', 'lib', '.' }) do
    local full = r .. '/' .. d
    if vim.fn.isdirectory(full) == 1 then
      dirs[#dirs + 1] = '-I' .. full
    end
  end
  -- Deduplicate (e.g. when root IS src)
  local seen, out = {}, {}
  for _, f in ipairs(dirs) do
    if not seen[f] then
      seen[f] = true; out[#out + 1] = f
    end
  end
  return out
end

-- ── LDFLAGS from #include scanning ───────────────────────────────────────────
local LINK_MAP = {
  { pat = 'pthread',               flags = { '-lpthread' } },
  { pat = 'thread',                flags = { '-lpthread' } },
  { pat = 'openssl',               flags = { '-lssl', '-lcrypto' } },
  { pat = 'ssl%.h',                flags = { '-lssl', '-lcrypto' } },
  { pat = 'curl',                  flags = { '-lcurl' } },
  { pat = 'cmath',                 flags = { '-lm' } },
  { pat = 'math%.h',               flags = { '-lm' } },
  { pat = 'complex',               flags = { '-lm' } },
  { pat = 'boost/filesystem',      flags = { '-lboost_filesystem', '-lboost_system' } },
  { pat = 'boost/regex',           flags = { '-lboost_regex' } },
  { pat = 'boost/thread',          flags = { '-lboost_thread', '-lpthread' } },
  { pat = 'boost/program_options', flags = { '-lboost_program_options' } },
  { pat = 'boost/asio',            flags = { '-lpthread' } },
  { pat = 'fmt/',                  flags = { '-lfmt' } },
  { pat = 'spdlog/',               flags = { '-lfmt' } },
  { pat = 'sqlite3',               flags = { '-lsqlite3' } },
  { pat = 'zlib%.h',               flags = { '-lz' } },
  { pat = 'zconf%.h',              flags = { '-lz' } },
  { pat = 'ncurses',               flags = { '-lncurses' } },
  { pat = 'readline',              flags = { '-lreadline' } },
  { pat = 'GLFW',                  flags = { '-lglfw' } },
  { pat = 'GL/gl%.h',              flags = { '-lGL' } },
  { pat = 'vulkan',                flags = { '-lvulkan' } },
  { pat = 'SDL2',                  flags = { '-lSDL2' } },
  { pat = 'gtest',                 flags = { '-lgtest', '-lgtest_main', '-lpthread' } },
  { pat = 'gmock',                 flags = { '-lgmock', '-lgtest', '-lpthread' } },
  { pat = 'yaml%-cpp',             flags = { '-lyaml-cpp' } },
  { pat = 'google/protobuf',       flags = { '-lprotobuf' } },
  { pat = 'grpc',                  flags = { '-lgrpc++', '-lgrpc' } },
  { pat = 'lz4',                   flags = { '-llz4' } },
  { pat = 'zstd',                  flags = { '-lzstd' } },
  { pat = 'libavcodec',            flags = { '-lavcodec', '-lavutil' } },
}

-- Scan a set of files (passed as a list of absolute paths) for known includes.
local function scan_ldflags_files(file_list)
  local seen = {}
  local out  = {}
  for _, path in ipairs(file_list) do
    local ok, lines = pcall(vim.fn.readfile, path)
    if ok then
      for _, line in ipairs(lines) do
        local inc = line:match('#%s*include%s*[<"]([^>"]+)[>"]')
        if inc then
          for _, entry in ipairs(LINK_MAP) do
            if not seen[entry.pat] and inc:find(entry.pat) then
              seen[entry.pat] = true
              for _, f in ipairs(entry.flags) do out[#out + 1] = f end
            end
          end
        end
      end
    end
  end
  return out
end

function CPP.scan_ldflags(root)
  local r     = abs(root)
  local cmd   = string.format(
    "find %s \\( -name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp'"
    .. " -o -name '*.cxx' -o -name '*.hxx' \\)"
    .. " -not -path '*/.marvin-obj/*' -type f 2>/dev/null",
    sh_path(r))
  local files = {}
  local h     = io.popen(cmd)
  if h then
    for line in h:lines() do
      local a = vim.trim(line)
      if a ~= '' then files[#files + 1] = a end
    end
    h:close()
  end
  return scan_ldflags_files(files)
end

-- ── Source file collection ────────────────────────────────────────────────────
-- Returns a sorted list of absolute paths to all .c / .cpp files,
-- excluding the .marvin-obj staging directory.
function CPP.all_sources(root, lang)
  local r     = abs(root)
  local exts  = lang == 'cpp'
      and [[-name '*.cpp' -o -name '*.cxx' -o -name '*.cc']]
      or [[-name '*.c']]

  local cmd   = string.format(
    "find %s \\( %s \\) -not -path '*/.marvin-obj/*' -type f 2>/dev/null | sort",
    sh_path(r), exts)

  local found = {}
  local seen  = {}
  local h     = io.popen(cmd)
  if h then
    for line in h:lines() do
      local a = vim.trim(line)
      if a ~= '' and not seen[a] then
        seen[a] = true
        found[#found + 1] = a
      end
    end
    h:close()
  end
  return found
end

-- ── Main file detection ───────────────────────────────────────────────────────
function CPP.find_main_files(root, lang)
  local sources    = CPP.all_sources(root, lang)
  local candidates = {}
  for _, f in ipairs(sources) do
    local ok, lines = pcall(vim.fn.readfile, f)
    if ok then
      for _, line in ipairs(lines) do
        if line:match('int%s+main%s*%(') then
          candidates[#candidates + 1] = f
          break
        end
      end
    end
  end
  if #candidates == 0 then return candidates end
  local cur = abs(vim.fn.expand('%:p'))
  table.sort(candidates, function(a, b)
    if a == cur then return true end
    if b == cur then return false end
    local da = select(2, a:gsub('/', ''))
    local db = select(2, b:gsub('/', ''))
    if da ~= db then return da < db end
    return a < b
  end)
  return candidates
end

function CPP.find_main_file(root, lang)
  return CPP.find_main_files(root, lang)[1]
end

-- ── Project language detection ────────────────────────────────────────────────
function CPP.project_lang(p)
  local root = abs(p.root)

  -- Count actual files on disk first — this is the ground truth.
  -- We always do this regardless of other hints because compiler config
  -- and filetype can both lie (e.g. g++ set globally, editing a .c file).
  local function count_files(exts_pat)
    local h = io.popen(
      "find " .. sh_path(root)
      .. " \\( " .. exts_pat .. " \\)"
      .. " -not -path '*/.marvin-obj/*' -type f 2>/dev/null | wc -l")
    if not h then return 0 end
    local result = h:read('*l'); h:close()
    return tonumber(vim.trim(result or '0')) or 0
  end

  local n_c   = count_files("-name '*.c'")
  local n_cpp = count_files("-name '*.cpp' -o -name '*.cxx' -o -name '*.cc'")

  -- More C files than C++ → C project, even in a mixed repo
  if n_c > 0 and n_c >= n_cpp then return 'c' end
  if n_cpp > 0 then return 'cpp' end

  -- No files on disk yet (new project) — fall back to softer signals
  local explicit = p.language or p.lang
  if explicit == 'cpp' or explicit == 'c' then return explicit end

  local ft = vim.bo.filetype
  if ft == 'cpp' then return 'cpp' end
  if ft == 'c' then return 'c' end

  -- Absolute last resort
  local cfg = cpp_cfg()
  if cfg.compiler == 'g++' or cfg.compiler == 'clang++' then return 'cpp' end
  return 'c'
end

-- ── Object file staging area ──────────────────────────────────────────────────
local function obj_path(root, src_abs)
  local r       = abs(root)
  local rel     = src_abs:sub(#r + 2)
  local mangled = rel:gsub('/', '-'):gsub('%.%w+$', '') .. '.o'
  return r .. '/.marvin-obj/' .. mangled
end

-- ── Binary path derivation ────────────────────────────────────────────────────
-- Returns the *unescaped* absolute path to the output binary.
local function binary_path(root, main_file)
  local r = abs(root)
  if main_file then
    return r .. '/' .. vim.fn.fnamemodify(main_file, ':t:r')
  end
  return r .. '/' .. vim.fn.fnamemodify(r, ':t')
end

-- ── Build command (multi-file project) ───────────────────────────────────────
-- Returns a single /bin/sh string. Steps are joined with " && \<newline>  ".
function CPP.build_cmd(p)
  local root     = abs(p.root)
  local lang     = CPP.project_lang(p)
  local lf_list  = CPP.scan_ldflags(root)
  local inc_list = CPP.include_flags(root)
  local sources  = CPP.all_sources(root, lang)
  local obj_dir  = root .. '/.marvin-obj'

  if #sources == 0 then
    -- Try the other language before giving up entirely
    local other         = lang == 'c' and 'cpp' or 'c'
    local other_sources = CPP.all_sources(root, other)
    if #other_sources > 0 then
      -- Disk scan and other hints disagreed — trust the files
      sources = other_sources
      lang    = other
    else
      vim.notify(
        '[Marvin] No C/C++ sources found in ' .. root
        .. '\nLooked for .' .. lang .. ' files.'
        .. '\nRun :JasonCppInfo for diagnostics.',
        vim.log.levels.ERROR)
      return 'echo "[Marvin] No sources found" && exit 1'
    end
  end

  local main_file = CPP.find_main_file(root, lang)
  local binary    = binary_path(root, main_file)

  local steps     = { 'mkdir -p ' .. esc(obj_dir) }

  local obj_files = {}
  for _, src in ipairs(sources) do
    local slang               = file_lang(src)
    local cc                  = compiler(slang)
    local std                 = std_flag(slang)
    local obj                 = obj_path(root, src)
    obj_files[#obj_files + 1] = obj
    steps[#steps + 1]         = string.format('%s -std=%s %s %s -c %s -o %s',
      cc, std, extra_cflags(), join(inc_list), esc(src), esc(obj))
  end

  local link_cc = compiler(main_file and file_lang(main_file) or lang)
  steps[#steps + 1] = string.format('%s %s %s -o %s',
    link_cc,
    join(vim.tbl_map(esc, obj_files)),
    join(lf_list),
    esc(binary))

  return table.concat(steps, ' && \\\n  ')
end

-- ── Single-file build command ─────────────────────────────────────────────────
-- Compiles exactly one .c/.cpp file. No object staging.
-- Returns { cmd = string, binary = string }.
function CPP.build_single_file_cmd(file_abs, root_abs)
  local f      = abs(file_abs)
  local root   = abs(root_abs or vim.fn.fnamemodify(f, ':h'))
  local lang   = file_lang(f)
  local cc     = compiler(lang)
  local std    = std_flag(lang)
  local cfl    = extra_cflags()
  local incs   = join(CPP.include_flags(root))
  -- Scan just this one file for link flags (fast)
  local lflags = join(scan_ldflags_files({ f }))
  local binary = root .. '/' .. vim.fn.fnamemodify(f, ':t:r')

  local cmd    = string.format('%s -std=%s %s %s %s -o %s',
    cc, std, cfl, incs, esc(f), esc(binary))
  if lflags ~= '' then cmd = cmd .. ' ' .. lflags end

  return { cmd = cmd, binary = binary }
end

-- ── Run command (unescaped binary path) ──────────────────────────────────────
-- Returns a plain shell string that runs the binary.
-- NOTE: do NOT shell-escape the return value again — it is already a
-- ready-to-run shell fragment.
function CPP.run_cmd(p, run_args)
  local root      = abs(p.root)
  local lang      = CPP.project_lang(p)
  local main_file = CPP.find_main_file(root, lang)
  local bin       = binary_path(root, main_file)
  local cmd       = esc(bin)
  if run_args and run_args ~= '' then
    cmd = cmd .. ' ' .. run_args
  end
  return cmd
end

-- ── Build + run (multi-file) ─────────────────────────────────────────────────
function CPP.build_and_run_cmd(p, run_args)
  local build = CPP.build_cmd(p)
  local run   = CPP.run_cmd(p, run_args)
  return build .. ' && \\\n  ' .. run
end

-- ── Clean ─────────────────────────────────────────────────────────────────────
function CPP.clean_cmd(p)
  local root   = abs(p.root)
  local lang   = CPP.project_lang(p)
  local main   = CPP.find_main_file(root, lang)
  local binary = binary_path(root, main)
  return 'rm -rf ' .. esc(root .. '/.marvin-obj') .. ' ' .. esc(binary)
end

-- ── Binary detection (for external callers) ──────────────────────────────────
function CPP.find_binary(p)
  local root = abs(p.root)
  local lang = CPP.project_lang(p)
  local main = CPP.find_main_file(root, lang)
  if main then return binary_path(root, main) end
  for _, name in ipairs({ vim.fn.fnamemodify(root, ':t'), 'main', 'app', 'demo', 'out' }) do
    for _, prefix in ipairs({ '', 'build/', 'bin/' }) do
      local candidate = root .. '/' .. prefix .. name
      if vim.fn.executable(candidate) == 1 then return candidate end
    end
  end
  return root .. '/' .. vim.fn.fnamemodify(root, ':t')
end

-- ── compile_commands.json — native generation ─────────────────────────────────
function CPP.generate_compile_commands(p)
  local root     = abs(p.root)
  local lang     = CPP.project_lang(p)
  local inc_list = CPP.include_flags(root)
  local sources  = CPP.all_sources(root, lang)

  if #sources == 0 then
    vim.notify('[Marvin] No C/C++ sources found in ' .. root, vim.log.levels.WARN)
    return false
  end

  local function q(s) return '"' .. s:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"' end

  local entries = {}
  for _, src in ipairs(sources) do
    local slang = file_lang(src)
    local cc    = compiler(slang)
    local std   = std_flag(slang)
    local cfl   = extra_cflags()
    local obj   = obj_path(root, src)
    local args  = { cc, '-std=' .. std }
    for _, f in ipairs(vim.split(cfl, '%s+')) do
      if f ~= '' then args[#args + 1] = f end
    end
    for _, inc in ipairs(inc_list) do args[#args + 1] = inc end
    args[#args + 1] = '-c'
    args[#args + 1] = src
    args[#args + 1] = '-o'
    args[#args + 1] = obj
    entries[#entries + 1] = string.format(
      '  {\n    "file": %s,\n    "directory": %s,\n    "arguments": [%s],\n    "output": %s\n  }',
      q(src), q(root), table.concat(vim.tbl_map(q, args), ', '), q(obj))
  end

  local json = '[\n' .. table.concat(entries, ',\n') .. '\n]\n'
  local out  = root .. '/compile_commands.json'
  local f    = io.open(out, 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. out, vim.log.levels.ERROR)
    return false
  end
  f:write(json); f:close()
  vim.notify(string.format(
    '[Marvin] compile_commands.json written (%d files).\nRestart clangd: :LspRestart',
    #sources), vim.log.levels.INFO)
  return true
end

-- ── Project info ─────────────────────────────────────────────────────────────
function CPP.show_info(p)
  local root      = abs(p.root)
  local lang      = CPP.project_lang(p)
  local mains     = CPP.find_main_files(root, lang)
  local srcs      = CPP.all_sources(root, lang)
  local incs      = CPP.include_flags(root)
  local lf        = CPP.scan_ldflags(root)
  local bin       = CPP.find_binary(p)

  local src_list  = #srcs > 0
      and table.concat(vim.tbl_map(function(f) return '    ' .. f end, srcs), '\n')
      or '    (none found)'
  local main_list = #mains > 0
      and table.concat(vim.tbl_map(function(f) return '    ' .. f end, mains), '\n')
      or '    (none — no file contains "int main(")'

  local lines     = {
    '',
    '  C/C++ Project — ' .. vim.fn.fnamemodify(root, ':t'),
    '  ' .. string.rep('─', 52),
    '  Root:      ' .. root,
    '  Language:  ' .. lang:upper(),
    '  Compiler:  ' .. compiler(lang) .. '  -std=' .. std_flag(lang),
    '  Sources (' .. #srcs .. '):',
    src_list,
    '  Includes:  ' .. join(incs),
    '  LDFLAGS:   ' .. (join(lf) ~= '' and join(lf) or '(none detected)'),
    '  Binary:    ' .. bin,
    '  Obj dir:   ' .. root .. '/.marvin-obj/',
    '  Entry point(s):',
    main_list,
    '',
  }
  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

-- Expose CPP engine
M.cpp = CPP

-- ══════════════════════════════════════════════════════════════════════════════
-- COMMAND TABLE — one entry per project type × action
-- ══════════════════════════════════════════════════════════════════════════════

local B = {
  maven = {
    build   = 'mvn compile',
    run     = function(p) return 'mvn exec:java -Dexec.mainClass=' .. M.find_main_class(p) end,
    test    = 'mvn test',
    clean   = 'mvn clean',
    install = 'mvn install',
    package = 'mvn package',
  },
  gradle = {
    build   = './gradlew build',
    run     = './gradlew run',
    test    = './gradlew test',
    clean   = './gradlew clean',
    install = './gradlew publishToMavenLocal',
    package = './gradlew jar',
  },
  cargo = {
    build   = function()
      local prof = require('marvin').config.rust.profile
      return prof == 'release' and 'cargo build --release' or 'cargo build'
    end,
    run     = function()
      local prof = require('marvin').config.rust.profile
      return prof == 'release' and 'cargo run --release' or 'cargo run'
    end,
    test    = 'cargo test',
    clean   = 'cargo clean',
    fmt     = 'cargo fmt',
    lint    = 'cargo clippy',
    install = 'cargo install --path .',
    package = function()
      local prof = require('marvin').config.rust.profile
      return prof == 'release' and 'cargo build --release' or 'cargo build'
    end,
  },
  go_mod = {
    build   = 'go build ./...',
    run     = 'go run .',
    test    = 'go test ./...',
    clean   = 'go clean ./...',
    fmt     = 'gofmt -w .',
    lint    = 'golangci-lint run',
    install = 'go install .',
    package = 'go build -o dist/ ./...',
  },
  cmake = {
    build   = 'cmake --build build',
    run     = function(p) return CPP.run_cmd(p) end,
    test    = 'ctest --test-dir build',
    clean   = 'cmake --build build --target clean',
    fmt     = 'find src include -name "*.cpp" -o -name "*.h" -o -name "*.c" | xargs clang-format -i',
    lint    = 'clang-tidy $(find src -name "*.cpp" -o -name "*.c")',
    install = 'cmake --install build',
    package = 'cpack --config build/CPackConfig.cmake',
  },
  -- Makefile: plugin owns build/run/clean; make is fallback for install etc.
  makefile = {
    build   = function(p) return CPP.build_cmd(p) end,
    run     = function(p) return CPP.run_cmd(p) end,
    test    = 'make test',
    clean   = function(p) return CPP.clean_cmd(p) end,
    fmt     = 'find src include -name "*.cpp" -o -name "*.h" -o -name "*.c" 2>/dev/null | xargs clang-format -i',
    lint    = 'make lint',
    install = 'make install',
    package = 'make dist',
  },
  -- Single file: compile exactly the current buffer.
  single_file = {
    build   = function(p)
      local ft = p.language or p.lang
      local f  = abs(p.file or vim.fn.expand('%:p'))
      if ft == 'java' then return 'javac ' .. esc(f) end
      if ft == 'rust' then return 'rustc ' .. esc(f) end
      if ft == 'go' then return 'go build ' .. esc(f) end
      if ft == 'c' or ft == 'cpp' then
        local root   = abs(p.root or vim.fn.fnamemodify(f, ':h'))
        local result = CPP.build_single_file_cmd(f, root)
        return result.cmd
      end
    end,
    run     = function(p)
      local ft   = p.language or p.lang
      local f    = abs(p.file or vim.fn.expand('%:p'))
      local root = abs(p.root or vim.fn.fnamemodify(f, ':h'))
      local stem = vim.fn.fnamemodify(f, ':t:r')
      if ft == 'java' then return 'java ' .. stem end
      if ft == 'c' or ft == 'cpp' then
        return esc(root .. '/' .. stem)
      end
      if ft == 'rust' then
        local dir = abs(vim.fn.fnamemodify(f, ':h'))
        return esc(dir .. '/' .. stem)
      end
      if ft == 'go' then return 'go run ' .. esc(f) end
    end,
    test    = nil,
    clean   = function(p)
      local f    = abs(p.file or vim.fn.expand('%:p'))
      local root = abs(p.root or vim.fn.fnamemodify(f, ':h'))
      local stem = vim.fn.fnamemodify(f, ':t:r')
      return 'rm -f ' .. esc(root .. '/' .. stem)
    end,
    fmt     = nil,
    lint    = nil,
    install = nil,
    package = nil,
  },
}

function M.get_command(action, project)
  local b = B[project.type]; if not b then return nil end
  local v = b[action]
  return type(v) == 'function' and v(project) or v
end

-- ══════════════════════════════════════════════════════════════════════════════
-- INTERNAL HELPERS
-- ══════════════════════════════════════════════════════════════════════════════

local function proj()
  local p = require('marvin.detector').get()
  if not p then vim.notify('No project detected', vim.log.levels.ERROR) end
  return p
end

local function tcfg() return require('marvin').config.terminal end

local function base_opts(p, title, action_id, extra_args)
  return {
    cwd       = abs(p.root),
    title     = title,
    term_cfg  = tcfg(),
    plugin    = 'jason',
    action_id = action_id,
    args      = extra_args ~= '' and extra_args or nil,
  }
end

local function run_action(action, title, action_id, p, prompt_args)
  local cmd = M.get_command(action, p)
  if not cmd then
    vim.notify(action .. ' not supported for ' .. p.type, vim.log.levels.WARN); return
  end
  if prompt_args then
    local saved = M.get_args(p.root, action)
    vim.ui.input({ prompt = title .. ' args: ', default = saved }, function(args)
      if args == nil then return end
      M.set_args(p.root, action, args)
      require('core.runner').execute(vim.tbl_extend('force',
        base_opts(p, title, action_id, args), { cmd = cmd }))
    end)
  else
    require('core.runner').execute(vim.tbl_extend('force',
      base_opts(p, title, action_id, ''), { cmd = cmd }))
  end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════════════════════

function M.build(prompt_args)
  local p = proj(); if not p then return end
  if not require('marvin.detector').require_tool(p.type) then return end
  run_action('build', 'Build', 'build', p, prompt_args)
end

function M.run(prompt_args)
  local p = proj(); if not p then return end
  run_action('run', 'Run', 'run', p, prompt_args)
end

function M.test(filter)
  local p = proj(); if not p then return end
  if filter then
    vim.ui.input({ prompt = 'Test filter: ', default = M.get_args(p.root, 'test') }, function(f)
      if f == nil then return end
      M.set_args(p.root, 'test', f)
      local cmd = M.get_test_cmd_filtered(p, f)
      require('core.runner').execute(vim.tbl_extend('force',
        base_opts(p, 'Test: ' .. f, 'test', ''), { cmd = cmd }))
    end)
  else
    run_action('test', 'Test', 'test', p, false)
  end
end

function M.clean()
  local p = proj(); if p then run_action('clean', 'Clean', 'clean', p, false) end
end

function M.fmt()
  local p = proj(); if p then run_action('fmt', 'Format', 'fmt', p, false) end
end

function M.lint()
  local p = proj(); if p then run_action('lint', 'Lint', 'lint', p, false) end
end

function M.install()
  local p = proj(); if p then run_action('install', 'Install', 'install', p, false) end
end

function M.package()
  local p = proj(); if p then run_action('package', 'Package', 'package', p, false) end
end

-- ── Build & Run ───────────────────────────────────────────────────────────────
-- For C/C++ (makefile, single_file, cmake-with-binary): build and run are
-- concatenated into one atomic shell command so the terminal shows everything
-- in a single pane and the run step is skipped on build failure.
-- For other types: two sequential runner calls.
function M.build_and_run(prompt_args)
  local p = proj(); if not p then return end

  -- ── single file (any language) ───────────────────────────────────────────
  if p.type == 'single_file' then
    local ft = p.language or p.lang or vim.bo.filetype
    local f  = abs(p.file or vim.fn.expand('%:p'))
    -- Refresh file/lang from current buffer if not set
    if not f or f == '' then f = abs(vim.fn.expand('%:p')) end
    p.file     = f
    p.language = ft
    p.lang     = ft
    p.root     = abs(p.root or vim.fn.fnamemodify(f, ':h'))

    local bc   = M.get_command('build', p)
    local rc   = M.get_command('run', p)

    if not bc then
      vim.notify('[Marvin] Cannot build filetype: ' .. ft, vim.log.levels.WARN); return
    end

    local function do_run(run_args)
      local run_cmd = rc or ''
      if run_args and run_args ~= '' and run_cmd ~= '' then
        run_cmd = run_cmd .. ' ' .. run_args
      end
      local full = run_cmd ~= '' and (bc .. ' && \\\n  ' .. run_cmd) or bc
      require('core.runner').execute(vim.tbl_extend('force',
        base_opts(p, 'Build & Run', 'build_run', ''), { cmd = full }))
    end

    if prompt_args then
      local saved = M.get_args(p.root, 'run')
      vim.ui.input({ prompt = 'Run args: ', default = saved }, function(args)
        if args == nil then return end
        M.set_args(p.root, 'run', args)
        do_run(args)
      end)
    else
      do_run(M.get_args(p.root, 'run'))
    end
    return
  end

  -- ── C/C++ native pipeline (makefile / flat dir) ─────────────────────────
  if p.type == 'makefile' then
    local root    = abs(p.root)
    local lang    = CPP.project_lang(p)
    local sources = CPP.all_sources(root, lang)
    -- If still empty after project_lang's best guess, try the other lang
    if #sources == 0 then
      local other = lang == 'c' and 'cpp' or 'c'
      sources     = CPP.all_sources(root, other)
      if #sources > 0 then lang = other end
    end
    if #sources == 0 then
      vim.notify('[Marvin] No C/C++ sources found in ' .. root
        .. '\nRun :JasonCppInfo for diagnostics.', vim.log.levels.ERROR)
      return
    end

    -- Single file shortcut: skip object staging entirely
    if #sources == 1 then
      local result = CPP.build_single_file_cmd(sources[1], abs(p.root))
      local function do_run(run_args)
        local run_cmd = esc(result.binary)
            .. (run_args ~= '' and (' ' .. run_args) or '')
        require('core.runner').execute(vim.tbl_extend('force',
          base_opts(p, 'Build & Run', 'build_run', ''),
          { cmd = result.cmd .. ' && \\\n  ' .. run_cmd }))
      end
      if prompt_args then
        local saved = M.get_args(p.root, 'run')
        vim.ui.input({ prompt = 'Run args: ', default = saved }, function(args)
          if args == nil then return end
          M.set_args(p.root, 'run', args); do_run(args)
        end)
      else
        do_run(M.get_args(p.root, 'run'))
      end
      return
    end

    -- Multi-file: full object-staging pipeline
    local function do_run(run_args)
      local cmd = CPP.build_and_run_cmd(p, run_args)
      require('core.runner').execute(vim.tbl_extend('force',
        base_opts(p, 'Build & Run', 'build_run', ''), { cmd = cmd }))
    end
    if prompt_args then
      local saved = M.get_args(p.root, 'run')
      vim.ui.input({ prompt = 'Run args: ', default = saved }, function(args)
        if args == nil then return end
        M.set_args(p.root, 'run', args)
        do_run(args)
      end)
    else
      do_run(M.get_args(p.root, 'run'))
    end
    return
  end

  -- ── cmake: build then run binary (atomic) ───────────────────────────────
  if p.type == 'cmake' then
    local function do_run(run_args)
      local bc  = M.get_command('build', p)
      local run = CPP.run_cmd(p, run_args)
      local cmd = bc .. ' && \\\n  ' .. run
      require('core.runner').execute(vim.tbl_extend('force',
        base_opts(p, 'Build & Run', 'build_run', ''), { cmd = cmd }))
    end
    if prompt_args then
      local saved = M.get_args(p.root, 'run')
      vim.ui.input({ prompt = 'Run args: ', default = saved }, function(args)
        if args == nil then return end
        M.set_args(p.root, 'run', args)
        do_run(args)
      end)
    else
      do_run(M.get_args(p.root, 'run'))
    end
    return
  end

  -- ── Other project types (Cargo, Go, Maven, Gradle) ──────────────────────
  -- These tools handle "run" themselves, so just call their run command which
  -- implicitly builds first (cargo run, go run, ./gradlew run, etc.).
  -- Exception: maven needs explicit build+exec sequence.
  if p.type == 'maven' then
    local bc = M.get_command('build', p)
    local rc = M.get_command('run', p)
    if bc and rc then
      local run_args = prompt_args and M.get_args(p.root, 'run') or ''
      local cmd      = bc .. ' && ' .. rc
          .. (run_args ~= '' and (' ' .. run_args) or '')
      require('core.runner').execute(vim.tbl_extend('force',
        base_opts(p, 'Build & Run', 'build_run', ''), { cmd = cmd }))
    end
    return
  end

  -- For cargo, go_mod, gradle: their "run" command already compiles.
  run_action('run', 'Build & Run', 'build_run', p, prompt_args)
end

function M.custom(cmd, title)
  local p = proj(); if not p then return end
  require('core.runner').execute(vim.tbl_extend('force',
    base_opts(p, title or cmd, cmd, ''), { cmd = cmd }))
end

-- ── Build just the currently open C/C++ file ─────────────────────────────────
function M.build_current_file()
  local file = abs(vim.fn.expand('%:p'))
  local ft   = vim.bo.filetype
  if ft ~= 'c' and ft ~= 'cpp' then
    vim.notify('[Marvin] Not a C/C++ file', vim.log.levels.WARN); return
  end
  local p_real = require('marvin.detector').get()
  local root   = p_real and p_real.root or vim.fn.fnamemodify(file, ':h')
  local result = CPP.build_single_file_cmd(file, root)
  require('core.runner').execute({
    cmd      = result.cmd,
    cwd      = abs(root),
    title    = 'Build ' .. vim.fn.fnamemodify(file, ':t'),
    term_cfg = tcfg(),
    plugin   = 'jason',
  })
end

-- ── Generate compile_commands.json natively ───────────────────────────────────
function M.generate_compile_commands()
  local p = proj(); if not p then return end
  CPP.generate_compile_commands(p)
end

-- ── Show C/C++ project diagnostics ───────────────────────────────────────────
function M.show_cpp_info()
  local p = proj(); if not p then return end
  if p.type ~= 'makefile' and p.type ~= 'cmake' and p.type ~= 'single_file' then
    vim.notify('[Marvin] Not a C/C++ project', vim.log.levels.WARN); return
  end
  CPP.show_info(p)
end

-- ── Backwards-compat shims ────────────────────────────────────────────────────
function M.execute(cmd, cwd, title)
  require('core.runner').execute({
    cmd = cmd,
    cwd = abs(cwd),
    title = title or cmd,
    term_cfg = tcfg(),
    plugin = 'jason',
  })
end

function M.execute_sequence(steps, cwd)
  require('core.runner').execute_sequence(steps,
    { cwd = abs(cwd), term_cfg = tcfg(), plugin = 'jason' })
end

function M.stop() require('core.runner').stop_last() end

-- ── Test filter helpers ───────────────────────────────────────────────────────
function M.get_test_cmd_filtered(project, filter)
  local t = project.type
  if t == 'cargo' then return 'cargo test ' .. filter end
  if t == 'go_mod' then return 'go test ./... -run ' .. filter end
  if t == 'maven' then return 'mvn test -Dtest=' .. filter end
  if t == 'gradle' then return './gradlew test --tests ' .. filter end
  if t == 'makefile' or t == 'cmake' then return 'ctest -R ' .. filter end
  return M.get_command('test', project)
end

-- ── Java helpers ─────────────────────────────────────────────────────────────
function M.find_main_class(project)
  local java_root = abs(project.root) .. '/src/main/java'
  local files = vim.fn.glob(java_root .. '/**/*.java', false, true)
  for _, file in ipairs(files) do
    local pkg, cls, has_main
    for _, line in ipairs(vim.fn.readfile(file)) do
      if line:match('^%s*package%s+') then
        pkg = line:match('package%s+([%w%.]+)')
      end
      if line:match('public%s+class%s+') then
        cls = line:match('class%s+(%w+)')
      end
      if line:match('public%s+static%s+void%s+main') then
        has_main = true
      end
      if pkg and cls and has_main then return pkg .. '.' .. cls end
    end
  end
  return 'Main'
end

-- Legacy shims
function M.find_cmake_executable(p) return CPP.find_binary(p) end

function M.find_makefile_executable(p) return CPP.find_binary(p) end

function M.find_main_file(root, lang) return CPP.find_main_file(abs(root), lang) end

function M.scan_ldflags(root) return join(CPP.scan_ldflags(abs(root))) end

return M
