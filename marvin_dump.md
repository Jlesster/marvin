# marvin — full source dump

Generated: 2026-03-30 21:33 UTC
Repo: /home/jless/Code/lua/marvin.nvim

---

## Directory Tree

```
/home/jless/Code/lua/marvin.nvim
doc
doc/marvin.txt
doc/tags
dump.sh
.git
lua
lua/core
lua/core/runner.lua
lua/marvin
lua/marvin/build.lua
lua/marvin/cmake_creator.lua
lua/marvin/commands.lua
lua/marvin/compiler.lua
lua/marvin/config.lua
lua/marvin/console.lua
lua/marvin/creator
lua/marvin/creator/cpp.lua
lua/marvin/creator/go.lua
lua/marvin/creator/java.lua
lua/marvin/creator/rust.lua
lua/marvin/dashboard.lua
lua/marvin/dependencies.lua
lua/marvin/deps
lua/marvin/deps/go.lua
lua/marvin/deps/java.lua
lua/marvin/deps/rust.lua
lua/marvin/detector.lua
lua/marvin/executor.lua
lua/marvin/generator.lua
lua/marvin/graalvm.lua
lua/marvin/init.lua
lua/marvin/jason_dashboard.lua
lua/marvin/java_creator.lua
lua/marvin/keymaps.lua
lua/marvin/lang
lua/marvin/lang/cpp.lua
lua/marvin/lang/go.lua
lua/marvin/lang/java.lua
lua/marvin/lang/rust.lua
lua/marvin/local_libs.lua
lua/marvin/makefile_creator.lua
lua/marvin/meson_creator.lua
lua/marvin/parser.lua
lua/marvin/project.lua
lua/marvin/tasks.lua
lua/marvin/templates.lua
lua/marvin/trixie_bridge.lua
lua/marvin/ui.lua
lua/marvin/wayland_protocols.lua
marvin_dump.md
plugin
plugin/marvin.vim
```

---

## File Contents

### `doc/marvin.txt`

```txt
*marvin.txt*  Maven plugin for Neovim

                    MARVIN - MAVEN FOR NEOVIM
                    
                    Run Maven goals without leaving Vim!

==============================================================================
CONTENTS                                                      *marvin-contents*

    1. Introduction ............................ |marvin-introduction|
    2. Requirements ............................ |marvin-requirements|
    3. Installation ............................ |marvin-installation|
    4. Quick Start ............................. |marvin-quickstart|
    5. Commands ................................ |marvin-commands|
    6. Configuration ........................... |marvin-configuration|
    7. Usage ................................... |marvin-usage|
    8. Keymaps ................................. |marvin-keymaps|
    9. FAQ ..................................... |marvin-faq|
   10. About ................................... |marvin-about|

==============================================================================
1. INTRODUCTION                                           *marvin-introduction*

Marvin is a Neovim plugin that provides seamless integration with Apache 
Maven. It allows you to run Maven goals, create new projects, and view build 
output without leaving your editor.

Features:
  • Interactive goal menu
  • Project generation from archetypes
  • Build output parsing to quickfix
  • Profile selection
  • Multiple UI backends (snacks.nvim, dressing.nvim, builtin)
  • Terminal or background execution

==============================================================================
2. REQUIREMENTS                                           *marvin-requirements*

Required:
  • Neovim 0.9.0 or later
  • Apache Maven installed and in PATH

Optional (for enhanced UI):
  • snacks.nvim
  • dressing.nvim

==============================================================================
3. INSTALLATION                                           *marvin-installation*

Using lazy.nvim: >lua
    {
      'yourusername/marvin.nvim',
      config = function()
        require('marvin').setup({
          -- your config here
        })
      end,
    }
<

Using packer.nvim: >lua
    use {
      'yourusername/marvin.nvim',
      config = function()
        require('marvin').setup()
      end
    }
<

==============================================================================
4. QUICK START                                             *marvin-quickstart*

1. Open a file in a Maven project (directory containing pom.xml)
2. Run `:Maven` to open the goal menu
3. Select a goal (e.g., "Clean", "Test", "Package")
4. Watch Maven execute in a terminal or background

Common workflows:
  • `:Maven` - Interactive menu
  • `:MavenClean` - Run mvn clean
  • `:MavenTest` - Run mvn test
  • `:MavenPackage` - Run mvn package
  • `:MavenNew` - Create new Maven project

==============================================================================
5. COMMANDS                                                   *marvin-commands*

                                                                        *:Maven*
:Maven                  Open interactive Maven goal menu

                                                                    *:MavenExec*
:MavenExec {goal}       Execute a specific Maven goal
                        Example: >
                        :MavenExec clean install
<
                                                                   *:MavenClean*
:MavenClean             Run `mvn clean`

                                                                    *:MavenTest*
:MavenTest              Run `mvn test`

                                                                 *:MavenPackage*
:MavenPackage           Run `mvn package`

                                                                     *:MavenNew*
:MavenNew               Create a new Maven project from archetype

                                                                    *:MavenStop*
:MavenStop              Stop the currently running Maven build

==============================================================================
6. CONFIGURATION                                         *marvin-configuration*

Default configuration: >lua
    require('marvin').setup({
      maven_command = 'mvn',        -- Maven executable
      ui_backend = 'auto',          -- 'auto', 'snacks', 'dressing', 'builtin'
      
      terminal = {
        position = 'float',         -- 'float', 'split', 'vsplit', 'background'
        size = 0.4,                 -- Height/width ratio
        close_on_success = false,   -- Auto-close on successful build
      },
      
      quickfix = {
        auto_open = true,           -- Auto-open quickfix for errors
        height = 10,                -- Quickfix window height
      },
      
      keymaps = {
        run_goal = '<leader>Mg',
        clean = '<leader>Mc',
        test = '<leader>Mt',
        package = '<leader>Mp',
        install = '<leader>Mi',
      },
      
      archetypes = {
        'maven-archetype-quickstart',
        'maven-archetype-webapp',
        'maven-archetype-simple',
      },
    })
<

Configuration options:                          *marvin-config-maven_command*
maven_command           Maven executable to use. Can be 'mvn' or 'mvnw' 
                        for Maven wrapper.

                                                *marvin-config-ui_backend*
ui_backend              UI backend for menus and prompts:
                        • 'auto' - Auto-detect (snacks > dressing > builtin)
                        • 'snacks' - Use snacks.nvim
                        • 'dressing' - Use dressing.nvim
                        • 'builtin' - Use Vim's builtin UI

                                                *marvin-config-terminal*
terminal                Terminal execution settings:
                        • position - Where to show terminal
                        • size - Height/width ratio (0-1)
                        • close_on_success - Auto-close on success

                                                *marvin-config-quickfix*
quickfix                Quickfix integration for build errors:
                        • auto_open - Automatically open quickfix
                        • height - Quickfix window height

                                                *marvin-config-keymaps*
keymaps                 Default keymaps for common goals

                                                *marvin-config-archetypes*
archetypes              List of archetypes to show in project creation menu

==============================================================================
7. USAGE                                                         *marvin-usage*

BASIC USAGE ~

Open the interactive menu: >
    :Maven
<
This shows a list of common Maven goals. Select one to execute.

Execute a specific goal: >
    :MavenExec clean install
<

PROFILES ~

If your pom.xml contains profiles, Marvin will detect them and prompt you
to select one when running goals.

CUSTOM GOALS ~

Select "Custom Goal..." from the menu to enter arbitrary Maven commands: >
    clean install -DskipTests=true -U
<

PROJECT GENERATION ~

Create a new Maven project: >
    :MavenNew
<
This will guide you through:
1. Selecting an archetype
2. Entering groupId, artifactId, version
3. Choosing a directory
4. Generating the project

QUICKFIX INTEGRATION ~

When a build fails, compilation errors are automatically parsed and added
to the quickfix list. Navigate with:
  • :cnext - Next error
  • :cprev - Previous error
  • :copen - Open quickfix window
  • :cclose - Close quickfix window

==============================================================================
8. KEYMAPS                                                     *marvin-keymaps*

Default keymaps (configurable):

    <leader>Mg          Open Maven goal menu
    <leader>Mc          Run mvn clean
    <leader>Mt          Run mvn test
    <leader>Mp          Run mvn package
    <leader>Mi          Run mvn install

To disable default keymaps, set: >lua
    require('marvin').setup({
      keymaps = {},  -- Empty table disables keymaps
    })
<

Then create your own: >lua
    vim.keymap.set('n', '<leader>mm', ':Maven<CR>')
    vim.keymap.set('n', '<leader>mc', ':MavenClean<CR>')
<

==============================================================================
9. FAQ                                                             *marvin-faq*

Q: Maven is installed but Marvin says it's not found.
A: Check that `mvn --version` works in your terminal. If you're using a 
   Maven wrapper, set `maven_command = 'mvnw'` in configuration.

Q: Build output doesn't show in terminal.
A: Make sure `terminal.position` is not set to 'background'. Try 'float' 
   or 'split'.

Q: Errors aren't showing in quickfix.
A: Ensure `quickfix.auto_open = true` and that your build actually failed.
   Error parsing currently supports Java compilation errors and test failures.

Q: How do I add more archetypes to the project creation menu?
A: Add them to the `archetypes` config: >lua
    require('marvin').setup({
      archetypes = {
        'maven-archetype-quickstart',
        'your-custom-archetype',
      },
    })
<

Q: Can I use this with Gradle?
A: No, Marvin is specifically for Maven. For Gradle, consider using a 
   different plugin.

==============================================================================
10. ABOUT                                                        *marvin-about*

Marvin is a Maven plugin for Neovim, designed to make Java development 
more efficient without leaving your editor.

Project: https://github.com/yourusername/marvin.nvim
License: MIT
Author: Your Name

Contribute:
  • Report bugs: GitHub issues
  • Submit PRs: GitHub pull requests
  • Star the repo if you find it useful!

==============================================================================
vim:tw=78:ts=8:ft=help:norl:

```

### `dump.sh`

```sh
#!/usr/bin/env bash
# dump_repo.sh
# Run from the root of your marvin repo:
#   bash dump_repo.sh > marvin_dump.md
# Then paste marvin_dump.md contents to Claude.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUTPUT_FILE="marvin_dump.md"

# File extensions to include
INCLUDE_EXT=("lua" "vim" "toml" "json" "yaml" "yml" "sh" "md" "txt" "nix")

# Dirs/files to skip
SKIP_PATTERNS=(".git" "node_modules" "*.zip" "*.png" "*.jpg" "*.gif")

should_skip() {
  local path="$1"
  for pat in "${SKIP_PATTERNS[@]}"; do
    case "$path" in
      *"$pat"*) return 0 ;;
    esac
  done
  return 1
}

has_ext() {
  local file="$1"
  local ext="${file##*.}"
  for e in "${INCLUDE_EXT[@]}"; do
    [[ "$ext" == "$e" ]] && return 0
  done
  return 1
}

{
  echo "# marvin — full source dump"
  echo ""
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M UTC')"
  echo "Repo: $REPO_ROOT"
  echo ""
  echo "---"
  echo ""

  # Directory tree overview
  echo "## Directory Tree"
  echo ""
  echo '```'
  if command -v tree &>/dev/null; then
    tree -a --noreport -I '.git|node_modules|*.zip' "$REPO_ROOT"
  else
    find "$REPO_ROOT" -not -path '*/.git/*' -not -name '*.zip' | sort | sed "s|$REPO_ROOT/||"
  fi
  echo '```'
  echo ""
  echo "---"
  echo ""

  # File contents
  echo "## File Contents"
  echo ""

  while IFS= read -r -d '' file; do
    rel="${file#$REPO_ROOT/}"

    should_skip "$rel" && continue
    has_ext "$file"  || continue

    ext="${file##*.}"
    echo "### \`$rel\`"
    echo ""
    echo "\`\`\`$ext"
    cat "$file"
    echo ""
    echo "\`\`\`"
    echo ""
  done < <(find "$REPO_ROOT" -type f -print0 | sort -z)

} > "$OUTPUT_FILE"

echo "Done! → $OUTPUT_FILE  ($(wc -l < "$OUTPUT_FILE") lines)" >&2

```

### `lua/core/runner.lua`

```lua
-- lua/core/runner.lua
-- Shared job execution engine for Jason + Marvin.
-- Owns: terminal/background execution, job tracking, unified history,
--       sequence runner, watch/restart mode, output log storage.

local M            = {}

M.jobs             = {} -- jid -> { title, cmd, start_time, buf?, win? }
M.history          = {} -- newest-first list of run entries
M.MAX_HIST         = 100

-- ── Listeners ─────────────────────────────────────────────────────────────────
M._listeners       = {}
M._start_listeners = {}

function M.on_finish(fn) M._listeners[#M._listeners + 1] = fn end

function M.on_start(fn) M._start_listeners[#M._start_listeners + 1] = fn end

local function fire_finish(entry)
  for _, fn in ipairs(M._listeners) do pcall(fn, entry) end
end

local function fire_start(entry)
  for _, fn in ipairs(M._start_listeners) do pcall(fn, entry) end
end

-- ── History ───────────────────────────────────────────────────────────────────
local function record(e)
  e.timestamp = e.timestamp or os.time()
  table.insert(M.history, 1, e)
  if #M.history > M.MAX_HIST then table.remove(M.history) end
end

function M.clear_history() M.history = {} end

function M.get_last_status(action_id)
  for _, e in ipairs(M.history) do
    if e.action_id == action_id and e.success ~= nil then return e end
  end
  return nil
end

-- ── Window builders ───────────────────────────────────────────────────────────
local function win_float(buf, title, cfg)
  local ui = vim.api.nvim_list_uis()[1]
  local w  = math.floor(ui.width * 0.82)
  local h  = math.floor(ui.height * (cfg.size or 0.4))
  local r  = math.floor((ui.height - h) / 2)
  local c  = math.floor((ui.width - w) / 2)
  return vim.api.nvim_open_win(buf, true, {
    relative  = 'editor',
    width     = w,
    height    = h,
    row       = r,
    col       = c,
    style     = 'minimal',
    border    = 'rounded',
    title     = ' ' .. title .. ' ',
    title_pos = 'center',
  })
end

local function win_split(buf, cfg)
  vim.cmd('split')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(win, math.floor(vim.api.nvim_win_get_height(win) * (cfg.size or 0.4)))
  vim.api.nvim_win_set_buf(win, buf)
  return win
end

local function win_vsplit(buf, cfg)
  vim.cmd('vsplit')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(win, math.floor(vim.api.nvim_win_get_width(win) * (cfg.size or 0.4)))
  vim.api.nvim_win_set_buf(win, buf)
  return win
end

local function set_win_opts(win)
  for k, v in pairs({ number = false, relativenumber = false, signcolumn = 'no', scrolloff = 0 }) do
    pcall(vim.api.nvim_set_option_value, k, v, { win = win })
  end
end

local function buf_keymaps(buf, win)
  local o = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, o)
  vim.keymap.set('t', '<Esc><Esc>', function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, o)
end

-- ── Build environment string from table ───────────────────────────────────────
local function env_prefix(env)
  if not env or vim.tbl_isempty(env) then return '' end
  local parts = {}
  for k, v in pairs(env) do parts[#parts + 1] = k .. '=' .. vim.fn.shellescape(tostring(v)) end
  return table.concat(parts, ' ') .. ' '
end

-- ── Core execute ──────────────────────────────────────────────────────────────
function M.execute(opts)
  local cmd   = env_prefix(opts.env) .. opts.cmd .. (opts.args and (' ' .. opts.args) or '')
  local cwd   = opts.cwd or vim.fn.getcwd()
  local title = opts.title or opts.cmd
  local tcfg  = opts.term_cfg or { position = 'float', size = 0.4, close_on_success = false }

  if tcfg.position == 'background' then
    M._bg(cmd, cwd, title, opts)
  else
    M._term(cmd, cwd, title, tcfg, opts)
  end
end

function M._bg(cmd, cwd, title, opts)
  local output = {}
  local start  = os.time()

  -- Insert a live "running" entry immediately so the console can show it
  local entry  = {
    action    = title,
    action_id = opts.action_id,
    plugin    = opts.plugin,
    success   = nil,    -- nil = still running
    output    = output, -- shared reference; appended to as output arrives
    duration  = 0,
    cmd       = cmd,
    timestamp = start,
  }
  record(entry)
  vim.notify('🔨 ' .. title, vim.log.levels.INFO)
  fire_start(entry)

  local jid
  jid = vim.fn.jobstart(cmd, {
    cwd             = cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout       = function(_, d) vim.list_extend(output, d) end,
    on_stderr       = function(_, d) vim.list_extend(output, d) end,
    on_exit         = function(_, code)
      M.jobs[jid]    = nil
      local ok       = code == 0
      local dur      = os.time() - start
      -- Mutate in-place so history viewers see the update without a new record()
      entry.success  = ok
      entry.duration = dur
      if ok then
        vim.notify(string.format('✅ %s  (%ds)', title, dur), vim.log.levels.INFO)
      else
        vim.notify(string.format('❌ %s failed  (%ds)', title, dur), vim.log.levels.ERROR)
        M._parse(output, opts.plugin)
      end
      fire_finish(entry)
      if opts.on_exit then pcall(opts.on_exit, ok, output) end
    end,
  })
  M.jobs[jid] = { title = title, cmd = cmd, start_time = start }
end

function M._term(cmd, cwd, title, tcfg, opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })

  local win
  local pos = tcfg.position or 'float'
  if pos == 'split' then
    win = win_split(buf, tcfg)
  elseif pos == 'vsplit' then
    win = win_vsplit(buf, tcfg)
  else
    win = win_float(buf, title, tcfg)
  end
  set_win_opts(win)

  local output = {}
  local start  = os.time()

  -- Insert a live "running" entry immediately
  local entry  = {
    action    = title,
    action_id = opts.action_id,
    plugin    = opts.plugin,
    success   = nil,
    output    = output,
    duration  = 0,
    cmd       = cmd,
    timestamp = start,
  }
  record(entry)
  fire_start(entry)

  local jid
  jid = vim.fn.termopen(cmd, {
    cwd       = cwd,
    on_stdout = function(_, d) vim.list_extend(output, d) end,
    on_stderr = function(_, d) vim.list_extend(output, d) end,
    on_exit   = function(_, code)
      M.jobs[jid]    = nil
      local ok       = code == 0
      local dur      = os.time() - start
      entry.success  = ok
      entry.duration = dur
      if ok then
        if tcfg.close_on_success then
          vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
          end, 1200)
        end
        vim.notify(string.format('✅ %s  (%ds)', title, dur), vim.log.levels.INFO)
      else
        vim.notify(string.format('❌ %s failed  (%ds)', title, dur), vim.log.levels.ERROR)
        M._parse(output, opts.plugin)
      end
      fire_finish(entry)
      if opts.on_exit then pcall(opts.on_exit, ok, output) end
    end,
  })
  M.jobs[jid] = { title = title, cmd = cmd, start_time = start, buf = buf, win = win }
  buf_keymaps(buf, win)
  vim.cmd('startinsert')
end

-- ── Sequence ──────────────────────────────────────────────────────────────────
function M.execute_sequence(steps, base_opts)
  local idx = 1
  local function nxt()
    if idx > #steps then
      vim.notify('✅ All tasks completed!', vim.log.levels.INFO); return
    end
    local step = steps[idx]
    local o    = vim.tbl_extend('force', base_opts, {
      cmd     = step.cmd,
      title   = step.title,
      on_exit = function(ok)
        if ok then
          idx = idx + 1; vim.schedule(nxt)
        else
          vim.notify('❌ Stopped at: ' .. step.title, vim.log.levels.ERROR)
        end
      end,
    })
    M.execute(o)
  end
  nxt()
end

-- ── Watch / restart ───────────────────────────────────────────────────────────
M._watchers = {}

function M.execute_watch(opts)
  local id        = opts.action_id or opts.cmd
  M._watchers[id] = true
  local function launch()
    local o = vim.tbl_extend('force', opts, {
      on_exit = function(ok, output)
        if opts.on_exit then pcall(opts.on_exit, ok, output) end
        if M._watchers[id] then
          vim.defer_fn(function()
            if M._watchers[id] then
              vim.notify('[runner] Restarting: ' .. (opts.title or id), vim.log.levels.INFO)
              launch()
            end
          end, 600)
        end
      end,
    })
    M.execute(o)
  end
  launch()
end

function M.stop_watch(action_id) M._watchers[action_id] = nil end

function M.is_watching(action_id) return M._watchers[action_id] == true end

-- ── Stop ──────────────────────────────────────────────────────────────────────
function M.stop_all()
  for jid, info in pairs(M.jobs) do
    vim.fn.jobstop(jid)
    vim.notify('Stopped: ' .. info.title, vim.log.levels.WARN)
  end
  M.jobs      = {}
  M._watchers = {}
end

function M.stop_last()
  local jid = nil
  for j in pairs(M.jobs) do jid = j end
  if jid then
    local info = M.jobs[jid]
    vim.fn.jobstop(jid)
    M.jobs[jid] = nil
    for id in pairs(M._watchers) do
      M._watchers[id] = nil; break
    end
    vim.notify('Stopped: ' .. info.title, vim.log.levels.WARN)
  else
    vim.notify('No running tasks', vim.log.levels.WARN)
  end
end

function M.running_count() return vim.tbl_count(M.jobs) end

function M.get_running()
  local r = {}
  for _, info in pairs(M.jobs) do r[#r + 1] = info end
  return r
end

-- ── Output log viewer ────────────────────────────────────────────────────────
function M.show_output(entry)
  if not entry or not entry.output or #entry.output == 0 then
    vim.notify('No output recorded for this run', vim.log.levels.INFO); return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('filetype', 'log', { buf = buf })

  local header = {
    '# ' .. (entry.action or 'Run'),
    '# cmd: ' .. (entry.cmd or '?'),
    '# status: ' .. (entry.success and 'SUCCESS' or 'FAILED'),
    '# duration: ' .. (entry.duration or '?') .. 's',
    string.rep('-', 60), '',
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false,
    vim.list_extend(header, entry.output or {}))
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  vim.cmd('split')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, math.floor(vim.o.lines * 0.4))
  vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, true) end,
    { noremap = true, silent = true, buffer = buf })
end

-- ── Parser dispatch ──────────────────────────────────────────────────────────
function M._parse(output, plugin)
  if plugin == 'marvin' then
    local ok, p = pcall(require, 'marvin.parser')
    if ok then
      p.parse_output(output); return
    end
  end
  local ok, p = pcall(require, 'jason.parser')
  if ok then p.parse_output(output) end
end

return M

```

### `lua/marvin/build.lua`

```lua
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

local function esc(s) return vim.fn.shellescape(tostring(s)) end

local function join(t)
  local out = {}
  for _, v in ipairs(t) do
    if v and v ~= '' then out[#out + 1] = v end
  end
  return table.concat(out, ' ')
end

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
    local is_cpp_std = cfg.standard:find('+', 1, true)
    if lang == 'c' and is_cpp_std then return 'c11' end
    if lang == 'cpp' and not is_cpp_std then return 'c++17' end
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

-- ── pkg-config header → package map ──────────────────────────────────────────
-- Used to auto-inject pkg-config --cflags into compile_commands.json and the
-- direct build pipeline, so headers like <wlr/backend.h> are found without
-- the user having to touch anything.
-- ── Dynamic pkg-config reverse map ──────────────────────────────────────────
-- Instead of a hardcoded pattern list, we build a header→package map at
-- runtime by scanning the include dirs advertised by every installed package.
-- This means any library will be auto-detected as long as it has a .pc file.
--
-- The map is built once and cached for the lifetime of the neovim session.
local _hdr_to_pkg_cache = nil

local function build_header_pkg_map()
  if _hdr_to_pkg_cache then return _hdr_to_pkg_cache end
  local map = {} -- 'hb-ft.h' → 'harfbuzz',  'wlr/backend.h' → 'wlroots-0.18'

  -- 1. Get all installed package names
  local h = io.popen('pkg-config --list-all 2>/dev/null')
  if not h then
    _hdr_to_pkg_cache = map; return map
  end
  local pkg_names = {}
  for line in h:lines() do
    local name = line:match('^(%S+)')
    if name then pkg_names[#pkg_names + 1] = name end
  end
  h:close()

  -- 2. For each package, find its include dirs and scan the headers in them
  local scanned_dirs = {}
  for _, pkg in ipairs(pkg_names) do
    local dirs = {}

    -- a) explicit -I flags from --cflags-only-I
    local ch = io.popen('pkg-config --cflags-only-I ' .. pkg .. ' 2>/dev/null')
    if ch then
      for line in ch:lines() do
        for token in line:gmatch('%S+') do
          if token:sub(1, 2) == '-I' then
            dirs[#dirs + 1] = token:sub(3)
          end
        end
      end
      ch:close()
    end

    -- b) includedir variable (catches packages whose headers are in /usr/include
    --    with no explicit -I since that's the default compiler search path)
    local ih = io.popen('pkg-config --variable=includedir ' .. pkg .. ' 2>/dev/null')
    if ih then
      local d = vim.trim(ih:read('*l') or ''); ih:close()
      if d ~= '' then dirs[#dirs + 1] = d end
    end

    -- c) also guess <includedir>/<stem> subdir for packages like harfbuzz
    --    whose headers live in /usr/include/harfbuzz/ with no -I flag
    local stem = pkg:match('^([%w]+)') -- 'harfbuzz-gobject' → 'harfbuzz'
    if stem then
      for _, base in ipairs({ '/usr/include', '/usr/local/include' }) do
        local guessed = base .. '/' .. stem
        if vim.fn.isdirectory(guessed) == 1 then
          dirs[#dirs + 1] = base    -- so 'harfbuzz/hb-ft.h' maps correctly
          dirs[#dirs + 1] = guessed -- so flat 'hb-ft.h' also maps
        end
      end
    end

    -- scan each dir
    for _, dir in ipairs(dirs) do
      if not scanned_dirs[dir] and vim.fn.isdirectory(dir) == 1 then
        scanned_dirs[dir] = true
        -- flat headers: hb-ft.h → pkg
        local fh = io.popen('ls ' .. vim.fn.shellescape(dir) .. ' 2>/dev/null')
        if fh then
          for entry in fh:lines() do
            if entry:match('%.h$') and not map[entry] then
              map[entry] = pkg
            elseif vim.fn.isdirectory(dir .. '/' .. entry) == 1 then
              -- subdir headers: wlr/backend.h → pkg
              local sh = io.popen('ls ' .. vim.fn.shellescape(dir .. '/' .. entry) .. ' 2>/dev/null')
              if sh then
                for hdr in sh:lines() do
                  if hdr:match('%.h$') then
                    local key = entry .. '/' .. hdr
                    if not map[key] then map[key] = pkg end
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

  _hdr_to_pkg_cache = map
  return map
end

-- Look up which pkg-config package provides a given #include path.
-- include_path is the raw string from #include <...>, e.g. 'wlr/backend.h', 'hb-ft.h'
local function include_to_pkg(include_path)
  local map = build_header_pkg_map()
  -- exact match first
  if map[include_path] then return map[include_path] end
  -- try just the filename (for includes like <cairo/cairo.h> → 'cairo.h')
  local fname = include_path:match('([^/]+)$')
  if fname and map[fname] then return map[fname] end
  return nil
end

-- Scan source tree for pkg-config packages, then return their --cflags tokens
-- (each -I/path as a separate entry, suitable for inserting into inc_list).
-- Also returns --libs tokens for lf_list.
-- Results are cached per root to avoid repeated shell calls.

-- Resolve a base pkg-config name to the actual installed name.
-- Handles versioned packages: 'wlroots' → 'wlroots-0.18' etc.
local _pkg_resolve_cache = {}
local function resolve_pkg(base)
  if _pkg_resolve_cache[base] ~= nil then return _pkg_resolve_cache[base] or nil end
  -- 1. Exact name
  if os.execute('pkg-config --exists ' .. base .. ' 2>/dev/null') == 0 then
    _pkg_resolve_cache[base] = base; return base
  end
  -- 2. Versioned variant: e.g. wlroots-0.18
  local h = io.popen(
    "pkg-config --list-all 2>/dev/null | grep -E '^" .. base .. "[-[:space:]]' | head -1 | awk '{print $1}'")
  if h then
    local found = vim.trim(h:read('*l') or ''); h:close()
    if found ~= '' then
      _pkg_resolve_cache[base] = found; return found
    end
  end
  _pkg_resolve_cache[base] = false; return nil
end

local _pkg_flag_cache = {}
function CPP.pkg_config_flags(root)
  if _pkg_flag_cache[root] then return _pkg_flag_cache[root] end

  local r       = abs(root)
  local found   = {}
  local ordered = {}

  -- collect all source+header files
  local cmd     = string.format(
    "find %s \\( -name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp'"
    .. " -o -name '*.cxx' -o -name '*.hxx' \\)"
    .. " -not -path '*/.marvin-obj/*' -not -path '*/build/*' -not -path '*/builddir/*'"
    .. " -type f 2>/dev/null",
    sh_path(r))
  local files   = {}
  local h       = io.popen(cmd)
  if h then
    for line in h:lines() do
      local a = vim.trim(line)
      if a ~= '' then files[#files + 1] = a end
    end
    h:close()
  end

  for _, fpath in ipairs(files) do
    local ok, lines = pcall(vim.fn.readfile, fpath)
    if ok then
      for _, line in ipairs(lines) do
        local inc = line:match('#%s*include%s*[<\"]([^>\"]+)[>\"]')
        if inc then
          local pkg = include_to_pkg(inc)
          if pkg and not found[pkg] then
            local resolved = resolve_pkg(pkg)
            if resolved then
              found[pkg]            = true
              ordered[#ordered + 1] = resolved
            end
          end
        end
      end
    end
  end

  local iflags = {}
  local lflags = {}

  if #ordered > 0 then
    local pkgs = table.concat(ordered, ' ')

    -- --cflags: split on spaces, keep only -I tokens for inc_list
    local cf_h = io.popen('pkg-config --cflags ' .. pkgs .. ' 2>/dev/null')
    if cf_h then
      local cf_out = cf_h:read('*l') or ''; cf_h:close()
      for token in cf_out:gmatch('%S+') do
        iflags[#iflags + 1] = token
      end
    end

    -- --libs: split on spaces for lf_list
    local lf_h = io.popen('pkg-config --libs ' .. pkgs .. ' 2>/dev/null')
    if lf_h then
      local lf_out = lf_h:read('*l') or ''; lf_h:close()
      for token in lf_out:gmatch('%S+') do
        lflags[#lflags + 1] = token
      end
    end

    -- wlroots also needs -DWLR_USE_UNSTABLE if any wlr/ headers are included
    local needs_wlr = false
    for _, pkg in ipairs(ordered) do
      if pkg:match('^wlroots') then
        needs_wlr = true; break
      end
    end
    if needs_wlr then
      -- check source files for wlr/ includes to be sure
      for _, fpath in ipairs(files) do
        local ok2, ls = pcall(vim.fn.readfile, fpath)
        if ok2 then
          for _, line in ipairs(ls) do
            if line:match('#%s*include%s*[<\"]wlr/') then
              iflags[#iflags + 1] = '-DWLR_USE_UNSTABLE'
              needs_wlr = false -- only add once
              break
            end
          end
          if not needs_wlr then break end
        end
      end
    end
  end

  local result = { iflags = iflags, lflags = lflags, pkg_names = ordered }
  _pkg_flag_cache[root] = result
  return result
end

local POSIX_HEADERS = {
  'unistd.h', 'pthread.h', 'sys/types.h', 'sys/stat.h', 'sys/wait.h',
  'sys/file.h', 'sys/socket.h', 'sys/mman.h', 'sys/select.h',
  'netinet/in.h', 'arpa/inet.h', 'netdb.h',
  'dirent.h', 'fcntl.h', 'signal.h', 'termios.h',
  'openssl/ssl.h', 'openssl/err.h', 'curl/curl.h', 'readline/readline.h',
}

local POSIX_FUNCTIONS = {
  'strtok_r', 'strndup', 'strdup', 'stpcpy', 'stpncpy',
  'getline', 'getdelim', 'dprintf', 'vasprintf', 'asprintf',
  'fdopen', 'fileno', 'popen', 'pclose',
  'ftruncate', 'fchmod', 'fchown', 'fsync', 'fdatasync',
  'openat', 'mkstemp', 'mkdtemp',
  'fork', 'vfork', 'execvp', 'execve', 'execle', 'execl', 'execv',
  'setsid', 'setpgid', 'getpgid', 'getsid',
  'waitpid', 'wait3', 'wait4',
  'flock', 'lockf', 'fcntl',
  'opendir', 'readdir', 'closedir', 'scandir', 'nftw', 'ftw',
  'symlink', 'readlink', 'realpath', 'dirname', 'basename',
  'socket', 'bind', 'listen', 'accept', 'connect',
  'send', 'recv', 'sendto', 'recvfrom',
  'getaddrinfo', 'freeaddrinfo', 'getnameinfo',
  'clock_gettime', 'clock_settime', 'nanosleep', 'timer_create',
  'gethostname', 'sysconf', 'pathconf', 'confstr',
  'getpwnam', 'getpwuid', 'getgrnam', 'getgrgid',
  'mmap', 'munmap', 'mprotect', 'mlock',
  'pipe', 'dup', 'dup2', 'dup3',
  'usleep', 'sleep',
  'truncate', 'link', 'unlink', 'rmdir', 'chdir', 'getcwd',
  'chown', 'chmod', 'lstat',
  'setenv', 'unsetenv', 'putenv',
  'dlopen', 'dlsym', 'dlclose',
  'sem_open', 'sem_wait', 'sem_post', 'sem_close', 'sem_unlink',
  'shm_open', 'shm_unlink',
  'pthread_create', 'pthread_join', 'pthread_mutex_lock',
}

local _posix_fn_set = {}
for _, fn in ipairs(POSIX_FUNCTIONS) do _posix_fn_set[fn] = true end

local _posix_hdr_set = {}
for _, h in ipairs(POSIX_HEADERS) do _posix_hdr_set[h] = true end

local function lines_need_posix(lines)
  for _, line in ipairs(lines) do
    local hdr = line:match('#%s*include%s*[<"]([^>"]+)[>"]')
    if hdr and _posix_hdr_set[hdr] then return true end
    for fn in line:gmatch('([%a_][%w_]*)%s*%(') do
      if _posix_fn_set[fn] then return true end
    end
  end
  return false
end

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

function CPP.needs_posix_define(root)
  local r   = abs(root)
  local cmd = string.format(
    "find %s \\( -name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp'"
    .. " -o -name '*.cxx' -o -name '*.hxx' \\)"
    .. " -not -path '*/.marvin-obj/*' -type f 2>/dev/null",
    sh_path(r))
  local h   = io.popen(cmd)
  if not h then return false end
  for path in h:lines() do
    local ok, lines = pcall(vim.fn.readfile, vim.trim(path))
    if ok and lines_need_posix(lines) then
      h:close()
      return true
    end
  end
  h:close()
  return false
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

-- ── Local library flag injection ──────────────────────────────────────────────
local function inject_local_lib_flags(root, lf_list, inc_list)
  local ok, local_libs = pcall(require, 'marvin.local_libs')
  if not ok then return end
  local lflags = local_libs.build_flags(root)
  if lflags.lflags ~= '' then
    for _, f in ipairs(vim.split(lflags.lflags, '%s+')) do
      if f ~= '' then lf_list[#lf_list + 1] = f end
    end
  end
  if lflags.iflags ~= '' then
    for _, f in ipairs(vim.split(lflags.iflags, '%s+')) do
      if f ~= '' then inc_list[#inc_list + 1] = f end
    end
  end
end

-- ── Source file collection ────────────────────────────────────────────────────
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

  if n_c > 0 and n_c >= n_cpp then return 'c' end
  if n_cpp > 0 then return 'cpp' end

  local explicit = p.language or p.lang
  if explicit == 'cpp' or explicit == 'c' then return explicit end

  local ft = vim.bo.filetype
  if ft == 'cpp' then return 'cpp' end
  if ft == 'c' then return 'c' end

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
local function binary_path(root, main_file)
  local r = abs(root)
  if main_file then
    return r .. '/' .. vim.fn.fnamemodify(main_file, ':t:r')
  end
  return r .. '/' .. vim.fn.fnamemodify(r, ':t')
end

-- ── Build command (multi-file project) ───────────────────────────────────────
function CPP.build_cmd(p)
  local root     = abs(p.root)
  local lang     = CPP.project_lang(p)
  local lf_list  = CPP.scan_ldflags(root)
  local inc_list = CPP.include_flags(root)

  inject_local_lib_flags(root, lf_list, inc_list)

  -- pkg-config: inject --cflags into inc_list, --libs into lf_list
  local pkg = CPP.pkg_config_flags(root)
  for _, f in ipairs(pkg.iflags) do inc_list[#inc_list + 1] = f end
  for _, f in ipairs(pkg.lflags) do lf_list[#lf_list + 1] = f end
  if #pkg.pkg_names > 0 then
    vim.notify('[Marvin] pkg-config deps: ' .. table.concat(pkg.pkg_names, ' '), vim.log.levels.INFO)
  end

  local posix_flag = CPP.needs_posix_define(root) and '-D_POSIX_C_SOURCE=200809L' or nil

  local sources = CPP.all_sources(root, lang)
  local obj_dir = root .. '/.marvin-obj'

  if #sources == 0 then
    local other         = lang == 'c' and 'cpp' or 'c'
    local other_sources = CPP.all_sources(root, other)
    if #other_sources > 0 then
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
    steps[#steps + 1]         = string.format('%s -std=%s %s%s %s -c %s -o %s',
      cc, std, extra_cflags(),
      posix_flag and (' ' .. posix_flag) or '',
      join(inc_list), esc(src), esc(obj))
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
function CPP.build_single_file_cmd(file_abs, root_abs)
  local f               = abs(file_abs)
  local root            = abs(root_abs or vim.fn.fnamemodify(f, ':h'))
  local lang            = file_lang(f)
  local cc              = compiler(lang)
  local std             = std_flag(lang)
  local cfl             = extra_cflags()
  local incs            = join(CPP.include_flags(root))
  local lflags          = join(scan_ldflags_files({ f }))
  local ok_pf, pf_lines = pcall(vim.fn.readfile, f)
  local posix_flag      = (ok_pf and lines_need_posix(pf_lines)) and '-D_POSIX_C_SOURCE=200809L' or nil
  local binary          = root .. '/' .. vim.fn.fnamemodify(f, ':t:r')

  local ok, local_libs  = pcall(require, 'marvin.local_libs')
  if ok then
    local lf = local_libs.build_flags(root)
    if lf.lflags ~= '' then
      lflags = lflags ~= '' and (lflags .. ' ' .. lf.lflags) or lf.lflags
    end
    if lf.iflags ~= '' then
      incs = incs ~= '' and (incs .. ' ' .. lf.iflags) or lf.iflags
    end
  end

  local cmd = string.format('%s -std=%s %s%s %s %s -o %s',
    cc, std, cfl,
    posix_flag and (' ' .. posix_flag) or '',
    incs, esc(f), esc(binary))
  if lflags ~= '' then cmd = cmd .. ' ' .. lflags end

  return { cmd = cmd, binary = binary }
end

-- ── Run command ───────────────────────────────────────────────────────────────
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

-- ── Binary detection ──────────────────────────────────────────────────────────
function CPP.find_binary(p)
  local root = abs(p.root)
  local lang = CPP.project_lang(p)
  local main = CPP.find_main_file(root, lang)
  if main then return binary_path(root, main) end
  for _, name in ipairs({ vim.fn.fnamemodify(root, ':t'), 'main', 'app', 'demo', 'out' }) do
    for _, prefix in ipairs({ '', 'build/', 'bin/', 'builddir/' }) do
      local candidate = root .. '/' .. prefix .. name
      if vim.fn.executable(candidate) == 1 then return candidate end
    end
  end
  return root .. '/' .. vim.fn.fnamemodify(root, ':t')
end

-- ── Meson binary detection ────────────────────────────────────────────────────
local function meson_find_binary(p)
  local root = abs(p.root)
  local name = vim.fn.fnamemodify(root, ':t')
  for _, candidate in ipairs({
    root .. '/builddir/' .. name,
    root .. '/build/' .. name,
    root .. '/builddir/src/' .. name,
  }) do
    if vim.fn.executable(candidate) == 1 then return candidate end
  end
  return root .. '/builddir/' .. name
end

-- ── compile_commands.json ─────────────────────────────────────────────────────
function CPP.generate_compile_commands(p)
  local root = abs(p.root)

  -- For Meson projects: compile_commands.json is owned by Meson +
  -- rewrite_compile_commands in cpp.lua. A hand-rolled file would be missing
  -- all pkg-config-resolved include paths and immediately wrong.
  -- Direct the user to Build → Setup instead.
  if p.type == 'meson' then
    vim.notify(
      '[Marvin] Meson project detected.\n'
      .. '  Use Build → Setup (meson setup builddir) to generate\n'
      .. '  compile_commands.json with fully-resolved pkg-config paths.\n'
      .. '  Marvin will rewrite it with absolute paths and restart clangd.',
      vim.log.levels.INFO)
    return false
  end

  local lang              = CPP.project_lang(p)
  local inc_list          = CPP.include_flags(root)

  local ok_ll, local_libs = pcall(require, 'marvin.local_libs')
  if ok_ll then
    local lf = local_libs.build_flags(root)
    if lf.iflags ~= '' then
      for _, f in ipairs(vim.split(lf.iflags, '%s+')) do
        if f ~= '' then inc_list[#inc_list + 1] = f end
      end
    end
  end

  -- pkg-config: inject --cflags so clangd finds system library headers
  local pkg = CPP.pkg_config_flags(root)
  for _, f in ipairs(pkg.iflags) do inc_list[#inc_list + 1] = f end

  local posix_flag = CPP.needs_posix_define(root) and '-D_POSIX_C_SOURCE=200809L' or nil
  local sources    = CPP.all_sources(root, lang)

  if #sources == 0 then
    vim.notify('[Marvin] No C/C++ sources found in ' .. root, vim.log.levels.WARN)
    return false
  end

  local function q(s)
    return '"' .. s:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
  end

  local entries = {}
  for _, src in ipairs(sources) do
    local slang  = file_lang(src)
    local cc_bin = compiler(slang)
    local std    = std_flag(slang)
    local cfl    = extra_cflags()
    local obj    = obj_path(root, src)

    -- "arguments" array form: each token is a separate element.
    -- Preferred over "command" string — no shell parsing, no quoting ambiguity.
    local args   = { cc_bin, '-std=' .. std }

    for _, f in ipairs(vim.split(cfl, '%s+')) do
      if f ~= '' then args[#args + 1] = f end
    end

    if posix_flag then args[#args + 1] = posix_flag end

    for _, inc in ipairs(inc_list) do
      args[#args + 1] = inc
    end

    args[#args + 1] = '-c'
    args[#args + 1] = src
    args[#args + 1] = '-o'
    args[#args + 1] = obj

    entries[#entries + 1] = string.format(
      '  {\n    "file": %s,\n    "directory": %s,\n    "arguments": [%s],\n    "output": %s\n  }',
      q(src), q(root),
      table.concat(vim.tbl_map(q, args), ', '),
      q(obj))
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

-- ── Project info ──────────────────────────────────────────────────────────────
function CPP.show_info(p)
  local root              = abs(p.root)
  local lang              = CPP.project_lang(p)
  local mains             = CPP.find_main_files(root, lang)
  local srcs              = CPP.all_sources(root, lang)
  local incs              = CPP.include_flags(root)
  local lf                = CPP.scan_ldflags(root)
  local bin               = CPP.find_binary(p)

  local ll_lines          = {}
  local ok_ll, local_libs = pcall(require, 'marvin.local_libs')
  if ok_ll then
    local sel = local_libs.selected_libs(root)
    if #sel > 0 then
      ll_lines[#ll_lines + 1] = '  Local libs (' .. #sel .. '):'
      for _, lib in ipairs(sel) do
        ll_lines[#ll_lines + 1] = '    -l' .. lib.name .. '  (' .. lib.path .. ')'
      end
    else
      ll_lines[#ll_lines + 1] = '  Local libs:  (none selected)'
    end
  end

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
  }
  for _, l in ipairs(ll_lines) do lines[#lines + 1] = l end
  lines[#lines + 1] = ''

  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

-- Expose CPP engine
M.cpp = CPP

-- ══════════════════════════════════════════════════════════════════════════════
-- COMMAND TABLE
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
  meson = {
    build       = 'meson compile -C builddir',
    run         = function(p) return vim.fn.shellescape(meson_find_binary(p)) end,
    test        = 'meson test -C builddir',
    clean       = 'rm -rf builddir',
    fmt         = 'clang-format -i $(find src include -name "*.cpp" -o -name "*.c" -o -name "*.h" 2>/dev/null)',
    lint        = 'clang-tidy $(find src include -name "*.cpp" -o -name "*.c" 2>/dev/null)',
    install     = 'meson install -C builddir',
    package     = 'meson compile -C builddir && meson dist -C builddir',
    setup       = 'meson setup builddir',
    reconfigure = 'meson setup --reconfigure builddir',
  },
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
      if ft == 'c' or ft == 'cpp' then return esc(root .. '/' .. stem) end
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
function M.build_and_run(prompt_args)
  local p = proj(); if not p then return end

  if p.type == 'single_file' then
    local ft = p.language or p.lang or vim.bo.filetype
    local f  = abs(p.file or vim.fn.expand('%:p'))
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

  if p.type == 'makefile' then
    local root    = abs(p.root)
    local lang    = CPP.project_lang(p)
    local sources = CPP.all_sources(root, lang)
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

  if p.type == 'meson' then
    local function do_run(run_args)
      local bc      = M.get_command('build', p)
      local run_cmd = vim.fn.shellescape(meson_find_binary(p))
      if run_args and run_args ~= '' then
        run_cmd = run_cmd .. ' ' .. run_args
      end
      local cmd = bc .. ' && \\\n  ' .. run_cmd
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

  run_action('run', 'Build & Run', 'build_run', p, prompt_args)
end

function M.custom(cmd, title)
  local p = proj(); if not p then return end
  require('core.runner').execute(vim.tbl_extend('force',
    base_opts(p, title or cmd, cmd, ''), { cmd = cmd }))
end

-- ── Build current C/C++ file ──────────────────────────────────────────────────
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

-- ── Generate compile_commands.json ───────────────────────────────────────────
function M.generate_compile_commands()
  local p = proj(); if not p then return end
  CPP.generate_compile_commands(p)
end

-- ── C/C++ project diagnostics ─────────────────────────────────────────────────
function M.show_cpp_info()
  local p = proj(); if not p then return end
  if p.type ~= 'makefile' and p.type ~= 'cmake' and p.type ~= 'meson' and p.type ~= 'single_file' then
    vim.notify('[Marvin] Not a C/C++ project', vim.log.levels.WARN); return
  end
  CPP.show_info(p)
end

-- ── Backwards-compat shims ────────────────────────────────────────────────────
function M.execute(cmd, cwd, title)
  require('core.runner').execute({
    cmd      = cmd,
    cwd      = abs(cwd),
    title    = title or cmd,
    term_cfg = tcfg(),
    plugin   = 'jason',
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
  if t == 'meson' then return 'meson test -C builddir --suite ' .. filter end
  return M.get_command('test', project)
end

-- ── Java helpers ──────────────────────────────────────────────────────────────
function M.find_main_class(project)
  local java_root = abs(project.root) .. '/src/main/java'
  local files     = vim.fn.glob(java_root .. '/**/*.java', false, true)
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

```

### `lua/marvin/cmake_creator.lua`

```lua
-- lua/marvin/cmake_creator.lua
-- Interactive CMakeLists.txt wizard.
-- Generates a well-structured CMakeLists.txt for C or C++ projects,
-- with optional auto-link detection, pkg-config detection, test target
-- (CTest + gtest/catch2), and install rules.

local M = {}

local function ui() return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function plain(it) return it.label end

-- ── pkg-config header → package name map ──────────────────────────────────────
-- Mirrors the map in makefile_creator.lua exactly.

-- ── pkg-config scan ───────────────────────────────────────────────────────────
-- ── Dynamic pkg-config dependency detection ──────────────────────────────────
-- Builds a header→package reverse map from whatever is installed on this system.
-- No hardcoded list needed — works for any library with a .pc file.

local _hdr_pkg_map_cache = nil
local function get_hdr_pkg_map()
  if _hdr_pkg_map_cache then return _hdr_pkg_map_cache end
  local map = {}

  local h = io.popen('pkg-config --list-all 2>/dev/null')
  if not h then _hdr_pkg_map_cache = map; return map end
  local pkgs = {}
  for line in h:lines() do
    local name = line:match('^(%S+)')
    if name then pkgs[#pkgs + 1] = name end
  end
  h:close()

  local scanned = {}
  for _, pkg in ipairs(pkgs) do
    local dirs = {}
    -- explicit -I flags
    local ch = io.popen('pkg-config --cflags-only-I ' .. pkg .. ' 2>/dev/null')
    if ch then
      local out = ch:read('*a'); ch:close()
      for token in out:gmatch('%S+') do
        if token:sub(1,2) == '-I' then dirs[#dirs+1] = token:sub(3) end
      end
    end
    -- includedir variable
    local ih = io.popen('pkg-config --variable=includedir ' .. pkg .. ' 2>/dev/null')
    if ih then
      local d = vim.trim(ih:read('*l') or ''); ih:close()
      if d ~= '' then dirs[#dirs+1] = d end
    end
    -- guess <includedir>/<stem> for packages like harfbuzz in /usr/include/harfbuzz/
    local stem = pkg:match('^([%a%d]+)')
    if stem then
      for _, base in ipairs({'/usr/include', '/usr/local/include'}) do
        if vim.fn.isdirectory(base .. '/' .. stem) == 1 then
          dirs[#dirs+1] = base
          dirs[#dirs+1] = base .. '/' .. stem
        end
      end
    end
    for _, dir in ipairs(dirs) do
      if not scanned[dir] and vim.fn.isdirectory(dir) == 1 then
        scanned[dir] = true
        local fh = io.popen('ls ' .. vim.fn.shellescape(dir) .. ' 2>/dev/null')
        if fh then
          for entry in fh:lines() do
            if entry:match('%.h$') then
              if not map[entry] then map[entry] = pkg end
            elseif vim.fn.isdirectory(dir .. '/' .. entry) == 1 then
              local sh = io.popen('ls ' .. vim.fn.shellescape(dir..'/'..entry) .. ' 2>/dev/null')
              if sh then
                for hdr in sh:lines() do
                  if hdr:match('%.h$') then
                    local key = entry .. '/' .. hdr
                    if not map[key] then map[key] = pkg end
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
  if map[inc] then return map[inc] end
  local fname = inc:match('([^/]+)$')
  return fname and map[fname] or nil
end


-- Resolve a base pkg-config name to the actual installed name.
-- Handles versioned packages: 'wlroots' → 'wlroots-0.18' etc.
local _pkg_resolve_cache = {}
local function resolve_pkg(base)
  if _pkg_resolve_cache[base] ~= nil then return _pkg_resolve_cache[base] or nil end
  -- 1. Exact name
  if os.execute('pkg-config --exists ' .. base .. ' 2>/dev/null') == 0 then
    _pkg_resolve_cache[base] = base; return base
  end
  -- 2. Versioned variant: e.g. wlroots-0.18
  local h = io.popen(
    "pkg-config --list-all 2>/dev/null | grep -E '^" .. base .. "[-[:space:]]' | head -1 | awk '{print $1}'")
  if h then
    local found = vim.trim(h:read('*l') or ''); h:close()
    if found ~= '' then _pkg_resolve_cache[base] = found; return found end
  end
  _pkg_resolve_cache[base] = false; return nil
end

local function detect_pkg_deps(root)
  local patterns = { '*.c', '*.cpp', '*.h', '*.hpp', '*.cxx', '*.hxx' }
  local found    = {}
  local ordered  = {}

  for _, pat in ipairs(patterns) do
    for _, f in ipairs(vim.fn.globpath(root, '**/' .. pat, false, true)) do
      if not f:find('/build', 1, true) and not f:find('/builddir', 1, true) then
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            local inc = line:match('#%s*include%s*[<\"]([^>\"]+)[>\"]')
            if inc then
              local pkg = include_to_pkg(inc)
              if pkg and not found[pkg] then
                local resolved = resolve_pkg(pkg)
                if resolved then
                  found[pkg]            = true
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
-- ── wlroots unstable guard ────────────────────────────────────────────────────
local function scan_needs_wlr_unstable(root)
  for _, pat in ipairs({ '**/*.c', '**/*.cpp', '**/*.cxx', '**/*.h', '**/*.hpp' }) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
      if not f:find('/build', 1, true) and not f:find('/builddir', 1, true) then
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            if line:match('#%s*include%s*[<\"]wlr/') then return true end
            if line:match('WLR_USE_UNSTABLE') then return true end
          end
        end
      end
    end
  end
  return false
end

-- ── Auto-link integration ─────────────────────────────────────────────────────
-- Returns cmake_targets (e.g. Threads::Threads) from the existing creator/cpp
-- detection, plus pkg_deps list from our header scan.
local function auto_detect_cmake_targets(root)
  local cmake_targets = {}
  local ok_cr, cr   = pcall(require, 'marvin.creator.cpp')
  local ok_det, det2 = pcall(require, 'marvin.detector')
  if ok_cr and ok_det then
    local p = det2.get()
    if p then
      local links = cr.detect_links(p)
      cmake_targets = (links and links.cmake) or {}
    end
  end
  return cmake_targets
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function write(path, content, name)
  local f = io.open(path, 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. path, vim.log.levels.ERROR); return false
  end
  f:write(content); f:close()
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.notify('[Marvin] CMakeLists.txt created for: ' .. name, vim.log.levels.INFO)
  return true
end

local function check_existing(path, content, name)
  if vim.fn.filereadable(path) == 1 then
    ui().select({
        { id = 'overwrite', label = 'Overwrite', desc = 'Replace existing CMakeLists.txt' },
        { id = 'cancel',    label = 'Cancel',    desc = 'Keep existing file' },
      }, { prompt = 'CMakeLists.txt already exists', format_item = plain },
      function(ch)
        if ch and ch.id == 'overwrite' then write(path, content, name) end
      end)
    return
  end
  write(path, content, name)
end

-- ── Template ──────────────────────────────────────────────────────────────────


local function cmake_template(opts)
  local lines = {}
  local function l(s) lines[#lines + 1] = (s or '') end

  local lang     = opts.lang == 'c' and 'C' or 'CXX'
  local std_var  = opts.lang == 'c' and 'CMAKE_C_STANDARD' or 'CMAKE_CXX_STANDARD'
  local std_req  = opts.lang == 'c' and 'CMAKE_C_STANDARD_REQUIRED' or 'CMAKE_CXX_STANDARD_REQUIRED'
  local std_ext  = opts.lang == 'c' and 'CMAKE_C_EXTENSIONS' or 'CMAKE_CXX_EXTENSIONS'
  local src_glob = opts.lang == 'c' and '*.c' or '*.cpp'
  local std_val  = opts.std or (opts.lang == 'c' and '11' or '17')

  -- Header
  l('# ' .. opts.name .. ' — generated by Marvin')
  l('# CMake ' .. (opts.cmake_min or '3.20') .. '+')
  l()
  l('cmake_minimum_required(VERSION ' .. (opts.cmake_min or '3.20') .. ')')
  l('project(' .. opts.name .. ' LANGUAGES ' .. lang .. ')')
  l()

  -- Language standard
  l('# ── Language standard ────────────────────────────────────────────────────')
  l('set(' .. std_var .. ' ' .. std_val .. ')')
  l('set(' .. std_req .. ' ON)')
  l('set(' .. std_ext .. ' OFF)')
  l()

  -- Source glob
  l('# ── Sources ──────────────────────────────────────────────────────────────')
  l('file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS')
  l('    "${CMAKE_CURRENT_SOURCE_DIR}/src/' .. src_glob .. '"')
  l(')')
  l()

  -- Executable
  l('# ── Target ───────────────────────────────────────────────────────────────')
  l('add_executable(' .. opts.name .. ' ${SOURCES})')
  l()

  -- Include dirs
  l('target_include_directories(' .. opts.name .. ' PRIVATE')
  l('    "${CMAKE_CURRENT_SOURCE_DIR}/include"')
  l(')')
  l()

  -- Compiler warnings + defines
  l('# ── Compiler options ─────────────────────────────────────────────────────')
  l('target_compile_options(' .. opts.name .. ' PRIVATE')
  if opts.lang == 'c' then
    l('    -Wall -Wextra -Wpedantic')
  else
    l('    -Wall -Wextra -Wpedantic -Wno-unused-parameter')
  end
  if opts.sanitizer and opts.sanitizer ~= 'none' then
    local sflag = opts.sanitizer == 'asan' and 'address'
        or opts.sanitizer == 'tsan' and 'thread'
        or 'undefined'
    l('    -fsanitize=' .. sflag .. ' -fno-omit-frame-pointer')
  end
  l(')')
  l()

  -- Compile definitions
  local defs = {}
  if opts.wlr_guard   then defs[#defs + 1] = 'WLR_USE_UNSTABLE' end
  if opts.needs_posix then defs[#defs + 1] = '_POSIX_C_SOURCE=200809L' end
  if #defs > 0 then
    l('target_compile_definitions(' .. opts.name .. ' PRIVATE')
    for _, d in ipairs(defs) do l('    ' .. d) end
    l(')')
    l()
  end

  if opts.sanitizer and opts.sanitizer ~= 'none' then
    local sflag = opts.sanitizer == 'asan' and 'address'
        or opts.sanitizer == 'tsan' and 'thread'
        or 'undefined'
    l('target_link_options(' .. opts.name .. ' PRIVATE -fsanitize=' .. sflag .. ')')
    l()
  end

  -- pkg-config dependencies
  local pkg_deps = opts.pkg_deps or {}
  if #pkg_deps > 0 then
    l('# ── pkg-config dependencies ───────────────────────────────────────────────')
    l('find_package(PkgConfig REQUIRED)')
    for _, pkg in ipairs(pkg_deps) do
      local varname = pkg:gsub('[%-.]', '_'):upper()
      l('pkg_check_modules(' .. varname .. ' REQUIRED IMPORTED_TARGET ' .. pkg .. ')')
    end
    l()
  end

  -- Auto-detected cmake targets + user extra libs
  local all_targets = {}
  if opts.cmake_targets then
    for _, t in ipairs(opts.cmake_targets) do all_targets[#all_targets + 1] = t end
  end
  -- pkg-config targets as PkgConfig::VARNAME
  for _, pkg in ipairs(pkg_deps) do
    local varname = pkg:gsub('[%-.]', '_'):upper()
    all_targets[#all_targets + 1] = 'PkgConfig::' .. varname
  end
  if opts.extra_libs and opts.extra_libs ~= '' then
    all_targets[#all_targets + 1] = opts.extra_libs
  end
  if #all_targets > 0 then
    l('# ── Link libraries ───────────────────────────────────────────────────────')
    local needs_threads = false
    for _, t in ipairs(all_targets) do
      if t:match('Threads') then needs_threads = true end
    end
    if needs_threads then l('find_package(Threads REQUIRED)') end
    l('target_link_libraries(' .. opts.name .. ' PRIVATE')
    for _, t in ipairs(all_targets) do l('    ' .. t) end
    l(')')
    l()
  end

  -- Wayland protocol generation
  local protocol_xmls = opts.protocol_xmls or {}
  if #protocol_xmls > 0 then
    l('# ── Wayland protocol generation ──────────────────────────────────────────────')
    l('find_program(WAYLAND_SCANNER wayland-scanner REQUIRED)')
    l()
    l('set(PROTOCOL_SOURCES)')
    for _, xml in ipairs(protocol_xmls) do
      local stem = xml:gsub('%.xml$', '')
      l('# ' .. xml)
      l('execute_process(')
      l('    COMMAND ${WAYLAND_SCANNER} client-header')
      l('        ${CMAKE_CURRENT_SOURCE_DIR}/include/protocols/' .. xml)
      l('        ${CMAKE_CURRENT_SOURCE_DIR}/include/protocols/' .. stem .. '-protocol.h')
      l(')')
      l('execute_process(')
      l('    COMMAND ${WAYLAND_SCANNER} private-code')
      l('        ${CMAKE_CURRENT_SOURCE_DIR}/include/protocols/' .. xml)
      l('        ${CMAKE_CURRENT_SOURCE_DIR}/include/protocols/' .. stem .. '-protocol.c')
      l(')')
      l('list(APPEND PROTOCOL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/include/protocols/' .. stem .. '-protocol.c)')
      l()
    end
    l('target_sources(' .. opts.name .. ' PRIVATE ${PROTOCOL_SOURCES})')
    l('target_include_directories(' .. opts.name .. ' PRIVATE ${CMAKE_CURRENT_BINARY_DIR})')
    l('target_include_directories(' .. opts.name .. " PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include/protocols)')
    l()
  end

  -- compile_commands.json
  l('# ── compile_commands.json (for clangd) ───────────────────────────────────')
  l('set(CMAKE_EXPORT_COMPILE_COMMANDS ON)')
  l()

  -- Optional: testing
  if opts.testing then
    l('# ── Tests ────────────────────────────────────────────────────────────────')
    l('enable_testing()')
    l()
    if opts.test_framework == 'gtest' then
      l('find_package(GTest REQUIRED)')
      l('file(GLOB_RECURSE TEST_SOURCES CONFIGURE_DEPENDS')
      l('    "${CMAKE_CURRENT_SOURCE_DIR}/tests/' .. src_glob .. '"')
      l(')')
      l('add_executable(' .. opts.name .. '_tests ${TEST_SOURCES})')
      l('target_include_directories(' .. opts.name .. '_tests PRIVATE')
      l('    "${CMAKE_CURRENT_SOURCE_DIR}/include"')
      l(')')
      l('target_link_libraries(' .. opts.name .. '_tests PRIVATE GTest::gtest_main)')
      l('include(GoogleTest)')
      l('gtest_discover_tests(' .. opts.name .. '_tests)')
    elseif opts.test_framework == 'catch2' then
      l('find_package(Catch2 3 REQUIRED)')
      l('file(GLOB_RECURSE TEST_SOURCES CONFIGURE_DEPENDS')
      l('    "${CMAKE_CURRENT_SOURCE_DIR}/tests/' .. src_glob .. '"')
      l(')')
      l('add_executable(' .. opts.name .. '_tests ${TEST_SOURCES})')
      l('target_include_directories(' .. opts.name .. '_tests PRIVATE')
      l('    "${CMAKE_CURRENT_SOURCE_DIR}/include"')
      l(')')
      l('target_link_libraries(' .. opts.name .. '_tests PRIVATE Catch2::Catch2WithMain)')
      l('include(CTest)')
      l('include(Catch)')
      l('catch_discover_tests(' .. opts.name .. '_tests)')
    else
      l('# add_subdirectory(tests)')
    end
    l()
  end

  -- Optional: install rules
  if opts.install then
    l('# ── Install ──────────────────────────────────────────────────────────────')
    l('install(TARGETS ' .. opts.name .. ' DESTINATION bin)')
    l('install(DIRECTORY include/ DESTINATION include)')
    l()
  end

  return table.concat(lines, '\n')
end

-- ── Wizard ────────────────────────────────────────────────────────────────────
function M.create(root, on_back)
  root = root or vim.fn.getcwd()
  local default_name = vim.fn.fnamemodify(root, ':t')

  -- Step 1: project name
  ui().input({ prompt = '󰬷 Project name', default = default_name }, function(name)
    if not name or name == '' then return end

    -- Step 2: language
    ui().select({
        { id = 'cpp', label = 'C++', desc = 'CXX language, .cpp sources' },
        { id = 'c',   label = 'C',   desc = 'C language, .c sources' },
      }, { prompt = 'Language', on_back = on_back, format_item = plain },
      function(lang_ch)
        if not lang_ch then return end
        local lang = lang_ch.id

        -- Step 3: standard
        local stds = lang == 'c'
            and {
              { id = '11', label = 'C11', desc = 'Recommended' },
              { id = '17', label = 'C17', desc = 'Latest stable' },
              { id = '99', label = 'C99', desc = 'Wide compat' },
            }
            or {
              { id = '17', label = 'C++17', desc = 'Recommended' },
              { id = '20', label = 'C++20', desc = 'Concepts, ranges' },
              { id = '23', label = 'C++23', desc = 'Latest' },
              { id = '14', label = 'C++14', desc = 'Lambdas, auto' },
            }
        ui().select(stds, { prompt = 'Standard', format_item = plain },
          function(std_ch)
            if not std_ch then return end

            -- Step 4: cmake minimum version
            ui().select({
                { id = '3.20', label = 'CMake 3.20', desc = 'Recommended minimum' },
                { id = '3.25', label = 'CMake 3.25', desc = 'Latest LTS features' },
                { id = '3.16', label = 'CMake 3.16', desc = 'Wide compatibility' },
              }, { prompt = 'CMake minimum version', format_item = plain },
              function(cmake_ch)
                if not cmake_ch then return end

                -- Step 5: sanitizer
                ui().select({
                    { id = 'none',  label = 'None' },
                    { id = 'asan',  label = 'AddressSanitizer', desc = '-fsanitize=address' },
                    { id = 'tsan',  label = 'ThreadSanitizer',  desc = '-fsanitize=thread' },
                    { id = 'ubsan', label = 'UBSanitizer',      desc = '-fsanitize=undefined' },
                  }, { prompt = 'Sanitizer (optional)', format_item = plain },
                  function(san_ch)
                    -- Step 6: testing
                    ui().select({
                        { id = 'none',   label = 'No tests' },
                        { id = 'gtest',  label = 'GoogleTest', desc = 'find_package(GTest)' },
                        { id = 'catch2', label = 'Catch2',     desc = 'find_package(Catch2 3)' },
                      }, { prompt = 'Test framework', format_item = plain },
                      function(test_ch)
                        -- Step 7: install rules
                        ui().select({
                            { id = 'yes', label = 'Yes — add install() rules' },
                            { id = 'no',  label = 'No' },
                          }, { prompt = 'Add install rules?', format_item = plain },
                          function(inst_ch)
                            -- Run full detection pipeline
                            local cmake_targets = auto_detect_cmake_targets(root)
                            local wlr_guard     = false
                            local needs_posix   = false
                            local pkg_deps      = {}
                            local ok_b, build   = pcall(require, 'marvin.build')
                            if ok_b and build.cpp then
                              if build.cpp.pkg_config_flags then
                                local ok_f, flags = pcall(build.cpp.pkg_config_flags, root)
                                if ok_f then
                                  pkg_deps = flags.pkg_names or {}
                                  for _, f in ipairs(flags.iflags or {}) do
                                    if f == '-DWLR_USE_UNSTABLE' then wlr_guard = true end
                                  end
                                end
                              end
                              if build.cpp.needs_posix_define then
                                local ok_p, res = pcall(build.cpp.needs_posix_define, root)
                                if ok_p then needs_posix = res end
                              end
                            end
                            if not wlr_guard then wlr_guard = scan_needs_wlr_unstable(root) end

                            -- Notify what was injected
                            local notices = {}
                            if #pkg_deps > 0 then
                              notices[#notices + 1] = 'pkg-config deps: ' .. table.concat(pkg_deps, ' ')
                              notices[#notices + 1] = '  → find_package(PkgConfig) + pkg_check_modules()'
                            end
                            if wlr_guard   then notices[#notices + 1] = 'wlroots → WLR_USE_UNSTABLE defined' end
                            if needs_posix then notices[#notices + 1] = 'POSIX   → _POSIX_C_SOURCE=200809L defined' end
                            if #cmake_targets > 0 then
                              notices[#notices + 1] = 'CMake targets: ' .. table.concat(cmake_targets, ' ')
                            end
                            if #notices > 0 then
                              vim.notify(
                                '[Marvin] Auto-detected:\n  ' .. table.concat(notices, '\n  '),
                                vim.log.levels.INFO)
                            end

                            -- Optional extra libs
                            ui().input({
                              prompt  = 'Extra link targets (space-separated, optional)',
                              default = '',
                            }, function(extra)
                              local ok_wp, wl_proto = pcall(require, 'marvin.wayland_protocols')
                              if not ok_wp then
                                vim.notify('[Marvin] wayland_protocols module error: ' .. tostring(wl_proto), vim.log.levels.WARN)
                                wl_proto = nil
                              end
                              local protocol_xmls = {}
                              if wl_proto then
                                local ok_r, proto_entries = pcall(wl_proto.resolve, root)
                                if ok_r then
                                  for _, e in ipairs(proto_entries) do
                                    if e.in_root then
                                      protocol_xmls[#protocol_xmls + 1] = e.xml
                                    end
                                  end
                                else
                                  vim.notify('[Marvin] Protocol scan error: ' .. tostring(proto_entries), vim.log.levels.WARN)
                                end
                              end

                              local opts = {
                                name           = name,
                                lang           = lang,
                                std            = std_ch.id,
                                cmake_min      = cmake_ch.id,
                                sanitizer      = san_ch and san_ch.id or 'none',
                                testing        = test_ch and test_ch.id ~= 'none',
                                test_framework = test_ch and test_ch.id or nil,
                                install        = inst_ch and inst_ch.id == 'yes',
                                cmake_targets  = cmake_targets,
                                pkg_deps       = pkg_deps,
                                wlr_guard      = wlr_guard,
                                needs_posix    = needs_posix,
                                extra_libs     = extra and extra ~= '' and extra or nil,
                                protocol_xmls  = protocol_xmls,
                              }
                              local content = cmake_template(opts)
                              check_existing(root .. '/CMakeLists.txt', content, name)
                            end)
                          end)
                      end)
                  end)
              end)
          end)
      end)
  end)
end

return M

```

### `lua/marvin/commands.lua`

```lua
-- lua/marvin/commands.lua
-- All user commands for Marvin (project manager) and Jason (task runner).

local M = {}

function M.register()
  local function cmd(name, fn, opts)
    vim.api.nvim_create_user_command(name, fn, opts or {})
  end

  -- ════════════════════════════════════════════════════════════════════════════
  -- MARVIN — Project management
  -- ════════════════════════════════════════════════════════════════════════════

  -- Main dashboard
  cmd('Marvin', function() require('marvin.dashboard').show() end,
    { desc = 'Open Marvin project dashboard' })
  cmd('MarvinDashboard', function() require('marvin.dashboard').show() end,
    { desc = 'Open Marvin project dashboard' })

  -- Project info
  cmd('MarvinInfo', function()
    local p = require('marvin.detector').get()
    if not p then
      vim.notify('[Marvin] No project detected', vim.log.levels.WARN); return
    end
    local info = p.info or {}
    local lines = {
      'Project : ' .. (p.name or '?'),
      'Type    : ' .. p.type,
      'Lang    : ' .. p.lang,
      'Root    : ' .. p.root,
    }
    for k, v in pairs(info) do
      if type(v) == 'string' or type(v) == 'number' or type(v) == 'boolean' then
        lines[#lines + 1] = string.format('%-8s: %s', k, tostring(v))
      end
    end
    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
  end, { desc = 'Show current project info' })

  -- Project reload
  cmd('MarvinReload', function()
    require('marvin.detector').reload()
    vim.notify('[Marvin] Project reloaded', vim.log.levels.INFO)
  end, { desc = 'Re-parse project manifest' })

  -- Switch project (monorepo)
  cmd('MarvinSwitch', function()
    require('marvin.dashboard').show_project_picker()
  end, { desc = 'Switch active sub-project' })

  -- ── Java / Maven ────────────────────────────────────────────────────────────
  cmd('JavaNew', function()
    require('marvin.creator.java').show_menu(function()
      require('marvin.dashboard').show()
    end)
  end, { desc = 'New Java file (class/interface/record/enum…)' })

  cmd('MavenNew', function()
    local ok, gen = pcall(require, 'marvin.generator')
    if ok then gen.create_project() end
  end, { desc = 'New Maven project from archetype' })

  -- Direct Maven goal
  cmd('Maven', function(args)
    local goal = args.args
    if goal == '' then
      vim.notify('[Marvin] Usage: :Maven <goal>', vim.log.levels.WARN); return
    end
    require('marvin.executor').run(goal)
  end, { nargs = '+', desc = 'Run Maven goal' })

  -- Common Maven shortcuts
  for _, spec in ipairs({
    { 'MavenCompile', 'compile', 'mvn compile' },
    { 'MavenTest',    'test',    'mvn test' },
    { 'MavenPackage', 'package', 'mvn package' },
    { 'MavenInstall', 'install', 'mvn install' },
    { 'MavenClean',   'clean',   'mvn clean' },
    { 'MavenVerify',  'verify',  'mvn verify' },
    { 'MavenDeploy',  'deploy',  'mvn deploy' },
  }) do
    local name, goal = spec[1], spec[2]
    cmd(name, function() require('marvin.executor').run(goal) end,
      { desc = spec[3] })
  end

  cmd('MavenStop', function()
    local ok, runner = pcall(require, 'core.runner')
    if ok then runner.stop_all() end
  end, { desc = 'Stop running Maven process' })

  -- ── Rust / Cargo ────────────────────────────────────────────────────────────
  cmd('RustNew', function()
    require('marvin.creator.rust').create_crate()
  end, { desc = 'New Cargo crate (bin or lib)' })

  -- ── Go ───────────────────────────────────────────────────────────────────────
  cmd('GoNew', function()
    local p = require('marvin.detector').get()
    if not p or p.type ~= 'go_mod' then
      vim.notify('[Marvin] Not in a Go project', vim.log.levels.WARN); return
    end
    require('marvin.dashboard').show()
  end, { desc = 'Open Go creation menu' })

  -- ── C / C++ ──────────────────────────────────────────────────────────────────
  cmd('CppNew', function()
    local p = require('marvin.detector').get()
    if not p or (p.type ~= 'cmake' and p.type ~= 'makefile' and p.type ~= 'single_file') then
      vim.notify('[Marvin] Not in a C/C++ project', vim.log.levels.WARN); return
    end
    require('marvin.creator.cpp').handle(
      nil,  -- id = nil → show menu
      function() require('marvin.dashboard').show() end
    )
  end, { desc = 'New C/C++ file (class/struct/enum/test…)' })

  -- ── File creation ────────────────────────────────────────────────────────────
  cmd('MarvinNewMakefile', function()
    require('marvin.makefile_creator').create(vim.fn.getcwd())
  end, { desc = 'Create a Makefile from template' })

  -- ════════════════════════════════════════════════════════════════════════════
  -- JASON — Task runner
  -- ════════════════════════════════════════════════════════════════════════════

  cmd('Jason', function()
    require('marvin.jason_dashboard').show()
  end, { desc = 'Open Jason task runner dashboard' })
  cmd('JasonDashboard', function()
    require('marvin.jason_dashboard').show()
  end, { desc = 'Open Jason task runner dashboard' })

  -- Core build actions
  local bld = function() return require('marvin.build') end
  cmd('JasonBuild', function() bld().build() end, { desc = 'Jason: Build project' })
  cmd('JasonRun', function() bld().run() end, { desc = 'Jason: Run project' })
  cmd('JasonTest', function() bld().test() end, { desc = 'Jason: Run tests' })
  cmd('JasonClean', function() bld().clean() end, { desc = 'Jason: Clean' })
  cmd('JasonPackage', function() bld().package() end, { desc = 'Jason: Package' })
  cmd('JasonInstall', function() bld().install() end, { desc = 'Jason: Install' })
  cmd('JasonFmt', function() bld().fmt() end, { desc = 'Jason: Format' })
  cmd('JasonLint', function() bld().lint() end, { desc = 'Jason: Lint' })
  cmd('JasonBuildRun', function() bld().build_and_run() end, { desc = 'Jason: Build then run' })

  -- With prompts
  cmd('JasonBuildArgs', function() bld().build(true) end, { desc = 'Jason: Build with args' })
  cmd('JasonRunArgs', function() bld().run(true) end, { desc = 'Jason: Run with args' })
  cmd('JasonTestFilter', function() bld().test(true) end, { desc = 'Jason: Test with filter' })

  -- Exec arbitrary command in project root
  cmd('JasonExec', function(args)
    if args.args == '' then
      vim.notify('[Jason] Usage: :JasonExec <command>', vim.log.levels.WARN); return
    end
    bld().custom(args.args, args.args)
  end, { nargs = '+', desc = 'Jason: Run arbitrary command' })

  -- Console
  cmd('JasonConsole', function()
    require('marvin.console').toggle()
  end, { desc = 'Jason: Toggle task console' })
  cmd('JasonHistory', function()
    require('marvin.console').open()
  end, { desc = 'Jason: Open task history' })

  -- Stop
  cmd('JasonStop', function()
    local ok, runner = pcall(require, 'core.runner')
    if ok then runner.stop() end
  end, { desc = 'Jason: Stop current task' })
  cmd('JasonStopAll', function()
    local ok, runner = pcall(require, 'core.runner')
    if ok then runner.stop_all() end
  end, { desc = 'Jason: Stop all tasks' })

  -- Sub-project switch
  cmd('JasonSwitch', function()
    require('marvin.dashboard').show_project_picker()
  end, { desc = 'Jason: Switch sub-project' })

  -- Makefile
  cmd('JasonNewMakefile', function()
    require('marvin.makefile_creator').create(vim.fn.getcwd())
  end, { desc = 'Create a Makefile from template' })

  -- GraalVM
  cmd('GraalBuild', function()
    local p = require('marvin.detector').get()
    require('marvin.graalvm').build_native(p)
  end, { desc = 'GraalVM: Build native image' })
  cmd('GraalRun', function()
    local p = require('marvin.detector').get()
    require('marvin.graalvm').run_native(p)
  end, { desc = 'GraalVM: Run native binary' })
  cmd('GraalInfo', function()
    require('marvin.graalvm').show_info()
  end, { desc = 'GraalVM: Show status / install info' })
end

return M

```

### `lua/marvin/compiler.lua`

```lua
-- lua/marvin/compiler.lua
-- Sets vim's makeprg + errorformat per project type on BufEnter.
-- Makes :make work correctly for every supported language / build tool.
-- (Was jason.compiler — absorbed into marvin namespace.)

local M = {}

local EF = {
  java_javac = '%f:%l: error: %m,%-G%.%#',
  java_maven = table.concat({
    '%E[ERROR] %f:[%l\\,%c] %m',
    '%E[ERROR] %f:%l: %m',
    '%W[WARNING] %f:[%l\\,%c] %m',
    '%-G%.%#',
  }, ','),
  rust       = table.concat({
    '%Eerror%s%m',
    '%Cerror[E%n]: %m',
    '%Z%\\s%#-->%\\s%f:%l:%c',
    '%Wwarning: %m',
    '%Z%\\s%#-->%\\s%f:%l:%c',
    '%-G%.%#',
  }, ','),
  go         = table.concat({ '%f:%l:%c: %m', '%f:%l: %m', '%-G%.%#' }, ','),
  cpp        = table.concat({
    '%f:%l:%c: %trror: %m',
    '%f:%l:%c: %tarning: %m',
    '%f:%l:%c: %tote: %m',
    '%-G%.%#',
  }, ','),
  make       = '%f:%l:%c: %m,%-G%.%#',
  cmake      = '%f:%l:%c: %m,%-G%.%#',
}

local function cargo_cmd()
  local p = require('marvin').config.rust.profile
  return p == 'release' and 'cargo build --release 2>&1' or 'cargo build 2>&1'
end

local CONFIGS = {
  maven       = function() return { makeprg = 'mvn compile', errorformat = EF.java_maven } end,
  gradle      = function() return { makeprg = './gradlew build', errorformat = EF.java_maven } end,
  cargo       = function() return { makeprg = cargo_cmd(), errorformat = EF.rust } end,
  go_mod      = function() return { makeprg = 'go build ./... 2>&1', errorformat = EF.go } end,
  cmake       = function() return { makeprg = 'cmake --build build 2>&1', errorformat = EF.cmake } end,
  makefile    = function() return { makeprg = 'make 2>&1', errorformat = EF.make } end,
  single_file = function(p)
    local ft   = p.lang
    local file = p.file or vim.fn.expand('%:p')
    local base = vim.fn.fnamemodify(file, ':t:r')
    if ft == 'java' then
      return { makeprg = 'javac ' .. vim.fn.shellescape(file), errorformat = EF.java_javac }
    elseif ft == 'rust' then
      return { makeprg = 'rustc ' .. vim.fn.shellescape(file) .. ' 2>&1', errorformat = EF.rust }
    elseif ft == 'go' then
      return { makeprg = 'go build ' .. vim.fn.shellescape(file) .. ' 2>&1', errorformat = EF.go }
    elseif ft == 'cpp' then
      local cfg = require('marvin').config
      return {
        makeprg = string.format('%s -std=%s %s -o %s 2>&1',
          cfg.cpp.compiler, cfg.cpp.standard,
          vim.fn.shellescape(file), vim.fn.shellescape(base)),
        errorformat = EF.cpp,
      }
    elseif ft == 'c' then
      return {
        makeprg = string.format('gcc %s -o %s 2>&1', vim.fn.shellescape(file), vim.fn.shellescape(base)),
        errorformat = EF.cpp,
      }
    end
  end,
}

function M.apply(project)
  if not project then return end
  local fn = CONFIGS[project.type]
  if not fn then return end
  local cfg = fn(project)
  if not cfg then return end
  vim.bo.makeprg     = cfg.makeprg
  vim.bo.errorformat = cfg.errorformat
end

function M.setup_buf()
  local ok, det = pcall(require, 'marvin.detector')
  if not ok then return end
  M.apply(det.get())
end

return M

```

### `lua/marvin/config.lua`

```lua
-- lua/marvin/config.lua
local M = {}

M.defaults = {
  ui_backend = 'auto', -- auto | snacks | dressing | builtin

  terminal = {
    position         = 'float', -- float | split | vsplit | background
    size             = 0.4,
    close_on_success = false,
  },

  quickfix = {
    auto_open = true,
    height    = 10,
  },

  keymaps = {
    -- Marvin (project manager)
    dashboard   = '<leader>m',

    -- Jason (task runner)
    jason       = '<leader>j',
    jason_build = '<leader>jc',
    jason_run   = '<leader>jr',
    jason_test  = '<leader>jt',
    jason_clean = '<leader>jx',
    jason_console = '<leader>jo',
  },

  -- ── Java ──────────────────────────────────────────────────────────────────
  java = {
    enable_javadoc    = false,
    maven_command     = 'mvn',
    build_tool        = 'auto',   -- auto | maven | gradle | javac
    main_class_finder = 'auto',   -- auto | prompt
    archetypes = {
      'maven-archetype-quickstart',
      'maven-archetype-webapp',
      'maven-archetype-simple',
      'jless-schema-archetype',
    },
  },

  -- ── Rust ──────────────────────────────────────────────────────────────────
  rust = {
    profile = 'dev', -- dev | release
  },

  -- ── Go ────────────────────────────────────────────────────────────────────
  go = {
    -- nothing to configure yet — go toolchain is self-contained
  },

  -- ── C / C++ ───────────────────────────────────────────────────────────────
  cpp = {
    build_tool = 'auto', -- auto | cmake | make | gcc
    compiler   = 'g++',
    standard   = 'c++17',
  },

  -- ── GraalVM ───────────────────────────────────────────────────────────────
  graalvm = {
    extra_build_args = '',
    output_dir       = 'target/native',
    no_fallback      = true,
    g1gc             = false,
    pgo              = 'none', -- none | instrument | optimize
    report_size      = true,
    agent_output_dir = 'src/main/resources/META-INF/native-image',
  },
}

function M.setup(opts)
  return vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M

```

### `lua/marvin/console.lua`

```lua
-- lua/marvin/console.lua
-- Overseer-style task console (was jason.console).
-- Shows a split panel: left = job history list, right = live/stored output.

local M = {}

local C = {
  bg = '#1e1e2e',
  bg2 = '#181825',
  bg3 = '#11111b',
  surface0 = '#313244',
  surface1 = '#45475a',
  text = '#cdd6f4',
  sub1 = '#bac2de',
  ov0 = '#6c7086',
  blue = '#89b4fa',
  mauve = '#cba6f7',
  green = '#a6e3a1',
  yellow = '#f9e2af',
  peach = '#fab387',
  red = '#f38ba8',
  sky = '#89dceb',
}

local function setup_hl()
  local function hl(n, o) vim.api.nvim_set_hl(0, n, o) end
  hl('JasonConWin', { bg = C.bg, fg = C.text })
  hl('JasonConBorder', { fg = C.surface1, bg = C.bg })
  hl('JasonConTitle', { fg = C.mauve, bold = true })
  hl('JasonConOutWin', { bg = C.bg3, fg = C.sub1 })
  hl('JasonConOutBorder', { fg = C.surface0, bg = C.bg3 })
  hl('JasonConOutTitle', { fg = C.blue, bold = true })
  hl('JasonConSep', { fg = C.surface1 })
  hl('JasonConSepLbl', { fg = C.ov0, italic = true })
  hl('JasonConSel', { bg = C.surface0, fg = C.text })
  hl('JasonConOk', { fg = C.green, bold = true })
  hl('JasonConFail', { fg = C.red, bold = true })
  hl('JasonConRunning', { fg = C.yellow, bold = true })
  hl('JasonConDim', { fg = C.ov0 })
  hl('JasonConCmd', { fg = C.sky })
  hl('JasonConTime', { fg = C.peach })
  hl('JasonConFooter', { fg = C.ov0 })
  hl('JasonConFooterKey', { fg = C.peach, bold = true })
end

local state = {
  list_buf = nil,
  out_buf  = nil,
  list_win = nil,
  out_win  = nil,
  sel      = 1,
  ns_list  = vim.api.nvim_create_namespace('jason_con_list'),
  ns_out   = vim.api.nvim_create_namespace('jason_con_out'),
  open     = false,
  _timer   = nil,
}

local function ago(ts)
  if not ts then return '' end
  local d = os.time() - ts
  if d < 5 then
    return 'just now'
  elseif d < 60 then
    return d .. 's ago'
  elseif d < 3600 then
    return math.floor(d / 60) .. 'm ago'
  else
    return math.floor(d / 3600) .. 'h ago'
  end
end

local function dur(s)
  if not s or s == 0 then return '' end
  if s < 60 then return string.format('%.1fs', s) end
  return string.format('%dm%ds', math.floor(s / 60), s % 60)
end

local function history()
  local ok, r = pcall(require, 'core.runner')
  return ok and r.history or {}
end

local function running_jobs()
  local ok, r = pcall(require, 'core.runner')
  return ok and r.get_running and r.get_running() or {}
end

local function is_valid_win(w) return w and vim.api.nvim_win_is_valid(w) end
local function is_valid_buf(b) return b and vim.api.nvim_buf_is_valid(b) end

-- ── Safe line helpers ─────────────────────────────────────────────────────────
-- nvim_buf_set_lines rejects strings containing '\n'. This helper splits any
-- string on newlines and returns a flat list of single-line strings, with
-- carriage returns stripped (common in terminal output on some systems).
local function split_line(s)
  s = tostring(s or ''):gsub('\r', '')
  if not s:find('\n', 1, true) then return { s } end
  local out = {}
  for part in (s .. '\n'):gmatch('([^\n]*)\n') do
    out[#out + 1] = part
  end
  return out
end

-- Append a (potentially multi-line) string to the lines/hls accumulators.
-- `prefix` is prepended to the FIRST sub-line only; continuation lines get
-- the same width of spaces so output stays visually aligned.
-- `specs` highlights are applied to EACH sub-line.
local function add_line(lines, hls, raw, prefix, specs)
  prefix         = prefix or ''
  local cont_pad = string.rep(' ', vim.fn.strdisplaywidth(prefix))
  local parts    = split_line(raw)
  for i, part in ipairs(parts) do
    local ln = (i == 1 and prefix or cont_pad) .. part
    lines[#lines + 1] = ln
    local li = #lines - 1
    for _, s in ipairs(specs or {}) do
      hls[#hls + 1] = { line = li, hl = s[1], cs = s[2], ce = s[3] }
    end
  end
end

-- Simple single-line add (no prefix splitting needed, but still sanitise).
local function add_raw(lines, hls, raw, specs)
  -- raw should not contain newlines at this point, but sanitise anyway
  local safe = tostring(raw or ''):gsub('\r', ''):gsub('\n', ' ')
  lines[#lines + 1] = safe
  local li = #lines - 1
  for _, s in ipairs(specs or {}) do
    hls[#hls + 1] = { line = li, hl = s[1], cs = s[2], ce = s[3] }
  end
end

local LIST_W = 42

local function render_list()
  if not is_valid_buf(state.list_buf) then return end
  local lines, hls = {}, {}

  local function add(ln, specs) add_raw(lines, hls, ln, specs) end
  local function ahr(li, hl_name)
    hls[#hls + 1] = { line = li, hl = hl_name, cs = 0, ce = -1 }
  end

  add('  󰋚 Task Console', { { 'JasonConTitle', 2, -1 } })
  add(string.rep('─', LIST_W), { { 'JasonConSep', 0, -1 } })

  local running = running_jobs()
  if running and #running > 0 then
    add(' ● Running', { { 'JasonConRunning', 1, 2 }, { 'JasonConSepLbl', 3, -1 } })
    for _, job in ipairs(running) do
      local t = (job.title or job.cmd or '?'):sub(1, LIST_W - 6)
      add('  ⟳ ' .. t, { { 'JasonConRunning', 2, 3 }, { 'JasonConCmd', 4, -1 } })
    end
    add(string.rep('─', LIST_W), { { 'JasonConSep', 0, -1 } })
  end

  local h = history()
  if #h == 0 then
    add('', {})
    add('  No history yet.', { { 'JasonConDim', 0, -1 } })
    add('  Run a build to see output here.', { { 'JasonConDim', 0, -1 } })
  else
    add(' History', { { 'JasonConSepLbl', 1, -1 } })
    for i, entry in ipairs(h) do
      local is_sel = (i == state.sel)
      local status = entry.success == nil and '⟳' or (entry.success and '✓' or '✗')
      local hl_st  = entry.success == nil and 'JasonConRunning'
          or (entry.success and 'JasonConOk' or 'JasonConFail')
      local title  = (entry.action or entry.cmd or '?')
      local ts     = ago(entry.timestamp)
      local d      = dur(entry.duration)
      local right  = (d ~= '' and (d .. '  ') or '') .. ts
      local avail  = LIST_W - 2 - 2 - #right - 1
      local tdisp  = title:sub(1, math.max(4, avail))
      local pad    = math.max(0, avail - vim.fn.strdisplaywidth(tdisp))
      local ln     = '  ' .. status .. ' ' .. tdisp .. string.rep(' ', pad) .. right
      local li     = #lines
      add(ln, {})
      if is_sel then
        ahr(li, 'JasonConSel')
      else
        hls[#hls + 1] = { line = li, hl = hl_st, cs = 2, ce = 3 }
        hls[#hls + 1] = { line = li, hl = 'JasonConCmd', cs = 4, ce = 4 + #tdisp }
        hls[#hls + 1] = { line = li, hl = 'JasonConTime', cs = LIST_W - #right, ce = -1 }
      end
    end
  end

  add('', {})
  add(string.rep('─', LIST_W), { { 'JasonConSep', 0, -1 } })
  add('  j/k select  r re-run  d dismiss  q quit', { { 'JasonConFooterKey', 0, -1 } })
  add('  <CR>/<Tab> jump to output', { { 'JasonConFooter', 0, -1 } })

  vim.api.nvim_set_option_value('modifiable', true, { buf = state.list_buf })
  vim.api.nvim_buf_set_lines(state.list_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = state.list_buf })
  vim.api.nvim_buf_clear_namespace(state.list_buf, state.ns_list, 0, -1)
  for _, h2 in ipairs(hls) do
    pcall(vim.api.nvim_buf_add_highlight,
      state.list_buf, state.ns_list, h2.hl, h2.line, h2.cs, h2.ce)
  end
end

local function render_output()
  if not is_valid_buf(state.out_buf) then return end
  local h          = history()
  local entry      = h[state.sel]
  local lines, hls = {}, {}

  -- Wrapper: single fixed-content line (no embedded newlines expected, but sanitise)
  local function add(ln, specs) add_raw(lines, hls, ln, specs) end

  if not entry then
    local running = running_jobs()
    if running and #running > 0 then
      local job = running[1]
      add('  ⟳ ' .. (job.title or job.cmd or 'Running…'), { { 'JasonConRunning', 2, 3 } })
      add('', {})
      if job.output then
        for _, ln in ipairs(job.output) do
          add_line(lines, hls, ln, '  ', {})
        end
      else
        add('  (waiting for output…)', { { 'JasonConDim', 0, -1 } })
      end
    else
      add('', {}); add('  No entry selected.', { { 'JasonConDim', 0, -1 } })
    end
  else
    local ok_str = entry.success == nil and '⟳ Running'
        or (entry.success and '✓ Success' or '✗ Failed')
    local ok_hl  = entry.success == nil and 'JasonConRunning'
        or (entry.success and 'JasonConOk' or 'JasonConFail')
    add('  ' .. ok_str .. '  ' .. (entry.action or ''),
      { { ok_hl, 2, 2 + #ok_str } })
    add('  cmd: ' .. (entry.cmd or '?'), { { 'JasonConCmd', 7, -1 } })
    if entry.timestamp then
      add('  ran: ' .. os.date('%H:%M:%S', entry.timestamp)
        .. '  ' .. ago(entry.timestamp), { { 'JasonConTime', 7, -1 } })
    end
    if entry.duration and entry.duration > 0 then
      add('  dur: ' .. dur(entry.duration), { { 'JasonConDim', 0, -1 } })
    end
    add(string.rep('─', 60), { { 'JasonConSep', 0, -1 } })

    local output = entry.output or {}
    if #output == 0 then
      add('  (no captured output)', { { 'JasonConDim', 0, -1 } })
    else
      for _, ln in ipairs(output) do
        -- Determine highlight based on content (check before splitting)
        local specs = {}
        local lc = tostring(ln)
        if lc:match('%[ERROR%]') or lc:match('^error') or lc:match('FAILED') then
          specs = { { 'JasonConFail', 0, -1 } }
        elseif lc:match('%[WARNING%]') or lc:match('^warning') or lc:match(': warning:') then
          specs = { { 'JasonConRunning', 0, -1 } }
        elseif lc:match('%[INFO%]') or lc:match('^%s*at ') then
          specs = { { 'JasonConDim', 0, -1 } }
        end
        -- add_line handles embedded \n by splitting into multiple lines
        add_line(lines, hls, ln, '  ', specs)
      end
    end
  end

  vim.api.nvim_set_option_value('modifiable', true, { buf = state.out_buf })
  vim.api.nvim_buf_set_lines(state.out_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = state.out_buf })
  vim.api.nvim_buf_clear_namespace(state.out_buf, state.ns_out, 0, -1)
  for _, h2 in ipairs(hls) do
    pcall(vim.api.nvim_buf_add_highlight,
      state.out_buf, state.ns_out, h2.hl, h2.line, h2.cs, h2.ce)
  end
  if is_valid_win(state.out_win) then
    local e  = history()[state.sel]
    local ti = e and (e.action or 'output') or 'output'
    pcall(vim.api.nvim_win_set_config, state.out_win, {
      title = { { ' ' .. ti .. ' ', 'JasonConOutTitle' } },
    })
  end
end

local function redraw()
  render_list(); render_output()
end

local _hooks_registered = false
local function register_hooks()
  if _hooks_registered then return end
  _hooks_registered = true
  local runner = require('core.runner')
  runner.on_start(function(_entry)
    vim.schedule(function()
      state.sel = 1
      if not state.open then M.open() else redraw() end
    end)
  end)
  runner.on_finish(function(_entry)
    vim.schedule(function()
      if state.open and is_valid_win(state.list_win) then redraw() end
    end)
  end)
end

local function start_timer()
  if state._timer then return end
  state._timer = vim.loop.new_timer()
  state._timer:start(0, 500, vim.schedule_wrap(function()
    if not state.open or not is_valid_win(state.list_win) then
      if state._timer then
        state._timer:stop(); state._timer = nil
      end
      return
    end
    redraw()
  end))
end

local function stop_timer()
  if state._timer then
    state._timer:stop(); state._timer:close(); state._timer = nil
  end
end

function M.close()
  stop_timer()
  state.open = false
  pcall(vim.api.nvim_win_close, state.list_win, true)
  pcall(vim.api.nvim_win_close, state.out_win, true)
  state.list_win = nil; state.out_win = nil
  state.list_buf = nil; state.out_buf = nil
end

function M.open()
  setup_hl()
  if state.open and is_valid_win(state.list_win) then
    M.close(); return
  end
  register_hooks()
  state.open    = true
  local h       = history()
  state.sel     = math.max(1, math.min(state.sel, math.max(1, #h)))

  local screen  = vim.api.nvim_list_uis()[1]
  local H       = screen.height
  local W       = screen.width
  local TOTAL_H = math.floor(H * 0.45)
  local OUT_W   = W - LIST_W - 3
  local ROW     = H - TOTAL_H - 2
  local COL     = 1

  local function mkbuf()
    local b = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = b })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = b })
    vim.api.nvim_set_option_value('swapfile', false, { buf = b })
    vim.api.nvim_set_option_value('modifiable', false, { buf = b })
    return b
  end
  state.list_buf = mkbuf()
  state.out_buf  = mkbuf()

  local common   = {
    relative = 'editor',
    height   = TOTAL_H,
    row      = ROW,
    style    = 'minimal',
    zindex   = 45,
    border   = 'single',
  }
  state.list_win = vim.api.nvim_open_win(state.list_buf, true,
    vim.tbl_extend('force', common, {
      width     = LIST_W,
      col       = COL,
      title     = { { ' Jason Console ', 'JasonConTitle' } },
      title_pos = 'center',
    }))
  state.out_win  = vim.api.nvim_open_win(state.out_buf, false,
    vim.tbl_extend('force', common, {
      width     = OUT_W,
      col       = COL + LIST_W + 1,
      title     = { { ' output ', 'JasonConOutTitle' } },
      title_pos = 'left',
    }))

  local function setwhl(w, n, b2)
    vim.api.nvim_set_option_value('winhl',
      'Normal:' .. n .. ',FloatBorder:' .. b2, { win = w })
  end
  setwhl(state.list_win, 'JasonConWin', 'JasonConBorder')
  setwhl(state.out_win, 'JasonConOutWin', 'JasonConOutBorder')

  local base_wopts = {
    wrap = false,
    number = false,
    relativenumber = false,
    signcolumn = 'no',
    scrolloff = 2,
    cursorline = false,
  }
  for k, v in pairs(base_wopts) do
    pcall(vim.api.nvim_set_option_value, k, v, { win = state.list_win })
    pcall(vim.api.nvim_set_option_value, k, v, { win = state.out_win })
  end
  pcall(vim.api.nvim_set_option_value, 'wrap', true, { win = state.out_win })

  local mo = { noremap = true, silent = true, buffer = state.list_buf }

  local function nav_h(n)
    local hh = history()
    if #hh == 0 then return end
    state.sel = math.max(1, math.min(state.sel + n, #hh))
    redraw()
  end
  local function focus_output()
    if is_valid_win(state.out_win) then
      vim.api.nvim_set_current_win(state.out_win)
    end
  end
  local function rerun_sel()
    local hh = history(); local e = hh[state.sel]
    if not e then return end
    require('marvin.build').custom(e.cmd, e.action)
  end
  local function dismiss_sel()
    local hh = history()
    if #hh == 0 then return end
    table.remove(hh, state.sel)
    state.sel = math.max(1, math.min(state.sel, #hh))
    redraw()
  end

  vim.keymap.set('n', 'j', function() nav_h(1) end, mo)
  vim.keymap.set('n', 'k', function() nav_h(-1) end, mo)
  vim.keymap.set('n', '<Down>', function() nav_h(1) end, mo)
  vim.keymap.set('n', '<Up>', function() nav_h(-1) end, mo)
  vim.keymap.set('n', '<C-d>', function() nav_h(5) end, mo)
  vim.keymap.set('n', '<C-u>', function() nav_h(-5) end, mo)
  vim.keymap.set('n', '<CR>', focus_output, mo)
  vim.keymap.set('n', '<Tab>', focus_output, mo)
  vim.keymap.set('n', 'r', rerun_sel, mo)
  vim.keymap.set('n', 'd', dismiss_sel, mo)
  vim.keymap.set('n', 'q', M.close, mo)
  vim.keymap.set('n', '<Esc>', M.close, mo)

  local omo = { noremap = true, silent = true, buffer = state.out_buf }
  vim.keymap.set('n', 'q', M.close, omo)
  vim.keymap.set('n', '<Esc>', M.close, omo)
  vim.keymap.set('n', 'r', rerun_sel, omo)
  vim.keymap.set('n', '<Tab>', function()
    if is_valid_win(state.list_win) then
      vim.api.nvim_set_current_win(state.list_win)
    end
  end, omo)

  vim.api.nvim_create_autocmd('WinClosed', {
    pattern  = tostring(state.list_win) .. ',' .. tostring(state.out_win),
    once     = false,
    callback = function(ev)
      local closed = tonumber(ev.match)
      if closed == state.list_win or closed == state.out_win then
        vim.defer_fn(function()
          if not is_valid_win(state.list_win) or not is_valid_win(state.out_win) then
            M.close()
          end
        end, 10)
      end
    end,
  })

  redraw()
  start_timer()
end

function M.toggle() M.open() end

function M.show_for(action_id)
  local h = history()
  for i, e in ipairs(h) do
    if e.action_id == action_id then
      state.sel = i; break
    end
  end
  M.open()
end

function M.on_job_event()
  if state.open and is_valid_win(state.list_win) then vim.schedule(redraw) end
end

return M

```

### `lua/marvin/creator/cpp.lua`

```lua
-- lua/marvin/creator/cpp.lua
-- Interactive C/C++ file creation wizard.
-- Handles: class (header + source), header-only, interface (abstract base),
--          struct, enum, test file, main file, and Makefile regeneration.
-- Now includes: auto-link detection (scans includes/CMakeLists for known libs
--               and injects LDFLAGS / target_link_libraries suggestions).

local M = {}

local function ui() return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function plain(it) return it.label end

-- ── Auto-link detection ───────────────────────────────────────────────────────
-- Maps well-known #include patterns → { lib, cmake_target, pkg_config }
-- lib          = -l flag for LDFLAGS
-- cmake_target = CMake target_link_libraries() name
-- pkg_config   = pkg-config name (for Makefile)
-- system       = true → no separate -l needed (standard library)

local KNOWN_LIBS = {
  -- Threading
  { include = 'pthread',               lib = '-lpthread',                         cmake = 'Threads::Threads',             pkg = 'threads' },
  { include = 'thread',                lib = '-lpthread',                         cmake = 'Threads::Threads',             pkg = 'threads' },
  -- Networking / TLS
  { include = 'openssl',               lib = '-lssl -lcrypto',                    cmake = 'OpenSSL::SSL OpenSSL::Crypto', pkg = 'openssl' },
  { include = 'ssl',                   lib = '-lssl -lcrypto',                    cmake = 'OpenSSL::SSL OpenSSL::Crypto', pkg = 'openssl' },
  { include = 'curl',                  lib = '-lcurl',                            cmake = 'CURL::libcurl',                pkg = 'libcurl' },
  -- Math
  { include = 'cmath',                 lib = '-lm',                               cmake = 'm',                            system = true },
  { include = 'math.h',                lib = '-lm',                               cmake = 'm',                            system = true },
  { include = 'complex',               lib = '-lm',                               cmake = 'm',                            system = true },
  -- Boost
  { include = 'boost/filesystem',      lib = '-lboost_filesystem -lboost_system', cmake = 'Boost::filesystem',            pkg = 'boost_filesystem' },
  { include = 'boost/regex',           lib = '-lboost_regex',                     cmake = 'Boost::regex',                 pkg = 'boost_regex' },
  { include = 'boost/thread',          lib = '-lboost_thread',                    cmake = 'Boost::thread',                pkg = 'boost_thread' },
  { include = 'boost/program_options', lib = '-lboost_program_options',           cmake = 'Boost::program_options',       pkg = 'boost_program_options' },
  { include = 'boost/asio',            lib = '-lpthread',                         cmake = 'Boost::asio Threads::Threads', pkg = nil },
  -- fmt
  { include = 'fmt/',                  lib = '-lfmt',                             cmake = 'fmt::fmt',                     pkg = 'fmt' },
  -- spdlog
  { include = 'spdlog/',               lib = '-lfmt',                             cmake = 'spdlog::spdlog',               pkg = 'spdlog' },
  -- SQLite
  { include = 'sqlite3',               lib = '-lsqlite3',                         cmake = 'SQLite::SQLite3',              pkg = 'sqlite3' },
  -- zlib
  { include = 'zlib',                  lib = '-lz',                               cmake = 'ZLIB::ZLIB',                   pkg = 'zlib' },
  { include = 'zconf',                 lib = '-lz',                               cmake = 'ZLIB::ZLIB',                   pkg = 'zlib' },
  -- ncurses / readline
  { include = 'ncurses',               lib = '-lncurses',                         cmake = 'Curses::Curses',               pkg = 'ncurses' },
  { include = 'readline',              readline = true,                           lib = '-lreadline',                     cmake = 'readline',           pkg = 'readline' },
  -- Graphics / windowing
  { include = 'GLFW',                  lib = '-lglfw',                            cmake = 'glfw',                         pkg = 'glfw3' },
  { include = 'GL/',                   lib = '-lGL',                              cmake = 'OpenGL::GL',                   pkg = 'gl' },
  { include = 'GLES',                  lib = '-lGLES',                            cmake = 'OpenGL::GLES',                 pkg = nil },
  { include = 'vulkan',                lib = '-lvulkan',                          cmake = 'Vulkan::Vulkan',               pkg = 'vulkan' },
  { include = 'SDL2',                  lib = '-lSDL2',                            cmake = 'SDL2::SDL2',                   pkg = 'sdl2' },
  -- Testing (header-only; no link needed for catch2 amalgam)
  { include = 'gtest',                 lib = '-lgtest -lgtest_main -lpthread',    cmake = 'GTest::gtest_main',            pkg = 'gtest' },
  { include = 'gmock',                 lib = '-lgmock -lgtest -lpthread',         cmake = 'GTest::gmock',                 pkg = nil },
  -- JSON
  { include = 'nlohmann/json',         lib = nil,                                 cmake = 'nlohmann_json::nlohmann_json', pkg = nil,                    header_only = true },
  { include = 'rapidjson',             lib = nil,                                 cmake = nil,                            pkg = nil,                    header_only = true },
  -- YAML
  { include = 'yaml-cpp',              lib = '-lyaml-cpp',                        cmake = 'yaml-cpp::yaml-cpp',           pkg = 'yaml-cpp' },
  -- Protocol Buffers / gRPC
  { include = 'google/protobuf',       lib = '-lprotobuf',                        cmake = 'protobuf::libprotobuf',        pkg = 'protobuf' },
  { include = 'grpc',                  lib = '-lgrpc++ -lgrpc',                   cmake = 'gRPC::grpc++',                 pkg = 'grpc++' },
  -- Compression
  { include = 'lz4',                   lib = '-llz4',                             cmake = 'lz4::lz4',                     pkg = 'liblz4' },
  { include = 'zstd',                  lib = '-lzstd',                            cmake = 'zstd::libzstd',                pkg = 'libzstd' },
  -- FFmpeg
  { include = 'libavcodec',            lib = '-lavcodec -lavutil',                cmake = nil,                            pkg = 'libavcodec libavutil' },
}

-- Scan a list of #include lines and return detected library entries (deduplicated)
local function detect_includes_from_lines(lines)
  local found, seen = {}, {}
  for _, line in ipairs(lines) do
    -- Match both <> and "" includes
    local inc = line:match('#%s*include%s*[<"]([^>"]+)[>"]')
    if inc then
      for _, entry in ipairs(KNOWN_LIBS) do
        if not seen[entry.include] and inc:find(entry.include, 1, true) then
          seen[entry.include] = true
          found[#found + 1] = entry
        end
      end
    end
  end
  return found
end

-- Scan all .h/.hpp/.cpp/.c files under root for includes
local function scan_project_includes(root)
  local all_lines = {}
  local patterns  = { '*.h', '*.hpp', '*.cpp', '*.c', '*.hxx', '*.cxx' }
  for _, pat in ipairs(patterns) do
    local files = vim.fn.globpath(root, '**/' .. pat, false, true)
    for _, f in ipairs(files) do
      local ok, content = pcall(vim.fn.readfile, f)
      if ok then
        for _, l in ipairs(content) do
          all_lines[#all_lines + 1] = l
        end
      end
    end
  end
  return detect_includes_from_lines(all_lines)
end

-- Scan CMakeLists.txt for target_link_libraries entries
local function scan_cmake_links(root)
  local cmake_path = root .. '/CMakeLists.txt'
  if vim.fn.filereadable(cmake_path) == 0 then return {} end
  local content = vim.fn.readfile(cmake_path)
  local linked  = {}
  for _, line in ipairs(content) do
    -- e.g. target_link_libraries(myapp PRIVATE pthread ssl)
    local libs_str = line:match('target_link_libraries%s*%([^%)]+%)')
    if libs_str then
      for lib in libs_str:gmatch('(%S+)') do
        if lib ~= 'target_link_libraries(' and lib ~= 'PRIVATE'
            and lib ~= 'PUBLIC' and lib ~= 'INTERFACE' and not lib:match('%($') then
          linked[lib] = true
        end
      end
    end
  end
  return linked
end

-- Build a deduplicated LDFLAGS string and cmake targets list
-- from a list of KNOWN_LIBS entries, excluding already-linked ones
local function build_link_suggestions(detected, already_linked)
  already_linked = already_linked or {}
  local ldflags_parts, cmake_parts, pkg_parts = {}, {}, {}
  local seen = {}

  for _, entry in ipairs(detected) do
    if entry.header_only then goto continue end
    local key = entry.include
    if seen[key] then goto continue end
    seen[key] = true

    -- Check if cmake target already present
    if entry.cmake then
      local skip = false
      for _, ct in ipairs(vim.split(entry.cmake, ' ')) do
        if already_linked[ct] then
          skip = true; break
        end
      end
      if skip then goto continue end
      for _, ct in ipairs(vim.split(entry.cmake, ' ')) do
        cmake_parts[#cmake_parts + 1] = ct
      end
    end

    if entry.lib and not entry.system then
      ldflags_parts[#ldflags_parts + 1] = entry.lib
    end
    if entry.pkg then
      pkg_parts[#pkg_parts + 1] = entry.pkg
    end

    ::continue::
  end

  return {
    ldflags    = table.concat(ldflags_parts, ' '),
    cmake      = cmake_parts,
    pkg_config = pkg_parts,
  }
end

-- Public: detect links for a project, return suggestion table
function M.detect_links(p)
  local detected       = scan_project_includes(p.root)
  local already_linked = p.type == 'cmake' and scan_cmake_links(p.root) or {}
  return build_link_suggestions(detected, already_linked)
end

-- Public: detect links for a specific set of include lines (for new file wizard)
function M.detect_links_for_includes(includes_list, p)
  local lines = {}
  for _, inc in ipairs(includes_list) do
    lines[#lines + 1] = '#include ' .. inc
  end
  local detected       = detect_includes_from_lines(lines)
  local already_linked = p and p.type == 'cmake' and scan_cmake_links(p.root) or {}
  return build_link_suggestions(detected, already_linked)
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function write(path, lines, label)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local f = io.open(path, 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. path, vim.log.levels.ERROR); return false
  end
  for _, l in ipairs(lines) do f:write(l .. '\n') end
  f:close()
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.notify('[Marvin] Created ' .. label .. ': ' .. vim.fn.fnamemodify(path, ':t'), vim.log.levels.INFO)
  return true
end

local function guard(name)
  return name:upper():gsub('[^A-Z0-9]', '_') .. '_H'
end

local function cfg()
  return require('marvin').config.cpp
end

-- Notify with link suggestions after file creation
local function notify_link_suggestions(links, p)
  if not links then return end
  local parts = {}
  if links.ldflags and links.ldflags ~= '' then
    parts[#parts + 1] = 'LDFLAGS: ' .. links.ldflags
  end
  if links.cmake and #links.cmake > 0 then
    parts[#parts + 1] = 'CMake:   target_link_libraries(<target> ' .. table.concat(links.cmake, ' ') .. ')'
  end
  if links.pkg_config and #links.pkg_config > 0 then
    parts[#parts + 1] = 'pkg-cfg: ' .. table.concat(links.pkg_config, ' ')
  end
  if #parts > 0 then
    vim.notify('[Marvin] Detected linker flags for new file:\n' .. table.concat(parts, '\n'),
      vim.log.levels.INFO)
  end
end

-- ── Templates ─────────────────────────────────────────────────────────────────

local function class_header(name, opts)
  local g     = guard(name)
  local ns    = opts.ns
  local lines = {
    '#pragma once',
    '#ifndef ' .. g,
    '#define ' .. g,
    '',
  }
  if opts.includes and #opts.includes > 0 then
    for _, inc in ipairs(opts.includes) do
      lines[#lines + 1] = '#include ' .. inc
    end
    lines[#lines + 1] = ''
  end
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = 'class ' .. name .. (opts.base and (' : public ' .. opts.base) or '') .. ' {'
  lines[#lines + 1] = 'public:'
  lines[#lines + 1] = '    ' .. name .. '();'
  lines[#lines + 1] = '    ~' .. name .. (opts.base and '() override;' or '();')
  if opts.copy then
    lines[#lines + 1] = '    ' .. name .. '(const ' .. name .. '&) = default;'
    lines[#lines + 1] = '    ' .. name .. '& operator=(const ' .. name .. '&) = default;'
  end
  if opts.move then
    lines[#lines + 1] = '    ' .. name .. '(' .. name .. '&&) noexcept = default;'
    lines[#lines + 1] = '    ' .. name .. '& operator=(' .. name .. '&&) noexcept = default;'
  end
  if opts.methods and #opts.methods > 0 then
    lines[#lines + 1] = ''
    for _, m in ipairs(opts.methods) do
      lines[#lines + 1] = '    ' .. m .. ';'
    end
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = 'private:'
  if opts.fields and #opts.fields > 0 then
    for _, f in ipairs(opts.fields) do
      lines[#lines + 1] = '    ' .. f.typ .. ' ' .. f.name .. ';'
    end
  else
    lines[#lines + 1] = '    // TODO: add members'
  end
  lines[#lines + 1] = '};'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '#endif // ' .. g
  return lines
end

local function class_source(name, opts)
  local inc_path = opts.inc_dir and (opts.inc_dir .. '/' .. name .. '.h') or (name .. '.h')
  local ns       = opts.ns
  local lines    = {
    '#include "' .. inc_path .. '"',
    '',
  }
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = name .. '::' .. name .. '() {'
  lines[#lines + 1] = '    // TODO: constructor'
  lines[#lines + 1] = '}'
  lines[#lines + 1] = ''
  lines[#lines + 1] = name .. '::~' .. name .. '() {'
  lines[#lines + 1] = '    // TODO: destructor'
  lines[#lines + 1] = '}'
  -- Stub out any method definitions
  if opts.methods and #opts.methods > 0 then
    for _, m in ipairs(opts.methods) do
      -- Strip parameter names, just get signature
      lines[#lines + 1] = ''
      lines[#lines + 1] = '// ' .. m
      local ret, rest = m:match('^(%S+)%s+(.+)')
      if ret and rest then
        lines[#lines + 1] = ret .. ' ' .. name .. '::' .. rest .. ' {'
      else
        lines[#lines + 1] = name .. '::' .. m .. ' {'
      end
      lines[#lines + 1] = '    // TODO: implement'
      lines[#lines + 1] = '}'
    end
  end
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  return lines
end

local function abstract_header(name, opts)
  local g     = guard(name)
  local ns    = opts.ns
  local lines = {
    '#pragma once',
    '#ifndef ' .. g,
    '#define ' .. g,
    '',
  }
  if opts.includes and #opts.includes > 0 then
    for _, inc in ipairs(opts.includes) do
      lines[#lines + 1] = '#include ' .. inc
    end
    lines[#lines + 1] = ''
  end
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = 'class ' .. name .. ' {'
  lines[#lines + 1] = 'public:'
  lines[#lines + 1] = '    virtual ~' .. name .. '() = default;'
  lines[#lines + 1] = ''
  if opts.methods and #opts.methods > 0 then
    for _, m in ipairs(opts.methods) do
      lines[#lines + 1] = '    virtual ' .. m .. ' = 0;'
    end
  else
    lines[#lines + 1] = '    // TODO: add pure virtual methods'
    lines[#lines + 1] = '    // virtual void doSomething() = 0;'
  end
  lines[#lines + 1] = '};'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '#endif // ' .. g
  return lines
end

local function struct_header(name, opts)
  local g     = guard(name)
  local ns    = opts.ns
  local lines = {
    '#pragma once',
    '#ifndef ' .. g,
    '#define ' .. g,
    '',
  }
  if opts.includes and #opts.includes > 0 then
    for _, inc in ipairs(opts.includes) do
      lines[#lines + 1] = '#include ' .. inc
    end
    lines[#lines + 1] = ''
  end
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = 'struct ' .. name .. ' {'
  if opts.fields and #opts.fields > 0 then
    for _, f in ipairs(opts.fields) do
      lines[#lines + 1] = '    ' .. f.typ .. ' ' .. f.name .. ';'
    end
  else
    lines[#lines + 1] = '    // TODO: add fields'
  end
  lines[#lines + 1] = '};'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '#endif // ' .. g
  return lines
end

local function enum_header(name, opts)
  local g         = guard(name)
  local ns        = opts.ns
  local use_class = opts.scoped ~= false -- default to enum class
  local lines     = {
    '#pragma once',
    '#ifndef ' .. g,
    '#define ' .. g,
    '',
  }
  if ns then
    lines[#lines + 1] = 'namespace ' .. ns .. ' {'
    lines[#lines + 1] = ''
  end
  lines[#lines + 1] = (use_class and 'enum class ' or 'enum ') .. name .. ' {'
  if opts.values and #opts.values > 0 then
    for i, v in ipairs(opts.values) do
      local comma = i < #opts.values and ',' or ''
      lines[#lines + 1] = '    ' .. v .. comma
    end
  else
    lines[#lines + 1] = '    // TODO: add values'
  end
  lines[#lines + 1] = '};'
  if ns then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '} // namespace ' .. ns
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '#endif // ' .. g
  return lines
end

local function test_file(name, opts)
  local subject = opts.subject or name
  if opts.framework == 'catch2' then
    return {
      '#include <catch2/catch_test_macros.hpp>',
      '',
      '// TODO: #include "' .. subject .. '.h"',
      '',
      'TEST_CASE("' .. subject .. ' basic", "[' .. subject .. ']") {',
      '    SECTION("placeholder") {',
      '        REQUIRE(true);',
      '    }',
      '}',
    }
  else -- gtest default
    return {
      '#include <gtest/gtest.h>',
      '',
      '// TODO: #include "' .. subject .. '.h"',
      '',
      'TEST(' .. subject .. 'Test, BasicAssertion) {',
      '    EXPECT_TRUE(true);',
      '}',
      '',
      'int main(int argc, char** argv) {',
      '    ::testing::InitGoogleTest(&argc, argv);',
      '    return RUN_ALL_TESTS();',
      '}',
    }
  end
end

-- ── Prompt helpers ────────────────────────────────────────────────────────────
local function prompt_ns(cb)
  ui().select({
    { id = '__none__', label = '(no namespace)' },
    { id = '__custom__', label = '󰏫 Enter namespace…' },
  }, { prompt = 'Namespace', format_item = plain }, function(choice)
    if not choice or choice.id == '__none__' then
      cb(nil); return
    end
    ui().input({ prompt = 'Namespace name' }, function(ns)
      cb(ns ~= '' and ns or nil)
    end)
  end)
end

local function prompt_fields(cb)
  ui().input({
    prompt  = 'Fields (type:name, …) e.g. int:age,std::string:name',
    default = '',
  }, function(input)
    if not input or input == '' then
      cb({}); return
    end
    local fields = {}
    for pair in input:gmatch('[^,]+') do
      local typ, nm = pair:match('%s*([^:]+):([^:]+)%s*')
      if typ and nm then
        fields[#fields + 1] = { typ = vim.trim(typ), name = vim.trim(nm) }
      end
    end
    cb(fields)
  end)
end

local function prompt_methods(cb)
  ui().input({
    prompt  = 'Method signatures (semicolon-separated)',
    default = 'void doSomething()',
  }, function(input)
    if not input or input == '' then
      cb({}); return
    end
    local methods = {}
    for m in input:gmatch('[^;]+') do
      local t = vim.trim(m); if t ~= '' then methods[#methods + 1] = t end
    end
    cb(methods)
  end)
end

-- Ask user to pick extra includes for a new file, show lib detection results
local function prompt_includes(cb)
  ui().select({
    { id = '__none__', label = '(no extra includes)' },
    { id = '__custom__', label = '󰏫 Add includes…', desc = 'e.g. <thread>,<openssl/ssl.h>' },
  }, { prompt = 'Extra #includes (for auto-link detection)', format_item = plain }, function(choice)
    if not choice or choice.id == '__none__' then
      cb({}); return
    end
    ui().input({ prompt = 'Includes (comma-separated)', default = '' }, function(raw)
      if not raw or raw == '' then
        cb({}); return
      end
      local includes = {}
      for inc in raw:gmatch('[^,]+') do
        local t = vim.trim(inc)
        -- Wrap bare names in <> if missing delimiters
        if t ~= '' then
          if not t:match('^[<"]') then t = '<' .. t .. '>' end
          includes[#includes + 1] = t
        end
      end
      cb(includes)
    end)
  end)
end

-- ── Resolve source/include dirs from project ─────────────────────────────────
local function resolve_dirs(p)
  local src = vim.fn.isdirectory(p.root .. '/src') == 1 and 'src' or ''
  local inc = vim.fn.isdirectory(p.root .. '/include') == 1 and 'include' or src
  return src, inc
end

-- ── Entry points ──────────────────────────────────────────────────────────────

function M.create_class(on_back)
  local p = det().get()
  if not p then return end
  local src_dir, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰙲 Class name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_ns(function(ns)
        ui().select({
          { id = 'default',   label = 'Default (constructor + destructor)' },
          { id = 'copy',      label = '+ Copy semantics' },
          { id = 'move',      label = '+ Move semantics' },
          { id = 'rule_of_5', label = '+ Rule of 5 (copy + move)' },
        }, { prompt = 'Class type', format_item = plain }, function(kind)
          -- Optionally prompt for methods
          ui().select({
            { id = 'yes', label = 'Yes — declare methods now' },
            { id = 'no', label = 'No — just constructor/destructor' },
          }, { prompt = 'Add method signatures?', format_item = plain }, function(do_methods)
            local function after_methods(methods)
              prompt_fields(function(fields)
                prompt_includes(function(includes)
                  local links  = M.detect_links_for_includes(includes, p)
                  local opts   = {
                    ns       = ns,
                    inc_dir  = inc_dir ~= '' and inc_dir or nil,
                    copy     = kind and (kind.id == 'copy' or kind.id == 'rule_of_5'),
                    move     = kind and (kind.id == 'move' or kind.id == 'rule_of_5'),
                    methods  = methods,
                    fields   = fields,
                    includes = includes,
                  }
                  local h_path = p.root
                      .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
                      .. '/' .. name .. '.h'
                  local c_path = p.root
                      .. (src_dir ~= '' and ('/' .. src_dir) or '')
                      .. '/' .. name .. '.cpp'
                  write(h_path, class_header(name, opts), 'Header')
                  write(c_path, class_source(name, opts), 'Source')
                  notify_link_suggestions(links, p)
                end)
              end)
            end
            if do_methods and do_methods.id == 'yes' then
              prompt_methods(function(methods)
                vim.schedule(function() after_methods(methods) end)
              end)
            else
              after_methods({})
            end
          end)
        end)
      end)
    end)
  end)
end

function M.create_abstract(on_back)
  local p = det().get()
  if not p then return end
  local _, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰙲 Abstract class / interface name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_ns(function(ns)
        prompt_methods(function(methods)
          prompt_includes(function(includes)
            local links = M.detect_links_for_includes(includes, p)
            local opts  = { ns = ns, methods = methods, includes = includes }
            local path  = p.root
                .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
                .. '/' .. name .. '.h'
            write(path, abstract_header(name, opts), 'Abstract Class')
            notify_link_suggestions(links, p)
          end)
        end)
      end)
    end)
  end)
end

function M.create_struct(on_back)
  local p = det().get()
  if not p then return end
  local _, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰙲 Struct name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_ns(function(ns)
        prompt_fields(function(fields)
          prompt_includes(function(includes)
            local links = M.detect_links_for_includes(includes, p)
            local opts  = { ns = ns, fields = fields, includes = includes }
            local path  = p.root
                .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
                .. '/' .. name .. '.h'
            write(path, struct_header(name, opts), 'Struct')
            notify_link_suggestions(links, p)
          end)
        end)
      end)
    end)
  end)
end

function M.create_enum(on_back)
  local p = det().get()
  if not p then return end
  local _, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰒻 Enum name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      ui().input({ prompt = 'Values (comma-separated)', default = 'ValueA, ValueB, ValueC' }, function(raw)
        local values = {}
        for v in (raw or ''):gmatch('[^,]+') do
          values[#values + 1] = vim.trim(v)
        end
        prompt_ns(function(ns)
          local opts = { ns = ns, values = values }
          local path = p.root
              .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
              .. '/' .. name .. '.h'
          write(path, enum_header(name, opts), 'Enum')
        end)
      end)
    end)
  end)
end

function M.create_header_only(on_back)
  local p = det().get()
  if not p then return end
  local _, inc_dir = resolve_dirs(p)

  ui().input({ prompt = '󰈙 Header-only file name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1, 1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_ns(function(ns)
        prompt_includes(function(includes)
          local links = M.detect_links_for_includes(includes, p)
          local g     = guard(name)
          local lines = {
            '#pragma once',
            '#ifndef ' .. g,
            '#define ' .. g,
            '',
          }
          if #includes > 0 then
            for _, inc in ipairs(includes) do
              lines[#lines + 1] = '#include ' .. inc
            end
            lines[#lines + 1] = ''
          end
          if ns then
            lines[#lines + 1] = 'namespace ' .. ns .. ' {'
            lines[#lines + 1] = ''
          end
          lines[#lines + 1] = '// TODO: implement ' .. name
          if ns then
            lines[#lines + 1] = ''
            lines[#lines + 1] = '} // namespace ' .. ns
          end
          lines[#lines + 1] = ''
          lines[#lines + 1] = '#endif // ' .. g
          local path = p.root
              .. (inc_dir ~= '' and ('/' .. inc_dir) or '')
              .. '/' .. name .. '.hpp'
          write(path, lines, 'Header-only')
          notify_link_suggestions(links, p)
        end)
      end)
    end)
  end)
end

function M.create_test(on_back)
  local p = det().get()
  if not p then return end

  ui().input({ prompt = '󰙨 Subject / class under test' }, function(subject)
    if not subject or subject == '' then return end
    vim.schedule(function()
      ui().select({
        { id = 'gtest',  label = 'GoogleTest (gtest)' },
        { id = 'catch2', label = 'Catch2' },
      }, { prompt = 'Test framework', format_item = plain }, function(fw)
        local framework = fw and fw.id or 'gtest'
        local lines     = test_file(subject, { framework = framework, subject = subject })
        -- Auto-detect links for the chosen framework
        local fw_inc    = framework == 'catch2'
            and { '<catch2/catch_test_macros.hpp>' }
            or { '<gtest/gtest.h>' }
        local links     = M.detect_links_for_includes(fw_inc, p)
        local test_dir  = vim.fn.isdirectory(p.root .. '/tests') == 1 and 'tests'
            or (vim.fn.isdirectory(p.root .. '/test') == 1 and 'test' or 'tests')
        local path      = p.root .. '/' .. test_dir .. '/' .. subject .. '_test.cpp'
        write(path, lines, 'Test')
        notify_link_suggestions(links, p)
      end)
    end)
  end)
end

function M.create_main(on_back)
  local p = det().get()
  if not p then return end
  local src_dir, _ = resolve_dirs(p)
  local c          = cfg()

  local is_cpp     = (c.compiler == 'g++' or c.compiler == 'clang++')
  local ext        = is_cpp and '.cpp' or '.c'

  prompt_includes(function(includes)
    local links = M.detect_links_for_includes(includes, p)
    local lines = {}
    if is_cpp then
      lines[#lines + 1] = '#include <iostream>'
    else
      lines[#lines + 1] = '#include <stdio.h>'
    end
    for _, inc in ipairs(includes) do
      lines[#lines + 1] = '#include ' .. inc
    end
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'int main(int argc, char* argv[]) {'
    if is_cpp then
      lines[#lines + 1] = '    std::cout << "Hello, World!" << std::endl;'
    else
      lines[#lines + 1] = '    printf("Hello, World!\\n");'
    end
    lines[#lines + 1] = '    return 0;'
    lines[#lines + 1] = '}'

    local path = p.root
        .. (src_dir ~= '' and ('/' .. src_dir) or '')
        .. '/main' .. ext
    write(path, lines, 'main' .. ext)
    notify_link_suggestions(links, p)
  end)
end

-- ── Scan project and show full link report ────────────────────────────────────
function M.show_link_report()
  local p = det().get()
  if not p then
    vim.notify('[Marvin] No C/C++ project detected', vim.log.levels.WARN); return
  end
  local detected = scan_project_includes(p.root)
  if #detected == 0 then
    vim.notify('[Marvin] No known library includes detected in project', vim.log.levels.INFO)
    return
  end
  local already = p.type == 'cmake' and scan_cmake_links(p.root) or {}
  local links   = build_link_suggestions(detected, already)

  local lines   = { '', '  Detected Library Dependencies', '  ' .. string.rep('─', 40), '' }
  for _, entry in ipairs(detected) do
    local note = entry.header_only and '(header-only)' or (entry.lib or '')
    lines[#lines + 1] = string.format('  %-28s %s', entry.include, note)
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '  Suggested Link Flags'
  lines[#lines + 1] = '  ' .. string.rep('─', 40)
  if links.ldflags ~= '' then
    lines[#lines + 1] = '  LDFLAGS:  ' .. links.ldflags
  end
  if #links.cmake > 0 then
    lines[#lines + 1] = '  CMake:    target_link_libraries(<target> '
        .. table.concat(links.cmake, ' ') .. ')'
  end
  if #links.pkg_config > 0 then
    lines[#lines + 1] = '  pkg-cfg:  ' .. table.concat(links.pkg_config, ' ')
  end
  lines[#lines + 1] = ''
  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items()
  local items = {}
  local function sep(l) items[#items + 1] = { label = l, is_separator = true } end
  local function it(id, icon, label, desc)
    items[#items + 1] = { id = id, label = icon .. ' ' .. label, desc = desc }
  end

  sep('Create')
  it('cr_class', '󰙲', 'New Class', 'Header + source pair, auto-link detection')
  it('cr_abstract', '󰦊', 'New Abstract Class', 'Pure virtual interface header')
  it('cr_struct', '󰙲', 'New Struct', 'POD struct header')
  it('cr_enum', '󰒻', 'New Enum', 'enum class header')
  it('cr_header_only', '󰈙', 'New Header-only', 'Single .hpp file')
  it('cr_test', '󰙨', 'New Test File', 'GoogleTest or Catch2 scaffold + link hints')
  it('cr_main', '󰐊', 'New main.cpp', 'Entry point + include-based link detection')

  sep('Analysis')
  it('cr_link_report', '󰘦', 'Link Report', 'Scan project includes → suggest LDFLAGS')
  it('cr_makefile', '󰈙', 'New/Regenerate Makefile', 'Interactive Makefile wizard')
  return items
end

function M.handle(id, on_back)
  if id == 'cr_class' then
    M.create_class(on_back)
  elseif id == 'cr_abstract' then
    M.create_abstract(on_back)
  elseif id == 'cr_struct' then
    M.create_struct(on_back)
  elseif id == 'cr_enum' then
    M.create_enum(on_back)
  elseif id == 'cr_header_only' then
    M.create_header_only(on_back)
  elseif id == 'cr_test' then
    M.create_test(on_back)
  elseif id == 'cr_main' then
    M.create_main(on_back)
  elseif id == 'cr_link_report' then
    M.show_link_report()
  elseif id == 'cr_makefile' then
    local p = det().get()
    require('marvin.makefile_creator').create(p and p.root or vim.fn.getcwd(), on_back)
  else
    return false
  end
  return true
end

return M

```

### `lua/marvin/creator/go.lua`

```lua
-- lua/marvin/creator/go.lua
-- Interactive Go code creation wizard.
-- Handles: struct (with methods), interface, package dir, _test.go,
--          cmd/name/main.go entry point, pkg/name/ package scaffold.

local M = {}

local function ui()  return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function plain(it) return it.label end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function write(path, lines, label)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local f = io.open(path, 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. path, vim.log.levels.ERROR); return false
  end
  for _, l in ipairs(lines) do f:write(l .. '\n') end
  f:close()
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.notify('[Marvin] Created ' .. label .. ': ' .. path, vim.log.levels.INFO)
  return true
end

local function module_path(p)
  return (p.info and p.info.module) or vim.fn.fnamemodify(p.root, ':t')
end

local function lower_first(s)
  return s:sub(1, 1):lower() .. s:sub(2)
end

-- ── Templates ─────────────────────────────────────────────────────────────────

local function struct_template(pkg, name, opts)
  local lines = {}
  lines[#lines + 1] = 'package ' .. pkg
  lines[#lines + 1] = ''

  -- Imports
  local imports = {}
  if opts.json_tags then imports[#imports + 1] = '"encoding/json"' end
  if #imports > 0 then
    lines[#lines + 1] = 'import ('
    for _, im in ipairs(imports) do lines[#lines + 1] = '\t' .. im end
    lines[#lines + 1] = ')'
    lines[#lines + 1] = ''
  end

  -- Struct
  lines[#lines + 1] = '// ' .. name .. ' ...'
  lines[#lines + 1] = 'type ' .. name .. ' struct {'
  if opts.fields and #opts.fields > 0 then
    for _, f in ipairs(opts.fields) do
      local tag = opts.json_tags
        and (' `json:"' .. lower_first(f.name) .. '"`')
        or ''
      lines[#lines + 1] = '\t' .. f.name .. ' ' .. f.typ .. tag
    end
  else
    lines[#lines + 1] = '\t// TODO: add fields'
  end
  lines[#lines + 1] = '}'
  lines[#lines + 1] = ''

  -- Constructor
  if opts.constructor then
    local params, assigns = {}, {}
    if opts.fields and #opts.fields > 0 then
      for _, f in ipairs(opts.fields) do
        params[#params + 1]  = lower_first(f.name) .. ' ' .. f.typ
        assigns[#assigns + 1] = '\t\t' .. f.name .. ': ' .. lower_first(f.name) .. ','
      end
    end
    lines[#lines + 1] = '// New' .. name .. ' creates a new ' .. name .. '.'
    lines[#lines + 1] = 'func New' .. name .. '(' .. table.concat(params, ', ') .. ') *' .. name .. ' {'
    lines[#lines + 1] = '\treturn &' .. name .. '{'
    for _, a in ipairs(assigns) do lines[#lines + 1] = a end
    lines[#lines + 1] = '\t}'
    lines[#lines + 1] = '}'
    lines[#lines + 1] = ''
  end

  -- Methods
  if opts.methods then
    for _, m in ipairs(opts.methods) do
      lines[#lines + 1] = 'func (r *' .. name .. ') ' .. m .. ' {'
      lines[#lines + 1] = '\t// TODO: implement'
      lines[#lines + 1] = '\tpanic("not implemented")'
      lines[#lines + 1] = '}'
      lines[#lines + 1] = ''
    end
  end

  return lines
end

local function interface_template(pkg, name, opts)
  local lines = {}
  lines[#lines + 1] = 'package ' .. pkg
  lines[#lines + 1] = ''
  lines[#lines + 1] = '// ' .. name .. ' defines the contract for ...'
  lines[#lines + 1] = 'type ' .. name .. ' interface {'
  if opts.methods and #opts.methods > 0 then
    for _, m in ipairs(opts.methods) do
      lines[#lines + 1] = '\t' .. m
    end
  else
    lines[#lines + 1] = '\t// TODO: define methods'
  end
  lines[#lines + 1] = '}'
  lines[#lines + 1] = ''

  if opts.mock then
    -- Simple mock struct
    lines[#lines + 1] = '// Mock' .. name .. ' is a test mock for ' .. name .. '.'
    lines[#lines + 1] = 'type Mock' .. name .. ' struct{}'
    lines[#lines + 1] = ''
    if opts.methods then
      for _, m in ipairs(opts.methods) do
        -- Extract method name
        local mname = m:match('^(%w+)')
        if mname then
          lines[#lines + 1] = 'func (m *Mock' .. name .. ') ' .. m .. ' {'
          lines[#lines + 1] = '\tpanic("mock not implemented")'
          lines[#lines + 1] = '}'
          lines[#lines + 1] = ''
        end
      end
    end
  end
  return lines
end

local function test_template(pkg, subject)
  local sname = subject or 'Example'
  return {
    'package ' .. pkg .. '_test',
    '',
    'import (',
    '\t"testing"',
    '',
    '\t"github.com/stretchr/testify/assert"',
    ')',
    '',
    'func Test' .. sname .. '(t *testing.T) {',
    '\t// Arrange',
    '\t',
    '\t// Act',
    '\t',
    '\t// Assert',
    '\tassert.True(t, true, "placeholder")',
    '}',
  }
end

local function cmd_main_template(mod_path, cmd_name)
  return {
    'package main',
    '',
    'import (',
    '\t"fmt"',
    '\t"os"',
    ')',
    '',
    'func main() {',
    '\tif err := run(); err != nil {',
    '\t\tfmt.Fprintf(os.Stderr, "error: %v\\n", err)',
    '\t\tos.Exit(1)',
    '\t}',
    '}',
    '',
    'func run() error {',
    '\tfmt.Println("' .. cmd_name .. ' starting...")',
    '\t// TODO: implement ' .. cmd_name,
    '\treturn nil',
    '}',
  }
end

local function pkg_template(pkg)
  return {
    '// Package ' .. pkg .. ' provides ...',
    'package ' .. pkg,
    '',
    '// TODO: implement package ' .. pkg,
  }
end

-- ── Prompt helpers ────────────────────────────────────────────────────────────
local function prompt_fields(cb)
  ui().input({
    prompt  = 'Fields (type:Name, …) e.g. string:Name,int:Age',
    default = '',
  }, function(input)
    if not input or input == '' then cb({}); return end
    local fields = {}
    for pair in input:gmatch('[^,]+') do
      local typ, name = pair:match('%s*([^:]+):([^:]+)%s*')
      if typ and name then
        -- Go convention: exported fields are PascalCase
        local n = vim.trim(name)
        n = n:sub(1,1):upper() .. n:sub(2)
        fields[#fields + 1] = { typ = vim.trim(typ), name = n }
      end
    end
    cb(fields)
  end)
end

local function prompt_methods(cb)
  ui().input({
    prompt  = 'Method signatures (semicolon-separated)',
    default = 'DoSomething() error',
  }, function(input)
    if not input or input == '' then cb({}); return end
    local methods = {}
    for m in input:gmatch('[^;]+') do
      local t = vim.trim(m)
      if t ~= '' then methods[#methods + 1] = t end
    end
    cb(methods)
  end)
end

local function pkg_name(p)
  -- Derive from last segment of module path
  local mod = module_path(p)
  return vim.fn.fnamemodify(mod, ':t'):gsub('-', '_')
end

-- ── Entry points ──────────────────────────────────────────────────────────────

function M.create_struct(on_back)
  local p = det().get()
  if not p then return end
  local pkg = pkg_name(p)

  ui().input({ prompt = '󰙲 Struct name' }, function(name)
    if not name or name == '' then return end
    -- Ensure PascalCase
    name = name:sub(1,1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_fields(function(fields)
        ui().select({
          { id = 'yes_ctor',  label = 'Yes — New' .. name .. '() constructor' },
          { id = 'yes_chain', label = 'Yes — builder-style with methods' },
          { id = 'no',        label = 'No' },
        }, { prompt = 'Generate constructor?', format_item = plain }, function(ctor)
          local gen_ctor = ctor and ctor.id ~= 'no'
          ui().select({
            { id = 'yes', label = 'Yes — JSON struct tags' },
            { id = 'no',  label = 'No' },
          }, { prompt = 'Add JSON tags?', format_item = plain }, function(json)
            local gen_json = json and json.id == 'yes'
            local methods  = {}
            if ctor and ctor.id == 'yes_chain' then
              for _, f in ipairs(fields) do
                methods[#methods + 1] = 'Set' .. f.name .. '(v ' .. f.typ .. ') *' .. name
              end
            end
            local lines = struct_template(pkg, name, {
              fields = fields, constructor = gen_ctor,
              json_tags = gen_json, methods = #methods > 0 and methods or nil,
            })
            local path = p.root .. '/' .. lower_first(name) .. '.go'
            write(path, lines, 'Struct')
          end)
        end)
      end)
    end)
  end)
end

function M.create_interface(on_back)
  local p = det().get()
  if not p then return end
  local pkg = pkg_name(p)

  ui().input({ prompt = '󰜰 Interface name' }, function(name)
    if not name or name == '' then return end
    name = name:sub(1,1):upper() .. name:sub(2)
    vim.schedule(function()
      prompt_methods(function(methods)
        ui().select({
          { id = 'yes', label = 'Yes — Mock' .. name .. ' struct' },
          { id = 'no',  label = 'No' },
        }, { prompt = 'Generate mock implementation?', format_item = plain }, function(mock)
          local lines = interface_template(pkg, name, {
            methods = methods, mock = mock and mock.id == 'yes'
          })
          local path = p.root .. '/' .. lower_first(name) .. '.go'
          write(path, lines, 'Interface')
        end)
      end)
    end)
  end)
end

function M.create_test(on_back)
  local p = det().get()
  if not p then return end
  local pkg = pkg_name(p)

  ui().input({ prompt = '󰙨 Test subject (function/type name)' }, function(subject)
    if not subject or subject == '' then return end
    subject = subject:sub(1,1):upper() .. subject:sub(2)
    local lines = test_template(pkg, subject)
    local path  = p.root .. '/' .. lower_first(subject) .. '_test.go'
    write(path, lines, 'Test')
  end)
end

function M.create_cmd(on_back)
  local p = det().get()
  if not p then return end

  ui().input({ prompt = '󰐊 Command name (e.g. serve, migrate)' }, function(name)
    if not name or name == '' then return end
    local path = p.root .. '/cmd/' .. name .. '/main.go'
    write(path, cmd_main_template(module_path(p), name), 'Command')
  end)
end

function M.create_pkg(on_back)
  local p = det().get()
  if not p then return end

  ui().input({ prompt = '󰉿 Package name (e.g. auth, storage)' }, function(name)
    if not name or name == '' then return end
    -- Create both the dir and a stub .go file
    local dir  = p.root .. '/pkg/' .. name
    local path = dir .. '/' .. name .. '.go'
    write(path, pkg_template(name), 'Package')
  end)
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items()
  local items = {}
  local function sep(l) items[#items + 1] = { label = l, is_separator = true } end
  local function it(id, icon, label, desc)
    items[#items + 1] = { id = id, label = icon .. ' ' .. label, desc = desc }
  end

  sep('Create')
  it('cr_struct',    '󰙲', 'New Struct',        'Struct with constructor, JSON tags, methods')
  it('cr_interface', '󰜰', 'New Interface',     'Interface with optional mock implementation')
  it('cr_test',      '󰙨', 'New Test File',     '<subject>_test.go with testify scaffold')
  it('cr_cmd',       '󰐊', 'New Command',       'cmd/<name>/main.go entry point')
  it('cr_pkg',       '󰉿', 'New Package',       'pkg/<name>/<name>.go scaffold')
  return items
end

function M.handle(id, on_back)
  if     id == 'cr_struct'    then M.create_struct(on_back)
  elseif id == 'cr_interface' then M.create_interface(on_back)
  elseif id == 'cr_test'      then M.create_test(on_back)
  elseif id == 'cr_cmd'       then M.create_cmd(on_back)
  elseif id == 'cr_pkg'       then M.create_pkg(on_back)
  end
end

return M

```

### `lua/marvin/creator/java.lua`

```lua
-- lua/marvin/creator/java.lua
-- Alias: the Java creator lives at marvin.java_creator (unchanged from original).
-- This shim lets lang/java.lua use the consistent  require('marvin.creator.java')  path.
return require('marvin.java_creator')

```

### `lua/marvin/creator/rust.lua`

```lua
-- lua/marvin/creator/rust.lua
-- Interactive Rust code creation wizard.
-- Handles: struct, trait, impl, module file, integration test,
--          [[bin]] target, new library crate, new binary crate.

local M = {}

local function ui()  return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function plain(it) return it.label end

-- ── File writing ──────────────────────────────────────────────────────────────
local function write(path, lines, label)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local f = io.open(path, 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. path, vim.log.levels.ERROR); return false
  end
  for _, l in ipairs(lines) do f:write(l .. '\n') end
  f:close()
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.notify('[Marvin] Created ' .. label .. ': ' .. vim.fn.fnamemodify(path, ':t'), vim.log.levels.INFO)
  return true
end

local function snake(name)
  -- PascalCase → snake_case
  return name:gsub('(%u)', function(c) return '_' .. c:lower() end):gsub('^_', '')
end

-- ── Templates ─────────────────────────────────────────────────────────────────

local function struct_template(name, opts)
  local lines = {}
  if opts.derives and #opts.derives > 0 then
    lines[#lines + 1] = '#[derive(' .. table.concat(opts.derives, ', ') .. ')]'
  end
  lines[#lines + 1] = 'pub struct ' .. name .. ' {'
  if opts.fields and #opts.fields > 0 then
    for _, f in ipairs(opts.fields) do
      lines[#lines + 1] = '    pub ' .. f.name .. ': ' .. f.typ .. ','
    end
  else
    lines[#lines + 1] = '    // TODO: add fields'
  end
  lines[#lines + 1] = '}'
  lines[#lines + 1] = ''

  if opts.impl then
    lines[#lines + 1] = 'impl ' .. name .. ' {'
    if opts.fields and #opts.fields > 0 then
      -- new() constructor
      local params = {}
      for _, f in ipairs(opts.fields) do
        params[#params + 1] = f.name .. ': ' .. f.typ
      end
      lines[#lines + 1] = '    pub fn new(' .. table.concat(params, ', ') .. ') -> Self {'
      lines[#lines + 1] = '        Self {'
      for _, f in ipairs(opts.fields) do
        lines[#lines + 1] = '            ' .. f.name .. ','
      end
      lines[#lines + 1] = '        }'
      lines[#lines + 1] = '    }'
    else
      lines[#lines + 1] = '    pub fn new() -> Self {'
      lines[#lines + 1] = '        Self {}'
      lines[#lines + 1] = '    }'
    end
    lines[#lines + 1] = '}'
    lines[#lines + 1] = ''
  end

  if opts.tests then
    lines[#lines + 1] = '#[cfg(test)]'
    lines[#lines + 1] = 'mod tests {'
    lines[#lines + 1] = '    use super::*;'
    lines[#lines + 1] = ''
    lines[#lines + 1] = '    #[test]'
    lines[#lines + 1] = '    fn test_' .. snake(name) .. '() {'
    lines[#lines + 1] = '        // TODO: write test'
    lines[#lines + 1] = '        todo!()'
    lines[#lines + 1] = '    }'
    lines[#lines + 1] = '}'
  end
  return lines
end

local function trait_template(name, opts)
  local lines = {}
  lines[#lines + 1] = 'pub trait ' .. name .. ' {'
  if opts.methods and #opts.methods > 0 then
    for _, m in ipairs(opts.methods) do
      lines[#lines + 1] = '    fn ' .. m .. ';'
    end
  else
    lines[#lines + 1] = '    // TODO: define methods'
  end
  lines[#lines + 1] = '}'
  lines[#lines + 1] = ''
  if opts.default_impl then
    lines[#lines + 1] = '// Default implementation'
    lines[#lines + 1] = 'pub struct Default' .. name .. ';'
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'impl ' .. name .. ' for Default' .. name .. ' {'
    if opts.methods and #opts.methods > 0 then
      for _, m in ipairs(opts.methods) do
        -- Strip signature noise for body stub
        local fname = m:match('fn%s+(%w+)') or m
        lines[#lines + 1] = '    fn ' .. m .. ' {'
        lines[#lines + 1] = '        todo!("implement ' .. fname .. '")'
        lines[#lines + 1] = '    }'
      end
    end
    lines[#lines + 1] = '}'
  end
  return lines
end

local function impl_template(trait_name, type_name)
  return {
    'use crate::' .. snake(trait_name) .. '::' .. trait_name .. ';',
    '',
    'impl ' .. trait_name .. ' for ' .. type_name .. ' {',
    '    // TODO: implement methods',
    '}',
  }
end

local function module_template(name)
  return {
    '//! ' .. name .. ' module',
    '',
    '// TODO: implement ' .. name,
    '',
    '#[cfg(test)]',
    'mod tests {',
    '    use super::*;',
    '',
    '    #[test]',
    '    fn test_placeholder() {',
    '        // TODO',
    '    }',
    '}',
  }
end

local function integration_test_template(name)
  return {
    'use ' .. name .. '::*;',
    '',
    '#[test]',
    'fn integration_test() {',
    '    // TODO: write integration test',
    '    todo!()',
    '}',
  }
end

local function bin_template(name)
  return {
    'fn main() {',
    '    println!("' .. name .. ' starting...");',
    '    // TODO: implement ' .. name,
    '}',
  }
end

-- ── Prompt helpers ────────────────────────────────────────────────────────────
local function prompt_fields(cb)
  ui().input({
    prompt  = 'Fields (type:name, …) e.g. String:name,u32:age',
    default = '',
  }, function(input)
    if not input or input == '' then cb({}); return end
    local fields = {}
    for pair in input:gmatch('[^,]+') do
      local typ, name = pair:match('%s*([^:]+):([^:]+)%s*')
      if typ and name then
        fields[#fields + 1] = { typ = vim.trim(typ), name = vim.trim(name) }
      end
    end
    cb(fields)
  end)
end

local function prompt_methods(cb)
  ui().input({
    prompt  = 'Method signatures (semicolon-separated)',
    default = 'fn do_something(&self)',
  }, function(input)
    if not input or input == '' then cb({}); return end
    local methods = {}
    for m in input:gmatch('[^;]+') do
      local t = vim.trim(m)
      if t ~= '' then methods[#methods + 1] = t end
    end
    cb(methods)
  end)
end

local COMMON_DERIVES = { 'Debug', 'Clone', 'PartialEq', 'Eq', 'Hash', 'Serialize', 'Deserialize' }

local function prompt_derives(cb)
  local items = {}
  for _, d in ipairs(COMMON_DERIVES) do
    items[#items + 1] = { id = d, label = d }
  end
  items[#items + 1] = { id = '__none__', label = '(none)' }
  items[#items + 1] = { id = '__custom__', label = '󰏫 Custom…' }

  -- multi-select simulation via repeated selection
  -- For simplicity, offer a preset selection
  ui().select({
    { id = 'debug_clone',     label = 'Debug, Clone' },
    { id = 'debug_clone_eq',  label = 'Debug, Clone, PartialEq, Eq' },
    { id = 'serde',           label = 'Debug, Clone, Serialize, Deserialize (+ serde dep)' },
    { id = 'none',            label = '(no derives)' },
    { id = 'custom',          label = '󰏫 Custom…' },
  }, { prompt = 'Derives', format_item = plain }, function(choice)
    if not choice then cb({}); return end
    if choice.id == 'debug_clone'    then cb({ 'Debug', 'Clone' })
    elseif choice.id == 'debug_clone_eq' then cb({ 'Debug', 'Clone', 'PartialEq', 'Eq' })
    elseif choice.id == 'serde'      then cb({ 'Debug', 'Clone', 'Serialize', 'Deserialize' })
    elseif choice.id == 'none'       then cb({})
    elseif choice.id == 'custom'     then
      ui().input({ prompt = 'Derives (comma-separated)', default = 'Debug, Clone' }, function(raw)
        if not raw then cb({}); return end
        local d = {}
        for s in raw:gmatch('[^,]+') do d[#d + 1] = vim.trim(s) end
        cb(d)
      end)
    end
  end)
end

-- ── Source path resolution ────────────────────────────────────────────────────
local function src_path(root, name, subdir)
  local sn = snake(name)
  local base = root .. '/src' .. (subdir and ('/' .. subdir) or '')
  return base .. '/' .. sn .. '.rs'
end

-- ── Entry points ──────────────────────────────────────────────────────────────

function M.create_struct(on_back)
  local p = det().get()
  if not p then return end
  ui().input({ prompt = '󰙲 Struct name' }, function(name)
    if not name or name == '' then return end
    vim.schedule(function()
      prompt_derives(function(derives)
        ui().select({
          { id = 'yes', label = 'Yes — generate impl { new() }' },
          { id = 'no',  label = 'No' },
        }, { prompt = 'Generate impl block?', format_item = plain }, function(impl_choice)
          local gen_impl = impl_choice and impl_choice.id == 'yes'
          if gen_impl then
            prompt_fields(function(fields)
              ui().select({
                { id = 'yes', label = 'Yes — add #[cfg(test)] block' },
                { id = 'no',  label = 'No' },
              }, { prompt = 'Include unit tests?', format_item = plain }, function(tc)
                local lines = struct_template(name, {
                  derives = derives, fields = fields,
                  impl = true, tests = tc and tc.id == 'yes',
                })
                write(src_path(p.root, name), lines, 'Struct')
              end)
            end)
          else
            local lines = struct_template(name, { derives = derives })
            write(src_path(p.root, name), lines, 'Struct')
          end
        end)
      end)
    end)
  end)
end

function M.create_trait(on_back)
  local p = det().get()
  if not p then return end
  ui().input({ prompt = '󰙲 Trait name' }, function(name)
    if not name or name == '' then return end
    vim.schedule(function()
      prompt_methods(function(methods)
        ui().select({
          { id = 'yes', label = 'Yes — generate default impl struct' },
          { id = 'no',  label = 'No' },
        }, { prompt = 'Generate default implementation?', format_item = plain }, function(di)
          local lines = trait_template(name, {
            methods = methods, default_impl = di and di.id == 'yes'
          })
          write(src_path(p.root, name), lines, 'Trait')
        end)
      end)
    end)
  end)
end

function M.create_impl(on_back)
  local p = det().get()
  if not p then return end
  ui().input({ prompt = '󰙲 Trait name to implement' }, function(trait_name)
    if not trait_name or trait_name == '' then return end
    vim.schedule(function()
      ui().input({ prompt = '󰙲 Type to implement it for' }, function(type_name)
        if not type_name or type_name == '' then return end
        local lines = impl_template(trait_name, type_name)
        write(src_path(p.root, snake(trait_name) .. '_impl_' .. snake(type_name)), lines, 'Impl')
      end)
    end)
  end)
end

function M.create_module(on_back)
  local p = det().get()
  if not p then return end
  ui().input({ prompt = '󰙲 Module name' }, function(name)
    if not name or name == '' then return end
    local lines = module_template(name)
    write(src_path(p.root, name), lines, 'Module')
    -- Prompt to add `pub mod name;` to lib.rs / main.rs
    local lib = p.root .. '/src/lib.rs'
    local main = p.root .. '/src/main.rs'
    local target = vim.fn.filereadable(lib) == 1 and lib or (vim.fn.filereadable(main) == 1 and main or nil)
    if target then
      local f = io.open(target, 'r')
      if f then
        local content = f:read('*all'); f:close()
        local decl = 'pub mod ' .. snake(name) .. ';'
        if not content:find(decl, 1, true) then
          f = io.open(target, 'a')
          if f then f:write('\n' .. decl .. '\n'); f:close() end
        end
      end
    end
  end)
end

function M.create_integration_test(on_back)
  local p = det().get()
  if not p then return end
  ui().input({ prompt = '󰙨 Integration test name' }, function(name)
    if not name or name == '' then return end
    local sn    = snake(name)
    local path  = p.root .. '/tests/' .. sn .. '.rs'
    -- Determine crate name from Cargo.toml
    local crate = (p.info and p.info.name) or vim.fn.fnamemodify(p.root, ':t')
    crate = crate:gsub('-', '_')
    write(path, integration_test_template(crate), 'Integration Test')
  end)
end

function M.create_bin(on_back)
  local p = det().get()
  if not p then return end
  ui().input({ prompt = '󰐊 Binary name' }, function(name)
    if not name or name == '' then return end
    local sn   = snake(name)
    local path = p.root .. '/src/bin/' .. sn .. '.rs'
    write(path, bin_template(name), 'Binary')
    vim.notify('[Marvin] Add [[bin]] to Cargo.toml:\n  name = "' .. sn .. '"\n  path = "src/bin/' .. sn .. '.rs"',
      vim.log.levels.INFO)
  end)
end

function M.create_crate(on_back)
  local p = det().get()
  if not p then return end

  ui().select({
    { id = 'bin', label = '󰐊 Binary crate',  desc = 'cargo new <name> — executable' },
    { id = 'lib', label = '󰙲 Library crate', desc = 'cargo new --lib <name> — library' },
  }, { prompt = 'New Crate Type', on_back = on_back, format_item = plain }, function(kind)
    if not kind then return end
    vim.schedule(function()
      ui().input({ prompt = 'Crate name' }, function(name)
        if not name or name == '' then return end
        local flag = kind.id == 'lib' and ' --lib' or ''
        local cwd  = vim.fn.fnamemodify(p.root, ':h') -- create alongside, not inside
        require('core.runner').execute({
          cmd      = 'cargo new' .. flag .. ' ' .. name,
          cwd      = cwd,
          title    = 'New Crate: ' .. name,
          term_cfg = require('marvin').config.terminal,
          plugin   = 'marvin',
        })
      end)
    end)
  end)
end

-- ── Menu items (returned to lang/rust.lua → dashboard) ────────────────────────
function M.menu_items()
  local items = {}
  local function sep(l) items[#items + 1] = { label = l, is_separator = true } end
  local function it(id, icon, label, desc)
    items[#items + 1] = { id = id, label = icon .. ' ' .. label, desc = desc }
  end

  sep('Create')
  it('cr_struct',  '󰙲', 'New Struct',            'Struct with optional derives, impl, tests')
  it('cr_trait',   '󰜰', 'New Trait',             'Trait with method signatures')
  it('cr_impl',    '󰙲', 'New Impl',              'Implement a trait for a type')
  it('cr_module',  '󰉿', 'New Module',            'New .rs module file + pub mod declaration')
  it('cr_test',    '󰙨', 'New Integration Test',  'tests/<name>.rs')
  it('cr_bin',     '󰐊', 'New Binary Target',     'src/bin/<name>.rs')
  it('cr_crate',   '󰏗', 'New Crate',             'cargo new (bin or lib)')
  return items
end

function M.handle(id, on_back)
  if     id == 'cr_struct' then M.create_struct(on_back)
  elseif id == 'cr_trait'  then M.create_trait(on_back)
  elseif id == 'cr_impl'   then M.create_impl(on_back)
  elseif id == 'cr_module' then M.create_module(on_back)
  elseif id == 'cr_test'   then M.create_integration_test(on_back)
  elseif id == 'cr_bin'    then M.create_bin(on_back)
  elseif id == 'cr_crate'  then M.create_crate(on_back)
  end
end

return M

```

### `lua/marvin/dashboard.lua`

```lua
-- lua/marvin/dashboard.lua
-- Unified Marvin dashboard. Detects the current project and routes
-- to the appropriate language module (lang/java, lang/rust, lang/go).
-- Jason (build/run/test) is accessed separately via :Jason / <leader>j.

local M = {}

-- ── UI helpers ────────────────────────────────────────────────────────────────
local function plain(it) return it.label end
local function sep(l) return { label = l, is_separator = true } end

local function item(id, icon, label, desc)
  return { id = id, _icon = icon, label = label, desc = desc }
end

local function ui() return require('marvin.ui') end
local function det() return require('marvin.detector') end

-- ── Language module registry ──────────────────────────────────────────────────
local LANG = {
  maven    = 'marvin.lang.java',
  gradle   = 'marvin.lang.java',
  cargo    = 'marvin.lang.rust',
  go_mod   = 'marvin.lang.go',
  cmake    = 'marvin.lang.cpp',
  makefile = 'marvin.lang.cpp',
}

local function lang_mod(ptype)
  local mod_name = LANG[ptype]
  if not mod_name then return nil end
  local ok, mod = pcall(require, mod_name)
  return ok and mod or nil
end

-- ── Dashboard header ──────────────────────────────────────────────────────────
local LANG_ICONS = {
  maven = '󰬷',
  gradle = '󰏗',
  cargo = '󱘗',
  go_mod = '󰟓',
  cmake = '󰙲',
  makefile = '󰙱',
  single_file = '󰈙',
}

local LANG_LABELS = {
  maven = 'Maven',
  gradle = 'Gradle',
  cargo = 'Cargo',
  go_mod = 'Go',
  cmake = 'CMake',
  makefile = 'Make',
  single_file = 'Single File',
}

local function build_prompt(p)
  if not p then return 'Marvin  (no project detected)' end
  local icon   = LANG_ICONS[p.type] or '󰙅'
  local label  = LANG_LABELS[p.type] or p.type
  local lmod   = lang_mod(p.type)
  local header = lmod and lmod.prompt_header(p) or p.name
  return string.format('Marvin  %s %s  %s', icon, label, header)
end

-- ── Create section (always shown) ────────────────────────────────────────────
local function create_items()
  return {
    sep('Create Project'),
    item('gen_maven', '󰬷', 'New Maven Project', 'Generate from Maven archetype'),
    item('gen_cargo_bin', '󱘗', 'New Cargo Binary', 'cargo new <name>'),
    item('gen_cargo_lib', '󱘗', 'New Cargo Library', 'cargo new --lib <name>'),
    item('gen_go', '󰟓', 'New Go Module', 'go mod init <module>'),
    sep('Create File'),
    item('new_makefile', '󰈙', 'New Makefile', 'Makefile creation wizard'),
  }
end

-- ── New-project / file handlers ───────────────────────────────────────────────

-- Shared helper: show ~/Code subdirs as a picker, then call back with the chosen dir.
local function prompt_location(callback)
  local code_dir    = vim.fn.expand('~/Code')
  local items       = {}

  -- Always offer ~/Code itself as the first option
  items[#items + 1] = {
    id    = '__code_root__',
    label = '~/Code',
    desc  = 'Project root',
    _path = code_dir,
  }

  -- List immediate subdirectories of ~/Code
  if vim.fn.isdirectory(code_dir) == 1 then
    local ok, entries = pcall(vim.fn.readdir, code_dir)
    if ok then
      -- Sort: directories only, alphabetical
      local dirs = {}
      for _, name in ipairs(entries) do
        if name:sub(1, 1) ~= '.'
            and vim.fn.isdirectory(code_dir .. '/' .. name) == 1 then
          dirs[#dirs + 1] = name
        end
      end
      table.sort(dirs)
      for _, name in ipairs(dirs) do
        items[#items + 1] = {
          id    = name,
          label = name,
          desc  = '~/Code/' .. name,
          _path = code_dir .. '/' .. name,
        }
      end
    end
  end

  -- Always offer a manual entry option at the bottom
  items[#items + 1] = {
    id    = '__custom__',
    label = 'Other…',
    desc  = 'Enter a custom path',
    _path = nil,
  }

  ui().select(items, {
    prompt        = 'Project location',
    enable_search = true,
    format_item   = function(it) return it.label end,
  }, function(choice)
    if not choice then return end

    if choice.id == '__custom__' then
      ui().input({ prompt = 'Parent directory', default = code_dir }, function(dir)
        if not dir or dir == '' then return end
        dir = vim.fn.expand(dir)
        if vim.fn.isdirectory(dir) == 0 then
          vim.notify('[Marvin] Directory not found: ' .. dir, vim.log.levels.ERROR)
          return
        end
        callback(dir)
      end)
    else
      callback(choice._path)
    end
  end)
end

-- Prompt to cd into the new project and open its manifest file.
local function offer_open_project(proj_dir, entry)
  vim.schedule(function()
    ui().select({
      { id = 'yes', label = '󰄬 Open project', desc = proj_dir },
      { id = 'no', label = '󰅖 Stay here', desc = '' },
    }, {
      prompt      = 'Project ready!',
      format_item = function(it) return it.label end,
    }, function(choice)
      if not choice or choice.id == 'no' then return end
      vim.cmd('cd ' .. vim.fn.fnameescape(proj_dir))
      local full = proj_dir .. '/' .. entry
      if vim.fn.filereadable(full) == 1 then
        vim.cmd('edit ' .. vim.fn.fnameescape(full))
      end
      -- Force Marvin to re-detect the new project
      require('marvin.detector')._project = nil
    end)
  end)
end

local function handle_no_project(id)
  if id == 'gen_maven' then
    require('marvin.generator').create_project()
  elseif id == 'gen_cargo_bin' then
    ui().input({ prompt = 'Crate name' }, function(name)
      if not name or name == '' then return end
      prompt_location(function(dir)
        local proj_dir = dir .. '/' .. name
        local cfg = vim.tbl_extend('force', require('marvin').config.terminal, { close_on_success = true })
        require('core.runner').execute({
          cmd      = 'cargo new ' .. name,
          cwd      = dir,
          title    = 'New Cargo Binary',
          term_cfg = cfg,
          on_exit  = function(ok)
            if ok then offer_open_project(proj_dir, 'Cargo.toml') end
          end,
        })
      end)
    end)
  elseif id == 'gen_cargo_lib' then
    ui().input({ prompt = 'Crate name' }, function(name)
      if not name or name == '' then return end
      prompt_location(function(dir)
        local proj_dir = dir .. '/' .. name
        local cfg = vim.tbl_extend('force', require('marvin').config.terminal, { close_on_success = true })
        require('core.runner').execute({
          cmd      = 'cargo new --lib ' .. name,
          cwd      = dir,
          title    = 'New Cargo Library',
          term_cfg = cfg,
          on_exit  = function(ok)
            if ok then offer_open_project(proj_dir, 'Cargo.toml') end
          end,
        })
      end)
    end)
  elseif id == 'gen_go' then
    ui().input({ prompt = 'Module path (e.g. github.com/you/project)' }, function(mod)
      if not mod or mod == '' then return end
      local default_name = vim.fn.fnamemodify(mod, ':t')
      ui().input({ prompt = 'Project directory name', default = default_name }, function(dirname)
        if not dirname or dirname == '' then return end
        prompt_location(function(parent)
          local proj_dir = parent .. '/' .. dirname
          vim.fn.mkdir(proj_dir, 'p')
          local cfg = vim.tbl_extend('force', require('marvin').config.terminal, { close_on_success = true })
          require('core.runner').execute({
            cmd      = 'go mod init ' .. mod,
            cwd      = proj_dir,
            title    = 'go mod init',
            term_cfg = cfg,
            on_exit  = function(ok)
              if ok then offer_open_project(proj_dir, 'go.mod') end
            end,
          })
        end)
      end)
    end)
  elseif id == 'new_makefile' then
    require('marvin.makefile_creator').create(vim.fn.getcwd(), M.show)
  end
end

-- ── C/C++ fallback (cmake/makefile — no lang module) ─────────────────────────
local function cpp_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end

  add(sep('Create'))
  add(item('new_makefile', '󰈙', 'New/Regenerate Makefile', 'Makefile creation wizard'))

  add(sep('Build'))
  if p.type == 'cmake' then
    add(item('cmake_cfg', '󰒓', 'Configure', 'cmake -B build -S .'))
    add(item('cmake_build', '󰑕', 'Build', 'cmake --build build'))
    add(item('cmake_test', '󰙨', 'Test', 'ctest --test-dir build'))
    add(item('cmake_clean', '󰃢', 'Clean', 'cmake --build build --target clean'))
    add(item('cmake_install', '󰇚', 'Install', 'cmake --install build'))
  else
    add(item('make_build', '󰑕', 'Build', 'make'))
    add(item('make_test', '󰙨', 'Test', 'make test'))
    add(item('make_clean', '󰃢', 'Clean', 'make clean'))
    add(item('make_install', '󰇚', 'Install', 'make install'))
  end

  add(sep('Console'))
  add(item('console', '󰋚', 'Task Console', 'View build output history'))
  return items
end

local function handle_cpp(id, p)
  local function run(cmd, title)
    require('core.runner').execute({
      cmd = cmd,
      cwd = p.root,
      title = title,
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  end
  if id == 'new_makefile' then
    require('marvin.makefile_creator').create(p.root, M.show)
  elseif id == 'cmake_cfg' then
    run('cmake -B build -S .', 'CMake Configure')
  elseif id == 'cmake_build' then
    run('cmake --build build', 'CMake Build')
  elseif id == 'cmake_test' then
    run('ctest --test-dir build', 'CTest')
  elseif id == 'cmake_clean' then
    run('cmake --build build --target clean', 'CMake Clean')
  elseif id == 'cmake_install' then
    run('cmake --install build', 'CMake Install')
  elseif id == 'make_build' then
    run('make', 'Make')
  elseif id == 'make_test' then
    run('make test', 'Make Test')
  elseif id == 'make_clean' then
    run('make clean', 'Make Clean')
  elseif id == 'make_install' then
    run('make install', 'Make Install')
  elseif id == 'console' then
    require('marvin.console').toggle()
  end
end

-- ── Common footer (always appended) ──────────────────────────────────────────
local function footer_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end

  if p then
    local subs = require('marvin.detector').detect_sub_projects(vim.fn.getcwd())
    if subs and #subs > 1 then
      add(sep('Workspace'))
      add(item('switch_project', '󰙅', 'Switch Project…',
        #subs .. ' sub-projects detected'))
    end
  end

  add(sep('Tools'))
  add(item('console', '󰋚', 'Task Console', 'Jason build output history'))
  add(item('reload', '󰚰', 'Reload Project', 'Re-parse the manifest'))
  if p then
    add(item('open_manifest', '󰈙', 'Open Manifest', 'Edit the project manifest file'))
  end

  return items
end

local function handle_footer(id, p)
  if id == 'console' then
    require('marvin.console').toggle()
  elseif id == 'switch_project' then
    M.show_project_picker()
  elseif id == 'reload' then
    require('marvin.detector').reload()
    vim.notify('[Marvin] Project reloaded', vim.log.levels.INFO)
    vim.schedule(M.show)
  elseif id == 'open_manifest' and p then
    local manifests = {
      maven = 'pom.xml',
      gradle = 'build.gradle',
      cargo = 'Cargo.toml',
      go_mod = 'go.mod',
      cmake = 'CMakeLists.txt',
    }
    local f = manifests[p.type]
    if f and vim.fn.filereadable(p.root .. '/' .. f) == 1 then
      vim.cmd('edit ' .. vim.fn.fnameescape(p.root .. '/' .. f))
    end
  end
end

-- ── Main show function ────────────────────────────────────────────────────────
function M.show()
  local det   = require('marvin.detector')
  local p     = det.get()
  local lmod  = p and lang_mod(p.type)

  local items = {}
  local function add_all(t) for _, v in ipairs(t) do items[#items + 1] = v end end

  if not p then
    -- No project: create options first
    add_all(create_items())
    add_all(footer_items(nil))
  elseif lmod then
    -- Full language module (Java, Rust, Go)
    add_all(lmod.menu_items(p))
    add_all(footer_items(p))
    add_all(create_items())
  else
    -- single_file or unknown
    add_all(create_items())
    add_all(footer_items(p))
  end

  local prompt = build_prompt(p)

  ui().select(items, {
    prompt        = prompt,
    enable_search = true,
    format_item   = function(it)
      if it.is_separator then return it.label end
      return (it._icon and (it._icon .. ' ') or '') .. it.label
    end,
  }, function(choice)
    if not choice then return end
    local id   = choice.id
    local back = M.show

    -- Create / new-project actions (available from any context)
    if id == 'gen_maven' or id == 'gen_cargo_bin' or id == 'gen_cargo_lib'
        or id == 'gen_go' or id == 'new_makefile' then
      handle_no_project(id)

      -- Footer / tools actions
    elseif id == 'console' or id == 'switch_project'
        or id == 'reload' or id == 'open_manifest' then
      handle_footer(id, p)

      -- Language module actions (Java / Rust / Go)
    elseif lmod then
      lmod.handle(id, p, back)
    end
  end)
end

-- ── Project switcher (monorepo) ───────────────────────────────────────────────
function M.show_project_picker()
  local det  = require('marvin.detector')
  local subs = det.detect_sub_projects(vim.fn.getcwd())
  if not subs or #subs == 0 then
    vim.notify('[Marvin] No sub-projects found', vim.log.levels.INFO); return
  end

  local items = {}
  for _, sp in ipairs(subs) do
    local icon        = LANG_ICONS[sp.type] or '󰙅'
    local label       = LANG_LABELS[sp.type] or sp.type
    items[#items + 1] = {
      id    = sp.root,
      label = icon .. ' ' .. sp.name,
      desc  = label .. ' — ' .. sp.root,
      _proj = sp,
    }
  end

  ui().select(items, {
    prompt      = 'Switch Project',
    format_item = plain,
  }, function(choice)
    if choice then
      det.set(choice._proj)
      vim.notify('[Marvin] Active project → ' .. choice._proj.name, vim.log.levels.INFO)
      vim.schedule(M.show)
    end
  end)
end

return M

```

### `lua/marvin/dependencies.lua`

```lua
-- lua/marvin/dependencies.lua
-- All pom.xml manipulation: adding deps, plugins, setting properties.

local M = {}

-- ── POM I/O ───────────────────────────────────────────────────────────────────
local function pom_path() return vim.fn.getcwd() .. '/pom.xml' end

local function read_pom()
  local p = pom_path()
  if vim.fn.filereadable(p) == 0 then return nil, 'No pom.xml in current directory' end
  return vim.fn.readfile(p), nil
end

local function write_pom(lines)
  vim.fn.writefile(lines, pom_path())
end

local function notify(msg, level)
  require('marvin.ui').notify(msg, level)
end

-- ── XML helpers ───────────────────────────────────────────────────────────────
local function find_tag(lines, open, close)
  for i, line in ipairs(lines) do
    if line:match(open) then
      for j = i + 1, #lines do
        if lines[j]:match(close) then return i, j end
      end
    end
  end
  return nil, nil
end

local function ensure_section(lines, open_pat, close_pat, insert_before_pat, indent, open_tag, close_tag)
  local s, e = find_tag(lines, open_pat, close_pat)
  if s then return lines, s, e end
  for i = #lines, 1, -1 do
    if lines[i]:match(insert_before_pat) then
      table.insert(lines, i, indent .. close_tag)
      table.insert(lines, i, indent .. open_tag)
      table.insert(lines, i, '')
      return lines, i + 1, i + 2
    end
  end
  return lines, nil, nil
end

local function insert_before(lines, idx, new_lines)
  for i = #new_lines, 1, -1 do
    table.insert(lines, idx, new_lines[i])
  end
end

-- ── Properties ────────────────────────────────────────────────────────────────
local function ensure_properties(lines)
  return ensure_section(lines,
    '<%s*properties%s*>', '<%s*/properties%s*>',
    '<%s*/project%s*>', '  ', '<properties>', '</properties>')
end

local function set_property(lines, key, value)
  lines, s, e = ensure_properties(lines)
  if not s then return lines, false end
  local tag_o = '<' .. key .. '>'
  local tag_c = '</' .. key .. '>'
  for i = s + 1, e - 1 do
    if lines[i]:match(vim.pesc(tag_o)) then
      lines[i] = '    ' .. tag_o .. value .. tag_c
      return lines, true
    end
  end
  table.insert(lines, e, '    ' .. tag_o .. value .. tag_c)
  return lines, true
end

-- ── Dependencies section ──────────────────────────────────────────────────────
local function ensure_deps(lines)
  -- Skip dependencyManagement's <dependencies>
  local in_mgmt = false
  for i, line in ipairs(lines) do
    if line:match('<%s*dependencyManagement%s*>') then in_mgmt = true end
    if line:match('<%s*/dependencyManagement%s*>') then in_mgmt = false end
    if not in_mgmt and line:match('<%s*dependencies%s*>') then
      for j = i + 1, #lines do
        if lines[j]:match('<%s*/dependencies%s*>') then return lines, i, j end
      end
    end
  end
  return ensure_section(lines,
    '<%s*dependencies%s*>', '<%s*/dependencies%s*>',
    '<%s*/project%s*>', '  ', '<dependencies>', '</dependencies>')
end

local function add_deps(lines, dep_lines)
  lines, s, e = ensure_deps(lines)
  if not s then return lines, false end
  insert_before(lines, e, dep_lines)
  return lines, true
end

-- ── Dependency check helper ───────────────────────────────────────────────────
local function already_has(lines, artifact_id)
  local content = table.concat(lines, '\n')
  return content:match('<artifactId>%s*' .. vim.pesc(artifact_id) .. '%s*</artifactId>') ~= nil
end

-- ── Build plugins section ─────────────────────────────────────────────────────
local function ensure_build_plugins(lines)
  lines, bs, be = ensure_section(lines,
    '<%s*build%s*>', '<%s*/build%s*>',
    '<%s*/project%s*>', '  ', '<build>', '</build>')
  if not bs then return lines, nil, nil end
  return ensure_section(lines,
    '<%s*plugins%s*>', '<%s*/plugins%s*>',
    '<%s*/build%s*>', '    ', '<plugins>', '</plugins>')
end

-- ── Public: add dependencies ─────────────────────────────────────────────────
function M.add_jackson()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if already_has(lines, 'jackson-databind') then
    notify('Jackson already in pom.xml', vim.log.levels.WARN); return
  end
  lines, ok = add_deps(lines, {
    '',
    '    <!-- Jackson JSON -->',
    '    <dependency>',
    '      <groupId>com.fasterxml.jackson.core</groupId>',
    '      <artifactId>jackson-databind</artifactId>',
    '      <version>2.18.2</version>',
    '    </dependency>',
    '    <dependency>',
    '      <groupId>com.fasterxml.jackson.core</groupId>',
    '      <artifactId>jackson-core</artifactId>',
    '      <version>2.18.2</version>',
    '    </dependency>',
    '    <dependency>',
    '      <groupId>com.fasterxml.jackson.core</groupId>',
    '      <artifactId>jackson-annotations</artifactId>',
    '      <version>2.18.2</version>',
    '    </dependency>',
  })
  if ok then
    write_pom(lines); notify('✅ Jackson added', vim.log.levels.INFO)
  else
    notify('Failed to add Jackson', vim.log.levels.ERROR)
  end
end

function M.add_spring()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if already_has(lines, 'spring-boot-starter') then
    notify('Spring Boot already in pom.xml', vim.log.levels.WARN); return
  end
  -- Also add spring-boot-maven-plugin
  lines, ok = add_deps(lines, {
    '',
    '    <!-- Spring Boot -->',
    '    <dependency>',
    '      <groupId>org.springframework.boot</groupId>',
    '      <artifactId>spring-boot-starter</artifactId>',
    '      <version>3.4.1</version>',
    '    </dependency>',
    '    <dependency>',
    '      <groupId>org.springframework.boot</groupId>',
    '      <artifactId>spring-boot-starter-test</artifactId>',
    '      <version>3.4.1</version>',
    '      <scope>test</scope>',
    '    </dependency>',
  })
  if ok then
    write_pom(lines); notify('✅ Spring Boot added', vim.log.levels.INFO)
  else
    notify('Failed to add Spring Boot', vim.log.levels.ERROR)
  end
end

function M.add_lombok()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if already_has(lines, 'lombok') then
    notify('Lombok already in pom.xml', vim.log.levels.WARN); return
  end
  lines, ok = add_deps(lines, {
    '',
    '    <!-- Lombok -->',
    '    <dependency>',
    '      <groupId>org.projectlombok</groupId>',
    '      <artifactId>lombok</artifactId>',
    '      <version>1.18.36</version>',
    '      <scope>provided</scope>',
    '    </dependency>',
  })
  if ok then
    write_pom(lines); notify('✅ Lombok added', vim.log.levels.INFO)
  else
    notify('Failed to add Lombok', vim.log.levels.ERROR)
  end
end

function M.add_junit5()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if already_has(lines, 'junit-jupiter') then
    notify('JUnit 5 already in pom.xml', vim.log.levels.WARN); return
  end
  lines, ok = add_deps(lines, {
    '',
    '    <!-- JUnit 5 -->',
    '    <dependency>',
    '      <groupId>org.junit.jupiter</groupId>',
    '      <artifactId>junit-jupiter</artifactId>',
    '      <version>5.11.4</version>',
    '      <scope>test</scope>',
    '    </dependency>',
  })
  if ok then
    write_pom(lines); notify('✅ JUnit 5 added', vim.log.levels.INFO)
  else
    notify('Failed to add JUnit 5', vim.log.levels.ERROR)
  end
end

function M.add_mockito()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if already_has(lines, 'mockito-core') then
    notify('Mockito already in pom.xml', vim.log.levels.WARN); return
  end
  lines, ok = add_deps(lines, {
    '',
    '    <!-- Mockito -->',
    '    <dependency>',
    '      <groupId>org.mockito</groupId>',
    '      <artifactId>mockito-core</artifactId>',
    '      <version>5.15.2</version>',
    '      <scope>test</scope>',
    '    </dependency>',
  })
  if ok then
    write_pom(lines); notify('✅ Mockito added', vim.log.levels.INFO)
  else
    notify('Failed to add Mockito', vim.log.levels.ERROR)
  end
end

function M.add_lwjgl()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if already_has(lines, 'lwjgl-bom') or already_has(lines, 'lwjgl') then
    notify('LWJGL already in pom.xml', vim.log.levels.WARN); return
  end
  lines, ok = set_property(lines, 'lwjgl.version', '3.3.6')
  lines, ok = set_property(lines, 'joml.version', '1.10.8')
  -- BOM in dependencyManagement
  lines, s, e = ensure_section(lines,
    '<%s*dependencyManagement%s*>.*<%s*dependencies%s*>',
    '<%s*/dependencyManagement', '<%s*dependencies%s*>', '    ',
    '<dependencyManagement><dependencies>', '</dependencies></dependencyManagement>')
  if s then
    insert_before(lines, e, {
      '      <dependency>',
      '        <groupId>org.lwjgl</groupId>',
      '        <artifactId>lwjgl-bom</artifactId>',
      '        <version>${lwjgl.version}</version>',
      '        <scope>import</scope>',
      '        <type>pom</type>',
      '      </dependency>',
    })
  end
  -- Core + natives
  local native_classifiers = { 'natives-linux', 'natives-windows', 'natives-macos' }
  local modules = { 'lwjgl', 'lwjgl-glfw', 'lwjgl-opengl', 'lwjgl-stb' }
  local dep_lines = { '', '    <!-- LWJGL -->' }
  for _, mod in ipairs(modules) do
    dep_lines[#dep_lines + 1] = '    <dependency>'
    dep_lines[#dep_lines + 1] = '      <groupId>org.lwjgl</groupId>'
    dep_lines[#dep_lines + 1] = '      <artifactId>' .. mod .. '</artifactId>'
    dep_lines[#dep_lines + 1] = '    </dependency>'
    for _, cls in ipairs(native_classifiers) do
      dep_lines[#dep_lines + 1] = '    <dependency>'
      dep_lines[#dep_lines + 1] = '      <groupId>org.lwjgl</groupId>'
      dep_lines[#dep_lines + 1] = '      <artifactId>' .. mod .. '</artifactId>'
      dep_lines[#dep_lines + 1] = '      <classifier>' .. cls .. '</classifier>'
      dep_lines[#dep_lines + 1] = '    </dependency>'
    end
  end
  dep_lines[#dep_lines + 1] = '    <!-- JOML -->'
  dep_lines[#dep_lines + 1] = '    <dependency>'
  dep_lines[#dep_lines + 1] = '      <groupId>org.joml</groupId>'
  dep_lines[#dep_lines + 1] = '      <artifactId>joml</artifactId>'
  dep_lines[#dep_lines + 1] = '      <version>${joml.version}</version>'
  dep_lines[#dep_lines + 1] = '    </dependency>'
  lines, ok = add_deps(lines, dep_lines)
  if ok then
    write_pom(lines); notify('✅ LWJGL + JOML added (Linux/Windows/macOS natives)', vim.log.levels.INFO)
  else
    notify('Failed to add LWJGL', vim.log.levels.ERROR)
  end
end

function M.add_assembly_plugin()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if table.concat(lines, '\n'):match('maven%-assembly%-plugin') then
    notify('Assembly plugin already configured', vim.log.levels.WARN); return
  end
  local main_class = M.find_main_class() or 'com.example.Main'
  lines, ps, pe = ensure_build_plugins(lines)
  if not ps then
    notify('Failed to locate <plugins>', vim.log.levels.ERROR); return
  end
  insert_before(lines, pe, {
    '      <!-- Fat JAR -->',
    '      <plugin>',
    '        <groupId>org.apache.maven.plugins</groupId>',
    '        <artifactId>maven-assembly-plugin</artifactId>',
    '        <version>3.7.1</version>',
    '        <configuration>',
    '          <archive><manifest>',
    '            <mainClass>' .. main_class .. '</mainClass>',
    '          </manifest></archive>',
    '          <descriptorRefs><descriptorRef>jar-with-dependencies</descriptorRef></descriptorRefs>',
    '        </configuration>',
    '        <executions><execution>',
    '          <id>make-assembly</id><phase>package</phase>',
    '          <goals><goal>single</goal></goals>',
    '        </execution></executions>',
    '      </plugin>',
  })
  write_pom(lines)
  notify('✅ Assembly plugin added  (main class: ' .. main_class .. ')', vim.log.levels.INFO)
end

function M.add_spotless()
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  if table.concat(lines, '\n'):match('spotless') then
    notify('Spotless already configured', vim.log.levels.WARN); return
  end
  lines, ps, pe = ensure_build_plugins(lines)
  if not ps then
    notify('Failed to locate <plugins>', vim.log.levels.ERROR); return
  end
  insert_before(lines, pe, {
    '      <!-- Spotless formatter -->',
    '      <plugin>',
    '        <groupId>com.diffplug.spotless</groupId>',
    '        <artifactId>spotless-maven-plugin</artifactId>',
    '        <version>2.43.0</version>',
    '        <configuration>',
    '          <java><googleJavaFormat/></java>',
    '        </configuration>',
    '      </plugin>',
  })
  write_pom(lines)
  notify('✅ Spotless added  (run: mvn spotless:apply)', vim.log.levels.INFO)
end

-- ── Public: properties ────────────────────────────────────────────────────────
function M.set_java_version(version)
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  version = tostring(version)
  lines, _ = set_property(lines, 'maven.compiler.source', version)
  lines, _ = set_property(lines, 'maven.compiler.target', version)
  write_pom(lines)
  notify('✅ Java version set to ' .. version, vim.log.levels.INFO)
end

function M.set_encoding(enc)
  local lines, err = read_pom(); if not lines then
    notify(err, vim.log.levels.ERROR); return
  end
  lines, _ = set_property(lines, 'project.build.sourceEncoding', enc)
  lines, _ = set_property(lines, 'project.reporting.outputEncoding', enc)
  write_pom(lines)
  notify('✅ Encoding set to ' .. enc, vim.log.levels.INFO)
end

-- ── Util: find main class ─────────────────────────────────────────────────────
function M.find_main_class()
  local files = vim.fn.globpath(vim.fn.getcwd() .. '/src/main/java', '**/*.java', false, true)
  for _, file in ipairs(files) do
    local pkg, cls, has_main
    for _, line in ipairs(vim.fn.readfile(file)) do
      if line:match('^%s*package%s+') then pkg = line:match('package%s+([%w%.]+)') end
      if line:match('^%s*public%s+class%s+') then cls = line:match('class%s+(%w+)') end
      if line:match('public%s+static%s+void%s+main') then has_main = true end
      if pkg and cls and has_main then return pkg .. '.' .. cls end
    end
  end
end

return M

```

### `lua/marvin/deps/go.lua`

```lua
-- lua/marvin/deps/go.lua
-- Go dependency management via the go toolchain.
-- Actions: list, add, remove, update, tidy, outdated (go list -u), audit (govulncheck).

local M = {}

local function ui()  return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function run(cmd, root, title)
  require('core.runner').execute({
    cmd      = cmd, cwd = root, title = title,
    term_cfg = require('marvin').config.terminal,
    plugin   = 'marvin',
  })
end
local function plain(it) return it.label end

-- ── Known package catalogue ───────────────────────────────────────────────────
local CATALOGUE = {
  -- Web / HTTP
  { path = 'github.com/gin-gonic/gin',              label = 'Gin',            desc = 'Fast HTTP web framework' },
  { path = 'github.com/gofiber/fiber/v2',           label = 'Fiber',          desc = 'Express-inspired framework' },
  { path = 'github.com/labstack/echo/v4',           label = 'Echo',           desc = 'Minimalist web framework' },
  { path = 'net/http',                              label = 'net/http',       desc = 'Standard library HTTP (no import needed)' },
  -- Router
  { path = 'github.com/gorilla/mux',                label = 'Gorilla Mux',    desc = 'Powerful URL router' },
  { path = 'github.com/go-chi/chi/v5',              label = 'Chi',            desc = 'Lightweight composable router' },
  -- Database
  { path = 'gorm.io/gorm',                          label = 'GORM',           desc = 'ORM for Go' },
  { path = 'gorm.io/driver/postgres',               label = 'GORM Postgres',  desc = 'GORM PostgreSQL driver' },
  { path = 'gorm.io/driver/sqlite',                 label = 'GORM SQLite',    desc = 'GORM SQLite driver' },
  { path = 'github.com/jmoiron/sqlx',               label = 'sqlx',           desc = 'Extensions to database/sql' },
  { path = 'github.com/lib/pq',                     label = 'lib/pq',         desc = 'PostgreSQL driver' },
  { path = 'github.com/mattn/go-sqlite3',           label = 'go-sqlite3',     desc = 'SQLite3 driver (CGO)' },
  -- Config
  { path = 'github.com/spf13/viper',                label = 'Viper',          desc = 'Configuration management' },
  { path = 'github.com/joho/godotenv',              label = 'godotenv',       desc = '.env file loading' },
  -- CLI
  { path = 'github.com/spf13/cobra',                label = 'Cobra',          desc = 'CLI framework' },
  { path = 'github.com/urfave/cli/v2',              label = 'urfave/cli',     desc = 'Simple CLI framework' },
  -- Logging
  { path = 'go.uber.org/zap',                       label = 'Zap',            desc = 'Blazing fast structured logger' },
  { path = 'github.com/rs/zerolog',                 label = 'Zerolog',        desc = 'Zero-allocation JSON logger' },
  { path = 'github.com/sirupsen/logrus',            label = 'Logrus',         desc = 'Structured logger' },
  -- Serialisation
  { path = 'encoding/json',                         label = 'encoding/json',  desc = 'Standard library JSON (no import needed)' },
  { path = 'github.com/bytedance/sonic',            label = 'Sonic',          desc = 'High-perf JSON encoder/decoder' },
  -- Testing
  { path = 'github.com/stretchr/testify',           label = 'Testify',        desc = 'Assertion + mocking library' },
  { path = 'github.com/golang/mock/gomock',         label = 'GoMock',         desc = 'Mocking framework' },
  { path = 'github.com/vektra/mockery/v2',          label = 'Mockery',        desc = 'Mock code generator' },
  -- Observability
  { path = 'go.opentelemetry.io/otel',              label = 'OpenTelemetry',  desc = 'Distributed tracing' },
  { path = 'github.com/prometheus/client_golang',   label = 'Prometheus',     desc = 'Metrics exposition' },
  -- Utility
  { path = 'github.com/google/uuid',                label = 'uuid',           desc = 'UUID generation' },
  { path = 'github.com/samber/lo',                  label = 'lo',             desc = 'Lodash-style generic helpers' },
  { path = 'golang.org/x/sync',                     label = 'x/sync',         desc = 'errgroup, semaphore, singleflight' },
}

-- ── Public API ────────────────────────────────────────────────────────────────

function M.menu_items()
  local items = {}
  local function add(t) items[#items + 1] = t end
  local function sep(l) add({ label = l, is_separator = true }) end
  local function it(id, icon, label, desc) add({ id=id, label=icon..' '..label, desc=desc }) end
  local p = det().get()

  sep('Dependencies')
  it('dep_list',     '󰘦', 'View Dependencies',    'All modules in go.mod')
  it('dep_add',      '󰐕', 'Add Package…',         'go get from catalogue or manual entry')
  it('dep_remove',   '󰍴', 'Remove Package…',      'go get pkg@none + go mod tidy')
  it('dep_update',   '󰚰', 'Update All',           'go get -u ./...')
  it('dep_tidy',     '󰃢', 'Tidy',                 'go mod tidy — remove unused')
  it('dep_outdated', '󰦉', 'Check Outdated',       'go list -u -m all')
  it('dep_download', '󰇚', 'Download All',         'go mod download')

  sep('Security')
  it('dep_audit',    '󰒃', 'Vulnerability Audit',  'govulncheck ./... (requires govulncheck)')

  sep('Modules')
  it('dep_why',      '󰍉', 'Why is this needed?',  'go mod why <module>')
  it('dep_verify',   '󰄬', 'Verify',               'go mod verify')
  it('dep_graph',    '󰙅', 'Dependency Graph',     'go mod graph')
  if p and p.info and p.info.is_workspace then
    it('ws_members', '󰙅', 'Workspace Members',    'go.work uses')
    it('ws_sync',    '󰚰', 'Workspace Sync',       'go work sync')
  end

  return items
end

function M.handle(id)
  local p = det().get()
  if not p then return end
  local root = p.root

  if id == 'dep_list' then
    M.show_dep_list(p)
  elseif id == 'dep_add' then
    M.show_add_menu(p)
  elseif id == 'dep_remove' then
    M.show_remove_menu(p)
  elseif id == 'dep_update' then
    run('go get -u ./...', root, 'Update All')
  elseif id == 'dep_tidy' then
    run('go mod tidy', root, 'Go Mod Tidy')
  elseif id == 'dep_outdated' then
    run('go list -u -m all', root, 'Outdated Modules')
  elseif id == 'dep_download' then
    run('go mod download', root, 'Download Modules')
  elseif id == 'dep_audit' then
    run('govulncheck ./...', root, 'Vulnerability Audit')
  elseif id == 'dep_why' then
    ui().input({ prompt = 'Module path to explain' }, function(mod)
      if mod and mod ~= '' then run('go mod why ' .. mod, root, 'Why ' .. mod) end
    end)
  elseif id == 'dep_verify' then
    run('go mod verify', root, 'Verify Modules')
  elseif id == 'dep_graph' then
    run('go mod graph', root, 'Module Graph')
  elseif id == 'ws_members' then
    M.show_workspace_members(p)
  elseif id == 'ws_sync' then
    run('go work sync', root, 'Workspace Sync')
  end
end

function M.show_dep_list(p)
  local deps = (p.info and p.info.deps) or {}
  if #deps == 0 then
    vim.notify('[Marvin] No dependencies in go.mod', vim.log.levels.INFO); return
  end
  local items = {}
  for _, d in ipairs(deps) do
    items[#items + 1] = {
      id    = d.path,
      label = d.path .. ' @ ' .. d.version,
      desc  = d.indirect and 'indirect' or 'direct',
    }
  end
  ui().select(items, {
    prompt        = 'Go Modules (' .. #deps .. ')',
    enable_search = true,
    format_item   = plain,
  }, function(_) end)
end

function M.show_add_menu(p)
  local cat_items = {}
  for _, c in ipairs(CATALOGUE) do
    -- Skip stdlib pseudo-entries (no import needed)
    if not c.path:match('^encoding/') and not c.path:match('^net/') then
      cat_items[#cat_items + 1] = {
        id     = 'cat__' .. c.path,
        label  = c.label,
        desc   = c.desc .. ' — ' .. c.path,
        _pkg   = c,
      }
    end
  end
  cat_items[#cat_items + 1] = {
    id = '__manual__', label = '󰏫 Enter module path manually…', desc = 'e.g. github.com/foo/bar@latest'
  }

  ui().select(cat_items, {
    prompt        = 'Add Go Module',
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then return end
    if choice.id == '__manual__' then
      ui().input({ prompt = 'Module path[@version]', default = '' }, function(path)
        if path and path ~= '' then
          -- Append @latest if no version given
          if not path:match('@') then path = path .. '@latest' end
          run('go get ' .. path, p.root, 'go get ' .. path)
          vim.defer_fn(function() det().reload() end, 3000)
        end
      end)
    else
      local pkg  = choice._pkg
      local path = pkg.path .. '@latest'
      run('go get ' .. path, p.root, 'go get ' .. pkg.label)
      vim.defer_fn(function() det().reload() end, 3000)
    end
  end)
end

function M.show_remove_menu(p)
  local deps = (p.info and p.info.deps) or {}
  local direct = {}
  for _, d in ipairs(deps) do
    if not d.indirect then direct[#direct + 1] = d end
  end
  if #direct == 0 then
    vim.notify('[Marvin] No direct dependencies to remove', vim.log.levels.INFO); return
  end
  local items = {}
  for _, d in ipairs(direct) do
    items[#items + 1] = { id = d.path, label = d.path, desc = d.version }
  end
  ui().select(items, {
    prompt        = 'Remove Module',
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then return end
    -- go get pkg@none removes it; then tidy cleans go.mod
    run('go get ' .. choice.id .. '@none && go mod tidy', p.root, 'Remove ' .. choice.id)
    vim.defer_fn(function() det().reload() end, 3000)
  end)
end

function M.show_workspace_members(p)
  local members = (p.info and p.info.workspace) or {}
  if #members == 0 then
    vim.notify('[Marvin] No go.work workspace members found', vim.log.levels.INFO); return
  end
  local items = {}
  for _, m in ipairs(members) do
    items[#items + 1] = { id = m, label = m }
  end
  ui().select(items, { prompt = 'Workspace Members', format_item = plain }, function(_) end)
end

return M

```

### `lua/marvin/deps/java.lua`

```lua
-- lua/marvin/deps/java.lua
-- Java dependency management for Maven and Gradle projects.
-- Actions: list, add, remove, update, check outdated, audit (OWASP), analyze.

local M = {}

local function ui() return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function ex() return require('marvin.executor') end
local function plain(it) return it.label end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function is_maven()
  local p = det().get(); return p and p.type == 'maven'
end

local function read_pom(root)
  local f = io.open(root .. '/pom.xml', 'r')
  if not f then return nil end
  local c = f:read('*all'); f:close(); return c
end

local function write_pom(root, content)
  local f = io.open(root .. '/pom.xml', 'w')
  if not f then
    vim.notify('[Marvin] Cannot write pom.xml', vim.log.levels.ERROR); return false
  end
  f:write(content); f:close(); return true
end

-- ── Maven: XML manipulation ───────────────────────────────────────────────────
local function maven_dep_xml(group, artifact, version, scope)
  local lines = {
    '        <dependency>',
    '            <groupId>' .. group .. '</groupId>',
    '            <artifactId>' .. artifact .. '</artifactId>',
  }
  if version and version ~= '' then
    lines[#lines + 1] = '            <version>' .. version .. '</version>'
  end
  if scope and scope ~= 'compile' then
    lines[#lines + 1] = '            <scope>' .. scope .. '</scope>'
  end
  lines[#lines + 1] = '        </dependency>'
  return table.concat(lines, '\n')
end

local function maven_insert_dep(root, group, artifact, version, scope)
  local content = read_pom(root)
  if not content then return false end

  -- Check already present
  if content:find('<artifactId>' .. artifact .. '</artifactId>', 1, true) then
    vim.notify('[Marvin] ' .. artifact .. ' is already in pom.xml', vim.log.levels.WARN)
    return false
  end

  local xml = maven_dep_xml(group, artifact, version, scope)
  -- Insert before closing </dependencies>
  local new, n = content:gsub('(</dependencies>)', xml .. '\n    %1', 1)
  if n == 0 then
    -- No <dependencies> block at all — create one before </project>
    new = content:gsub('(</project>)',
      '    <dependencies>\n' .. xml .. '\n    </dependencies>\n%1', 1)
  end
  if write_pom(root, new) then
    det().reload()
    vim.notify('[Marvin] Added ' .. group .. ':' .. artifact, vim.log.levels.INFO)
    return true
  end
  return false
end

local function maven_remove_dep(root, artifact)
  local content = read_pom(root)
  if not content then return false end
  -- Remove the whole <dependency>…</dependency> block containing this artifactId
  local new, n = content:gsub(
    '\n%s*<dependency>%s*\n[^<]*<groupId>[^<]*</groupId>%s*\n[^<]*<artifactId>'
    .. vim.pesc(artifact)
    .. '</artifactId>[^<]*\n.-</dependency>',
    '', 1)
  if n == 0 then
    vim.notify('[Marvin] ' .. artifact .. ' not found in pom.xml', vim.log.levels.WARN)
    return false
  end
  if write_pom(root, new) then
    det().reload()
    vim.notify('[Marvin] Removed ' .. artifact, vim.log.levels.INFO)
    return true
  end
  return false
end

-- ── Gradle: delegate to `gradle dependencies` for display, `build.gradle` edit ─
-- For Gradle we shell out to `gradle` commands rather than editing the file,
-- because Gradle DSL is far less regular than XML.
local function gradle_cmd(root)
  if vim.fn.filereadable(root .. '/gradlew') == 1 then return './gradlew' end
  return 'gradle'
end

-- ── Known dependency catalogue ─────────────────────────────────────────────────
-- Used for the quick-add menu. Users can also type any coordinate manually.
local CATALOGUE = {
  -- Testing
  { group = 'org.junit.jupiter',          artifact = 'junit-jupiter',                version = '5.10.2',     scope = 'test',     label = 'JUnit 5',               desc = 'Unit testing framework' },
  { group = 'org.mockito',                artifact = 'mockito-core',                 version = '5.11.0',     scope = 'test',     label = 'Mockito',               desc = 'Mocking framework' },
  { group = 'org.assertj',                artifact = 'assertj-core',                 version = '3.25.3',     scope = 'test',     label = 'AssertJ',               desc = 'Fluent assertions' },
  -- Spring
  { group = 'org.springframework.boot',   artifact = 'spring-boot-starter',          version = nil,          scope = 'compile',  label = 'Spring Boot Starter',   desc = 'Spring Boot base' },
  { group = 'org.springframework.boot',   artifact = 'spring-boot-starter-web',      version = nil,          scope = 'compile',  label = 'Spring Web',            desc = 'REST + MVC' },
  { group = 'org.springframework.boot',   artifact = 'spring-boot-starter-data-jpa', version = nil,          scope = 'compile',  label = 'Spring Data JPA',       desc = 'JPA / Hibernate' },
  { group = 'org.springframework.boot',   artifact = 'spring-boot-starter-test',     version = nil,          scope = 'test',     label = 'Spring Test',           desc = 'Spring testing' },
  -- Utilities
  { group = 'org.projectlombok',          artifact = 'lombok',                       version = '1.18.32',    scope = 'provided', label = 'Lombok',                desc = 'Annotation processor' },
  { group = 'com.fasterxml.jackson.core', artifact = 'jackson-databind',             version = '2.17.0',     scope = 'compile',  label = 'Jackson',               desc = 'JSON serialisation' },
  { group = 'com.google.guava',           artifact = 'guava',                        version = '33.1.0-jre', scope = 'compile',  label = 'Guava',                 desc = 'Google core libraries' },
  { group = 'org.apache.commons',         artifact = 'commons-lang3',                version = '3.14.0',     scope = 'compile',  label = 'Commons Lang',          desc = 'String/number helpers' },
  -- Database
  { group = 'com.h2database',             artifact = 'h2',                           version = '2.2.224',    scope = 'runtime',  label = 'H2 Database',           desc = 'In-memory database' },
  { group = 'org.postgresql',             artifact = 'postgresql',                   version = '42.7.3',     scope = 'runtime',  label = 'PostgreSQL Driver',     desc = 'PostgreSQL JDBC' },
  -- Logging
  { group = 'ch.qos.logback',             artifact = 'logback-classic',              version = '1.5.3',      scope = 'compile',  label = 'Logback',               desc = 'Logging framework' },
  -- Security / OWASP
  { group = 'org.owasp',                  artifact = 'dependency-check-maven',       version = '9.1.0',      scope = 'provided', label = 'OWASP Dep-Check',       desc = 'Vulnerability scanner plugin' },
  -- Fat jar
  { group = 'org.apache.maven.plugins',   artifact = '__shade__',                    version = nil,          scope = 'provided', label = 'Maven Shade (fat jar)', desc = 'Uber-jar plugin with ServicesResourceTransformer' },
  -- OpenGL / games
  { group = 'org.lwjgl',                  artifact = 'lwjgl',                        version = '3.4.1',      scope = 'compile',  label = 'LWJGL Core',            desc = 'OpenGL / Vulkan / GLFW' },
  { group = 'org.lwjgl',                  artifact = 'lwjgl-glfw',                   version = '3.4.1',      scope = 'compile',  label = 'LWJGL GLFW',            desc = 'Window / input' },
  { group = 'org.lwjgl',                  artifact = 'lwjgl-opengl',                 version = '3.4.1',      scope = 'compile',  label = 'LWJGL OpenGL',          desc = 'OpenGL bindings' },
  { group = 'org.lwjgl',                  artifact = '__lwjgl_full__',               version = '3.4.1',      scope = 'compile',  label = 'LWJGL Full Suite',      desc = 'BOM + all modules + natives profiles + JOML + extras' },
}

-- ── Public API ────────────────────────────────────────────────────────────────

-- Dashboard menu items for the Deps section
function M.menu_items()
  local p     = det().get()
  local mvn   = p and p.type == 'maven'
  local grad  = p and p.type == 'gradle'

  local items = {}
  local function add(t) items[#items + 1] = t end
  local function sep(l) add({ label = l, is_separator = true }) end
  local function it(id, icon, label, desc) add({ id = id, label = icon .. ' ' .. label, desc = desc }) end

  sep('Dependencies')
  it('dep_list', '󰘦', 'View Dependencies', 'All declared dependencies')
  it('dep_add', '󰐕', 'Add Dependency…', 'Quick-add from catalogue or enter coords')
  it('dep_remove', '󰍴', 'Remove Dependency…', 'Remove from manifest')
  it('dep_outdated', '󰦉', 'Check for Updates',
    mvn and 'versions:display-dependency-updates' or 'gradle dependencyUpdates')
  it('dep_analyze', '󰍉', 'Analyze Dependencies', 'Find unused / undeclared')

  sep('Security')
  it('dep_audit', '󰒃', 'Vulnerability Audit', mvn and 'OWASP dependency-check' or 'gradle dependencyCheckAnalyze')
  if mvn and det().info() and not det().info().has_owasp then
    it('dep_add_owasp', '󰒃', 'Enable OWASP Plugin', 'Add dependency-check-maven to pom.xml')
  end

  if mvn then
    sep('Maven')
    it('dep_purge', '󰃢', 'Purge Local Cache', 'mvn dependency:purge-local-repository')
    it('dep_resolve', '󰚰', 'Resolve All', 'mvn dependency:resolve')
    it('dep_tree', '󰙅', 'Dependency Tree', 'mvn dependency:tree')
  end

  if grad then
    sep('Gradle')
    it('dep_gradle_refresh', '󰚰', 'Refresh Dependencies', './gradlew --refresh-dependencies')
    it('dep_tree', '󰙅', 'Dependency Report', './gradlew dependencies')
  end

  return items
end

function M.handle(id)
  local p = det().get()
  if not p then return end
  local root = p.root
  local mvn  = p.type == 'maven'
  local gcmd = gradle_cmd(root)

  if id == 'dep_list' then
    M.show_dep_list(p)
  elseif id == 'dep_add' then
    M.show_add_menu(p)
  elseif id == 'dep_remove' then
    M.show_remove_menu(p)
  elseif id == 'dep_outdated' then
    if mvn then
      ex().run('versions:display-dependency-updates')
    else
      ex().run_raw(gcmd .. ' dependencyUpdates', root, 'Dependency Updates')
    end
  elseif id == 'dep_analyze' then
    if mvn then
      ex().run('dependency:analyze')
    else
      ex().run_raw(gcmd .. ' dependencies', root, 'Dependency Report')
    end
  elseif id == 'dep_audit' then
    if mvn then
      if not (det().info() or {}).has_owasp then
        vim.notify('[Marvin] Add the OWASP plugin first (Enable OWASP Plugin)', vim.log.levels.WARN)
        return
      end
      ex().run('dependency-check:check')
    else
      ex().run_raw(gcmd .. ' dependencyCheckAnalyze', root, 'OWASP Audit')
    end
  elseif id == 'dep_add_owasp' then
    maven_insert_dep(root, 'org.owasp', 'dependency-check-maven', '9.1.0', 'provided')
  elseif id == 'dep_purge' then
    ex().run('dependency:purge-local-repository')
  elseif id == 'dep_resolve' then
    ex().run('dependency:resolve')
  elseif id == 'dep_tree' then
    if mvn then
      ex().run('dependency:tree')
    else
      ex().run_raw(gcmd .. ' dependencies', root, 'Dependency Tree')
    end
  elseif id == 'dep_gradle_refresh' then
    ex().run_raw(gcmd .. ' --refresh-dependencies', root, 'Refresh Dependencies')
  end
end

-- ── Dep list viewer ───────────────────────────────────────────────────────────
function M.show_dep_list(p)
  local info = p.info
  local deps = info and info.deps or {}
  if #deps == 0 then
    vim.notify('[Marvin] No dependencies found in manifest', vim.log.levels.INFO); return
  end

  local items = {}
  for _, d in ipairs(deps) do
    local coord = p.type == 'go_mod'
        and d.path .. ' @ ' .. d.version
        or d.group .. ':' .. d.artifact .. ' @ ' .. d.version
    local scope = d.scope or (d.dev and 'dev' or (d.indirect and 'indirect' or 'direct'))
    items[#items + 1] = {
      id    = 'dep__' .. (d.artifact or d.path or d.name or '?'),
      label = coord,
      desc  = scope,
    }
  end

  ui().select(items, {
    prompt        = 'Dependencies (' .. #deps .. ')',
    enable_search = true,
    format_item   = plain,
  }, function(_) end) -- read-only view for now
end

-- ── Add dep menu ──────────────────────────────────────────────────────────────
function M.show_add_menu(p)
  local cat_items = {}
  for _, d in ipairs(CATALOGUE) do
    cat_items[#cat_items + 1] = {
      id    = 'cat__' .. d.artifact,
      label = d.label,
      desc  = d.desc .. (d.version and (' — ' .. d.version) or ''),
      _dep  = d,
    }
  end
  cat_items[#cat_items + 1] = {
    id = '__manual__', label = '󰏫 Enter coordinates manually…', desc = 'groupId:artifactId:version'
  }

  ui().select(cat_items, {
    prompt        = 'Add Dependency',
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then return end
    if choice.id == '__manual__' then
      M.prompt_manual_dep(p)
    elseif choice.id == 'cat____lwjgl_full__' then
      M.add_lwjgl_full(p.root)
    elseif choice.id == 'cat____shade__' then
      M.add_maven_shade(p.root)
    else
      local d = choice._dep
      if p.type == 'maven' then
        maven_insert_dep(p.root, d.group, d.artifact, d.version, d.scope)
      else
        -- Gradle: prompt for confirmation then run
        ex().run_raw(
          gradle_cmd(p.root) .. ' addDependency ' .. d.group .. ':' .. d.artifact,
          p.root, 'Add ' .. d.artifact)
      end
    end
  end)
end

function M.prompt_manual_dep(p)
  ui().input({ prompt = 'groupId:artifactId:version (version optional)' }, function(coord)
    if not coord or coord == '' then return end
    local parts    = vim.split(coord, ':')
    local group    = parts[1]
    local artifact = parts[2]
    local version  = parts[3] or ''
    if not group or not artifact then
      vim.notify('[Marvin] Invalid format. Use groupId:artifactId[:version]', vim.log.levels.ERROR)
      return
    end
    if p.type == 'maven' then
      ui().select({
        { id = 'compile',  label = 'compile  (default)' },
        { id = 'test',     label = 'test' },
        { id = 'provided', label = 'provided' },
        { id = 'runtime',  label = 'runtime' },
      }, { prompt = 'Scope', format_item = plain }, function(scope)
        if not scope then return end
        maven_insert_dep(p.root, group, artifact, version, scope.id)
      end)
    else
      ex().run_raw(
        gradle_cmd(p.root) .. " dependencies --configuration implementation",
        p.root, 'Dependency Info')
    end
  end)
end

-- ── Remove dep menu ───────────────────────────────────────────────────────────
function M.show_remove_menu(p)
  local deps = (p.info and p.info.deps) or {}
  if #deps == 0 then
    vim.notify('[Marvin] No dependencies to remove', vim.log.levels.INFO); return
  end
  local items = {}
  for _, d in ipairs(deps) do
    local label = p.type == 'maven'
        and (d.group .. ':' .. d.artifact)
        or d.path or d.name or '?'
    items[#items + 1] = { id = d.artifact or d.path or d.name or '?', label = label, desc = d.version or '', _dep = d }
  end
  ui().select(items, {
    prompt        = 'Remove Dependency',
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then return end
    if p.type == 'maven' then
      maven_remove_dep(p.root, choice.id)
    else
      ui().input({ prompt = 'Remove from Gradle config (implementation/testImplementation/etc.)' }, function(cfg)
        if cfg then
          ex().run_raw(
            "sed -i '/" .. vim.pesc(choice.id) .. "/d' build.gradle",
            p.root, 'Remove ' .. choice.id)
        end
      end)
    end
  end)
end

-- ── LWJGL full-suite installer ────────────────────────────────────────────────
-- Mirrors the official LWJGL customizer output:
--   • OS-activated <profiles> that set ${lwjgl.natives}
--   • <properties> for lwjgl, joml, joml-primitives, lwjgl3-awt, steamworks4j versions
--   • BOM import in <dependencyManagement>
--   • All compile + classifier-based native entries for every LWJGL module
--   • Extra libraries: joml-primitives, lwjgl3-awt, steamworks4j
function M.add_lwjgl_full(root)
  root = root or det().root()
  if not root then return end

  local content = read_pom(root)
  if not content then
    vim.notify('[Marvin] No pom.xml found', vim.log.levels.ERROR); return
  end

  -- Guard: already present?
  if content:find('<artifactId>lwjgl%-bom</artifactId>', 1, true)
      or content:find('<artifactId>lwjgl</artifactId>', 1, true) then
    vim.notify('[Marvin] LWJGL already in pom.xml', vim.log.levels.WARN); return
  end

  -- ── Version constants ──────────────────────────────────────────────────────
  local LWJGL_VERSION       = '3.4.1'
  local JOML_VERSION        = '1.10.8'
  local JOML_PRIMITIVES_VER = '1.10.0'
  local LWJGL3_AWT_VER      = '0.2.3'
  local STEAMWORKS4J_VER    = '1.10.0'

  -- ── Helper: replace or add a <property> ───────────────────────────────────
  local function replace_or_add_prop(c, prop, val)
    local new, n = c:gsub('<' .. prop .. '>[^<]+</' .. prop .. '>',
      '<' .. prop .. '>' .. val .. '</' .. prop .. '>')
    if n > 0 then return new end
    return c:gsub('(<properties>)',
      '%1\n        <' .. prop .. '>' .. val .. '</' .. prop .. '>')
  end

  -- ── 1. Properties ──────────────────────────────────────────────────────────
  if not content:find('<properties>', 1, true) then
    content = content:gsub('(</project>)',
      '    <properties>\n    </properties>\n%1', 1)
  end
  content = replace_or_add_prop(content, 'lwjgl.version', LWJGL_VERSION)
  content = replace_or_add_prop(content, 'joml.version', JOML_VERSION)
  content = replace_or_add_prop(content, 'joml-primitives.version', JOML_PRIMITIVES_VER)
  content = replace_or_add_prop(content, 'lwjgl3-awt.version', LWJGL3_AWT_VER)
  content = replace_or_add_prop(content, 'steamworks4j.version', STEAMWORKS4J_VER)

  -- ── 2. OS-activated profiles (set ${lwjgl.natives}) ────────────────────────
  local profiles_xml = [[
    <profiles>
        <profile>
            <id>lwjgl-natives-linux-amd64</id>
            <activation>
                <os>
                    <family>unix</family>
                    <name>linux</name>
                    <arch>amd64</arch>
                </os>
            </activation>
            <properties>
                <lwjgl.natives>natives-linux</lwjgl.natives>
            </properties>
        </profile>
        <profile>
            <id>lwjgl-natives-windows-amd64</id>
            <activation>
                <os>
                    <family>windows</family>
                    <arch>amd64</arch>
                </os>
            </activation>
            <properties>
                <lwjgl.natives>natives-windows</lwjgl.natives>
            </properties>
        </profile>
        <profile>
            <id>lwjgl-natives-windows-x86</id>
            <activation>
                <os>
                    <family>windows</family>
                    <arch>x86</arch>
                </os>
            </activation>
            <properties>
                <lwjgl.natives>natives-windows-x86</lwjgl.natives>
            </properties>
        </profile>
    </profiles>]]

  if not content:find('<profiles>', 1, true) then
    content = content:gsub('(</project>)', profiles_xml .. '\n%1', 1)
  end

  -- ── 3. BOM in <dependencyManagement> ───────────────────────────────────────
  local bom_xml = table.concat({
    '        <dependency>',
    '            <groupId>org.lwjgl</groupId>',
    '            <artifactId>lwjgl-bom</artifactId>',
    '            <version>${lwjgl.version}</version>',
    '            <scope>import</scope>',
    '            <type>pom</type>',
    '        </dependency>',
  }, '\n')

  if content:find('<dependencyManagement>', 1, true) then
    content = content:gsub(
      '(<dependencyManagement>.-</dependencies>)',
      function(block)
        return block:gsub('(</dependencies>)', bom_xml .. '\n    %1', 1)
      end, 1)
  else
    content = content:gsub('(</project>)',
      '    <dependencyManagement>\n'
      .. '        <dependencies>\n'
      .. bom_xml .. '\n'
      .. '        </dependencies>\n'
      .. '    </dependencyManagement>\n%1', 1)
  end

  -- ── 4. Module lists ────────────────────────────────────────────────────────
  -- All modules managed by the BOM (no version needed on compile entries).
  -- Classifier (native) entries also use ${lwjgl.natives} so the active profile
  -- selects the right artifact at build time.
  local BOM_MODULES    = {
    'lwjgl', 'lwjgl-assimp', 'lwjgl-bgfx', 'lwjgl-egl', 'lwjgl-fmod',
    'lwjgl-freetype', 'lwjgl-glfw', 'lwjgl-harfbuzz', 'lwjgl-hwloc',
    'lwjgl-jawt', 'lwjgl-jemalloc', 'lwjgl-ktx', 'lwjgl-llvm', 'lwjgl-lmdb',
    'lwjgl-lz4', 'lwjgl-meshoptimizer', 'lwjgl-msdfgen', 'lwjgl-nanovg',
    'lwjgl-nfd', 'lwjgl-nuklear', 'lwjgl-odbc', 'lwjgl-openal', 'lwjgl-opencl',
    'lwjgl-opengl', 'lwjgl-opengles', 'lwjgl-openxr', 'lwjgl-opus', 'lwjgl-par',
    'lwjgl-remotery', 'lwjgl-renderdoc', 'lwjgl-rpmalloc', 'lwjgl-sdl',
    'lwjgl-shaderc', 'lwjgl-spng', 'lwjgl-spvc', 'lwjgl-stb', 'lwjgl-tinyexr',
    'lwjgl-tinyfd', 'lwjgl-vma', 'lwjgl-vulkan', 'lwjgl-xxhash', 'lwjgl-yoga',
    'lwjgl-zstd',
  }

  -- Modules that ship native libraries (header-only / pure-Java ones excluded:
  -- egl, fmod, jawt, odbc, opencl, renderdoc, vulkan).
  -- Each gets explicit entries for EVERY target platform so the fat jar contains
  -- all natives regardless of which OS the build runs on.
  local NATIVE_MODULES = {
    'lwjgl', 'lwjgl-assimp', 'lwjgl-bgfx', 'lwjgl-freetype', 'lwjgl-glfw',
    'lwjgl-harfbuzz', 'lwjgl-hwloc', 'lwjgl-jemalloc', 'lwjgl-ktx', 'lwjgl-llvm',
    'lwjgl-lmdb', 'lwjgl-lz4', 'lwjgl-meshoptimizer', 'lwjgl-msdfgen',
    'lwjgl-nanovg', 'lwjgl-nfd', 'lwjgl-nuklear', 'lwjgl-openal', 'lwjgl-opengl',
    'lwjgl-opengles', 'lwjgl-openxr', 'lwjgl-opus', 'lwjgl-par', 'lwjgl-remotery',
    'lwjgl-rpmalloc', 'lwjgl-sdl', 'lwjgl-shaderc', 'lwjgl-spng', 'lwjgl-spvc',
    'lwjgl-stb', 'lwjgl-tinyexr', 'lwjgl-tinyfd', 'lwjgl-vma', 'lwjgl-xxhash',
    'lwjgl-yoga', 'lwjgl-zstd',
  }

  -- Per-module natives matrix. Not every module ships every platform classifier —
  -- missing ones simply don't exist in the LWJGL Maven repo and will error.
  -- Source of truth: https://repo1.maven.org/maven2/org/lwjgl/
  local WIN            = { 'natives-windows', 'natives-windows-x86', 'natives-windows-arm64' }
  local WIN_NO_ARM     = { 'natives-windows', 'natives-windows-x86' } -- bgfx, ktx
  local LIN            = { 'natives-linux', 'natives-linux-arm64', 'natives-linux-arm32' }
  local LIN_NO_ARM32   = { 'natives-linux', 'natives-linux-arm64' }
  local ALL_WIN_LIN    = {
    'natives-linux', 'natives-linux-arm64', 'natives-linux-arm32',
    'natives-windows', 'natives-windows-x86', 'natives-windows-arm64',
  }

  -- { artifact, { classifiers... } }
  local NATIVE_MATRIX  = {
    { 'lwjgl',               ALL_WIN_LIN },
    { 'lwjgl-assimp',        ALL_WIN_LIN },
    { 'lwjgl-bgfx',          { 'natives-linux', 'natives-linux-arm64', 'natives-linux-arm32', 'natives-windows', 'natives-windows-x86' } }, -- no windows-arm64
    { 'lwjgl-freetype',      ALL_WIN_LIN },
    { 'lwjgl-glfw',          ALL_WIN_LIN },
    { 'lwjgl-harfbuzz',      ALL_WIN_LIN },
    { 'lwjgl-hwloc',         ALL_WIN_LIN },
    { 'lwjgl-jemalloc',      ALL_WIN_LIN },
    { 'lwjgl-ktx',           { 'natives-linux', 'natives-linux-arm64', 'natives-windows' } }, -- no x86, no arm64-win, no arm32-lin
    { 'lwjgl-llvm',          { 'natives-linux', 'natives-windows' } },
    { 'lwjgl-lmdb',          ALL_WIN_LIN },
    { 'lwjgl-lz4',           ALL_WIN_LIN },
    { 'lwjgl-meshoptimizer', ALL_WIN_LIN },
    { 'lwjgl-msdfgen',       ALL_WIN_LIN },
    { 'lwjgl-nanovg',        ALL_WIN_LIN },
    { 'lwjgl-nfd',           ALL_WIN_LIN },
    { 'lwjgl-nuklear',       ALL_WIN_LIN },
    { 'lwjgl-openal',        ALL_WIN_LIN },
    { 'lwjgl-opengl',        ALL_WIN_LIN },
    { 'lwjgl-opengles',      ALL_WIN_LIN },
    { 'lwjgl-openxr',        { 'natives-linux', 'natives-windows' } },
    { 'lwjgl-opus',          ALL_WIN_LIN },
    { 'lwjgl-par',           ALL_WIN_LIN },
    { 'lwjgl-remotery',      { 'natives-linux', 'natives-windows' } }, -- no arm variants
    { 'lwjgl-rpmalloc',      ALL_WIN_LIN },
    { 'lwjgl-sdl',           ALL_WIN_LIN },
    { 'lwjgl-shaderc',       { 'natives-linux', 'natives-linux-arm64', 'natives-windows', 'natives-windows-arm64' } },
    { 'lwjgl-spng',          ALL_WIN_LIN },
    { 'lwjgl-spvc',          { 'natives-linux', 'natives-linux-arm64', 'natives-windows', 'natives-windows-arm64' } },
    { 'lwjgl-stb',           ALL_WIN_LIN },
    { 'lwjgl-tinyexr',       ALL_WIN_LIN },
    { 'lwjgl-tinyfd',        ALL_WIN_LIN },
    { 'lwjgl-vma',           ALL_WIN_LIN },
    { 'lwjgl-xxhash',        ALL_WIN_LIN },
    { 'lwjgl-yoga',          ALL_WIN_LIN },
    { 'lwjgl-zstd',          ALL_WIN_LIN },
  }

  -- ── 5. Build the full <dependencies> block ─────────────────────────────────
  local dep_parts      = { '\n        <!-- LWJGL ' .. LWJGL_VERSION .. ' -->' }

  -- Compile entries (BOM resolves version)
  for _, mod in ipairs(BOM_MODULES) do
    dep_parts[#dep_parts + 1] = table.concat({
      '        <dependency>',
      '            <groupId>org.lwjgl</groupId>',
      '            <artifactId>' .. mod .. '</artifactId>',
      '        </dependency>',
    }, '\n')
  end

  -- Native classifier entries — explicit version required (BOM doesn't cover classifier artifacts).
  for _, entry in ipairs(NATIVE_MATRIX) do
    local mod, classifiers = entry[1], entry[2]
    for _, cls in ipairs(classifiers) do
      dep_parts[#dep_parts + 1] = table.concat({
        '        <dependency>',
        '            <groupId>org.lwjgl</groupId>',
        '            <artifactId>' .. mod .. '</artifactId>',
        '            <version>${lwjgl.version}</version>',
        '            <classifier>' .. cls .. '</classifier>',
        '            <scope>runtime</scope>',
        '        </dependency>',
      }, '\n')
    end
  end

  -- JOML
  dep_parts[#dep_parts + 1] = table.concat({
    '        <!-- JOML -->',
    '        <dependency>',
    '            <groupId>org.joml</groupId>',
    '            <artifactId>joml</artifactId>',
    '            <version>${joml.version}</version>',
    '        </dependency>',
  }, '\n')

  -- JOML Primitives
  dep_parts[#dep_parts + 1] = table.concat({
    '        <dependency>',
    '            <groupId>org.joml</groupId>',
    '            <artifactId>joml-primitives</artifactId>',
    '            <version>${joml-primitives.version}</version>',
    '        </dependency>',
  }, '\n')

  -- lwjgl3-awt
  dep_parts[#dep_parts + 1] = table.concat({
    '        <!-- LWJGL extras -->',
    '        <dependency>',
    '            <groupId>org.lwjglx</groupId>',
    '            <artifactId>lwjgl3-awt</artifactId>',
    '            <version>${lwjgl3-awt.version}</version>',
    '        </dependency>',
  }, '\n')

  -- steamworks4j
  dep_parts[#dep_parts + 1] = table.concat({
    '        <dependency>',
    '            <groupId>com.code-disaster.steamworks4j</groupId>',
    '            <artifactId>steamworks4j</artifactId>',
    '            <version>${steamworks4j.version}</version>',
    '        </dependency>',
  }, '\n')

  local all_deps = table.concat(dep_parts, '\n')

  -- Insert into the main <dependencies> block (the last one before </project>)
  local inserted = false
  content = content:gsub('(</dependencies>%s*\n?%s*</project>)', function(tail)
    inserted = true
    return all_deps .. '\n    ' .. tail
  end, 1)

  if not inserted then
    content = content:gsub('(</project>)',
      '    <dependencies>\n' .. all_deps .. '\n    </dependencies>\n%1', 1)
  end

  -- ── 6. Write & report ──────────────────────────────────────────────────────
  if write_pom(root, content) then
    det().reload()
    vim.notify(
      '[Marvin] ✅ LWJGL ' .. LWJGL_VERSION
      .. ' full suite added ('
      .. #BOM_MODULES .. ' modules + natives via profile + JOML + joml-primitives + lwjgl3-awt + steamworks4j)',
      vim.log.levels.INFO)
  end
end

-- ── Maven Shade plugin installer ──────────────────────────────────────────────
-- Adds maven-shade-plugin to <build><plugins> with:
--   • ServicesResourceTransformer   (merges META-INF/services — needed by LWJGL)
--   • ManifestResourceTransformer   (sets Main-Class if the user provides one)
--   • shade bound to the package phase
function M.add_maven_shade(root)
  root = root or det().root()
  if not root then return end

  local content = read_pom(root)
  if not content then
    vim.notify('[Marvin] No pom.xml found', vim.log.levels.ERROR); return
  end

  if content:find('<artifactId>maven%-shade%-plugin</artifactId>', 1, true) then
    vim.notify('[Marvin] maven-shade-plugin already in pom.xml', vim.log.levels.WARN); return
  end

  -- Ask for Main-Class (optional)
  ui().input({ prompt = 'Main-Class (leave blank to skip)' }, function(main_class)
    local manifest_block = ''
    if main_class and main_class ~= '' then
      manifest_block = table.concat({
        '                            <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">',
        '                                <mainClass>' .. main_class .. '</mainClass>',
        '                            </transformer>',
      }, '\n') .. '\n'
    end

    local plugin_xml = table.concat({
      '            <plugin>',
      '                <groupId>org.apache.maven.plugins</groupId>',
      '                <artifactId>maven-shade-plugin</artifactId>',
      '                <version>3.6.0</version>',
      '                <executions>',
      '                    <execution>',
      '                        <phase>package</phase>',
      '                        <goals><goal>shade</goal></goals>',
      '                        <configuration>',
      '                            <createDependencyReducedPom>false</createDependencyReducedPom>',
      '                            <transformers>',
      '                                <transformer implementation="org.apache.maven.plugins.shade.resource.ServicesResourceTransformer"/>',
      manifest_block ~= '' and manifest_block or '',
      '                            </transformers>',
      '                        </configuration>',
      '                    </execution>',
      '                </executions>',
      '            </plugin>',
    }, '\n')

    -- Insert into <build><plugins> if it exists, otherwise create the block
    local new, n = content:gsub('(<build>%s*<plugins>)', '%1\n' .. plugin_xml)
    if n == 0 then
      -- Try <build> without <plugins>
      new, n = content:gsub('(<build>)', '%1\n            <plugins>\n' .. plugin_xml .. '\n            </plugins>')
    end
    if n == 0 then
      -- No <build> at all — create it before </project>
      new = content:gsub('(</project>)',
        '    <build>\n        <plugins>\n' .. plugin_xml .. '\n        </plugins>\n    </build>\n%1', 1)
    end

    if write_pom(root, new) then
      det().reload()
      vim.notify('[Marvin] ✅ maven-shade-plugin 3.6.0 added (bound to package phase)', vim.log.levels.INFO)
    end
  end)
end

-- ── Convenience functions (called from lang/java.lua) ─────────────────────────
function M.set_java_version(ver, root)
  root = root or det().root()
  if not root then return end
  local content = read_pom(root)
  if not content then return end

  local function replace_or_add_prop(c, prop, val)
    local new, n = c:gsub('<' .. prop .. '>[^<]+</' .. prop .. '>', '<' .. prop .. '>' .. val .. '</' .. prop .. '>')
    if n > 0 then return new end
    -- Add to <properties>
    return c:gsub('(<properties>)', '%1\n        <' .. prop .. '>' .. val .. '</' .. prop .. '>')
  end

  local new = replace_or_add_prop(content, 'maven.compiler.source', ver)
  new = replace_or_add_prop(new, 'maven.compiler.target', ver)
  new = replace_or_add_prop(new, 'java.version', ver)
  write_pom(root, new)
  vim.notify('[Marvin] Java version → ' .. ver, vim.log.levels.INFO)
end

function M.set_encoding(enc, root)
  root = root or det().root()
  if not root then return end
  local content = read_pom(root)
  if not content then return end
  local new, n = content:gsub('<project%.build%.sourceEncoding>[^<]+</project%.build%.sourceEncoding>',
    '<project.build.sourceEncoding>' .. enc .. '</project.build.sourceEncoding>')
  if n == 0 then
    new = content:gsub('(<properties>)',
      '%1\n        <project.build.sourceEncoding>' .. enc .. '</project.build.sourceEncoding>')
  end
  write_pom(root, new)
  vim.notify('[Marvin] Encoding → ' .. enc, vim.log.levels.INFO)
end

function M.add_spotless(root)
  root = root or det().root()
  maven_insert_dep(root, 'com.diffplug.spotless', 'spotless-maven-plugin', '2.43.0', 'provided')
end

return M

```

### `lua/marvin/deps/rust.lua`

```lua
-- lua/marvin/deps/rust.lua
-- Rust dependency management via Cargo.
-- Actions: list, add, remove, update, outdated (cargo-outdated), audit (cargo-audit).

local M = {}

local function ui()  return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function run(cmd, root, title)
  require('core.runner').execute({
    cmd      = cmd, cwd = root, title = title,
    term_cfg = require('marvin').config.terminal,
    plugin   = 'marvin',
  })
end
local function plain(it) return it.label end

-- ── Known crate catalogue ─────────────────────────────────────────────────────
local CATALOGUE = {
  -- Async
  { name = 'tokio',       features = 'full',    label = 'Tokio',        desc = 'Async runtime' },
  { name = 'async-trait', features = nil,        label = 'async-trait',  desc = 'Async trait methods' },
  { name = 'futures',     features = nil,        label = 'futures',      desc = 'Async combinators' },
  -- Web
  { name = 'axum',        features = nil,        label = 'Axum',         desc = 'Web framework (Tower-based)' },
  { name = 'actix-web',   features = nil,        label = 'Actix-web',    desc = 'High-perf web framework' },
  { name = 'reqwest',     features = 'json',     label = 'Reqwest',      desc = 'HTTP client' },
  { name = 'hyper',       features = 'full',     label = 'Hyper',        desc = 'Low-level HTTP' },
  -- Serialisation
  { name = 'serde',       features = 'derive',   label = 'Serde',        desc = 'Serialisation framework' },
  { name = 'serde_json',  features = nil,        label = 'serde_json',   desc = 'JSON support' },
  { name = 'toml',        features = nil,        label = 'toml',         desc = 'TOML parsing' },
  -- Database
  { name = 'sqlx',        features = 'runtime-tokio,postgres,macros', label = 'SQLx', desc = 'Async SQL (Postgres/MySQL/SQLite)' },
  { name = 'diesel',      features = 'postgres', label = 'Diesel',       desc = 'ORM / query builder' },
  -- Error handling
  { name = 'anyhow',      features = nil,        label = 'anyhow',       desc = 'Flexible error handling' },
  { name = 'thiserror',   features = nil,        label = 'thiserror',    desc = 'Derive Error implementations' },
  -- CLI
  { name = 'clap',        features = 'derive',   label = 'clap',         desc = 'CLI argument parsing' },
  -- Logging
  { name = 'tracing',     features = nil,        label = 'tracing',      desc = 'Structured logging' },
  { name = 'tracing-subscriber', features = 'env-filter', label = 'tracing-subscriber', desc = 'Tracing output' },
  { name = 'log',         features = nil,        label = 'log',          desc = 'Logging facade' },
  { name = 'env_logger',  features = nil,        label = 'env_logger',   desc = 'Simple env-based logger' },
  -- Utilities
  { name = 'rayon',       features = nil,        label = 'rayon',        desc = 'Data parallelism' },
  { name = 'itertools',   features = nil,        label = 'itertools',    desc = 'Iterator extras' },
  { name = 'uuid',        features = 'v4,serde', label = 'uuid',         desc = 'UUID generation' },
  { name = 'chrono',      features = 'serde',    label = 'chrono',       desc = 'Date and time' },
  { name = 'rand',        features = nil,        label = 'rand',         desc = 'Random number generation' },
  -- Testing
  { name = 'mockall',     features = nil,        label = 'mockall',      desc = 'Mocking framework', dev = true },
  { name = 'criterion',   features = nil,        label = 'criterion',    desc = 'Benchmarking', dev = true },
  { name = 'proptest',    features = nil,        label = 'proptest',     desc = 'Property-based testing', dev = true },
  { name = 'tokio-test',  features = nil,        label = 'tokio-test',   desc = 'Tokio test utilities', dev = true },
}

-- ── Public API ────────────────────────────────────────────────────────────────

function M.menu_items()
  local items = {}
  local function add(t) items[#items + 1] = t end
  local function sep(l) add({ label = l, is_separator = true }) end
  local function it(id, icon, label, desc) add({ id=id, label=icon..' '..label, desc=desc }) end

  sep('Dependencies')
  it('dep_list',     '󰘦', 'View Dependencies',    'All crates in Cargo.toml')
  it('dep_add',      '󰐕', 'Add Crate…',           'cargo add from catalogue or manual entry')
  it('dep_add_dev',  '󰐕', 'Add Dev Crate…',       'cargo add --dev')
  it('dep_remove',   '󰍴', 'Remove Crate…',        'cargo remove')
  it('dep_update',   '󰚰', 'Update All',           'cargo update')
  it('dep_outdated', '󰦉', 'Check Outdated',       'cargo outdated (requires cargo-outdated)')

  sep('Security')
  it('dep_audit',    '󰒃', 'Vulnerability Audit',  'cargo audit (requires cargo-audit)')
  it('dep_audit_fix','󰒃', 'Audit + Auto-fix',     'cargo audit --fix')
  it('dep_deny',     '󰒃', 'Check Deny Rules',     'cargo deny check (requires cargo-deny)')

  sep('Workspace')
  local p = det().get()
  if p and p.info and p.info.is_workspace then
    it('ws_members', '󰙅', 'Workspace Members', 'List crates in workspace')
  end
  it('dep_tree', '󰙅', 'Dependency Tree', 'cargo tree')

  return items
end

function M.handle(id)
  local p = det().get()
  if not p then return end
  local root = p.root

  if id == 'dep_list' then
    M.show_dep_list(p)
  elseif id == 'dep_add' then
    M.show_add_menu(p, false)
  elseif id == 'dep_add_dev' then
    M.show_add_menu(p, true)
  elseif id == 'dep_remove' then
    M.show_remove_menu(p)
  elseif id == 'dep_update' then
    run('cargo update', root, 'Cargo Update')
  elseif id == 'dep_outdated' then
    run('cargo outdated', root, 'Outdated Crates')
  elseif id == 'dep_audit' then
    run('cargo audit', root, 'Cargo Audit')
  elseif id == 'dep_audit_fix' then
    run('cargo audit --fix', root, 'Cargo Audit Fix')
  elseif id == 'dep_deny' then
    run('cargo deny check', root, 'Cargo Deny')
  elseif id == 'dep_tree' then
    run('cargo tree', root, 'Dependency Tree')
  elseif id == 'ws_members' then
    M.show_workspace_members(p)
  end
end

function M.show_dep_list(p)
  local deps = (p.info and p.info.deps) or {}
  if #deps == 0 then
    vim.notify('[Marvin] No dependencies in Cargo.toml', vim.log.levels.INFO); return
  end
  local items = {}
  for _, d in ipairs(deps) do
    items[#items + 1] = {
      id    = d.name,
      label = d.name .. ' @ ' .. (d.version or '?'),
      desc  = d.dev and '[dev]' or '[dep]',
    }
  end
  ui().select(items, {
    prompt        = 'Cargo Dependencies (' .. #deps .. ')',
    enable_search = true,
    format_item   = plain,
  }, function(_) end)
end

function M.show_add_menu(p, is_dev)
  local cat_items = {}
  for _, c in ipairs(CATALOGUE) do
    -- For dev menu show all; for normal menu skip dev-only
    if is_dev or not c.dev then
      cat_items[#cat_items + 1] = {
        id = 'cat__' .. c.name,
        label = c.label,
        desc  = c.desc,
        _crate = c,
      }
    end
  end
  cat_items[#cat_items + 1] = {
    id = '__manual__', label = '󰏫 Enter crate name manually…', desc = 'name[@version]'
  }

  ui().select(cat_items, {
    prompt        = is_dev and 'Add Dev Dependency' or 'Add Dependency',
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then return end
    local dev_flag = is_dev and ' --dev' or ''
    if choice.id == '__manual__' then
      ui().input({ prompt = 'Crate name[@version]' }, function(name)
        if name and name ~= '' then
          run('cargo add' .. dev_flag .. ' ' .. name, p.root, 'Add ' .. name)
          vim.defer_fn(function() det().reload() end, 2000)
        end
      end)
    else
      local c = choice._crate
      local feat = c.features and (' --features ' .. c.features) or ''
      run('cargo add' .. dev_flag .. feat .. ' ' .. c.name, p.root, 'Add ' .. c.name)
      vim.defer_fn(function() det().reload() end, 2000)
    end
  end)
end

function M.show_remove_menu(p)
  local deps = (p.info and p.info.deps) or {}
  if #deps == 0 then
    vim.notify('[Marvin] No dependencies to remove', vim.log.levels.INFO); return
  end
  local items = {}
  for _, d in ipairs(deps) do
    items[#items + 1] = { id = d.name, label = d.name, desc = d.version or '?' }
  end
  ui().select(items, {
    prompt        = 'Remove Crate',
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then return end
    run('cargo remove ' .. choice.id, p.root, 'Remove ' .. choice.id)
    vim.defer_fn(function() det().reload() end, 2000)
  end)
end

function M.show_workspace_members(p)
  local members = (p.info and p.info.members) or {}
  if #members == 0 then
    vim.notify('[Marvin] No workspace members found', vim.log.levels.INFO); return
  end
  local items = {}
  for _, m in ipairs(members) do
    items[#items + 1] = { id = m, label = m, desc = p.root .. '/' .. m }
  end
  ui().select(items, {
    prompt      = 'Workspace Members',
    format_item = plain,
  }, function(choice)
    if choice then
      -- Switch active project to this member
      local member_root = p.root .. '/' .. choice.id
      local sub_info    = require('marvin.detector').detect_sub_projects(p.root)
      for _, sp in ipairs(sub_info or {}) do
        if sp.root == member_root then
          require('marvin.detector').set(sp)
          vim.notify('[Marvin] Switched to workspace member: ' .. choice.id, vim.log.levels.INFO)
          return
        end
      end
    end
  end)
end

return M

```

### `lua/marvin/detector.lua`

```lua
-- lua/marvin/detector.lua
-- Unified project detection and deep manifest parsing for Marvin + Jason.
-- Understands: Maven, Gradle, Cargo (+ workspaces), go.mod (+ go.work),
--              CMake, Meson, Makefile, and single-file fallback.

local M               = {}

M._project            = nil
M._sub_projects       = nil

-- ── Manifest markers ──────────────────────────────────────────────────────────
local MARKERS         = {
  maven    = { file = 'pom.xml', lang = 'java' },
  gradle   = { files = { 'build.gradle', 'build.gradle.kts' }, lang = 'java' },
  cargo    = { file = 'Cargo.toml', lang = 'rust' },
  go_mod   = { file = 'go.mod', lang = 'go' },
  cmake    = { file = 'CMakeLists.txt', lang = 'cpp' },
  meson    = { file = 'meson.build', lang = 'cpp' },
  makefile = { files = { 'Makefile', 'makefile' }, lang = 'cpp' },
}

local MARKER_PRIORITY = {
  'maven', 'gradle', 'cargo', 'go_mod', 'cmake', 'meson', 'makefile',
}

-- ── Tool availability ─────────────────────────────────────────────────────────
local TOOLS           = {
  maven    = { cmd = 'mvn', name = 'Maven', url = 'https://maven.apache.org/install.html' },
  gradle   = { cmd = 'gradle', name = 'Gradle', url = 'https://gradle.org/install/' },
  cargo    = { cmd = 'cargo', name = 'Cargo', url = 'https://rustup.rs' },
  go_mod   = { cmd = 'go', name = 'Go', url = 'https://go.dev/dl/' },
  cmake    = { cmd = 'cmake', name = 'CMake', url = 'https://cmake.org/download/' },
  meson    = { cmd = 'meson', name = 'Meson', url = 'pip install meson  OR  brew install meson' },
  makefile = { cmd = 'make', name = 'Make', url = 'sudo apt install build-essential' },
}

-- ── Low-level helpers ─────────────────────────────────────────────────────────
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

local function parse_pom(root)
  local content = read_file(root .. '/pom.xml')
  if not content then return {} end

  local function tag(t) return content:match('<' .. t .. '>(.-)</' .. t .. '>') end

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

  local profiles = {}
  for block in content:gmatch('<profile>(.-)</profile>') do
    local id = block:match('<id>(.-)</id>')
    if id then profiles[#profiles + 1] = id end
  end

  local modules = {}
  for m in content:gmatch('<module>(.-)</module>') do
    modules[#modules + 1] = m
  end

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

local function parse_gradle(root)
  local content = read_file(root .. '/build.gradle')
      or read_file(root .. '/build.gradle.kts')
  if not content then return { type = 'gradle', lang = 'java' } end

  local deps = {}
  for scope, coord in content:gmatch("(%w+)%s+['\"]([^'\"]+)['\"]") do
    local g, a, v = coord:match('([^:]+):([^:]+):?(.*)')
    if g and a then
      deps[#deps + 1] = {
        group    = g,
        artifact = a,
        version  = v ~= '' and v or 'dynamic',
        scope    = scope,
      }
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

local function parse_toml_section(content, section)
  local result     = {}
  local in_section = false
  for line in (content .. '\n'):gmatch('([^\n]*)\n') do
    local sec = line:match('^%[([^%]]+)%]')
    if sec then
      in_section = (sec == section or sec:match('^' .. vim.pesc(section)))
    elseif in_section then
      local k, v = line:match('^([%w_%-]+)%s*=%s*"([^"]*)"')
      if k then result[k] = v end
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

  local members  = {}
  local in_ws    = false
  for line in (content .. '\n'):gmatch('([^\n]*)\n') do
    if line:match('^%[workspace') then in_ws = true end
    if in_ws then
      local m = line:match('^%s*"([^"]+)"')
      if m then members[#members + 1] = m end
    end
    if in_ws and line:match('^%[') and not line:match('%[workspace') then
      in_ws = false
    end
  end

  local bins = {}
  for block in content:gmatch('%[%[bin%]%](.-)\n%[') do
    local n = block:match('name%s*=%s*"([^"]+)"')
    local p = block:match('path%s*=%s*"([^"]+)"')
    if n then bins[#bins + 1] = { name = n, path = p } end
  end

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

local function parse_go_mod(root)
  local content = read_file(root .. '/go.mod')
  if not content then return { type = 'go_mod', lang = 'go' } end

  local module = content:match('^module%s+(%S+)')
  local go_ver = content:match('\ngo%s+(%S+)')
  local deps   = {}

  for block in content:gmatch('require%s*%((.-)%)') do
    for path, ver in block:gmatch('%s+(%S+)%s+(%S+)') do
      if not path:match('^//') then
        deps[#deps + 1] = {
          path     = path,
          version  = ver,
          indirect = block:match(path .. '.+// indirect') ~= nil,
        }
      end
    end
  end
  for path, ver in content:gmatch('\nrequire%s+(%S+)%s+(%S+)') do
    deps[#deps + 1] = { path = path, version = ver, indirect = false }
  end
  table.sort(deps, function(a, b) return a.path < b.path end)

  local work_content   = read_file(root .. '/go.work')
  local workspace_uses = {}
  if work_content then
    for u in work_content:gmatch('\nuse%s+(%S+)') do
      workspace_uses[#workspace_uses + 1] = u
    end
  end

  local cmds    = {}
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

local function parse_meson(root)
  local content = read_file(root .. '/meson.build')
  if not content then
    return {
      type       = 'meson',
      lang       = 'cpp',
      name       = vim.fn.fnamemodify(root, ':t'),
      version    = '0.1.0',
      configured = false,
    }
  end

  local name       = content:match("project%s*%(%s*'([^']+)'")
      or content:match('project%s*%(%s*"([^"]+)"')
      or vim.fn.fnamemodify(root, ':t')

  local version    = content:match("version%s*:%s*'([^']+)'")
      or content:match('version%s*:%s*"([^"]+)"')
      or '0.1.0'

  local lang_raw   = content:match("project%s*%([^,]+,%s*'([^']+)'")
      or content:match('project%s*%([^,]+,%s*"([^"]+)"')
  local lang       = (lang_raw == 'c') and 'c' or 'cpp'

  local std        = content:match("'[c+]+_std=([^']+)'")
      or content:match('"[c+]+_std=([^"]+)"')

  local configured = vim.fn.isdirectory(root .. '/builddir') == 1
      or vim.fn.isdirectory(root .. '/build') == 1

  local dep_names  = {}
  for dep in content:gmatch("dependency%s*%(%s*'([^']+)'") do
    dep_names[#dep_names + 1] = dep
  end
  for dep in content:gmatch('dependency%s*%(%s*"([^"]+)"') do
    dep_names[#dep_names + 1] = dep
  end

  return {
    type       = 'meson',
    lang       = lang,
    name       = name,
    version    = version,
    std        = std,
    deps       = dep_names,
    configured = configured,
  }
end

-- ── Detection core ────────────────────────────────────────────────────────────

local function parse_manifest(root, ptype)
  if ptype == 'maven' then return parse_pom(root) end
  if ptype == 'gradle' then return parse_gradle(root) end
  if ptype == 'cargo' then return parse_cargo(root) end
  if ptype == 'go_mod' then return parse_go_mod(root) end
  if ptype == 'meson' then return parse_meson(root) end
  return { type = ptype, lang = MARKERS[ptype] and MARKERS[ptype].lang or 'unknown' }
end

function M.detect()
  local buf_name = vim.api.nvim_buf_get_name(0)
  local cwd      = vim.fn.fnamemodify(vim.fn.getcwd(), ':p'):gsub('/+$', '')

  -- Resolve the buffer's directory only when it points at a real file on disk.
  local buf_dir  = (buf_name ~= '' and vim.fn.filereadable(buf_name) == 1)
      and vim.fn.fnamemodify(buf_name, ':p:h'):gsub('/+$', '')
      or nil

  -- Start the upward walk from whichever candidate is deeper.
  -- e.g. cwd = /project, buf_dir = /project/src  → start from /project/src
  -- so the walk passes through /project and finds meson.build there.
  -- If buf_dir is outside cwd entirely, still prefer buf_dir.
  local curr
  if buf_dir then
    if buf_dir:sub(1, #cwd) == cwd then
      -- buf_dir is inside cwd — it's always deeper or equal, use it
      curr = buf_dir
    else
      -- buf_dir is outside cwd (e.g. editing a file from another tree) —
      -- try buf_dir first; if it finds nothing the walk reaches fs root and
      -- we fall through to single_file anyway
      curr = buf_dir
    end
  else
    curr = cwd
  end

  local dir  = curr
  local prev = nil

  while dir ~= '' and dir ~= prev do
    for _, ptype in ipairs(MARKER_PRIORITY) do
      local marker = MARKERS[ptype]
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

-- Never serve a cached single_file result — it is always a last-resort
-- fallback and must be re-evaluated when the active buffer changes.
-- Real project types (meson, cmake, cargo, …) are stable and stay cached.
function M.get()
  if M._project and M._project.type ~= 'single_file' then
    return M._project
  end
  return M.detect()
end

function M.reload()
  if not M._project then return M.detect() end
  M._project.info = parse_manifest(M._project.root, M._project.type)
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
        for _, ptype in ipairs(MARKER_PRIORITY) do
          local marker = MARKERS[ptype]
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

```

### `lua/marvin/executor.lua`

```lua
-- lua/marvin/executor.lua
-- Marvin side: Maven execution via  M.run(goal, options).
-- Jason side:  Multi-language build actions live in  marvin.build  (separate
--              module below).  This file re-exports a backwards-compat shim
--              so any code that did  require('jason.executor')  can be pointed
--              at  require('marvin.build')  instead.

local M = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- MARVIN — Maven executor
-- ══════════════════════════════════════════════════════════════════════════════

function M.run(goal, options)
  options = options or {}

  local project = require('marvin.project')
  if not project.validate_environment() then return end
  local proj = project.get()
  if not proj then
    vim.notify('No Maven project found', vim.log.levels.ERROR); return
  end

  local config = require('marvin').config
  local parts  = { config.maven_command }
  if options.profile then parts[#parts + 1] = '-P' .. options.profile end
  parts[#parts + 1] = goal
  local cmd = table.concat(parts, ' ')

  require('core.runner').execute({
    cmd       = cmd,
    cwd       = proj.root,
    title     = 'mvn ' .. goal,
    term_cfg  = config.terminal,
    plugin    = 'marvin',
    action_id = 'mvn_' .. goal:gsub('%s+', '_'),
  })
end

function M.stop() require('core.runner').stop_last() end

return M

```

### `lua/marvin/generator.lua`

```lua
-- lua/marvin/generator.lua
local M = {}

local function ui() return require('marvin.ui') end

function M.create_project()
  M.scan_local_archetypes()
end

function M.scan_local_archetypes()
  ui().notify('Scanning local Maven repository…', vim.log.levels.INFO)

  local home             = os.getenv('HOME') or os.getenv('USERPROFILE')
  local m2_repo          = home .. '/.m2/repository'
  local cmd              = string.format(
    'find "%s" -type f -name "*archetype*.jar" 2>/dev/null | grep -v "maven-archetype-plugin"',
    m2_repo)

  local archetypes, seen = {}, {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= '' then
          local parts    = vim.split(line, '/')
          local repo_idx = nil
          for i, p in ipairs(parts) do
            if p == 'repository' then
              repo_idx = i; break
            end
          end
          if repo_idx and #parts >= repo_idx + 3 then
            local version     = parts[#parts - 1]
            local artifact_id = parts[#parts - 2]
            local gparts      = {}
            for i = repo_idx + 1, #parts - 3 do gparts[#gparts + 1] = parts[i] end
            local group_id = table.concat(gparts, '.')
            if group_id ~= '' and artifact_id ~= '' and version ~= '' then
              local key = group_id .. ':' .. artifact_id .. ':' .. version
              if not seen[key] then
                seen[key] = true
                archetypes[#archetypes + 1] = {
                  group_id    = group_id,
                  artifact_id = artifact_id,
                  version     = version,
                  label       = artifact_id,
                  desc        = 'v' .. version .. '  ' .. group_id,
                }
              end
            end
          end
        end
      end
    end,
    on_exit = function()
      vim.schedule(function()
        if #archetypes == 0 then
          ui().notify('No local archetypes found in ' .. m2_repo, vim.log.levels.WARN)
        else
          M.show_archetype_menu(archetypes)
        end
      end)
    end,
  })
end

-- ── Archetype picker ──────────────────────────────────────────────────────────
function M.show_archetype_menu(archetypes)
  local items = {}
  for _, a in ipairs(archetypes) do
    items[#items + 1] = {
      label      = a.label,
      desc       = a.desc,
      icon       = '󰏗',
      _archetype = a,
    }
  end

  ui().select(items, {
    prompt        = 'New Maven Project  — Select Archetype',
    enable_search = true,
    format_item   = function(it) return it.label end,
  }, function(choice)
    if choice then M.show_project_wizard(choice._archetype) end
  end)
end

-- ── Project wizard ────────────────────────────────────────────────────────────
function M.show_project_wizard(archetype)
  local details = {
    group_id    = 'com.example',
    artifact_id = 'my-app',
    version     = '1.0-SNAPSHOT',
  }

  local function ask_version()
    ui().input({ prompt = '󰏷 Version', default = details.version }, function(v)
      if not v then return end
      details.version = v
      M.confirm_and_generate(archetype, details)
    end)
  end

  local function ask_artifact()
    ui().input({ prompt = '󰏗 Artifact ID', default = details.artifact_id }, function(a)
      if not a then return end
      details.artifact_id = a
      ask_version()
    end)
  end

  ui().input({ prompt = '󰬷 Group ID', default = details.group_id }, function(g)
    if not g then return end
    details.group_id = g
    ask_artifact()
  end)
end

-- ── Confirmation / edit menu ──────────────────────────────────────────────────
function M.confirm_and_generate(archetype, details)
  local coord = details.group_id .. ':' .. details.artifact_id .. ':' .. details.version

  ui().select({
    { id = 'confirm', icon = '󰄬', label = 'Generate Project', desc = coord },
    { id = 'edit_group', icon = '󰬷', label = 'Change Group ID', desc = details.group_id },
    { id = 'edit_artifact', icon = '󰏗', label = 'Change Artifact ID', desc = details.artifact_id },
    { id = 'edit_version', icon = '󰏷', label = 'Change Version', desc = details.version },
    { id = 'cancel', icon = '󰅖', label = 'Cancel', desc = '' },
  }, {
    prompt      = 'New Maven Project  — ' .. archetype.artifact_id .. ' v' .. archetype.version,
    on_back     = function() M.show_archetype_menu_cached(archetype) end,
    format_item = function(it) return it.label end,
  }, function(choice)
    if not choice or choice.id == 'cancel' then return end

    if choice.id == 'confirm' then
      ui().input({ prompt = '󰉋 Output Directory', default = vim.fn.getcwd() }, function(dir)
        if dir then M.generate_project(archetype, details, dir) end
      end)
    elseif choice.id == 'edit_group' then
      ui().input({ prompt = '󰬷 Group ID', default = details.group_id }, function(v)
        if v then details.group_id = v end
        M.confirm_and_generate(archetype, details)
      end)
    elseif choice.id == 'edit_artifact' then
      ui().input({ prompt = '󰏗 Artifact ID', default = details.artifact_id }, function(v)
        if v then details.artifact_id = v end
        M.confirm_and_generate(archetype, details)
      end)
    elseif choice.id == 'edit_version' then
      ui().input({ prompt = '󰏷 Version', default = details.version }, function(v)
        if v then details.version = v end
        M.confirm_and_generate(archetype, details)
      end)
    end
  end)
end

-- ── Maven execution ───────────────────────────────────────────────────────────
function M.generate_project(archetype, details, directory)
  local config = require('marvin').config
  local cmd    = string.format(
    '%s archetype:generate -B ' ..
    '-DarchetypeGroupId=%s -DarchetypeArtifactId=%s -DarchetypeVersion=%s ' ..
    '-DgroupId=%s -DartifactId=%s -Dversion=%s -Dpackage=%s',
    config.maven_command,
    archetype.group_id, archetype.artifact_id, archetype.version,
    details.group_id, details.artifact_id, details.version, details.group_id)

  ui().notify('Generating ' .. details.artifact_id .. '…', vim.log.levels.INFO)

  local output = {}
  vim.fn.jobstart(cmd, {
    cwd             = directory,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout       = function(_, data)
      for _, l in ipairs(data) do if l ~= '' then output[#output + 1] = l end end
    end,
    on_stderr       = function(_, data)
      for _, l in ipairs(data) do if l ~= '' then output[#output + 1] = l end end
    end,
    on_exit         = function(_, code)
      vim.schedule(function()
        if code == 0 then
          local proj_path = directory .. '/' .. details.artifact_id
          M.fix_eclipse_files(proj_path, details.version)
          ui().notify('✅ Project created: ' .. details.artifact_id, vim.log.levels.INFO)

          ui().select({
            { id = 'yes', icon = '󰄬', label = 'Open project', desc = proj_path },
            { id = 'no', icon = '󰅖', label = 'Stay here', desc = '' },
          }, {
            prompt      = 'Project ready!',
            format_item = function(it) return it.label end,
          }, function(choice)
            if choice and choice.id == 'yes' then
              vim.cmd('cd ' .. vim.fn.fnameescape(proj_path))
              vim.cmd('edit ' .. vim.fn.fnameescape(proj_path .. '/pom.xml'))
            end
          end)
        else
          ui().notify('❌ Generation failed (exit ' .. code .. ')', vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

-- ── Eclipse fix ───────────────────────────────────────────────────────────────
function M.fix_eclipse_files(project_path, version)
  for _, fp in ipairs({ project_path .. '/.classpath', project_path .. '/.project' }) do
    if vim.fn.filereadable(fp) == 1 then
      local lines, fixed = vim.fn.readfile(fp), false
      for i, line in ipairs(lines) do
        if line:match('<?xml version="' .. vim.pesc(version) .. '"') then
          lines[i] = line:gsub(vim.pesc(version), '1.0'); fixed = true
        end
      end
      if fixed then vim.fn.writefile(lines, fp) end
    end
  end
end

return M

```

### `lua/marvin/graalvm.lua`

```lua
-- lua/marvin/graalvm.lua
-- GraalVM native-image helpers (was jason.graalvm).

local M = {}

function M.is_graalvm()
  local java_home = os.getenv('JAVA_HOME') or ''
  if java_home:lower():match('graal') then return true end
  if os.getenv('GRAALVM_HOME') then return true end
  local out = vim.trim(vim.fn.system('java -version 2>&1'))
  return out:lower():match('graalvm') ~= nil
end

function M.graalvm_home()
  return os.getenv('GRAALVM_HOME')
      or os.getenv('JAVA_HOME')
      or vim.trim(vim.fn.system("dirname $(dirname $(readlink -f $(which java))) 2>/dev/null"))
end

function M.native_image_bin()
  local home = M.graalvm_home()
  local candidates = {
    home .. '/bin/native-image',
    home .. '/lib/svm/bin/native-image',
    vim.trim(vim.fn.system('which native-image 2>/dev/null')),
  }
  for _, p in ipairs(candidates) do
    if p ~= '' and vim.fn.executable(p) == 1 then return p end
  end
  return nil
end

function M.gu_bin()
  local home = M.graalvm_home()
  local p = home .. '/bin/gu'
  if vim.fn.executable(p) == 1 then return p end
  local wp = vim.trim(vim.fn.system('which gu 2>/dev/null'))
  if wp ~= '' and vim.fn.executable(wp) == 1 then return wp end
  return nil
end

local defaults = {
  extra_build_args = '',
  output_dir       = 'target/native',
  no_fallback      = true,
  g1gc             = false,
  pgo              = 'none',
  report_size      = true,
  agent_output_dir = 'src/main/resources/META-INF/native-image',
}

function M.get_config()
  local ok, marvin = pcall(require, 'marvin')
  if ok and marvin.config and marvin.config.graalvm then
    return vim.tbl_deep_extend('force', defaults, marvin.config.graalvm)
  end
  return defaults
end

function M.native_image_cmd_maven(_project)
  local cfg   = M.get_config()
  local parts = { 'mvn -Pnative native:compile' }
  if cfg.extra_build_args ~= '' then
    parts[#parts + 1] = '-Dnative.image.buildArgs="' .. cfg.extra_build_args .. '"'
  end
  return table.concat(parts, ' ')
end

function M.native_image_cmd_gradle(_project)
  local cfg   = M.get_config()
  local parts = { './gradlew nativeCompile' }
  if cfg.extra_build_args ~= '' then
    parts[#parts + 1] = '-PnativeBuildArgs="' .. cfg.extra_build_args .. '"'
  end
  return table.concat(parts, ' ')
end

function M.native_image_cmd_jar(project)
  local cfg = M.get_config()
  local bin = M.native_image_bin()
  if not bin then return nil, 'native-image not found – run: gu install native-image' end

  local jar = M.find_jar(project)
  if not jar then return nil, 'No JAR found – run Build first' end

  local base = vim.fn.fnamemodify(jar, ':t:r')
  local out  = (cfg.output_dir ~= '' and (project.root .. '/' .. cfg.output_dir .. '/') or '') .. base
  local args = { bin, '-jar', vim.fn.shellescape(jar), '-o', vim.fn.shellescape(out) }

  if cfg.no_fallback then args[#args + 1] = '--no-fallback' end
  if cfg.g1gc then args[#args + 1] = '--gc=G1' end
  if cfg.report_size then args[#args + 1] = '-H:+PrintAnalysisCallTree' end

  if cfg.pgo == 'instrument' then
    args[#args + 1] = '--pgo-instrument'
  elseif cfg.pgo == 'optimize' then
    args[#args + 1] = '--pgo'
  end

  if cfg.extra_build_args ~= '' then args[#args + 1] = cfg.extra_build_args end
  return table.concat(args, ' '), nil
end

function M.find_native_binary(project)
  local cfg  = M.get_config()
  local dirs = {
    project.root .. '/' .. cfg.output_dir,
    project.root .. '/target',
    project.root .. '/build/native/nativeCompile',
    project.root .. '/build',
  }
  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      local handle = io.popen(
        'find ' .. vim.fn.shellescape(dir) ..
        ' -maxdepth 2 -type f -executable ! -name "*.so" ! -name "*.dylib" 2>/dev/null | head -1')
      if handle then
        local p = handle:read('*l'); handle:close()
        if p and p ~= '' then return p end
      end
    end
  end
  return nil
end

function M.find_jar(project)
  local dirs = { project.root .. '/target', project.root .. '/build/libs' }
  local best = nil
  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      for _, j in ipairs(vim.fn.globpath(dir, '*.jar', false, true)) do
        if j:match('%-all%.jar') or j:match('%-shaded%.jar') or j:match('%-fat%.jar') then
          return j
        end
        if not j:match('%-sources%.jar') and not j:match('%-javadoc%.jar') then
          best = j
        end
      end
    end
  end
  return best
end

-- ── High-level actions ────────────────────────────────────────────────────────
function M.build_native(project)
  local ex = require('marvin.build')
  local cmd, err

  if project.type == 'maven' then
    cmd = M.native_image_cmd_maven(project)
  elseif project.type == 'gradle' then
    cmd = M.native_image_cmd_gradle(project)
  else
    cmd, err = M.native_image_cmd_jar(project)
  end

  if err then
    vim.notify('[GraalVM] ' .. err, vim.log.levels.ERROR); return
  end

  local cfg    = M.get_config()
  local outdir = project.root .. '/' .. cfg.output_dir
  vim.fn.mkdir(outdir, 'p')
  ex.execute(cmd, project.root, 'Native Image')
end

function M.run_native(project)
  local ex  = require('marvin.build')
  local bin = M.find_native_binary(project)
  if not bin then
    vim.notify('[GraalVM] Native binary not found – build it first', vim.log.levels.WARN); return
  end
  ex.execute(vim.fn.shellescape(bin), project.root, 'Run Native')
end

function M.build_and_run_native(project)
  local ex  = require('marvin.build')
  local cfg = M.get_config()
  local build_cmd, err

  if project.type == 'maven' then
    build_cmd = M.native_image_cmd_maven(project)
  elseif project.type == 'gradle' then
    build_cmd = M.native_image_cmd_gradle(project)
  else
    build_cmd, err = M.native_image_cmd_jar(project)
  end

  if err then
    vim.notify('[GraalVM] ' .. err, vim.log.levels.ERROR); return
  end

  vim.fn.mkdir(project.root .. '/' .. cfg.output_dir, 'p')
  ex.execute_sequence({
    { cmd = build_cmd, title = 'Native Image Build' },
    {
      cmd = 'sh -c ' .. vim.fn.shellescape(
        'BIN=$(find ' .. vim.fn.shellescape(project.root) ..
        ' -maxdepth 4 -type f -executable ! -name "*.so" ! -name "*.dylib"' ..
        ' -newer ' .. vim.fn.shellescape(project.root) .. '/pom.xml 2>/dev/null | head -1); ' ..
        'test -n "$BIN" && exec "$BIN" || echo "Binary not found" >&2 && exit 1'),
      title = 'Run Native',
    },
  }, project.root)
end

function M.run_with_agent(project)
  local ex  = require('marvin.build')
  local cfg = M.get_config()
  local jar = M.find_jar(project)
  if not jar then
    vim.notify('[GraalVM] No JAR found – build the project first', vim.log.levels.WARN); return
  end
  local agent_dir = project.root .. '/' .. cfg.agent_output_dir
  vim.fn.mkdir(agent_dir, 'p')
  local cmd = string.format(
    'java -agentlib:native-image-agent=config-output-dir=%s -jar %s',
    vim.fn.shellescape(agent_dir), vim.fn.shellescape(jar))
  ex.execute(cmd, project.root, 'Agent Run')
  vim.notify('[GraalVM] Agent config → ' .. agent_dir, vim.log.levels.INFO)
end

function M.show_info()
  local lines       = { '', '  GraalVM Status', '  ' .. string.rep('─', 32), '' }
  local ni_bin      = M.native_image_bin()
  local gu_b        = M.gu_bin()
  local gvm         = M.is_graalvm()
  local home        = M.graalvm_home()

  lines[#lines + 1] = string.format('  %-22s %s', 'Active GraalVM:', gvm and '✔' or '✗ (not detected)')
  lines[#lines + 1] = string.format('  %-22s %s', 'GRAALVM_HOME:', home ~= '' and home or '(not set)')
  lines[#lines + 1] = string.format('  %-22s %s', 'native-image:', ni_bin or '✗ not installed')
  lines[#lines + 1] = string.format('  %-22s %s', 'gu (updater):', gu_b or '✗ not found')
  lines[#lines + 1] = ''

  if not ni_bin then
    lines[#lines + 1] = '  To install native-image:'
    lines[#lines + 1] = '    gu install native-image'
    lines[#lines + 1] = '  or with SDKMAN:'
    lines[#lines + 1] = '    sdk install java <graalvm-version>'
    lines[#lines + 1] = ''
  end

  local cfg = M.get_config()
  lines[#lines + 1] = '  Config'
  lines[#lines + 1] = '  ' .. string.rep('─', 32)
  lines[#lines + 1] = string.format('  %-22s %s', 'no_fallback:', tostring(cfg.no_fallback))
  lines[#lines + 1] = string.format('  %-22s %s', 'pgo:', cfg.pgo)
  lines[#lines + 1] = string.format('  %-22s %s', 'g1gc:', tostring(cfg.g1gc))
  lines[#lines + 1] = string.format('  %-22s %s', 'output_dir:', cfg.output_dir)
  lines[#lines + 1] = string.format('  %-22s %s', 'agent_output_dir:', cfg.agent_output_dir)
  lines[#lines + 1] = ''

  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

function M.install_native_image(project)
  local ex = require('marvin.build')
  local gu = M.gu_bin()
  if not gu then
    vim.notify('[GraalVM] gu not found – is GraalVM in PATH?', vim.log.levels.ERROR); return
  end
  ex.execute(gu .. ' install native-image',
    project and project.root or vim.fn.getcwd(), 'Install native-image')
end

return M

```

### `lua/marvin/init.lua`

```lua
-- lua/marvin/init.lua
-- Plugin entry point. Call require('marvin').setup(opts) in your config.

local M = {}

M.config = {}

function M.setup(opts)
  M.config = require('marvin.config').setup(opts)

  -- ── Initialise UI (highlights) ───────────────────────────────────────────
  -- We require ui first, then call init(M.config) passing config as a
  -- parameter so ui.lua never has to require('marvin') back while we are
  -- still inside setup() — doing so would be a circular require and
  -- return a partially-constructed module where M.init is still nil.
  local ui = require('marvin.ui')
  ui.init(M.config)

  -- ── Autocommands ────────────────────────────────────────────────────────────
  local group = vim.api.nvim_create_augroup('Marvin', { clear = true })

  -- Re-detect project whenever we enter a relevant buffer
  vim.api.nvim_create_autocmd({ 'BufEnter', 'DirChanged' }, {
    group    = group,
    pattern  = {
      '*.java', '*.kt', '*.xml', '*.rs', '*.toml', '*.go', '*.mod',
      'pom.xml', 'Cargo.toml', 'go.mod', 'build.gradle', 'build.gradle.kts',
    },
    callback = function()
      require('marvin.detector')._project = nil
    end,
  })

  -- Set makeprg / errorformat for the current buffer's language
  vim.api.nvim_create_autocmd({ 'BufEnter', 'FileType' }, {
    group    = group,
    pattern  = { '*.java', '*.rs', '*.go', '*.c', '*.cpp', '*.h', '*.hpp' },
    callback = function()
      local ok, compiler = pcall(require, 'marvin.compiler')
      if ok then compiler.setup_buf() end
    end,
  })

  -- ── Keymaps ─────────────────────────────────────────────────────────────────
  local ok_km, km = pcall(require, 'marvin.keymaps')
  if ok_km then km.register(M.config.keymaps) end

  -- ── Commands ────────────────────────────────────────────────────────────────
  local ok_cmd, cmds = pcall(require, 'marvin.commands')
  if ok_cmd then cmds.register() end
end

return M

```

### `lua/marvin/jason_dashboard.lua`

```lua
-- lua/marvin/jason_dashboard.lua
-- Jason task-runner dashboard. Purely focused on build/run/test/package operations.
-- Project management (deps, file creation, settings) lives in marvin.dashboard.
-- Accessed via :Jason, <leader>j, or from within Marvin dashboard.

local M = {}

local function plain(it) return it.label end
local function sep(l) return { label = l, is_separator = true } end
local function item(id, icon, label, desc)
  return { id = id, _icon = icon, label = label, desc = desc }
end

local function ui() return require('marvin.ui') end
local function bld() return require('marvin.build') end
local function det() return require('marvin.detector') end

-- ── Language/tool metadata ────────────────────────────────────────────────────
local META = {
  maven = {
    label = 'Maven',
    lang = 'Java',
    icon = '󰬷',
    has = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, test_filter = 1 },
  },
  gradle = {
    label = 'Gradle',
    lang = 'Java',
    icon = '󰏗',
    has = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, test_filter = 1 },
  },
  cargo = {
    label = 'Cargo',
    lang = 'Rust',
    icon = '󱘗',
    has = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, fmt = 1, lint = 1, test_filter = 1 },
  },
  go_mod = {
    label = 'Go',
    lang = 'Go',
    icon = '󰟓',
    has = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, fmt = 1, lint = 1, test_filter = 1 },
  },
  cmake = {
    label = 'CMake',
    lang = 'C/C++',
    icon = '󰙲',
    has = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, fmt = 1, lint = 1, build_system = 1, package_lib = 1 },
  },
  meson = {
    label = 'Meson',
    lang  = 'C/C++',
    icon  = '󰒓',
    has   = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, fmt = 1, lint = 1, build_system = 1, package_lib = 1 },
  },
  makefile = {
    label = 'Make',
    lang = 'C/C++',
    icon = '󰙱',
    has = { build = 1, run = 1, test = 1, clean = 1, build_run = 1, package = 1, install = 1, fmt = 1, lint = 1, build_system = 1, package_lib = 1 },
  },
  single_file = {
    label = 'Single File',
    lang = nil,
    icon = '󰈙',
    has = { build = 1, run = 1, clean = 1, build_run = 1 },
  },
}

-- ── Language-specific extras ──────────────────────────────────────────────────
local EXTRAS = {
  cargo = function(_p)
    local profile = require('marvin').config.rust.profile
    return {
      sep('Rust'),
      item('j_rust_profile', '󰒓',
        'Toggle Profile (' .. profile .. ')',
        'Currently: ' .. profile .. ' → switch to ' .. (profile == 'release' and 'dev' or 'release')),
      item('j_clippy', '󰅾', 'Clippy', 'cargo clippy — lint'),
      item('j_bench', '󰙨', 'Benchmark', 'cargo bench'),
      item('j_doc', '󰈙', 'Doc', 'cargo doc --open'),
    }
  end,
  go_mod = function(_p)
    return {
      sep('Go'),
      item('j_go_race', '󰍉', 'Test (race)', 'go test -race ./...'),
      item('j_go_cover', '󰙨', 'Test + Coverage', 'go test -cover ./...'),
      item('j_go_vet', '󰅾', 'Vet', 'go vet ./...'),
      item('j_go_doc', '󰈙', 'godoc', 'godoc -http=:6060'),
    }
  end,
  cmake = function(p)
    local configured = vim.fn.isdirectory(p.root .. '/build') == 1
    return {
      sep('CMake'),
      item('j_cmake_cfg', '󰒓', configured and 'Re-configure' or 'Configure', 'cmake -B build -S .'),
      item('j_cpp_info', '󰙅', 'C/C++ Project Info', 'Auto-detected binary, flags, links'),
      item('j_build_file', '󰐊', 'Build Current File', 'Compile active buffer with auto-flags'),
    }
  end,
  meson = function(p)
    local configured = vim.fn.isdirectory(p.root .. '/builddir') == 1
        or vim.fn.isdirectory(p.root .. '/build') == 1
    return {
      sep('Meson'),
      item('j_meson_setup', '󰒓',
        configured and 'Re-configure (--reconfigure)' or 'Setup builddir',
        configured and 'meson setup --reconfigure builddir' or 'meson setup builddir'),
      item('j_cpp_info', '󰙅', 'C/C++ Project Info', 'Auto-detected binary, flags, links'),
      item('j_build_file', '󰐊', 'Build Current File', 'Compile active buffer with auto-flags'),
      item('j_meson_introspect', '󰙅', 'Introspect…', 'meson introspect subcommands'),
    }
  end,
  makefile = function(_p)
    return {
      sep('C/C++'),
      item('j_cpp_info', '󰙅', 'C/C++ Project Info', 'Auto-detected binary, flags, links'),
      item('j_build_file', '󰐊', 'Build Current File', 'Compile active buffer with auto-flags'),
    }
  end,
  maven = function(_p)
    return {
      sep('GraalVM'),
      item('j_graal_build', '󰂮', 'Build Native Image', 'Compile to native binary'),
      item('j_graal_run', '󰐊', 'Run Native Binary', 'Execute native build'),
      item('j_graal_agent', '󰋊', 'Run with Agent', 'Collect reflection config'),
      item('j_graal_info', '󰙅', 'GraalVM Info', 'Status / install guide'),
    }
  end,
  gradle = function(p) return EXTRAS.maven(p) end,
}

-- ── Dashboard ─────────────────────────────────────────────────────────────────
function M.show()
  local p         = det().get()
  local meta      = p and META[p.type]
  local has       = (meta and meta.has) or {}
  local tool      = meta and meta.label or 'No Project'
  local lang      = meta and (meta.lang or (p and p.lang) or '') or ''
  local pname     = p and p.name or '(no project)'
  local icon      = meta and meta.icon or '󰙅'

  local is_single = p and p.type == 'single_file'
  local prompt    = is_single
      and string.format('Jason  %s %s  %s  [%s]  — use Build System to create meson/cmake/make',
        icon, tool, pname, lang)
      or string.format('Jason  %s %s  %s  [%s]', icon, tool, pname, lang)
  local items     = M._build_items(p, meta, has)

  ui().select(items, {
    prompt        = prompt,
    enable_search = true,
    format_item   = function(it)
      if it.is_separator then return it.label end
      return (it._icon and (it._icon .. ' ') or '') .. it.label
    end,
  }, function(choice)
    if choice then M._handle(choice.id, p, meta) end
  end)
end

-- ── Item builder ──────────────────────────────────────────────────────────────
function M._build_items(p, meta, has)
  local items = {}
  local function add(t) items[#items + 1] = t end
  local function addall(t) for _, v in ipairs(t) do add(v) end end

  local tool = meta and meta.label or 'Actions'

  -- Core actions
  add(sep(tool .. ' Actions'))
  if has.build_run then add(item('j_build_run', '󰑓', 'Build & Run', 'Compile then run')) end
  if has.build then add(item('j_build', '󰑕', 'Build', 'Compile')) end
  if has.run then add(item('j_run', '󰐊', 'Run', 'Run')) end
  if has.test then add(item('j_test', '󰙨', 'Test', 'Run tests')) end
  if has.clean then add(item('j_clean', '󰃢', 'Clean', 'Remove artifacts')) end

  -- With options
  if has.build or has.run or has.test_filter then
    add(sep('With Options'))
    if has.build then add(item('j_build_args', '󰒓', 'Build (args…)', 'Extra build flags')) end
    if has.run then add(item('j_run_args', '󰒓', 'Run (args…)', 'Runtime arguments')) end
    if has.test_filter then add(item('j_test_filter', '󰍉', 'Test (filter…)', 'Specific test name')) end
  end

  -- Extras
  if has.fmt or has.lint or has.package or has.install then
    add(sep('Extras'))
    if has.fmt then add(item('j_fmt', '󰉣', 'Format', 'Auto-format')) end
    if has.lint then add(item('j_lint', '󰅾', 'Lint', 'Run linter')) end
    if has.package then add(item('j_package', '󰏗', 'Package', 'Create distributable')) end
    if has.install then add(item('j_install', '󰇚', 'Install', 'Install to local registry')) end
  end

  -- Package as Library (C/C++ only)
  if has.package_lib then
    add(sep('Library'))
    add(item('j_package_lib', '󰘦', 'Package as Library…',
      'Build .a + copy headers → lib/ for use as #include'))
  end

  -- Language-specific extras
  if p then
    local extras_fn = EXTRAS[p.type]
    if extras_fn then addall(extras_fn(p)) end
  end

  -- Build System submenu (C/C++ + no-project fallback)
  if has.build_system or not p or (p and p.type == 'single_file') then
    add(sep('Build System'))
    add(item('j_build_system_menu', '󰈙', 'Build System…',
      'Makefile, CMakeLists.txt, meson.build, compile_commands.json'))
  end

  -- Custom .jason.lua tasks
  if p then
    local ok, tasks_m = pcall(require, 'marvin.tasks')
    if ok then
      local tasks = tasks_m.load(p.root)
      if tasks and #tasks > 0 then
        add(sep('Tasks (.jason.lua)'))
        for _, t in ipairs(tasks_m.to_menu_items(tasks)) do
          items[#items + 1] = vim.tbl_extend('force', t, { _icon = t.icon })
        end
      end
    end
  end

  -- Monorepo
  if p then
    local subs = det().detect_sub_projects(vim.fn.getcwd())
    if subs and #subs > 1 then
      add(sep('Monorepo'))
      add(item('j_switch', '󰙅', 'Switch Sub-project…', #subs .. ' projects found'))
    end
  end

  add(sep('Console'))
  add(item('j_console', '󰋚', 'Task Console', 'View output history'))

  return items
end

-- ── Build System submenu ──────────────────────────────────────────────────────
function M.show_build_system_menu(p)
  local root         = p and p.root or vim.fn.getcwd()
  local has_makefile = vim.fn.filereadable(root .. '/Makefile') == 1
  local has_cmake    = vim.fn.filereadable(root .. '/CMakeLists.txt') == 1
  local has_meson    = vim.fn.filereadable(root .. '/meson.build') == 1
  local has_ccmd     = vim.fn.filereadable(root .. '/compile_commands.json') == 1

  local function exists_tag(flag) return flag and '  (exists)' or '' end

  local items = {
    {
      id    = 'j_new_makefile',
      label = '󰈙 ' .. (has_makefile and 'Regenerate' or 'New') .. ' Makefile' .. exists_tag(has_makefile),
      desc  = 'Interactive wizard — C, C++, Go, Rust, Generic',
    },
    {
      id    = 'j_new_cmake',
      label = '󰒓 ' .. (has_cmake and 'Regenerate' or 'New') .. ' CMakeLists.txt' .. exists_tag(has_cmake),
      desc  = 'Interactive CMake wizard with auto-link detection',
    },
    {
      id    = 'j_new_meson',
      label = '󰒓 ' .. (has_meson and 'Regenerate' or 'New') .. ' meson.build' .. exists_tag(has_meson),
      desc  = 'Interactive Meson wizard with auto-link detection',
    },
    {
      id    = 'j_gen_compile_commands',
      label = '󰘦 Generate compile_commands.json' .. exists_tag(has_ccmd),
      desc  = 'For clangd — via cmake, meson, bear, or compiledb',
    },
  }

  ui().select(items, {
    prompt      = 'Build System',
    on_back     = M.show,
    format_item = plain,
  }, function(ch)
    if ch then M._handle(ch.id, p, nil) end
  end)
end

-- ── compile_commands generator ────────────────────────────────────────────────
function M.show_compile_commands_menu(p)
  local root           = p and p.root or vim.fn.getcwd()
  local has_cmake_file = vim.fn.filereadable(root .. '/CMakeLists.txt') == 1
  local has_meson_file = vim.fn.filereadable(root .. '/meson.build') == 1
  local has_make_file  = vim.fn.filereadable(root .. '/Makefile') == 1
  local has_bear       = vim.fn.executable('bear') == 1
  local has_compdb     = vim.fn.executable('compiledb') == 1
  local has_cmake_bin  = vim.fn.executable('cmake') == 1
  local has_meson_bin  = vim.fn.executable('meson') == 1

  local items          = {}
  local function add(t) items[#items + 1] = t end

  if has_meson_file and has_meson_bin then
    add({
      id = 'ccmd_meson',
      label = '󰒓 Meson  (recommended for Meson projects)',
      desc =
      'meson setup builddir — compile_commands.json generated automatically'
    })
  end
  if has_cmake_file and has_cmake_bin then
    add({
      id = 'ccmd_cmake',
      label = '󰒓 CMake  (recommended)',
      desc =
      'cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -S .'
    })
  end
  if has_bear then
    if has_make_file then
      add({ id = 'ccmd_bear_make', label = '󰈙 bear + make', desc = 'bear -- make' })
    end
    add({ id = 'ccmd_bear_custom', label = '󰈙 bear + custom command…', desc = 'bear -- <cmd>' })
  end
  if has_compdb and has_make_file then
    add({ id = 'ccmd_compiledb', label = '󰘦 compiledb', desc = 'compiledb make' })
  end
  add({
    id = 'ccmd_clangd_file',
    label = '󰄬 Write .clangd config',
    desc =
    'No build needed — adds -Iinclude flags for clangd'
  })
  if #items == 1 then
    add({ id = 'ccmd_install_hint', label = '󰋖 How to install bear / compiledb', desc = 'Show installation instructions' })
  end

  ui().select(items, {
    prompt      = 'Generate compile_commands.json',
    on_back     = function() M.show_build_system_menu(p) end,
    format_item = plain,
  }, function(ch)
    if ch then M._handle(ch.id, p, nil) end
  end)
end

-- ── Meson introspect submenu ──────────────────────────────────────────────────
function M.show_meson_introspect_menu(p)
  local root  = p and p.root or vim.fn.getcwd()
  local items = {
    { id = 'mi_targets', label = '󰙅 Targets', desc = 'meson introspect --targets' },
    { id = 'mi_deps', label = '󰘦 Dependencies', desc = 'meson introspect --dependencies' },
    { id = 'mi_buildopts', label = '󰒓 Build Options', desc = 'meson introspect --buildoptions' },
    { id = 'mi_tests', label = '󰙨 Tests', desc = 'meson introspect --tests' },
    { id = 'mi_compilers', label = '󰙲 Compilers', desc = 'meson introspect --compilers' },
    { id = 'mi_installed', label = '󰇚 Installed Files', desc = 'meson introspect --installed' },
  }

  ui().select(items, {
    prompt      = 'Meson Introspect',
    on_back     = function() M.show() end,
    format_item = plain,
  }, function(ch)
    if not ch then return end
    local subcmds = {
      mi_targets   = '--targets',
      mi_deps      = '--dependencies',
      mi_buildopts = '--buildoptions',
      mi_tests     = '--tests',
      mi_compilers = '--compilers',
      mi_installed = '--installed',
    }
    local flag = subcmds[ch.id]
    if flag then
      local bdir = vim.fn.isdirectory(root .. '/builddir') == 1 and 'builddir' or 'build'
      require('core.runner').execute({
        cmd      = 'meson introspect ' .. bdir .. ' ' .. flag,
        cwd      = root,
        title    = 'Meson Introspect ' .. flag,
        term_cfg = require('marvin').config.terminal,
        plugin   = 'marvin',
      })
    end
  end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- PACKAGE AS LIBRARY WIZARD
-- ══════════════════════════════════════════════════════════════════════════════

function M.show_package_lib_wizard(p)
  local root         = p and p.root or vim.fn.getcwd()
  local default_name = vim.fn.fnamemodify(root, ':t'):gsub('-', '_')

  ui().input({ prompt = '󰘦 Library name', default = default_name }, function(name)
    if not name or name == '' then return end
    name = name:gsub('^lib', '')

    ui().select({
      { id = 'include', label = 'include/', desc = root .. '/include  (recommended)' },
      { id = 'src', label = 'src/  (*.h only)', desc = 'Headers alongside sources' },
      { id = 'root', label = '. (root *.h)', desc = 'Headers at project root' },
      { id = 'custom', label = '󰏫 Custom…', desc = 'Enter header directory path' },
    }, { prompt = 'Public header directory', format_item = plain }, function(hdr_ch)
      if not hdr_ch then return end

      local function after_hdr(hdr_dir)
        ui().select({
          { id = 'lib', label = 'lib/  (project-local)', desc = root .. '/lib/lib' .. name .. '.a' },
          { id = 'home_lib', label = '~/.local/lib', desc = vim.fn.expand('~/.local/lib') },
          { id = 'custom', label = '󰏫 Custom…', desc = 'Enter destination root' },
        }, { prompt = 'Export destination', format_item = plain }, function(dest_ch)
          if not dest_ch then return end

          local function after_dest(dest_root)
            ui().select({
              { id = 'c11',   label = 'C11' },
              { id = 'c17',   label = 'C17' },
              { id = 'c++17', label = 'C++17' },
              { id = 'c++20', label = 'C++20' },
            }, { prompt = 'Language standard', format_item = plain }, function(std_ch)
              local std = std_ch and std_ch.id or 'c11'

              ui().input({
                prompt  = 'Extra CFLAGS (optional)',
                default = '-Wall -Wextra -O2',
              }, function(cflags)
                M._do_package_lib({
                  name      = name,
                  root      = root,
                  hdr_dir   = hdr_dir,
                  dest_root = dest_root,
                  std       = std,
                  cflags    = cflags or '-Wall -Wextra -O2',
                })
              end)
            end)
          end

          if dest_ch.id == 'lib' then
            after_dest(root .. '/lib')
          elseif dest_ch.id == 'home_lib' then
            after_dest(vim.fn.expand('~/.local/lib'))
          else
            ui().input({ prompt = 'Destination directory', default = root .. '/lib' }, function(d)
              if d and d ~= '' then after_dest(d) end
            end)
          end
        end)
      end

      if hdr_ch.id == 'custom' then
        ui().input({ prompt = 'Header directory', default = root .. '/include' }, function(d)
          if d and d ~= '' then after_hdr(d) end
        end)
      elseif hdr_ch.id == 'src' then
        after_hdr(root .. '/src')
      elseif hdr_ch.id == 'root' then
        after_hdr(root)
      else
        after_hdr(root .. '/include')
      end
    end)
  end)
end

function M._do_package_lib(opts)
  local name      = opts.name
  local root      = opts.root
  local hdr_dir   = opts.hdr_dir
  local dest_root = opts.dest_root
  local std       = opts.std or 'c11'
  local cflags    = opts.cflags or '-Wall -Wextra -O2'

  local has_cpp   = std:find('+') ~= nil
  local cc        = has_cpp and 'g++' or 'gcc'
  local std_flag  = '-std=' .. std

  local src_ext   = has_cpp and [[-name '*.cpp' -o -name '*.cxx' -o -name '*.cc']] or [[-name '*.c']]
  local src_cmd   = string.format(
    "find '%s' \\( %s \\) -not -path '*/.marvin-obj/*' -not -path '*/lib/*' -type f 2>/dev/null | sort",
    root:gsub("'", "'\\''"), src_ext)

  local sources   = {}
  local h         = io.popen(src_cmd)
  if h then
    for line in h:lines() do
      local t = vim.trim(line)
      if t ~= '' then sources[#sources + 1] = t end
    end
    h:close()
  end

  if #sources == 0 then
    vim.notify('[Marvin] No sources found in ' .. root .. ' for packaging.', vim.log.levels.ERROR)
    return
  end

  local obj_dir   = root .. '/.marvin-obj-lib-' .. name
  local archive   = dest_root .. '/lib' .. name .. '.a'
  local inc_dest  = dest_root .. '/include/' .. name

  local inc_flags = {}
  for _, d in ipairs({ root .. '/include', root .. '/src', root }) do
    if vim.fn.isdirectory(d) == 1 then
      inc_flags[#inc_flags + 1] = '-I' .. d
    end
  end
  local ok_ll, ll = pcall(require, 'marvin.local_libs')
  if ok_ll then
    local lf = ll.build_flags(root)
    if lf.iflags ~= '' then
      for _, f in ipairs(vim.split(lf.iflags, '%s+')) do
        if f ~= '' then inc_flags[#inc_flags + 1] = f end
      end
    end
  end
  local inc_str = table.concat(inc_flags, ' ')

  local function esc(s) return vim.fn.shellescape(tostring(s)) end
  local function sh(s) return "'" .. s:gsub("'", "'\\''") .. "'" end

  local steps = {
    'mkdir -p ' .. esc(obj_dir),
    'mkdir -p ' .. esc(dest_root),
    'mkdir -p ' .. esc(inc_dest),
  }

  local obj_files = {}
  for _, src in ipairs(sources) do
    local stem                = vim.fn.fnamemodify(src, ':t:r')
    local obj                 = obj_dir .. '/' .. stem .. '.o'
    obj_files[#obj_files + 1] = obj
    steps[#steps + 1]         = string.format(
      '%s %s %s %s -c %s -o %s',
      cc, std_flag, cflags, inc_str, esc(src), esc(obj))
  end

  steps[#steps + 1] = string.format('ar rcs %s %s',
    esc(archive),
    table.concat(vim.tbl_map(esc, obj_files), ' '))

  steps[#steps + 1] = 'ranlib ' .. esc(archive) .. ' 2>/dev/null || true'

  if vim.fn.isdirectory(hdr_dir) == 1 then
    steps[#steps + 1] = string.format(
      "find %s -maxdepth 2 \\( -name '*.h' -o -name '*.hpp' -o -name '*.hxx' \\) -exec cp {} %s/ \\;",
      sh(hdr_dir), sh(inc_dest))
  else
    vim.notify('[Marvin] Header directory not found: ' .. hdr_dir
      .. '\nLibrary will be built without headers.', vim.log.levels.WARN)
  end

  steps[#steps + 1] = 'rm -rf ' .. esc(obj_dir)

  local cmd = table.concat(steps, ' && \\\n  ')

  require('core.runner').execute({
    cmd      = cmd,
    cwd      = root,
    title    = 'Package lib' .. name .. '.a',
    term_cfg = require('marvin').config.terminal,
    plugin   = 'marvin',
    on_exit  = function(ok)
      if not ok then
        vim.notify('[Marvin] ❌ Library packaging failed.', vim.log.levels.ERROR)
        return
      end

      local summary = string.format(
        '[Marvin] ✅ Packaged lib%s\n'
        .. '  Archive : %s\n'
        .. '  Headers : %s\n\n'
        .. '  To use in another project:\n'
        .. '    gcc main.c -I%s/include -L%s -l%s -o app\n'
        .. '    #include <%s/foo.h>',
        name, archive, inc_dest,
        dest_root, dest_root, name, name)
      vim.notify(summary, vim.log.levels.INFO)

      vim.schedule(function()
        M._offer_register_lib(root, dest_root, name)
      end)
    end,
  })
end

function M._offer_register_lib(root, dest_root, name)
  ui().select({
    { id = 'yes', label = '󰐕 Yes — register "' .. vim.fn.fnamemodify(dest_root, ':~:.') .. '" as library search path' },
    { id = 'no', label = '󰅖 No thanks' },
  }, { prompt = 'Register for auto-discovery?', format_item = plain }, function(ch)
    if not ch or ch.id == 'no' then return end
    local ok, ll = pcall(require, 'marvin.local_libs')
    if not ok then return end
    ll.show_register_after_export(root, dest_root)
  end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- ACTION HANDLER
-- ══════════════════════════════════════════════════════════════════════════════

function M._handle(id, p, meta)
  local b    = bld()
  local root = p and p.root or vim.fn.getcwd()

  local function run(cmd, title, on_exit)
    require('core.runner').execute({
      cmd      = cmd,
      cwd      = root,
      title    = title,
      term_cfg = require('marvin').config.terminal,
      plugin   = 'marvin',
      on_exit  = on_exit,
    })
  end

  -- ── Package as Library ────────────────────────────────────────────────────
  if id == 'j_package_lib' then
    M.show_package_lib_wizard(p)

    -- ── Core build actions ────────────────────────────────────────────────────
  elseif id == 'j_build' then
    b.build()
  elseif id == 'j_run' then
    b.run()
  elseif id == 'j_test' then
    b.test()
  elseif id == 'j_clean' then
    b.clean()
  elseif id == 'j_build_run' then
    b.build_and_run()
  elseif id == 'j_build_args' then
    b.build(true)
  elseif id == 'j_run_args' then
    b.run(true)
  elseif id == 'j_test_filter' then
    b.test(true)
  elseif id == 'j_fmt' then
    b.fmt()
  elseif id == 'j_lint' then
    b.lint()
  elseif id == 'j_package' then
    b.package()
  elseif id == 'j_install' then
    b.install()
  elseif id == 'j_console' then
    require('marvin.console').toggle()
  elseif id == 'j_switch' then
    require('marvin.dashboard').show_project_picker()

    -- ── Build system submenu ──────────────────────────────────────────────────
  elseif id == 'j_build_system_menu' then
    M.show_build_system_menu(p)
  elseif id == 'j_new_cmake' then
    require('marvin.cmake_creator').create(root, function()
      det().set(nil)
      M.show_build_system_menu(det().get())
    end)
  elseif id == 'j_new_makefile' then
    require('marvin.makefile_creator').create(root, function()
      det().set(nil)
      M.show_build_system_menu(det().get())
    end)
  elseif id == 'j_new_meson' then
    require('marvin.meson_creator').create(root, function()
      -- Invalidate the cached project so the next detect() finds meson.build
      det().set(nil)
      M.show_build_system_menu(det().get())
    end)
  elseif id == 'j_gen_compile_commands' then
    M.show_compile_commands_menu(p)

    -- ── Meson-specific ────────────────────────────────────────────────────────
  elseif id == 'j_meson_setup' then
    local configured = vim.fn.isdirectory(root .. '/builddir') == 1
        or vim.fn.isdirectory(root .. '/build') == 1
    local cmd = configured
        and 'meson setup --reconfigure builddir'
        or 'meson setup builddir'
    run(cmd, 'Meson Setup', function(ok)
      if ok then
        -- Symlink compile_commands.json to root for clangd
        vim.defer_fn(function()
          local src = root .. '/builddir/compile_commands.json'
          local dst = root .. '/compile_commands.json'
          if vim.fn.filereadable(src) == 1 and vim.fn.filereadable(dst) == 0 then
            vim.fn.system('ln -sf ' .. vim.fn.shellescape(src) .. ' ' .. vim.fn.shellescape(dst))
            vim.notify('[Marvin] compile_commands.json symlinked from builddir.\nRun :LspRestart',
              vim.log.levels.INFO)
          end
        end, 800)
      end
    end)
  elseif id == 'j_meson_introspect' then
    M.show_meson_introspect_menu(p)

    -- ── compile_commands methods ──────────────────────────────────────────────
  elseif id == 'ccmd_meson' then
    run('meson setup builddir', 'Meson Setup (compile_commands)', function(ok)
      if not ok then return end
      vim.defer_fn(function()
        local src = root .. '/builddir/compile_commands.json'
        local dst = root .. '/compile_commands.json'
        if vim.fn.filereadable(src) == 1 then
          vim.fn.system('ln -sf ' .. vim.fn.shellescape(src) .. ' ' .. vim.fn.shellescape(dst))
          vim.notify('[Jason] compile_commands.json ready.\nRun :LspRestart', vim.log.levels.INFO)
        end
      end, 800)
    end)
  elseif id == 'ccmd_cmake' then
    run('cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
      'Generate compile_commands.json',
      function(ok)
        if not ok then return end
        vim.defer_fn(function()
          local src = root .. '/build/compile_commands.json'
          local dst = root .. '/compile_commands.json'
          if vim.fn.filereadable(src) == 1 then
            vim.fn.system('ln -sf ' .. vim.fn.shellescape(src) .. ' ' .. vim.fn.shellescape(dst))
            vim.notify('[Jason] compile_commands.json ready.\nRun :LspRestart', vim.log.levels.INFO)
          end
        end, 500)
      end)
  elseif id == 'ccmd_bear_make' then
    run('bear -- make', 'bear + make', function(ok)
      if ok then vim.notify('[Jason] compile_commands.json written.\nRun :LspRestart', vim.log.levels.INFO) end
    end)
  elseif id == 'ccmd_bear_custom' then
    ui().input({ prompt = 'Build command for bear', default = 'make' }, function(cmd)
      if cmd and cmd ~= '' then
        run('bear -- ' .. cmd, 'bear + ' .. cmd, function(ok)
          if ok then vim.notify('[Jason] compile_commands.json written.\nRun :LspRestart', vim.log.levels.INFO) end
        end)
      end
    end)
  elseif id == 'ccmd_compiledb' then
    run('compiledb make', 'compiledb', function(ok)
      if ok then vim.notify('[Jason] compile_commands.json written.\nRun :LspRestart', vim.log.levels.INFO) end
    end)
  elseif id == 'ccmd_clangd_file' then
    local inc_flags = {}
    for _, d in ipairs({ 'include', 'src', '.' }) do
      if vim.fn.isdirectory(root .. '/' .. d) == 1 then
        inc_flags[#inc_flags + 1] = '-I' .. d
      end
    end
    local ok_ll, ll = pcall(require, 'marvin.local_libs')
    if ok_ll then
      local lf = ll.build_flags(root)
      if lf.iflags ~= '' then
        for _, f in ipairs(vim.split(lf.iflags, '%s+')) do
          if f ~= '' then inc_flags[#inc_flags + 1] = f end
        end
      end
    end
    local cfg   = require('marvin').config.cpp or {}
    local std   = cfg.standard or 'c11'
    local lang  = (cfg.compiler == 'g++' or cfg.compiler == 'clang++') and 'c++' or 'c'
    local flags = {}
    for _, f in ipairs(inc_flags) do flags[#flags + 1] = f end
    flags[#flags + 1] = '-std=' .. std
    flags[#flags + 1] = '-x'
    flags[#flags + 1] = lang
    local content     = 'CompileFlags:\n  Add: [' .. table.concat(flags, ', ') .. ']\n'
    local path        = root .. '/.clangd'
    local function write_clangd()
      local f = io.open(path, 'w')
      if f then
        f:write(content); f:close()
        vim.cmd('edit ' .. vim.fn.fnameescape(path))
        vim.notify('[Jason] .clangd written.\nRun :LspRestart', vim.log.levels.INFO)
      end
    end
    if vim.fn.filereadable(path) == 1 then
      ui().select({
          { id = 'overwrite', label = 'Overwrite existing .clangd' },
          { id = 'cancel',    label = 'Cancel' },
        }, { prompt = '.clangd already exists', format_item = plain },
        function(ch) if ch and ch.id == 'overwrite' then write_clangd() end end)
    else
      write_clangd()
    end
  elseif id == 'ccmd_install_hint' then
    vim.api.nvim_echo({ { table.concat({
      '',
      '  Install bear (wraps any build system):',
      '    Ubuntu/Debian : sudo apt install bear',
      '    macOS         : brew install bear',
      '    Arch          : sudo pacman -S bear',
      '',
      '  Install compiledb (Make-based projects):',
      '    pip install compiledb',
      '',
      '  Meson generates compile_commands.json automatically:',
      '    meson setup builddir',
      '    ln -sf builddir/compile_commands.json .',
      '',
      '  Or use CMake:',
      '    cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
      '    ln -sf build/compile_commands.json .',
      '',
    }, '\n'), 'Normal' } }, true, {})

    -- ── C/C++ tools ───────────────────────────────────────────────────────────
  elseif id == 'j_cpp_info' then
    require('marvin.build').show_cpp_info()
  elseif id == 'j_build_file' then
    require('marvin.build').build_current_file()
  elseif id == 'j_cmake_cfg' then
    run('cmake -B build -S .', 'CMake Configure')

    -- ── Rust extras ───────────────────────────────────────────────────────────
  elseif id == 'j_rust_profile' then
    local cfg = require('marvin').config
    cfg.rust.profile = cfg.rust.profile == 'release' and 'dev' or 'release'
    vim.notify('[Jason] Rust profile → ' .. cfg.rust.profile, vim.log.levels.INFO)
    vim.schedule(M.show)
  elseif id == 'j_clippy' then
    b.custom('cargo clippy', 'Clippy')
  elseif id == 'j_bench' then
    b.custom('cargo bench', 'Bench')
  elseif id == 'j_doc' then
    b.custom('cargo doc --open', 'Doc')

    -- ── Go extras ─────────────────────────────────────────────────────────────
  elseif id == 'j_go_race' then
    b.custom('go test -race ./...', 'Test (race)')
  elseif id == 'j_go_cover' then
    b.custom('go test -cover -coverprofile=coverage.out ./...', 'Test + Cover')
  elseif id == 'j_go_vet' then
    b.custom('go vet ./...', 'Vet')
  elseif id == 'j_go_doc' then
    b.custom('godoc -http=:6060', 'godoc')

    -- ── GraalVM ───────────────────────────────────────────────────────────────
  elseif id == 'j_graal_build' then
    require('marvin.graalvm').build_native(p)
  elseif id == 'j_graal_run' then
    require('marvin.graalvm').run_native(p)
  elseif id == 'j_graal_agent' then
    require('marvin.graalvm').run_with_agent(p)
  elseif id == 'j_graal_info' then
    require('marvin.graalvm').show_info()
  else
    -- Custom .jason.lua task
    local ok, tasks_m = pcall(require, 'marvin.tasks')
    if ok and p then tasks_m.handle_action(id, p) end
  end
end

return M

```

### `lua/marvin/java_creator.lua`

```lua
-- lua/marvin/java_creator.lua
local M = {}

local function scan_packages()
  local project = require('marvin.project').get()
  if not project then return {} end

  local packages = {}
  local src_paths = {
    { path = project.root .. '/src/main/java', type = 'main' },
    { path = project.root .. '/src/test/java', type = 'test' },
  }

  for _, src_info in ipairs(src_paths) do
    if vim.fn.isdirectory(src_info.path) == 1 then
      local cmd = string.format('find "%s" -type d -not -path "*/\\.*" 2>/dev/null', src_info.path)
      local handle = io.popen(cmd)
      if handle then
        for dir in handle:lines() do
          if dir ~= src_info.path then
            local package = dir:gsub(vim.pesc(src_info.path) .. '/', ''):gsub('/', '.')
            if package ~= '' then
              if not packages[package] then
                packages[package] = { name = package, types = {}, file_count = 0 }
              end
              packages[package].types[src_info.type] = true
              local java_files = vim.fn.glob(dir .. '/*.java', false, true)
              packages[package].file_count = packages[package].file_count + #java_files
            end
          end
        end
        handle:close()
      end
    end
  end

  local package_list = {}
  for _, pkg_info in pairs(packages) do
    package_list[#package_list + 1] = pkg_info
  end
  table.sort(package_list, function(a, b)
    local ad = select(2, a.name:gsub('%.', '.'))
    local bd = select(2, b.name:gsub('%.', '.'))
    if ad == bd then return a.name < b.name end
    return ad < bd
  end)
  return package_list
end

local function get_package_depth(name)
  return select(2, name:gsub('%.', '.'))
end

-- ── Package selector ──────────────────────────────────────────────────────────
-- on_back: called when user presses <BS> — should re-open the file-type menu.
function M.select_package(callback, on_back)
  local templates = require('marvin.templates')
  local ui        = require('marvin.ui')
  local packages  = scan_packages()
  local cur_pkg   = templates.get_package_from_path()
  local def_pkg   = cur_pkg or templates.get_default_package()
  local items     = {}
  local function add(t) items[#items + 1] = t end

  add({ label = 'Current Location', is_separator = true })
  if cur_pkg then
    add({ value = cur_pkg, label = cur_pkg, icon = '󰉋', desc = 'Current file location' })
  end
  if def_pkg ~= cur_pkg then
    add({ value = def_pkg, label = def_pkg, icon = '󱂵', desc = 'Project default package' })
  end

  add({ label = 'Quick Actions', is_separator = true })
  add({ value = '__CREATE_NEW__', label = 'Create New Package', icon = '󰜄', desc = 'Enter custom package name' })
  if cur_pkg then
    add({ value = '__CREATE_SUB__', label = 'Create Subpackage', icon = '󰉋', desc = 'Create under ' .. cur_pkg })
  end

  if #packages > 0 then
    local root_pkgs, sub_pkgs = {}, {}
    for _, pkg in ipairs(packages) do
      if pkg.name ~= cur_pkg and pkg.name ~= def_pkg then
        if get_package_depth(pkg.name) == 0 then
          root_pkgs[#root_pkgs + 1] = pkg
        else
          sub_pkgs[#sub_pkgs + 1] = pkg
        end
      end
    end

    if #root_pkgs > 0 then
      add({ label = 'Root Packages', is_separator = true })
      for _, pkg in ipairs(root_pkgs) do
        local ti = (pkg.types.main and pkg.types.test) and 'main + test'
            or pkg.types.main and 'main' or 'test'
        add({
          value = pkg.name,
          label = pkg.name,
          icon = '󰏗',
          desc = string.format('%d files * %s', pkg.file_count, ti),
        })
      end
    end

    if #sub_pkgs > 0 then
      add({ label = 'Subpackages', is_separator = true })
      for _, pkg in ipairs(sub_pkgs) do
        local depth  = get_package_depth(pkg.name)
        local indent = string.rep('  ', depth - 1)
        local ti     = (pkg.types.main and pkg.types.test) and 'main + test'
            or pkg.types.main and 'main' or 'test'
        local segs   = {}
        for s in pkg.name:gmatch('[^.]+') do segs[#segs + 1] = s end
        add({
          value = pkg.name,
          label = indent .. '`- ' .. segs[#segs],
          icon  = '󰉓',
          desc  = string.format('%s * %d files', ti, pkg.file_count),
        })
      end
    end
  end

  ui.select(items, {
    prompt        = 'Select Package',
    enable_search = true,
    on_back       = on_back, -- <BS> goes back to file-type menu
    format_item   = function(it) return it.label end,
  }, function(choice)
    if not choice then
      callback(nil); return
    end

    if choice.value == '__CREATE_NEW__' then
      vim.cmd('stopinsert')
      vim.schedule(function()
        ui.input({ prompt = 'New Package Name', default = def_pkg }, function(pkg)
          callback(pkg ~= '' and pkg or nil)
        end)
      end)
    elseif choice.value == '__CREATE_SUB__' then
      vim.cmd('stopinsert')
      vim.schedule(function()
        ui.input({ prompt = 'Subpackage Name', default = cur_pkg .. '.' }, function(pkg)
          callback(pkg ~= '' and pkg or nil)
        end)
      end)
    else
      vim.cmd('stopinsert')
      vim.schedule(function() callback(choice.value) end)
    end
  end)
end

-- ── File creation wizard ──────────────────────────────────────────────────────
-- menu_on_back: passed through from show_menu so <BS> in the package picker
-- re-opens the file-type menu rather than closing entirely.
function M.create_file_interactive(type_name, options, menu_on_back)
  options         = options or {}
  local templates = require('marvin.templates')
  local ui        = require('marvin.ui')

  ui.input({ prompt = '󰬷 ' .. type_name .. ' Name' }, function(class_name)
    if not class_name or class_name == '' then return end
    vim.cmd('stopinsert')
    vim.schedule(function()
      -- on_back from the package picker reopens the file-type menu
      M.select_package(function(package_name)
        if not package_name then return end

        local lines
        if type_name == 'Class' then
          lines = templates.class_template(class_name, package_name, options)
        elseif type_name == 'Interface' then
          lines = templates.interface_template(class_name, package_name, options)
        elseif type_name == 'Enum' then
          lines = templates.enum_template(class_name, package_name, options)
        elseif type_name == 'Record' then
          lines = templates.record_template(class_name, package_name, options)
        elseif type_name == 'Abstract Class' then
          lines = templates.abstract_class_template(class_name, package_name, options)
        elseif type_name == 'Exception' then
          lines = templates.exception_template(class_name, package_name, options)
        elseif type_name == 'Test' then
          lines = templates.test_template(class_name, package_name, options)
        elseif type_name == 'Builder' then
          lines = templates.builder_template(class_name, package_name, options)
        end

        if not lines then
          vim.notify('Unknown type: ' .. type_name, vim.log.levels.ERROR); return
        end

        local file_path = M.get_file_path(class_name, package_name, type_name)
        if not file_path then return end

        vim.fn.mkdir(vim.fn.fnamemodify(file_path, ':h'), 'p')
        M.write_file(file_path, lines)
        vim.cmd('edit ' .. file_path)
        ui.notify('󰄬 Created ' .. type_name .. ': ' .. class_name, vim.log.levels.INFO)
      end, function()
        -- <BS> in package picker → back to file-type menu
        M.show_menu(menu_on_back)
      end)
    end)
  end)
end

function M.get_file_path(class_name, package_name, type_name)
  local project = require('marvin.project').get()
  if not project then
    vim.notify('Not in a Maven project', vim.log.levels.ERROR); return nil
  end
  local base = type_name == 'Test'
      and project.root .. '/src/test/java/'
      or project.root .. '/src/main/java/'
  return base .. package_name:gsub('%.', '/') .. '/' .. class_name .. '.java'
end

function M.write_file(file_path, lines)
  local file = io.open(file_path, 'w')
  if not file then
    vim.notify('Failed to create file: ' .. file_path, vim.log.levels.ERROR); return
  end
  for _, line in ipairs(lines) do file:write(line .. '\n') end
  file:close()
end

function M.prompt_enum_values(callback)
  require('marvin.ui').input({
    prompt  = '󰒻 Enum Values (comma-separated)',
    default = 'VALUE1, VALUE2, VALUE3',
  }, function(input)
    if not input or input == '' then
      callback(nil); return
    end
    local values = {}
    for v in input:gmatch('[^,]+') do values[#values + 1] = vim.trim(v):upper() end
    callback(values)
  end)
end

function M.prompt_fields(callback, prompt_text)
  require('marvin.ui').input({
    prompt  = prompt_text or '󰠱 Fields (Type name, ...)',
    default = 'String name, int value',
  }, function(input)
    if not input or input == '' then
      callback(nil); return
    end
    local fields = {}
    for fd in input:gmatch('[^,]+') do
      local tn, fn = vim.trim(fd):match('(%S+)%s+(%S+)')
      if tn and fn then fields[#fields + 1] = { type = tn, name = fn } end
    end
    callback(#fields > 0 and fields or nil)
  end)
end

-- ── File-type menu ────────────────────────────────────────────────────────────
-- on_back: called when user presses <BS> — should re-open whatever called this
-- (e.g. the Marvin dashboard or the Jason Maven submenu).
function M.show_menu(on_back)
  local ui = require('marvin.ui')

  local types = {
    { label = 'Common Types', is_separator = true },
    { id = 'class', icon = '󰬷', label = 'Java Class', desc = 'Standard class with fields and methods' },
    { id = 'class_main', icon = '󰁔', label = 'Main Class', desc = 'Executable class with main() method' },
    { id = 'interface', icon = '󰜰', label = 'Interface', desc = 'Contract definition for classes' },
    { id = 'enum', icon = '󰒻', label = 'Enum', desc = 'Type-safe enumeration of constants' },
    { id = 'record', icon = '󰏗', label = 'Record', desc = 'Immutable data carrier (Java 14+)' },

    { label = 'Design Patterns', is_separator = true },
    { id = 'builder', icon = '󰒓', label = 'Builder Pattern', desc = 'Fluent API for object construction' },

    { label = 'Advanced', is_separator = true },
    { id = 'abstract', icon = '󰦊', label = 'Abstract Class', desc = 'Partial implementation base class' },
    { id = 'exception', icon = '󰅖', label = 'Custom Exception', desc = 'Custom error type' },

    { label = 'Testing', is_separator = true },
    { id = 'test', icon = '󰙨', label = 'JUnit Test', desc = 'JUnit 5 test class' },
  }

  ui.select(types, {
    prompt      = 'Create Java File',
    on_back     = on_back, -- <BS> returns to wherever called show_menu
    format_item = function(it) return it.label end,
  }, function(choice)
    if not choice then return end
    local options = {}

    if choice.id == 'class' then
      M.create_file_interactive('Class', options, on_back)
    elseif choice.id == 'class_main' then
      options.main = true
      M.create_file_interactive('Class', options, on_back)
    elseif choice.id == 'interface' then
      M.create_file_interactive('Interface', options, on_back)
    elseif choice.id == 'enum' then
      M.prompt_enum_values(function(values)
        if values then
          options.values = values
          M.create_file_interactive('Enum', options, on_back)
        end
      end)
    elseif choice.id == 'record' then
      M.prompt_fields(function(fields)
        if fields then
          options.fields = fields
          M.create_file_interactive('Record', options, on_back)
        end
      end, '󰏗 Record Fields (Type name, Type name, ...)')
    elseif choice.id == 'abstract' then
      M.create_file_interactive('Abstract Class', options, on_back)
    elseif choice.id == 'exception' then
      M.create_file_interactive('Exception', options, on_back)
    elseif choice.id == 'test' then
      M.create_file_interactive('Test', options, on_back)
    elseif choice.id == 'builder' then
      M.prompt_fields(function(fields)
        if fields then
          if #fields > 0 then fields[1].required = true end
          options.fields = fields
          M.create_file_interactive('Builder', options, on_back)
        end
      end, '󰒓 Builder Fields (Type name, Type name, ...)')
    end
  end)
end

return M

```

### `lua/marvin/keymaps.lua`

```lua
-- lua/marvin/keymaps.lua
local M = {}

function M.register(km)
  km = km or {}
  local function map(lhs, rhs, desc)
    if lhs and lhs ~= '' then
      vim.keymap.set('n', lhs, rhs, { silent = true, desc = desc })
    end
  end

  -- Marvin: project dashboard
  map(km.dashboard, function() require('marvin.dashboard').show() end,
    'Marvin: Project dashboard')

  -- Jason: task runner dashboard
  map(km.jason, function() require('marvin.jason_dashboard').show() end,
    'Jason: Task runner dashboard')

  -- Jason: direct actions
  map(km.jason_build,   function() require('marvin.build').build()         end, 'Jason: Build')
  map(km.jason_run,     function() require('marvin.build').run()           end, 'Jason: Run')
  map(km.jason_test,    function() require('marvin.build').test()          end, 'Jason: Test')
  map(km.jason_clean,   function() require('marvin.build').clean()         end, 'Jason: Clean')
  map(km.jason_console, function() require('marvin.console').toggle()      end, 'Jason: Console')
end

return M

```

### `lua/marvin/lang/cpp.lua`

```lua
-- lua/marvin/lang/cpp.lua
-- C/C++ language module for the Marvin unified dashboard.

local M = {}

local function plain(it) return it.label end
local function ui() return require('marvin.ui') end
local function cr() return require('marvin.creator.cpp') end
local function det() return require('marvin.detector') end
local function local_libs() return require('marvin.local_libs') end

local function sep(l) return { label = l, is_separator = true } end
local function item(id, i, l, d) return { id = id, _icon = i, label = l, desc = d } end

-- ── Project header ────────────────────────────────────────────────────────────
function M.prompt_header(p)
  local info = p.info or {}
  local kind = p.type == 'cmake' and '[CMake]'
      or p.type == 'meson' and '[Meson]'
      or '[Makefile]'
  return string.format('%s  %s', info.name or p.name, kind)
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end

  for _, ci in ipairs(cr().menu_items()) do add(ci) end

  add(sep('Build'))
  local tool = p.type == 'cmake' and 'CMake'
      or p.type == 'meson' and 'Meson'
      or 'Make'
  add(item('build_menu', '󰑕', tool .. '…', 'Configure, build, test, install, clean'))

  add(sep('Libraries'))
  add(item('libs_link', '󰘦', 'Link Libraries…', 'Pick local .a/.so libs to link'))
  add(item('libs_build', '󰑕', 'Build Static Library…', 'Compile sources → .a archive'))
  add(item('libs_paths', '󰉿', 'Manage Library Paths…', 'Register / remove search dirs'))
  add(item('libs_report', '󰙅', 'Library Report', 'Show discovered libs + active flags'))

  add(sep('Project Files'))
  add(item('proj_files_menu', '󰈙', 'Build System…',
    'Makefile, CMakeLists.txt, meson.build, compile_commands.json'))

  return items
end

-- ── Submenu: Build ────────────────────────────────────────────────────────────
function M.show_build_menu(p, back)
  local items = {}
  if p.type == 'cmake' then
    items = {
      { id = 'cmake_cfg', label = '󰒓 Configure', desc = 'cmake -B build -S .' },
      { id = 'cmake_build', label = '󰑕 Build', desc = 'cmake --build build' },
      { id = 'cmake_test', label = '󰙨 Test', desc = 'ctest --test-dir build' },
      { id = 'cmake_install', label = '󰇚 Install', desc = 'cmake --install build' },
      { id = 'cmake_clean', label = '󰃢 Clean', desc = 'cmake --build build --target clean' },
    }
  elseif p.type == 'meson' then
    local configured = vim.fn.isdirectory(p.root .. '/builddir') == 1
        or vim.fn.isdirectory(p.root .. '/build') == 1
    items = {
      {
        id    = 'meson_setup',
        label = configured and '󰒓 Re-configure' or '󰒓 Setup (meson setup builddir)',
        desc  = configured and 'meson setup --reconfigure builddir' or 'meson setup builddir',
      },
      { id = 'meson_build', label = '󰑕 Build', desc = 'meson compile -C builddir' },
      { id = 'meson_test', label = '󰙨 Test', desc = 'meson test -C builddir' },
      { id = 'meson_install', label = '󰇚 Install', desc = 'meson install -C builddir' },
      { id = 'meson_clean', label = '󰃢 Clean', desc = 'rm -rf builddir' },
      { id = 'meson_introspect', label = '󰙅 Introspect…', desc = 'meson introspect subcommands' },
    }
  else
    items = {
      { id = 'make_build', label = '󰑕 Build', desc = 'make' },
      { id = 'make_test', label = '󰙨 Test', desc = 'make test' },
      { id = 'make_install', label = '󰇚 Install', desc = 'make install' },
      { id = 'make_clean', label = '󰃢 Clean', desc = 'make clean' },
    }
  end
  ui().select(items, { prompt = 'Build', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Meson introspect ─────────────────────────────────────────────────
function M.show_meson_introspect_menu(p, back)
  local root  = p and p.root or vim.fn.getcwd()
  local items = {
    { id = 'mi_targets', label = '󰙅 Targets', desc = 'meson introspect --targets' },
    { id = 'mi_deps', label = '󰘦 Dependencies', desc = 'meson introspect --dependencies' },
    { id = 'mi_buildopts', label = '󰒓 Build Options', desc = 'meson introspect --buildoptions' },
    { id = 'mi_tests', label = '󰙨 Tests', desc = 'meson introspect --tests' },
    { id = 'mi_compilers', label = '󰙲 Compilers', desc = 'meson introspect --compilers' },
    { id = 'mi_installed', label = '󰇚 Installed Files', desc = 'meson introspect --installed' },
  }
  ui().select(items, { prompt = 'Meson Introspect', on_back = back, format_item = plain },
    function(ch)
      if not ch then return end
      local subcmds = {
        mi_targets   = '--targets',
        mi_deps      = '--dependencies',
        mi_buildopts = '--buildoptions',
        mi_tests     = '--tests',
        mi_compilers = '--compilers',
        mi_installed = '--installed',
      }
      local flag = subcmds[ch.id]
      if flag then
        local bdir = vim.fn.isdirectory(root .. '/builddir') == 1 and 'builddir' or 'build'
        require('core.runner').execute({
          cmd      = 'meson introspect ' .. bdir .. ' ' .. flag,
          cwd      = root,
          title    = 'Meson Introspect ' .. flag,
          term_cfg = require('marvin').config.terminal,
          plugin   = 'marvin',
        })
      end
    end)
end

-- ── Submenu: Project Files ────────────────────────────────────────────────────
function M.show_proj_files_menu(p, back)
  local items = {
    {
      id    = 'gen_makefile',
      label = '󰈙 New/Regenerate Makefile',
      desc  = 'Interactive Makefile wizard',
    },
    {
      id    = 'gen_cmake',
      label = '󰒓 New/Regenerate CMakeLists.txt',
      desc  = 'Interactive CMake wizard with auto-link detection',
    },
    {
      id    = 'gen_meson',
      label = '󰒓 New/Regenerate meson.build',
      desc  = 'Interactive Meson wizard with auto-link detection',
    },
    {
      id    = 'gen_compile_commands',
      label = '󰘦 Generate compile_commands.json',
      desc  = 'For clangd — build then rewrite to project root',
    },
    {
      id    = 'rewrite_compile_commands',
      label = '󰑕 Rewrite & Restart clangd',
      desc  = 'Re-run path rewriter on existing compile_commands.json',
    },
  }
  ui().select(items, { prompt = 'Build System', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- compile_commands.json rewriter
--
-- Meson writes compile_commands.json inside builddir/ with:
--   • relative -I flags (e.g. -I.. -I../include -ITrixie.p)
--   • relative "file" paths (e.g. "../src/anim.c")
--   • NO reference to builddir itself (where generated protocol headers live)
--
-- This rewriter produces a file at the PROJECT ROOT with:
--   1. Every -I flag resolved to an absolute path
--   2. -I<builddir> injected → clangd finds wlr-*-protocol.h, xdg-*-protocol.h
--   3. -I<builddir>/<target>.p/ injected → meson per-target private dir headers
--   4. Every "file" field resolved to an absolute path
--   5. "directory" set to the project root (not builddir)
-- ══════════════════════════════════════════════════════════════════════════════

local REWRITE_PY = [[
import json, os, subprocess, sys

root  = sys.argv[1]   # project root  e.g. /home/user/Code/Trixie
bdir  = sys.argv[2]   # builddir      e.g. /home/user/Code/Trixie/builddir
src   = sys.argv[3]   # input         bdir/compile_commands.json
dst   = sys.argv[4]   # output        root/compile_commands.json

# ── pkg-config header → package map ──────────────────────────────────────────
# We scan every source file referenced in compile_commands.json for #include
# patterns, map them to pkg-config packages, then inject --cflags so clangd
# can find headers like <wlr/backend.h> that live outside standard paths.
PKG_MAP = [
    ('wlr/',               'wlroots'),
    ('wayland-server',     'wayland-server'),
    ('wayland-client',     'wayland-client'),
    ('xkbcommon',          'xkbcommon'),
    ('libinput',           'libinput'),
    ('libudev',            'libudev'),
    ('pixman',             'pixman-1'),
    ('drm',                'libdrm'),
    ('gbm',                'gbm'),
    ('EGL/egl',            'egl'),
    ('GLES',               'glesv2'),
    ('cairo',              'cairo'),
    ('pango',              'pango'),
    ('gdk-pixbuf',         'gdk-pixbuf-2.0'),
    ('gtk/gtk',            'gtk+-3.0'),
    ('glib',               'glib-2.0'),
    ('gio/',               'gio-2.0'),
    ('libavcodec',         'libavcodec'),
    ('libavformat',        'libavformat'),
    ('pulse',              'libpulse'),
    ('alsa',               'alsa'),
    ('openssl',            'openssl'),
    ('curl',               'libcurl'),
    ('dbus',               'dbus-1'),
    ('systemd',            'libsystemd'),
    ('json-c',             'json-c'),
    ('libxml2',            'libxml-2.0'),
    ('libpng',             'libpng'),
    ('freetype',           'freetype2'),
    ('fontconfig',         'fontconfig'),
    ('zlib',               'zlib'),
    ('lua',                'lua'),
    ('ffi',                'libffi'),
]

def resolve_pkg(base):
    """Resolve base pkg name to actual installed name, handling versioned packages.

    e.g. 'wlroots' -> 'wlroots-0.18' when only the versioned form is installed.
    Returns the resolved name string, or None if not found at all.
    """
    # 1. Try exact name first
    if subprocess.call(['pkg-config', '--exists', base],
                       stderr=subprocess.DEVNULL) == 0:
        return base
    # 2. Search for versioned variant via pkg-config --list-all
    try:
        all_pkgs = subprocess.check_output(
            ['pkg-config', '--list-all'],
            stderr=subprocess.DEVNULL).decode()
        for line in all_pkgs.splitlines():
            pkg_name = line.split()[0] if line.split() else ''
            # Match 'wlroots-0.18', 'wlroots-0.17', etc.
            if pkg_name == base or pkg_name.startswith(base + '-') or pkg_name.startswith(base + '.'):
                if subprocess.call(['pkg-config', '--exists', pkg_name],
                                   stderr=subprocess.DEVNULL) == 0:
                    return pkg_name
    except Exception:
        pass
    return None

def pkg_exists(name):
    return resolve_pkg(name) is not None

def pkg_cflags(names):
    """Return list of flag tokens from pkg-config --cflags for all names.
    Names should already be resolved (i.e. 'wlroots-0.18' not 'wlroots').
    """
    if not names:
        return []
    try:
        out = subprocess.check_output(
            ['pkg-config', '--cflags'] + names,
            stderr=subprocess.DEVNULL).decode().strip()
        return out.split() if out else []
    except Exception:
        return []

def scan_file_for_pkgs(path, found, ordered):
    """Scan a single source/header file for #include patterns."""
    try:
        with open(path, errors='replace') as f:
            for line in f:
                line = line.strip()
                if not line.startswith('#'):
                    continue
                if 'include' not in line:
                    continue
                start = line.find('<')
                if start == -1:
                    start = line.find('"')
                    end   = line.rfind('"')
                else:
                    end = line.find('>')
                if start == -1 or end <= start:
                    continue
                inc = line[start+1:end]
                for pat, pkg in PKG_MAP:
                    if pkg not in found and pat in inc:
                        # resolve handles versioned names: wlroots -> wlroots-0.18
                        resolved = resolve_pkg(pkg)
                        if resolved:
                            found.add(pkg)        # key on base to avoid duplicates
                            ordered.append(resolved)  # use actual installed name
    except OSError:
        pass

with open(src) as f:
    entries = json.load(f)

# ── collect all source files referenced in compile_commands ──────────────────
all_source_files = set()
for e in entries:
    fpath = e.get('file', '')
    if fpath and not fpath.startswith('/'):
        fpath = os.path.normpath(os.path.join(bdir, fpath))
    if fpath:
        all_source_files.add(fpath)
    # also scan headers alongside each source
    d = os.path.dirname(fpath)
    if os.path.isdir(d):
        for name in os.listdir(d):
            if name.endswith(('.h', '.hpp', '.hxx')):
                all_source_files.add(os.path.join(d, name))

# also scan include/ and src/ at project root
for subdir in ('include', 'src', '.'):
    dp = os.path.join(root, subdir)
    if os.path.isdir(dp):
        for dirpath, _, filenames in os.walk(dp):
            for name in filenames:
                if name.endswith(('.c', '.cpp', '.h', '.hpp', '.cxx', '.hxx')):
                    all_source_files.add(os.path.join(dirpath, name))

found_pkgs   = set()
ordered_pkgs = []
for fpath in all_source_files:
    scan_file_for_pkgs(fpath, found_pkgs, ordered_pkgs)

pkg_cflags_tokens = pkg_cflags(ordered_pkgs)
needs_wlr_unstable = any(p.startswith('wlroots') for p in ordered_pkgs)

if ordered_pkgs:
    print('pkg-config deps detected: ' + ' '.join(ordered_pkgs))
    print('injecting cflags: ' + ' '.join(pkg_cflags_tokens))

# ── rewrite every compile_commands entry ─────────────────────────────────────
for e in entries:
    parts = e.get('command', '').split()
    fixed = []
    seen  = set()

    for p in parts:
        if p.startswith('-I') and not p.startswith('-I/'):
            # resolve relative include path against builddir
            abs_inc = os.path.normpath(os.path.join(bdir, p[2:]))
            flag    = '-I' + abs_inc
        else:
            flag = p

        if flag not in seen:
            seen.add(flag)
            fixed.append(flag)

    # inject builddir itself → clangd finds generated protocol headers
    # (wlr-layer-shell-unstable-v1-protocol.h, xdg-shell-protocol.h, etc.)
    bdir_flag = '-I' + bdir
    if bdir_flag not in seen:
        seen.add(bdir_flag)
        fixed.append(bdir_flag)

    # inject every *.p/ subdir inside builddir (meson per-target private dirs)
    try:
        for entry in os.scandir(bdir):
            if entry.is_dir() and entry.name.endswith('.p'):
                flag = '-I' + entry.path
                if flag not in seen:
                    seen.add(flag)
                    fixed.append(flag)
    except OSError:
        pass

    # inject project root and include/protocols/ so generated protocol headers
    # are found regardless of whether they're in root or include/protocols/
    for extra_inc in [root, os.path.join(root, 'include', 'protocols')]:
        flag = '-I' + extra_inc
        if flag not in seen and os.path.isdir(extra_inc):
            seen.add(flag)
            fixed.append(flag)

    # inject every directory under the project root that contains a
    # *-protocol.h file (covers hand-committed or subdir-placed headers)
    try:
        for dirpath, dirnames, filenames in os.walk(root):
            # skip build dirs and hidden dirs
            dirnames[:] = [d for d in dirnames
                           if d not in ('builddir', 'build', '.git', '.marvin-obj')
                           and not d.startswith('.')]
            if any(f.endswith('-protocol.h') or f.endswith('_protocol.h')
                   for f in filenames):
                flag = '-I' + dirpath
                if flag not in seen:
                    seen.add(flag)
                    fixed.append(flag)
    except OSError:
        pass

    # inject pkg-config --cflags tokens (the key fix for wlr/backend.h etc.)
    for token in pkg_cflags_tokens:
        if token not in seen:
            seen.add(token)
            fixed.append(token)

    # wlroots requires this define or headers refuse to compile
    if needs_wlr_unstable and '-DWLR_USE_UNSTABLE' not in seen:
        seen.add('-DWLR_USE_UNSTABLE')
        fixed.append('-DWLR_USE_UNSTABLE')

    e['command']   = ' '.join(fixed)
    e['directory'] = root   # set directory to project root, not builddir

    # fix relative file path
    if not e.get('file', '').startswith('/'):
        e['file'] = os.path.normpath(os.path.join(bdir, e['file']))

    # fix relative output path if present
    if 'output' in e and not e['output'].startswith('/'):
        e['output'] = os.path.normpath(os.path.join(bdir, e['output']))

with open(dst, 'w') as f:
    json.dump(entries, f, indent=2)

print('ok: wrote ' + dst)
]]

local function rewrite_compile_commands(root, on_done)
  -- find builddir
  local bdir = nil
  for _, c in ipairs({ 'builddir', 'build' }) do
    if vim.fn.filereadable(root .. '/' .. c .. '/compile_commands.json') == 1 then
      bdir = root .. '/' .. c
      break
    end
  end

  if not bdir then
    vim.notify(
      '[Marvin] compile_commands.json not found in builddir/ or build/.\n'
      .. '  Run Meson Setup first to generate it.',
      vim.log.levels.WARN)
    return
  end

  local src         = bdir .. '/compile_commands.json'
  local dst         = root .. '/compile_commands.json'
  local script_path = vim.fn.tempname() .. '_marvin_rewrite.py'

  local sf          = io.open(script_path, 'w')
  if not sf then
    vim.notify('[Marvin] Cannot write temp script: ' .. script_path, vim.log.levels.ERROR)
    return
  end
  sf:write(REWRITE_PY)
  sf:close()

  vim.fn.jobstart({ 'python3', script_path, root, bdir, src, dst }, {
    on_stdout = function(_, data)
      local msg = table.concat(data or {}, '\n'):gsub('^%s+', ''):gsub('%s+$', '')
      if msg ~= '' then vim.notify('[Marvin] ' .. msg, vim.log.levels.INFO) end
    end,
    on_stderr = function(_, data)
      local msg = table.concat(data or {}, '\n'):gsub('^%s+', ''):gsub('%s+$', '')
      if msg ~= '' then vim.notify('[Marvin] rewrite error: ' .. msg, vim.log.levels.ERROR) end
    end,
    on_exit = function(_, code)
      os.remove(script_path)
      if code ~= 0 then
        vim.notify('[Marvin] compile_commands rewrite failed (exit ' .. code .. ')', vim.log.levels.ERROR)
        return
      end
      if on_done then vim.schedule(on_done) end
    end,
  })
end

-- ── clangd restart ────────────────────────────────────────────────────────────
local function restart_clangd()
  local cache = vim.fn.expand('~/.cache/clangd')
  if vim.fn.isdirectory(cache) == 1 then
    vim.fn.system('rm -rf ' .. vim.fn.shellescape(cache))
  end
  vim.lsp.stop_client(vim.lsp.get_clients({ name = 'clangd' }))
  vim.defer_fn(function() vim.cmd('edit') end, 300)
end

-- ── compile_commands generator (entry point) ─────────────────────────────────
function M.generate_compile_commands(p, back)
  local root          = p and p.root or vim.fn.getcwd()
  local has_meson     = vim.fn.filereadable(root .. '/meson.build') == 1
  local has_cmake     = vim.fn.filereadable(root .. '/CMakeLists.txt') == 1
  local has_make      = vim.fn.filereadable(root .. '/Makefile') == 1
  local has_bear      = vim.fn.executable('bear') == 1
  local has_compdb    = vim.fn.executable('compiledb') == 1
  local has_cmake_bin = vim.fn.executable('cmake') == 1
  local has_meson_bin = vim.fn.executable('meson') == 1

  -- Meson: always go through meson_setup so rewrite runs automatically
  if has_meson and has_meson_bin then
    M.handle('meson_setup', p, back)
    return
  end

  local items = {}
  local function add(t) items[#items + 1] = t end

  if has_cmake and has_cmake_bin then
    add({
      id = 'ccmd_cmake',
      label = '󰒓 CMake (recommended)',
      desc = 'cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -S .'
    })
  end
  if has_bear then
    if has_make then
      add({ id = 'ccmd_bear_make', label = '󰈙 bear + make', desc = 'bear -- make' })
    end
    add({ id = 'ccmd_bear_custom', label = '󰈙 bear + custom command…', desc = 'bear -- <cmd>' })
  end
  if has_compdb and has_make then
    add({ id = 'ccmd_compiledb', label = '󰘦 compiledb', desc = 'compiledb make' })
  end
  add({
    id = 'ccmd_clangd_file',
    label = '󰄬 .clangd config (no build needed)',
    desc = 'Write .clangd with -Iinclude flags'
  })
  if #items == 1 then
    add({ id = 'ccmd_install_hint', label = '󰋖 How to install bear / compiledb', desc = '' })
  end

  ui().select(items, { prompt = 'Generate compile_commands.json', on_back = back, format_item = plain },
    function(ch)
      if not ch then return end

      local function run(cmd, title, on_exit_cb)
        require('core.runner').execute({
          cmd = cmd,
          cwd = root,
          title = title,
          term_cfg = require('marvin').config.terminal,
          plugin = 'marvin',
          on_exit = on_exit_cb,
        })
      end

      if ch.id == 'ccmd_cmake' then
        run('cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
          'Generate compile_commands.json',
          function(ok)
            if not ok then return end
            vim.defer_fn(function()
              local s = root .. '/build/compile_commands.json'
              local d = root .. '/compile_commands.json'
              if vim.fn.filereadable(s) == 1 then
                vim.fn.system('ln -sf ' .. vim.fn.shellescape(s) .. ' ' .. vim.fn.shellescape(d))
                restart_clangd()
              end
            end, 500)
          end)
      elseif ch.id == 'ccmd_bear_make' then
        run('bear -- make', 'bear + make', function(ok)
          if ok then restart_clangd() end
        end)
      elseif ch.id == 'ccmd_bear_custom' then
        ui().input({ prompt = 'Build command for bear', default = 'make' }, function(cmd)
          if cmd and cmd ~= '' then
            run('bear -- ' .. cmd, 'bear + ' .. cmd, function(ok)
              if ok then restart_clangd() end
            end)
          end
        end)
      elseif ch.id == 'ccmd_compiledb' then
        run('compiledb make', 'compiledb', function(ok)
          if ok then restart_clangd() end
        end)
      elseif ch.id == 'ccmd_clangd_file' then
        local inc_flags = {}
        for _, d in ipairs({ 'include', 'src', '.' }) do
          if vim.fn.isdirectory(root .. '/' .. d) == 1 then
            inc_flags[#inc_flags + 1] = '-I' .. root .. '/' .. d
          end
        end
        local ok_ll, ll = pcall(require, 'marvin.local_libs')
        if ok_ll then
          local lf = ll.build_flags(root)
          if lf.iflags ~= '' then
            for _, f in ipairs(vim.split(lf.iflags, '%s+')) do
              if f ~= '' then inc_flags[#inc_flags + 1] = f end
            end
          end
        end
        local cfg         = require('marvin').config.cpp or {}
        local std         = cfg.standard or 'c11'
        local clang_lang  = (cfg.compiler == 'g++' or cfg.compiler == 'clang++') and 'c++' or 'c'
        local flags       = vim.deepcopy(inc_flags)

        local ok_b, build = pcall(require, 'marvin.build')
        if ok_b and build.cpp then
          -- POSIX define
          if build.cpp.needs_posix_define and build.cpp.needs_posix_define(root) then
            flags[#flags + 1] = '-D_POSIX_C_SOURCE=200809L'
          end
          -- pkg-config --cflags: resolves -I/usr/include/wlroots-0.17,
          -- -DWLR_USE_UNSTABLE, and flags for every other detected library.
          if build.cpp.pkg_config_flags then
            local pkg = build.cpp.pkg_config_flags(root)
            for _, f in ipairs(pkg.iflags) do flags[#flags + 1] = f end
            if #pkg.pkg_names > 0 then
              vim.notify('[Marvin] .clangd: injecting pkg-config flags for: '
                .. table.concat(pkg.pkg_names, ' '), vim.log.levels.INFO)
            end
          end
        end


        -- inject project root and include/protocols/ for generated protocol headers
        flags[#flags + 1] = '-I' .. root
        if vim.fn.isdirectory(root .. '/include/protocols') == 1 then
          flags[#flags + 1] = '-I' .. root .. '/include/protocols'
        end

        -- scan every subdir for *-protocol.h files and inject those dirs too
        -- (covers wlr-layer-shell-unstable-v1-protocol.h committed to the repo)
        local _skip = { build = true, builddir = true, ['.git'] = true, ['.marvin-obj'] = true }
        local function scan_proto_dirs(dir)
          for _, sub in ipairs(vim.fn.globpath(dir, '*', false, true)) do
            if vim.fn.isdirectory(sub) == 1 then
              local bn = vim.fn.fnamemodify(sub, ':t')
              if not _skip[bn] and not bn:match('^%.') then
                local ph = vim.fn.globpath(sub, '*-protocol.h', false, true)
                if #ph == 0 then ph = vim.fn.globpath(sub, '*_protocol.h', false, true) end
                if #ph > 0 then flags[#flags + 1] = '-I' .. sub end
                scan_proto_dirs(sub)
              end
            end
          end
        end
        scan_proto_dirs(root)

        flags[#flags + 1] = '-std=' .. std
        flags[#flags + 1] = '-x'
        flags[#flags + 1] = clang_lang
        local flag_lines = {}
        for _, f in ipairs(flags) do flag_lines[#flag_lines + 1] = '    - ' .. f end
        local clangd_content = 'CompileFlags:\n  Add:\n' .. table.concat(flag_lines, '\n') .. '\n'
        local clangd_path    = root .. '/.clangd'
        if vim.fn.filereadable(clangd_path) == 1 then
          ui().select({
              { id = 'overwrite', label = 'Overwrite existing .clangd' },
              { id = 'cancel',    label = 'Cancel' },
            }, { prompt = '.clangd already exists', format_item = plain },
            function(ow)
              if ow and ow.id == 'overwrite' then
                local f = io.open(clangd_path, 'w')
                if f then
                  f:write(clangd_content); f:close(); restart_clangd()
                end
              end
            end)
        else
          local f = io.open(clangd_path, 'w')
          if f then
            f:write(clangd_content); f:close(); restart_clangd()
          end
        end
      elseif ch.id == 'ccmd_install_hint' then
        vim.api.nvim_echo({ { table.concat({
          '', '  Install bear:', '    Arch: sudo pacman -S bear',
          '    Ubuntu: sudo apt install bear', '    macOS: brew install bear', '',
          '  Install compiledb:  pip install compiledb', '',
          '  Meson: meson setup builddir  (generates automatically)', '',
          '  CMake: cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON', '',
        }, '\n'), 'Normal' } }, true, {})
      end
    end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle(id, p, back)
  if cr().handle(id, back) then return end

  if id:match('^libs_') then
    local ll   = local_libs()
    local root = p and p.root or vim.fn.getcwd()
    ll.handle(id, root, back)
    return
  end

  if id == 'build_menu' then
    M.show_build_menu(p, back)
  elseif id == 'proj_files_menu' then
    M.show_proj_files_menu(p, back)
  elseif id == 'gen_makefile' then
    require('marvin.makefile_creator').create(p and p.root or vim.fn.getcwd(), back)
  elseif id == 'gen_cmake' then
    require('marvin.cmake_creator').create(p and p.root or vim.fn.getcwd(), back)
  elseif id == 'gen_meson' then
    require('marvin.meson_creator').create(p and p.root or vim.fn.getcwd(), back)
  elseif id == 'gen_compile_commands' then
    M.generate_compile_commands(p, back)
  elseif id == 'rewrite_compile_commands' then
    local root = p and p.root or vim.fn.getcwd()
    rewrite_compile_commands(root, function()
      restart_clangd()
      vim.notify('[Marvin] compile_commands.json rewritten + clangd restarted', vim.log.levels.INFO)
    end)

    -- ── CMake ───────────────────────────────────────────────────────────────────
  elseif id == 'cmake_cfg' then
    require('core.runner').execute({
      cmd = 'cmake -B build -S .',
      cwd = p.root,
      title = 'CMake Configure',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'cmake_build' then
    require('core.runner').execute({
      cmd = 'cmake --build build',
      cwd = p.root,
      title = 'CMake Build',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'cmake_test' then
    require('core.runner').execute({
      cmd = 'ctest --test-dir build',
      cwd = p.root,
      title = 'CTest',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'cmake_clean' then
    require('core.runner').execute({
      cmd = 'cmake --build build --target clean',
      cwd = p.root,
      title = 'CMake Clean',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'cmake_install' then
    require('core.runner').execute({
      cmd = 'cmake --install build',
      cwd = p.root,
      title = 'CMake Install',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })

    -- ── Meson ───────────────────────────────────────────────────────────────────
  elseif id == 'meson_setup' then
    local root       = p.root
    local configured = vim.fn.isdirectory(root .. '/builddir') == 1
        or vim.fn.isdirectory(root .. '/build') == 1
    require('core.runner').execute({
      cmd      = (configured
            and 'meson setup --reconfigure builddir'
            or 'meson setup builddir')
          .. ' && ninja -C builddir; true',
      cwd      = root,
      title    = 'Meson Setup + Build',
      term_cfg = require('marvin').config.terminal,
      plugin   = 'marvin',
      on_exit  = function(_)
        rewrite_compile_commands(root, function()
          restart_clangd()
          vim.notify(
            '[Marvin] Meson setup complete.\n'
            .. '  compile_commands.json → project root (absolute paths)\n'
            .. '  clangd cache cleared + restarted',
            vim.log.levels.INFO)
        end)
      end,
    })
  elseif id == 'meson_build' then
    require('core.runner').execute({
      cmd      = 'meson compile -C builddir',
      cwd      = p.root,
      title    = 'Meson Build',
      term_cfg = require('marvin').config.terminal,
      plugin   = 'marvin',
      on_exit  = function(_)
        rewrite_compile_commands(p.root, function()
          restart_clangd()
        end)
      end,
    })
  elseif id == 'meson_test' then
    require('core.runner').execute({
      cmd = 'meson test -C builddir',
      cwd = p.root,
      title = 'Meson Test',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'meson_install' then
    require('core.runner').execute({
      cmd = 'meson install -C builddir',
      cwd = p.root,
      title = 'Meson Install',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'meson_clean' then
    require('core.runner').execute({
      cmd = 'rm -rf builddir',
      cwd = p.root,
      title = 'Meson Clean',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'meson_introspect' then
    M.show_meson_introspect_menu(p, back)

    -- ── Make ────────────────────────────────────────────────────────────────────
  elseif id == 'make_build' then
    require('core.runner').execute({
      cmd = 'make',
      cwd = p.root,
      title = 'Make',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'make_test' then
    require('core.runner').execute({
      cmd = 'make test',
      cwd = p.root,
      title = 'Make Test',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'make_clean' then
    require('core.runner').execute({
      cmd = 'make clean',
      cwd = p.root,
      title = 'Make Clean',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  elseif id == 'make_install' then
    require('core.runner').execute({
      cmd = 'make install',
      cwd = p.root,
      title = 'Make Install',
      term_cfg = require('marvin').config.terminal,
      plugin = 'marvin',
    })
  end
end

return M

```

### `lua/marvin/lang/go.lua`

```lua
-- lua/marvin/lang/go.lua
-- Go language module for the Marvin unified dashboard.

local M = {}

local function plain(it) return it.label end
local function ui() return require('marvin.ui') end
local function deps() return require('marvin.deps.go') end
local function cr() return require('marvin.creator.go') end

local function sep(l) return { label = l, is_separator = true } end
local function item(id, i, l, d) return { id = id, _icon = i, label = l, desc = d } end

-- ── Project header ────────────────────────────────────────────────────────────
function M.prompt_header(p)
  local info = p.info or {}
  local kind = info.is_workspace and '[go.work workspace]' or '[module]'
  local cmds_label = (info.cmds and #info.cmds > 0)
      and ('  cmds: ' .. table.concat(info.cmds, ', '))
      or ''
  return string.format('%s  go%s  %s%s',
    info.module or p.name,
    info.go_version or '?',
    kind,
    cmds_label)
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end
  local info = p.info or {}

  -- Create
  for _, ci in ipairs(cr().menu_items()) do add(ci) end

  -- Go
  add(sep('Go'))
  add(item('test', '󰙨', 'Test…', 'Run tests'))
  add(item('lifecycle_menu', '󰑕', 'Build & Run…', 'Build, run, vet, fmt, lint, clean, doc'))

  -- Tools
  add(sep('Tools'))
  add(item('deps_menu', '󰘦', 'Dependencies…', 'Tidy, vendor, audit, update'))
  if info.cmds and #info.cmds > 1 then
    add(item('cmds_menu', '󰐊', 'Commands…',
      #info.cmds .. ' entry points'))
  end
  if info.is_workspace then
    add(item('ws_menu', '󰙅', 'Workspace…', 'go.work sync & members'))
  end

  return items
end

-- ── Submenu: Build & Run (lifecycle) ─────────────────────────────────────────
function M.show_lifecycle_menu(p, back)
  local info       = p.info or {}
  local run_target = (info.cmds and #info.cmds == 1)
      and 'go run ./cmd/' .. info.cmds[1]
      or 'go run .'
  local items      = {
    { id = 'build', label = '󰑕 Build', desc = 'go build ./...' },
    { id = 'run', label = '󰐊 Run', desc = run_target },
    { id = 'vet', label = '󰅾 Vet', desc = 'go vet ./...' },
    { id = 'fmt', label = '󰉣 Format', desc = 'gofmt -w .' },
    { id = 'lint', label = '󰅾 Lint', desc = 'golangci-lint run' },
    { id = 'clean', label = '󰃢 Clean', desc = 'go clean ./...' },
    { id = 'doc', label = '󰈙 godoc', desc = 'godoc -http=:6060' },
  }
  ui().select(items, { prompt = 'Build & Run', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Commands ────────────────────────────────────────────────────────
function M.show_cmds_menu(p, back)
  local info  = p.info or {}
  local items = {}
  for _, cmd in ipairs(info.cmds or {}) do
    items[#items + 1] = {
      id    = 'run_cmd__' .. cmd,
      label = '󰐊 ' .. cmd,
      desc  = 'go run ./cmd/' .. cmd,
    }
  end
  ui().select(items, { prompt = 'Run Command', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Workspace ───────────────────────────────────────────────────────
function M.show_ws_menu(p, back)
  local items = {
    { id = 'ws_sync', label = '󰚰 Sync Workspace', desc = 'go work sync' },
    { id = 'ws_members', label = '󰙅 Members', desc = 'go.work uses' },
  }
  ui().select(items, { prompt = 'Workspace', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Dependencies ────────────────────────────────────────────────────
function M.show_deps_menu(p, back)
  local items = {}
  for _, di in ipairs(deps().menu_items()) do items[#items + 1] = di end
  ui().select(items, { prompt = 'Dependencies', on_back = back, format_item = plain },
    function(ch) if ch then deps().handle(ch.id) end end)
end

-- ── Submenu: Tests ───────────────────────────────────────────────────────────
function M.show_test_menu(p, back)
  ui().select({
    { id = 'test_all', label = '󰙨 All packages', desc = 'go test ./...' },
    { id = 'test_filter', label = '󰍉 Filter…', desc = 'go test -run <pattern>' },
    { id = 'test_pkg', label = '󰉿 Current package', desc = 'go test .' },
    { id = 'test_race', label = '󰍉 Race detector', desc = 'go test -race ./...' },
    { id = 'test_cover', label = '󰙨 Coverage', desc = 'go test -cover ./...' },
    { id = 'test_bench', label = '󰙨 Benchmarks', desc = 'go test -bench=. ./...' },
    { id = 'test_short', label = '󰒭 Short (skip slow)', desc = 'go test -short ./...' },
  }, { prompt = 'Run Tests', on_back = back, format_item = plain }, function(ch)
    if not ch then return end
    if ch.id == 'test_all' then
      M._run('go test ./...', p, 'Test All')
    elseif ch.id == 'test_pkg' then
      M._run('go test .', p, 'Test Package')
    elseif ch.id == 'test_race' then
      M._run('go test -race ./...', p, 'Test (race)')
    elseif ch.id == 'test_cover' then
      M._run('go test -cover -coverprofile=coverage.out ./...', p, 'Test + Cover')
    elseif ch.id == 'test_bench' then
      M._run('go test -bench=. ./...', p, 'Benchmarks')
    elseif ch.id == 'test_short' then
      M._run('go test -short ./...', p, 'Test Short')
    elseif ch.id == 'test_filter' then
      ui().input({ prompt = 'Test name pattern' }, function(f)
        if f and f ~= '' then M._run('go test -run ' .. f .. ' ./...', p, 'Test: ' .. f) end
      end)
    end
  end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle(id, p, back)
  local info = p.info or {}

  if cr().handle(id, back) then return end

  -- Top-level submenus
  if id == 'lifecycle_menu' then
    M.show_lifecycle_menu(p, back)
  elseif id == 'test' then
    M.show_test_menu(p, back)
  elseif id == 'cmds_menu' then
    M.show_cmds_menu(p, back)
  elseif id == 'ws_menu' then
    M.show_ws_menu(p, back)
  elseif id == 'deps_menu' then
    M.show_deps_menu(p, back)

    -- Lifecycle
  elseif id == 'build' then
    M._run('go build ./...', p, 'Build')
  elseif id == 'run' then
    local target = (info.cmds and #info.cmds == 1)
        and ('go run ./cmd/' .. info.cmds[1])
        or 'go run .'
    M._run(target, p, 'Run')
  elseif id == 'vet' then
    M._run('go vet ./...', p, 'Vet')
  elseif id == 'fmt' then
    M._run('gofmt -w .', p, 'Format')
  elseif id == 'lint' then
    M._run('golangci-lint run', p, 'Lint')
  elseif id == 'clean' then
    M._run('go clean ./...', p, 'Clean')
  elseif id == 'doc' then
    M._run('godoc -http=:6060', p, 'godoc')

    -- Specific command
  elseif id:match('^run_cmd__') then
    local cmd = id:sub(10)
    M._run('go run ./cmd/' .. cmd, p, 'Run ' .. cmd)

    -- Workspace
  elseif id == 'ws_sync' then
    M._run('go work sync', p, 'Workspace Sync')
  elseif id == 'ws_members' then
    deps().show_workspace_members(p)

    -- Deps (delegated)
  elseif id:match('^dep_') or id:match('^ws_') then
    deps().handle(id)
  end
end

function M._run(cmd, p, title)
  require('core.runner').execute({
    cmd = cmd,
    cwd = p.root,
    title = title,
    term_cfg = require('marvin').config.terminal,
    plugin   = 'marvin',
  })
end

return M

```

### `lua/marvin/lang/java.lua`

```lua
-- lua/marvin/lang/java.lua
-- Java language module for the Marvin unified dashboard.
-- Contributes menu sections for Maven and Gradle projects.

local M = {}

local function plain(it) return it.label end
local function det() return require('marvin.detector') end
local function ui() return require('marvin.ui') end
local function ex() return require('marvin.executor') end
local function deps() return require('marvin.deps.java') end
local function jc() return require('marvin.creator.java') end

local function sep(l) return { label = l, is_separator = true } end
local function item(id, i, l, d) return { id = id, _icon = i, label = l, desc = d } end
local function sub(id, i, l, d) return { id = id, label = i .. ' ' .. l, desc = d } end

-- ── Project header info ───────────────────────────────────────────────────────
function M.prompt_header(p)
  local info = p.info or {}
  if p.type == 'maven' then
    return string.format('%s:%s  v%s  [%s]',
      info.group_id or '?',
      info.artifact_id or '?',
      info.version or '?',
      info.packaging or 'jar')
  elseif p.type == 'gradle' then
    return string.format('%s  [Gradle%s]',
      info.name or p.name,
      info.has_wrapper and '+wrapper' or '')
  end
  return p.name
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end
  local info = p.info or {}
  local mvn  = p.type == 'maven'
  local tool = mvn and 'Maven' or 'Gradle'

  -- Create
  add(sep('Create'))
  add(item('new_file_menu', '󰬷', 'New Java File…', 'Class, Interface, Record, Enum, Builder…'))
  add(item('new_test', '󰙨', 'New JUnit Test', 'JUnit 5 test class'))
  if mvn then
    add(item('new_project', '󰏗', 'New Maven Project', 'Generate from archetype'))
  end

  -- Build / Lifecycle
  add(sep(tool .. ' Lifecycle'))
  add(item('compile', '󰑕', 'Compile', mvn and 'mvn compile' or './gradlew compileJava'))
  add(item('test', '󰙨', 'Test', mvn and 'mvn test' or './gradlew test'))
  add(item('package', '󰏗', 'Package', mvn and ('Build ' .. (info.artifact_id or '?') .. '.jar') or './gradlew jar'))
  add(item('build_opts', '󰒓', 'Build Options…', 'Skip tests, profiles, fat JAR'))
  add(item('clean', '󰃢', 'Clean', mvn and 'mvn clean' or './gradlew clean'))

  -- Submenus
  add(sep('Tools'))
  add(item('inspect_menu', '󰙅', 'Inspect…', 'Dep tree, effective POM, plugin help'))
  add(item('deps_menu', '󰘦', 'Dependencies…', 'Add, remove, audit, update'))
  add(item('graal_menu', '󰂮', 'GraalVM…', 'Native image, agent, info'))
  add(item('settings_menu', '󰒓', 'Settings…', 'Java version, encoding, formatter'))

  return items
end

-- ── Submenu: Dependencies ─────────────────────────────────────────────────────
function M.show_deps_menu(p, back)
  local items = {}
  for _, di in ipairs(deps().menu_items()) do items[#items + 1] = di end
  ui().select(items, { prompt = 'Dependencies', on_back = back, format_item = plain },
    function(ch) if ch then deps().handle(ch.id) end end)
end

-- ── Submenu: GraalVM ──────────────────────────────────────────────────────────
function M.show_graal_menu(p, back)
  local items = {
    { id = 'graal_build', label = '󰂮 Build Native Image', desc = 'Compile to native binary' },
    { id = 'graal_run', label = '󰐊 Run Native Binary', desc = 'Execute the native build' },
    { id = 'graal_agent', label = '󰋊 Run with Agent', desc = 'Collect reflection config' },
    { id = 'graal_info', label = '󰙅 GraalVM Info', desc = 'Status and install guide' },
  }
  ui().select(items, { prompt = 'GraalVM', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Settings ─────────────────────────────────────────────────────────
function M.show_settings_menu(p, back)
  local mvn = p.type == 'maven'
  local items = {
    { id = 'java_version', label = '󰬷 Set Java Version…', desc = 'maven.compiler.source / target' },
    { id = 'set_encoding', label = '󰉣 Set Encoding…', desc = 'project.build.sourceEncoding' },
  }
  if mvn then
    items[#items + 1] = { id = 'add_spotless', label = '󰉣 Add Spotless', desc = 'Code formatter plugin' }
  end
  ui().select(items, { prompt = 'Project Settings', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle(id, p, back)
  local info = p.info or {}
  local mvn  = p.type == 'maven'

  -- Sub-menu dispatchers
  if id == 'new_file_menu' then
    jc().show_menu(back)
  elseif id == 'new_test' then
    jc().create_file_interactive('Test', {}, back)
  elseif id == 'new_project' then
    require('marvin.generator').create_project()
  elseif id == 'deps_menu' then
    M.show_deps_menu(p, back)
  elseif id == 'graal_menu' then
    M.show_graal_menu(p, back)
  elseif id == 'settings_menu' then
    M.show_settings_menu(p, back)

    -- Lifecycle
  elseif id == 'compile' then
    if mvn then ex().run('compile') else M._gradle('compileJava', p) end
  elseif id == 'test' then
    if mvn then ex().run('test') else M._gradle('test', p) end
  elseif id == 'package' then
    if mvn then ex().run('package') else M._gradle('jar', p) end
  elseif id == 'clean' then
    if mvn then ex().run('clean') else M._gradle('clean', p) end
  elseif id == 'build_opts' then
    M.show_build_opts(p, back)
    -- Inspect
  elseif id == 'inspect_menu' then
    M.show_inspect_menu(p, back)
  elseif id == 'dep_tree' then
    if mvn then ex().run('dependency:tree') else M._gradle('dependencies', p) end
  elseif id == 'dep_analyze' then
    if mvn then ex().run('dependency:analyze') else M._gradle('dependencyInsight', p) end
  elseif id == 'dep_resolve' then
    if mvn then ex().run('dependency:resolve') else M._gradle('dependencies', p) end
  elseif id == 'effective_pom' then
    ex().run('help:effective-pom')
  elseif id == 'effective_settings' then
    ex().run('help:effective-settings')
  elseif id == 'help_describe' then
    M.prompt_describe()

    -- Deps (delegated)
  elseif id:match('^dep_') or id:match('^ws_') then
    deps().handle(id)

    -- GraalVM
  elseif id == 'graal_build' then
    require('marvin.graalvm').build_native(p)
  elseif id == 'graal_run' then
    require('marvin.graalvm').run_native(p)
  elseif id == 'graal_agent' then
    require('marvin.graalvm').run_with_agent(p)
  elseif id == 'graal_info' then
    require('marvin.graalvm').show_info()

    -- Settings
  elseif id == 'java_version' then
    M.prompt_java_version(p)
  elseif id == 'set_encoding' then
    M.prompt_encoding(p)
  elseif id == 'add_spotless' then
    deps().add_spotless(p.root)
  end
end

-- ── Build options sub-menu ────────────────────────────────────────────────────
function M.show_build_opts(p, back)
  local mvn   = p.type == 'maven'
  local info  = p.info or {}
  local items = {
    sub('clean_install', '󰑓', 'Clean & Install', mvn and 'mvn clean install' or './gradlew clean build'),
    sub('install', '󰇚', 'Install', mvn and 'mvn install' or './gradlew publishToMavenLocal'),
    sub('verify', '󰄬', 'Verify', mvn and 'mvn verify' or './gradlew check'),
    sub('skip_tests', '󰒭', 'Build (skip tests)', mvn and '-DskipTests' or '-x test'),
  }
  if mvn and info.has_assembly then
    items[#items + 1] = sub('package_fat', '󱊞', 'Package Fat JAR', 'assembly:single')
  end
  if mvn and info.profiles and #info.profiles > 0 then
    items[#items + 1] = sub('with_profile', '󰒓', 'Run with Profile…',
      #info.profiles .. ' profiles available')
  end

  ui().select(items, { prompt = 'Build Options', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Inspect sub-menu ──────────────────────────────────────────────────────────
function M.show_inspect_menu(p, back)
  local mvn = p.type == 'maven'
  local items = {
    sub('dep_tree', '󰙅', 'Dependency Tree', mvn and 'mvn dependency:tree' or 'gradle dependencies'),
    sub('dep_analyze', '󰍉', 'Dependency Analysis', 'Find unused / undeclared'),
    sub('dep_resolve', '󰚰', 'Resolve Deps', 'Download all dependencies'),
  }
  if mvn then
    items[#items + 1] = sub('effective_pom', '󰈙', 'Effective POM', 'Resolved configuration')
    items[#items + 1] = sub('effective_settings', '󰈙', 'Effective Settings', 'Maven settings')
    items[#items + 1] = sub('help_describe', '󰅾', 'Describe Plugin', 'mvn help:describe')
  end

  ui().select(items, { prompt = 'Inspect', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Profile picker ────────────────────────────────────────────────────────────
function M.show_profile_menu(p, back)
  local profiles = (p.info and p.info.profiles) or {}
  if #profiles == 0 then
    vim.notify('[Marvin] No profiles in pom.xml', vim.log.levels.INFO); return
  end
  local prof_items = {}
  for _, pid in ipairs(profiles) do
    prof_items[#prof_items + 1] = { id = pid, label = pid, desc = 'Maven profile' }
  end
  local goals = {
    { id = 'compile', label = 'compile' }, { id = 'test', label = 'test' },
    { id = 'package', label = 'package' }, { id = 'install', label = 'install' },
    { id = 'verify', label = 'verify' },
  }
  ui().select(goals, { prompt = 'Goal to run', on_back = back, format_item = plain },
    function(goal)
      if not goal then return end
      ui().select(prof_items, { prompt = 'Profile for: ' .. goal.id, format_item = plain },
        function(prof)
          if prof then ex().run(goal.id, { profile = prof.id }) end
        end)
    end)
end

-- ── Prompts ───────────────────────────────────────────────────────────────────
function M.prompt_java_version(p)
  ui().select({
    { version = '21', label = 'Java 21 (LTS)', desc = 'Virtual threads, pattern matching' },
    { version = '17', label = 'Java 17 (LTS)', desc = 'Sealed classes, records' },
    { version = '11', label = 'Java 11 (LTS)', desc = 'Widely adopted' },
    { version = '8', label = 'Java 8  (LTS)', desc = 'Maximum compatibility' },
    { version = '__custom__', label = 'Custom…' },
  }, { prompt = 'Java Version', format_item = plain }, function(ch)
    if not ch then return end
    if ch.version == '__custom__' then
      ui().input({ prompt = 'Java version' }, function(v)
        if v and v ~= '' then deps().set_java_version(v, p.root) end
      end)
    else
      deps().set_java_version(ch.version, p.root)
    end
  end)
end

function M.prompt_encoding(p)
  ui().select({
    { id = 'UTF-8',      label = 'UTF-8',      desc = 'Recommended' },
    { id = 'ISO-8859-1', label = 'ISO-8859-1', desc = 'Latin-1' },
    { id = 'US-ASCII',   label = 'US-ASCII',   desc = 'ASCII only' },
  }, { prompt = 'Source Encoding', format_item = plain }, function(ch)
    if ch then deps().set_encoding(ch.id, p.root) end
  end)
end

function M.prompt_describe()
  vim.ui.input({ prompt = 'Plugin (e.g. maven-compiler-plugin): ' }, function(plugin)
    if plugin and plugin ~= '' then
      ex().run('help:describe -Dplugin=' .. plugin)
    end
  end)
end

-- ── Internal ──────────────────────────────────────────────────────────────────
function M._gradle(task, p)
  local gcmd = vim.fn.filereadable(p.root .. '/gradlew') == 1 and './gradlew' or 'gradle'
  require('core.runner').execute({
    cmd      = gcmd .. ' ' .. task,
    cwd      = p.root,
    title    = 'Gradle ' .. task,
    term_cfg = require('marvin').config.terminal,
    plugin   = 'marvin',
  })
end

return M

```

### `lua/marvin/lang/rust.lua`

```lua
-- lua/marvin/lang/rust.lua
-- Rust language module for the Marvin unified dashboard.

local M = {}

local function plain(it) return it.label end
local function ui() return require('marvin.ui') end
local function deps() return require('marvin.deps.rust') end
local function cr() return require('marvin.creator.rust') end

local function sep(l) return { label = l, is_separator = true } end
local function item(id, i, l, d) return { id = id, _icon = i, label = l, desc = d } end

-- ── Project header ────────────────────────────────────────────────────────────
function M.prompt_header(p)
  local info = p.info or {}
  local kind = info.is_workspace and '[workspace]'
      or (info.is_lib and info.is_bin) and '[bin+lib]'
      or info.is_lib and '[lib]'
      or info.is_bin and '[bin]'
      or '[?]'
  return string.format('%s  v%s  edition %s  %s',
    info.name or p.name,
    info.version or '?',
    info.edition or '2021',
    kind)
end

-- ── Menu items ────────────────────────────────────────────────────────────────
function M.menu_items(p)
  local items = {}
  local function add(t) items[#items + 1] = t end
  local info    = p.info or {}
  local profile = require('marvin').config.rust.profile

  -- Create
  for _, ci in ipairs(cr().menu_items()) do add(ci) end

  -- Cargo
  add(sep('Cargo'))
  add(item('test', '󰙨', 'Test…', 'Run tests'))
  add(item('lifecycle_menu', '󰑕', 'Build & Run…', 'Build, run, clean, fmt, clippy, doc'))
  add(item('toggle_profile', '󰒓',
    'Switch to ' .. (profile == 'release' and 'dev' or 'release'),
    'Currently: ' .. profile))

  -- Submenus
  add(sep('Tools'))
  add(item('deps_menu', '󰘦', 'Dependencies…', 'Add, remove, audit, update'))
  if info.is_workspace and info.members and #info.members > 0 then
    add(item('ws_menu', '󰙅', 'Workspace…',
      #info.members .. ' members'))
  end
  if info.bins and #info.bins > 0 then
    add(item('bins_menu', '󰐊', 'Binaries…',
      #info.bins .. ' binaries'))
  end

  return items
end

-- ── Submenu: Build & Run (lifecycle) ─────────────────────────────────────────
function M.show_lifecycle_menu(p, back)
  local profile = require('marvin').config.rust.profile
  local pflag   = profile == 'release' and ' --release' or ''
  local plab    = profile == 'release' and '(release)' or '(dev)'
  local items   = {
    { id = 'build', label = '󰑕 Build ' .. plab, desc = 'cargo build' .. pflag },
    { id = 'run', label = '󰐊 Run ' .. plab, desc = 'cargo run' .. pflag },
    { id = 'clean', label = '󰃢 Clean', desc = 'cargo clean' },
    { id = 'fmt', label = '󰉣 Format', desc = 'cargo fmt' },
    { id = 'clippy', label = '󰅾 Clippy', desc = 'cargo clippy' },
    { id = 'doc', label = '󰈙 Doc', desc = 'cargo doc --open' },
    { id = 'bench', label = '󰙨 Benchmark', desc = 'cargo bench' },
  }
  ui().select(items, { prompt = 'Build & Run', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Workspace ────────────────────────────────────────────────────────
function M.show_ws_menu(p, back)
  local items = {
    { id = 'ws_members', label = '󰙅 Switch Member', desc = 'Focus a workspace member' },
    { id = 'ws_build_all', label = '󰑕 Build All', desc = 'cargo build --workspace' },
    { id = 'ws_test_all', label = '󰙨 Test All', desc = 'cargo test --workspace' },
  }
  ui().select(items, { prompt = 'Workspace', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Binaries ────────────────────────────────────────────────────────
function M.show_bins_menu(p, back)
  local info    = p.info or {}
  local profile = require('marvin').config.rust.profile
  local pflag   = profile == 'release' and ' --release' or ''
  local items   = {}
  for _, b in ipairs(info.bins or {}) do
    items[#items + 1] = {
      id    = 'run_bin__' .. b.name,
      label = '󰐊 ' .. b.name,
      desc  = 'cargo run' .. pflag .. ' --bin ' .. b.name,
    }
  end
  ui().select(items, { prompt = 'Run Binary', on_back = back, format_item = plain },
    function(ch) if ch then M.handle(ch.id, p, back) end end)
end

-- ── Submenu: Dependencies ────────────────────────────────────────────────────
function M.show_deps_menu(p, back)
  local items = {}
  for _, di in ipairs(deps().menu_items()) do items[#items + 1] = di end
  ui().select(items, { prompt = 'Dependencies', on_back = back, format_item = plain },
    function(ch) if ch then deps().handle(ch.id) end end)
end

-- ── Submenu: Tests ───────────────────────────────────────────────────────────
function M.show_test_menu(p, back)
  ui().select({
    { id = 'test_all', label = '󰙨 All tests', desc = 'cargo test' },
    { id = 'test_filter', label = '󰍉 Filter…', desc = 'cargo test <name>' },
    { id = 'test_doc', label = '󰈙 Doc tests only', desc = 'cargo test --doc' },
    { id = 'test_ignored', label = '󰒭 Run ignored tests', desc = 'cargo test -- --ignored' },
  }, { prompt = 'Run Tests', on_back = back, format_item = plain }, function(ch)
    if not ch then return end
    if ch.id == 'test_all' then
      M._run('cargo test', p, 'Test')
    elseif ch.id == 'test_doc' then
      M._run('cargo test --doc', p, 'Doc Tests')
    elseif ch.id == 'test_ignored' then
      M._run('cargo test -- --ignored', p, 'Ignored Tests')
    elseif ch.id == 'test_filter' then
      ui().input({ prompt = 'Test name filter' }, function(f)
        if f and f ~= '' then M._run('cargo test ' .. f, p, 'Test: ' .. f) end
      end)
    end
  end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle(id, p, back)
  local profile = require('marvin').config.rust.profile
  local pflag   = profile == 'release' and ' --release' or ''

  if cr().handle(id, back) then return end

  -- Top-level submenus
  if id == 'lifecycle_menu' then
    M.show_lifecycle_menu(p, back)
  elseif id == 'test' then
    M.show_test_menu(p, back)
  elseif id == 'ws_menu' then
    M.show_ws_menu(p, back)
  elseif id == 'bins_menu' then
    M.show_bins_menu(p, back)
  elseif id == 'deps_menu' then
    M.show_deps_menu(p, back)

    -- Lifecycle
  elseif id == 'build' then
    M._run('cargo build' .. pflag, p, 'Build')
  elseif id == 'run' then
    M._run('cargo run' .. pflag, p, 'Run')
  elseif id == 'clean' then
    M._run('cargo clean', p, 'Clean')
  elseif id == 'fmt' then
    M._run('cargo fmt', p, 'Format')
  elseif id == 'clippy' then
    M._run('cargo clippy', p, 'Clippy')
  elseif id == 'doc' then
    M._run('cargo doc --open', p, 'Doc')
  elseif id == 'bench' then
    M._run('cargo bench', p, 'Bench')

    -- Profile toggle
  elseif id == 'toggle_profile' then
    local cfg = require('marvin').config
    cfg.rust.profile = cfg.rust.profile == 'release' and 'dev' or 'release'
    vim.notify('[Marvin] Rust profile → ' .. cfg.rust.profile, vim.log.levels.INFO)
    require('marvin.dashboard').show()

    -- Workspace
  elseif id == 'ws_members' then
    deps().show_workspace_members(p)
  elseif id == 'ws_build_all' then
    M._run('cargo build --workspace', p, 'Build All')
  elseif id == 'ws_test_all' then
    M._run('cargo test --workspace', p, 'Test All')

    -- Specific binary
  elseif id:match('^run_bin__') then
    local bin = id:sub(10)
    M._run('cargo run' .. pflag .. ' --bin ' .. bin, p, 'Run ' .. bin)

    -- Deps (delegated)
  elseif id:match('^dep_') or id:match('^ws_') then
    deps().handle(id)
  end
end

function M._run(cmd, p, title)
  require('core.runner').execute({
    cmd = cmd,
    cwd = p.root,
    title = title,
    term_cfg = require('marvin').config.terminal,
    plugin   = 'marvin',
  })
end

return M

```

### `lua/marvin/local_libs.lua`

```lua
-- lua/marvin/local_libs.lua
-- Local static library discovery, registration, linking, and building.
--
-- Discovery order:
--   1. Registered paths in .marvin-libs (per-project config file, auto-created)
--   2. Scan of common dirs: lib/, libs/, build/, . relative to project root
--      (also walks one level deep, e.g. build/lib/)
--
-- Build:
--   Compile all .c/.cpp sources in a directory into a static archive (.a)
--   then optionally export (copy) the .a + headers to a user-chosen prefix.
--
-- Link:
--   Show a picker of discovered libs; user selects which to add. The selected
--   libs produce -L<dir> -l<name> flags that are injected into the build pipeline.

local M = {}

local function ui() return require('marvin.ui') end
local function det() return require('marvin.detector') end
local function plain(it) return it.label end

-- ── Config file helpers ───────────────────────────────────────────────────────
-- .marvin-libs lives at <project_root>/.marvin-libs
-- Format: one path per line (absolute or relative to root)

local CONFIG_FILE = '.marvin-libs'

local function config_path(root)
  return root .. '/' .. CONFIG_FILE
end

local function read_registered(root)
  local path = config_path(root)
  local f    = io.open(path, 'r')
  if not f then return {} end
  local paths = {}
  for line in f:lines() do
    local t = vim.trim(line)
    if t ~= '' and not t:match('^#') then
      paths[#paths + 1] = t
    end
  end
  f:close()
  return paths
end

local function write_registered(root, paths)
  local f = io.open(config_path(root), 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. config_path(root), vim.log.levels.ERROR)
    return false
  end
  f:write('# Marvin local library search paths\n')
  f:write('# One path per line — absolute or relative to project root\n')
  for _, p in ipairs(paths) do
    f:write(p .. '\n')
  end
  f:close()
  return true
end

local function add_registered_path(root, new_path)
  local existing = read_registered(root)
  for _, p in ipairs(existing) do
    if p == new_path then return end -- already registered
  end
  existing[#existing + 1] = new_path
  write_registered(root, existing)
  vim.notify('[Marvin] Registered library path: ' .. new_path, vim.log.levels.INFO)
end

local function remove_registered_path(root, target)
  local existing = read_registered(root)
  local new = {}
  for _, p in ipairs(existing) do
    if p ~= target then new[#new + 1] = p end
  end
  write_registered(root, new)
  vim.notify('[Marvin] Removed library path: ' .. target, vim.log.levels.INFO)
end

-- ── Library scanning ──────────────────────────────────────────────────────────
-- Returns a list of { name, path, dir, kind } where:
--   name = "tui"  (stripped of lib prefix and .a suffix)
--   path = "/abs/path/to/libtui.a"
--   dir  = "/abs/path/to/"  (for -L flag)
--   kind = "static" | "shared"

local SCAN_DIRS = {
  '.',
  'lib',
  'libs',
  'build',
  'build/lib',
  'build/libs',
  'out',
  'out/lib',
  'dist',
}

local function abs(path)
  return vim.fn.fnamemodify(path, ':p'):gsub('/+$', '')
end

local function scan_dir_for_libs(dir_abs)
  local found = {}
  if vim.fn.isdirectory(dir_abs) == 0 then return found end

  -- Find .a and .so/.dylib files one level deep
  local patterns = { '*.a', '*.so', '*.dylib' }
  for _, pat in ipairs(patterns) do
    local files = vim.fn.glob(dir_abs .. '/' .. pat, false, true)
    for _, f in ipairs(files) do
      local fname = vim.fn.fnamemodify(f, ':t')
      local kind  = fname:match('%.a$') and 'static'
          or fname:match('%.so') and 'shared'
          or fname:match('%.dylib$') and 'shared'
          or nil
      if kind then
        -- Strip lib prefix and extension: libtui.a → tui
        local name = fname:gsub('^lib', ''):gsub('%.a$', ''):gsub('%.so.*$', ''):gsub('%.dylib$', '')
        if name ~= '' then
          found[#found + 1] = {
            name = name,
            path = abs(f),
            dir  = dir_abs,
            kind = kind,
          }
        end
      end
    end
  end
  return found
end

-- Deduplicate by path
local function dedup(libs)
  local seen, out = {}, {}
  for _, lib in ipairs(libs) do
    if not seen[lib.path] then
      seen[lib.path] = true
      out[#out + 1] = lib
    end
  end
  return out
end

function M.discover(root)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())
  local all = {}

  -- 1. Registered paths
  for _, rpath in ipairs(read_registered(root)) do
    local resolved = rpath:match('^/') and rpath or (root .. '/' .. rpath)
    resolved = abs(resolved)
    for _, lib in ipairs(scan_dir_for_libs(resolved)) do
      all[#all + 1] = lib
    end
  end

  -- 2. Common dirs
  for _, d in ipairs(SCAN_DIRS) do
    local full = abs(root .. '/' .. d)
    for _, lib in ipairs(scan_dir_for_libs(full)) do
      all[#all + 1] = lib
    end
  end

  return dedup(all)
end

-- ── Companion header dir detection ───────────────────────────────────────────
-- Given a lib path like /some/path/libtui.a, looks for include/ or headers/
-- next to the .a or one level up.
local function find_include_dir(lib)
  local dir = lib.dir
  for _, sub in ipairs({ 'include', 'headers', '../include', '../headers' }) do
    local candidate = abs(dir .. '/' .. sub)
    if vim.fn.isdirectory(candidate) == 1 then
      return candidate
    end
  end
  return nil
end

-- ── Linker flag generation ────────────────────────────────────────────────────
-- Returns { lflags = "-Ldir -lname ...", iflags = "-Iinclude ..." }
function M.flags_for(selected_libs)
  local ldirs, lnames, idirs = {}, {}, {}
  local seen_ldir, seen_inc = {}, {}

  for _, lib in ipairs(selected_libs) do
    if not seen_ldir[lib.dir] then
      seen_ldir[lib.dir] = true
      ldirs[#ldirs + 1] = '-L' .. lib.dir
    end
    lnames[#lnames + 1] = '-l' .. lib.name

    local inc = find_include_dir(lib)
    if inc and not seen_inc[inc] then
      seen_inc[inc] = true
      idirs[#idirs + 1] = '-I' .. inc
    end
  end

  local lflags = table.concat(ldirs, ' ') .. ' ' .. table.concat(lnames, ' ')
  local iflags = table.concat(idirs, ' ')
  return { lflags = vim.trim(lflags), iflags = vim.trim(iflags) }
end

-- ── Persistent selection store ────────────────────────────────────────────────
-- Which libs the user has selected for this project live in .marvin-libs-sel
local SEL_FILE = '.marvin-libs-sel'

local function sel_path(root) return root .. '/' .. SEL_FILE end

local function read_selection(root)
  local f = io.open(sel_path(root), 'r')
  if not f then return {} end
  local sel = {}
  for line in f:lines() do
    local t = vim.trim(line)
    if t ~= '' then sel[t] = true end
  end
  f:close()
  return sel
end

local function write_selection(root, paths_set)
  local f = io.open(sel_path(root), 'w')
  if not f then return end
  for path, _ in pairs(paths_set) do
    f:write(path .. '\n')
  end
  f:close()
end

-- ── Public: get currently selected libs for a project ─────────────────────────
function M.selected_libs(root)
  root           = abs(root)
  local sel      = read_selection(root)
  local all      = M.discover(root)
  local selected = {}
  for _, lib in ipairs(all) do
    if sel[lib.path] then
      selected[#selected + 1] = lib
    end
  end
  return selected
end

-- ── Public: flags to inject into build (called from build.lua CPP engine) ─────
function M.build_flags(root)
  local sel = M.selected_libs(root)
  if #sel == 0 then return { lflags = '', iflags = '' } end
  return M.flags_for(sel)
end

-- ── UI: link picker ───────────────────────────────────────────────────────────
function M.show_link_picker(root, on_done)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())
  local libs = M.discover(root)

  if #libs == 0 then
    vim.notify(
      '[Marvin] No local libraries found.\n'
      .. 'Use "Register Library Path" to add a search directory,\n'
      .. 'or place .a/.so files in lib/, libs/, or build/.',
      vim.log.levels.WARN)
    return
  end

  local sel   = read_selection(root)
  local items = {}
  for _, lib in ipairs(libs) do
    local inc         = find_include_dir(lib)
    local inc_tag     = inc and ('  +I' .. vim.fn.fnamemodify(inc, ':~:.')) or ''
    local tick        = sel[lib.path] and '● ' or '○ '
    items[#items + 1] = {
      id    = lib.path,
      label = tick .. lib.name .. '  [' .. lib.kind .. ']' .. inc_tag,
      desc  = vim.fn.fnamemodify(lib.path, ':~:.'),
      _lib  = lib,
      _sel  = sel[lib.path] or false,
    }
  end

  -- Summary header item
  local n_sel = 0
  for _ in pairs(sel) do n_sel = n_sel + 1 end
  local prompt = string.format('Link Libraries  (%d found, %d selected)', #libs, n_sel)

  ui().select(items, {
    prompt        = prompt,
    enable_search = true,
    format_item   = plain,
  }, function(choice)
    if not choice then
      if on_done then on_done() end
      return
    end
    -- Toggle selection
    if sel[choice.id] then
      sel[choice.id] = nil
    else
      sel[choice.id] = true
    end
    write_selection(root, sel)

    local action = sel[choice.id] and 'Added' or 'Removed'
    vim.notify(
      string.format('[Marvin] %s %s\nFlags: %s',
        action, choice._lib.name,
        M.flags_for(M.selected_libs(root)).lflags),
      vim.log.levels.INFO)

    -- Re-open picker so user can toggle more
    vim.schedule(function() M.show_link_picker(root, on_done) end)
  end)
end

-- ── UI: register a path ───────────────────────────────────────────────────────
function M.show_register_path(root, on_back)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())

  ui().input({
    prompt  = 'Library search path (absolute or relative to project root)',
    default = 'lib',
  }, function(input)
    if not input or input == '' then return end
    local resolved = input:match('^/') and input or (root .. '/' .. input)
    if vim.fn.isdirectory(resolved) == 0 then
      vim.notify(
        '[Marvin] Directory does not exist: ' .. resolved .. '\n'
        .. '(It will still be saved — useful if the dir will be created by a build step)',
        vim.log.levels.WARN)
    end
    add_registered_path(root, input)
    if on_back then on_back() end
  end)
end

-- ── UI: manage registered paths ───────────────────────────────────────────────
function M.show_manage_paths(root, on_back)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())
  local paths = read_registered(root)

  local items = {}
  for _, p in ipairs(paths) do
    items[#items + 1] = {
      id    = p,
      label = '󰍴 ' .. p,
      desc  = 'Click to remove',
    }
  end
  items[#items + 1] = {
    id    = '__add__',
    label = '󰐕 Add new path…',
    desc  = 'Register a directory to scan for .a/.so files',
  }

  local prompt = 'Registered Library Paths'
      .. (#paths > 0 and ('  (' .. #paths .. ')') or '  (none)')

  ui().select(items, {
    prompt      = prompt,
    on_back     = on_back,
    format_item = plain,
  }, function(choice)
    if not choice then return end
    if choice.id == '__add__' then
      M.show_register_path(root, function()
        vim.schedule(function() M.show_manage_paths(root, on_back) end)
      end)
    else
      -- Confirm removal
      ui().select({
        { id = 'yes', label = 'Yes — remove this path' },
        { id = 'no', label = 'Cancel' },
      }, { prompt = 'Remove: ' .. choice.id, format_item = plain }, function(ch)
        if ch and ch.id == 'yes' then
          remove_registered_path(root, choice.id)
        end
        vim.schedule(function() M.show_manage_paths(root, on_back) end)
      end)
    end
  end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- LIBRARY BUILDER
-- Compiles all .c/.cpp sources in a chosen directory into a static archive.
-- ══════════════════════════════════════════════════════════════════════════════

local function run(cmd, root, title, on_exit)
  require('core.runner').execute({
    cmd      = cmd,
    cwd      = root,
    title    = title,
    term_cfg = require('marvin').config.terminal,
    plugin   = 'marvin',
    on_exit  = on_exit,
  })
end

local function esc(s) return vim.fn.shellescape(tostring(s)) end

local function sh_path(p)
  return "'" .. p:gsub("'", "'\\''") .. "'"
end

-- Collect .c/.cpp sources from a directory (non-recursive by default)
local function collect_sources(dir, recursive)
  local exts = { '*.c', '*.cpp', '*.cxx', '*.cc' }
  local files = {}
  for _, pat in ipairs(exts) do
    local glob_pat = recursive and ('**/' .. pat) or pat
    local found    = vim.fn.glob(dir .. '/' .. glob_pat, false, true)
    for _, f in ipairs(found) do
      files[#files + 1] = abs(f)
    end
  end
  return files
end

-- Infer include dirs relative to the source dir
local function infer_includes(src_dir, root)
  local candidates = {
    src_dir,
    src_dir .. '/include',
    src_dir .. '/../include',
    root .. '/include',
    root,
  }
  local flags      = {}
  local seen       = {}
  for _, d in ipairs(candidates) do
    local a = abs(d)
    if not seen[a] and vim.fn.isdirectory(a) == 1 then
      seen[a] = true
      flags[#flags + 1] = '-I' .. a
    end
  end
  return flags
end

-- Build a static lib from sources in `src_dir`, output to `out_dir/lib<name>.a`
function M.build_static(opts)
  -- opts: { name, src_dir, out_dir, root, recursive, std, cflags }
  local name      = opts.name
  local src_dir   = abs(opts.src_dir)
  local out_dir   = abs(opts.out_dir)
  local root      = abs(opts.root or vim.fn.getcwd())
  local std       = opts.std or 'c11'
  local cflags    = opts.cflags or '-Wall -Wextra'
  local recursive = opts.recursive ~= false -- default true

  local sources   = collect_sources(src_dir, recursive)
  if #sources == 0 then
    vim.notify('[Marvin] No C/C++ sources found in: ' .. src_dir, vim.log.levels.ERROR)
    return
  end

  -- Detect language from sources
  local has_cpp = false
  for _, f in ipairs(sources) do
    if f:match('%.cpp$') or f:match('%.cxx$') or f:match('%.cc$') then
      has_cpp = true; break
    end
  end
  local cc        = has_cpp and 'g++' or 'gcc'
  local std_flag  = '-std=' .. (has_cpp and std:gsub('^c(%d)', 'c++%1') or std)

  local inc_flags = table.concat(infer_includes(src_dir, root), ' ')
  local obj_dir   = out_dir .. '/.marvin-obj-' .. name
  local archive   = out_dir .. '/lib' .. name .. '.a'

  -- Build compile steps for each source
  local steps     = {
    'mkdir -p ' .. esc(obj_dir),
    'mkdir -p ' .. esc(out_dir),
  }
  local obj_files = {}
  for _, src in ipairs(sources) do
    local rel                 = vim.fn.fnamemodify(src, ':t:r')
    local obj                 = obj_dir .. '/' .. rel .. '.o'
    obj_files[#obj_files + 1] = obj
    steps[#steps + 1]         = string.format(
      '%s %s %s %s -c %s -o %s',
      cc, std_flag, cflags, inc_flags, esc(src), esc(obj))
  end

  -- Archive step
  steps[#steps + 1] = string.format(
    'ar rcs %s %s',
    esc(archive),
    table.concat(vim.tbl_map(esc, obj_files), ' '))

  -- Cleanup obj dir
  steps[#steps + 1] = 'rm -rf ' .. esc(obj_dir)

  local cmd = table.concat(steps, ' && \\\n  ')
  local title = 'Build lib' .. name .. '.a'

  run(cmd, root, title, function(ok)
    if ok then
      vim.notify(
        string.format('[Marvin] ✅ Built %s\n→ %s', 'lib' .. name .. '.a', archive),
        vim.log.levels.INFO)
      -- Offer to export
      vim.schedule(function()
        M.show_export_prompt(name, archive, src_dir, root)
      end)
    else
      vim.notify('[Marvin] ❌ Build failed for lib' .. name .. '.a', vim.log.levels.ERROR)
    end
  end)
end

-- ── Export / install built library ───────────────────────────────────────────
-- Copies the .a and header files to a chosen destination so other projects
-- can discover it via scan or registered path.

function M.show_export_prompt(name, archive_path, src_dir, root)
  ui().select({
    { id = 'local_lib', label = '󰉿 Export to project lib/ dir', desc = root .. '/lib/lib' .. name .. '.a' },
    { id = 'local_home', label = '󰋜 Export to ~/.local/lib', desc = '~/.local/lib/lib' .. name .. '.a' },
    { id = 'custom', label = '󰏫 Choose export directory…', desc = 'Enter a custom path' },
    { id = 'skip', label = '󰅖 Skip export', desc = 'Keep the .a where it is' },
  }, { prompt = 'Export lib' .. name .. '.a ?', format_item = plain }, function(choice)
    if not choice or choice.id == 'skip' then return end

    local function do_export(dest_dir)
      dest_dir = abs(dest_dir)
      -- Also copy headers if include/ exists next to src
      local inc_src = nil
      for _, sub in ipairs({ src_dir .. '/include', abs(src_dir .. '/../include'), root .. '/include' }) do
        if vim.fn.isdirectory(sub) == 1 then
          inc_src = sub; break
        end
      end

      local dest_lib    = dest_dir .. '/lib' .. name .. '.a'
      local steps       = { 'mkdir -p ' .. esc(dest_dir) }
      steps[#steps + 1] = 'cp ' .. esc(archive_path) .. ' ' .. esc(dest_lib)

      local dest_inc    = nil
      if inc_src then
        dest_inc = dest_dir .. '/include'
        -- Only copy headers named after the lib (lib-specific) or all if small
        steps[#steps + 1] = 'mkdir -p ' .. esc(dest_inc)
        steps[#steps + 1] = 'cp -r ' .. esc(inc_src) .. '/. ' .. esc(dest_inc) .. '/'
      end

      local cmd = table.concat(steps, ' && \\\n  ')
      run(cmd, root, 'Export lib' .. name .. '.a', function(ok)
        if not ok then
          vim.notify('[Marvin] ❌ Export failed', vim.log.levels.ERROR)
          return
        end
        vim.notify(
          string.format('[Marvin] ✅ Exported lib%s.a → %s', name, dest_dir),
          vim.log.levels.INFO)
        -- Offer to register the destination as a search path
        vim.schedule(function()
          M.show_register_after_export(root, dest_dir)
        end)
      end)
    end

    if choice.id == 'local_lib' then
      do_export(root .. '/lib')
    elseif choice.id == 'local_home' then
      do_export(vim.fn.expand('~/.local/lib'))
    elseif choice.id == 'custom' then
      ui().input({ prompt = 'Export directory', default = root .. '/lib' }, function(d)
        if d and d ~= '' then do_export(d) end
      end)
    end
  end)
end

-- After export: offer to register the dir so it shows up in the link picker
function M.show_register_after_export(root, exported_dir)
  local rel = exported_dir:sub(#root + 2) -- make relative if inside project
  local display = rel ~= '' and rel or exported_dir

  ui().select({
    { id = 'yes', label = '󰐕 Yes — register "' .. display .. '" as a library search path' },
    { id = 'no', label = '󰅖 No thanks' },
  }, { prompt = 'Register path for auto-discovery?', format_item = plain }, function(ch)
    if ch and ch.id == 'yes' then
      add_registered_path(root, display)
    end
  end)
end

-- ── UI: Build Library wizard ──────────────────────────────────────────────────
function M.show_build_wizard(root, on_back)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())

  -- Step 1: library name
  ui().input({ prompt = '󰙲 Library name (e.g. tui, utils)', default = '' }, function(name)
    if not name or name == '' then return end
    name = name:gsub('^lib', '') -- strip accidental "lib" prefix

    -- Step 2: source directory
    ui().select({
      { id = 'src', label = 'src/', desc = root .. '/src' },
      { id = 'lib', label = 'lib/', desc = root .. '/lib' },
      { id = 'root', label = '. (project root)', desc = root },
      { id = 'custom', label = '󰏫 Custom…', desc = 'Enter path' },
    }, { prompt = 'Source directory', on_back = on_back, format_item = plain }, function(src_ch)
      if not src_ch then return end

      local function after_src(src_dir)
        -- Step 3: output directory
        ui().select({
          { id = 'lib', label = 'lib/', desc = root .. '/lib (recommended)' },
          { id = 'build', label = 'build/', desc = root .. '/build' },
          { id = 'custom', label = '󰏫 Custom…', desc = 'Enter path' },
        }, { prompt = 'Output directory for .a', format_item = plain }, function(out_ch)
          if not out_ch then return end

          local function after_out(out_dir)
            -- Step 4: C standard
            ui().select({
              { id = 'c11',   label = 'C11',   desc = 'Recommended for C' },
              { id = 'c17',   label = 'C17' },
              { id = 'c++17', label = 'C++17', desc = 'If sources are C++' },
              { id = 'c++20', label = 'C++20' },
            }, { prompt = 'Language standard', format_item = plain }, function(std_ch)
              local std = std_ch and std_ch.id or 'c11'

              -- Step 5: extra cflags
              ui().input({
                prompt  = 'Extra CFLAGS (optional)',
                default = '-Wall -Wextra -O2',
              }, function(cflags)
                M.build_static({
                  name      = name,
                  src_dir   = src_dir,
                  out_dir   = out_dir,
                  root      = root,
                  std       = std,
                  cflags    = cflags or '-Wall -Wextra -O2',
                  recursive = true,
                })
              end)
            end)
          end

          if out_ch.id == 'custom' then
            ui().input({ prompt = 'Output directory', default = root .. '/lib' }, function(d)
              if d and d ~= '' then after_out(d) end
            end)
          else
            after_out(root .. '/' .. out_ch.id)
          end
        end)
      end

      if src_ch.id == 'custom' then
        ui().input({ prompt = 'Source directory', default = root }, function(d)
          if d and d ~= '' then after_src(d) end
        end)
      else
        after_src(src_ch.id == 'root' and root or (root .. '/' .. src_ch.id))
      end
    end)
  end)
end

-- ── Main menu items (for lang/cpp.lua injection) ──────────────────────────────
function M.menu_items()
  local items = {}
  local function sep(l) items[#items + 1] = { label = l, is_separator = true } end
  local function it(id, icon, label, desc)
    items[#items + 1] = { id = id, label = icon .. ' ' .. label, desc = desc }
  end
  sep('Local Libraries')
  it('libs_link', '󰘦', 'Link Libraries…', 'Pick local .a/.so libs to link')
  it('libs_build', '󰑕', 'Build Static Library…', 'Compile sources → .a archive')
  it('libs_paths', '󰉿', 'Manage Library Paths…', 'Register / remove search dirs')
  it('libs_report', '󰙅', 'Library Report', 'Show discovered libs + active flags')
  return items
end

function M.handle(id, root, on_back)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())

  if id == 'libs_link' then
    M.show_link_picker(root, on_back)
  elseif id == 'libs_build' then
    M.show_build_wizard(root, on_back)
  elseif id == 'libs_paths' then
    M.show_manage_paths(root, on_back)
  elseif id == 'libs_report' then
    M.show_report(root)
  end
end

-- ── Report ────────────────────────────────────────────────────────────────────
function M.show_report(root)
  root = abs(root or (det().get() or {}).root or vim.fn.getcwd())
  local all = M.discover(root)
  local sel = read_selection(root)

  local lines = {
    '',
    '  Local Library Report — ' .. vim.fn.fnamemodify(root, ':t'),
    '  ' .. string.rep('─', 56),
  }

  if #all == 0 then
    lines[#lines + 1] = '  (no libraries found)'
  else
    lines[#lines + 1] = string.format('  %-20s %-8s  %s', 'Library', 'Kind', 'Path')
    lines[#lines + 1] = '  ' .. string.rep('─', 56)
    for _, lib in ipairs(all) do
      local tick = sel[lib.path] and '● ' or '○ '
      lines[#lines + 1] = string.format('  %s%-18s %-8s  %s',
        tick, lib.name, lib.kind, vim.fn.fnamemodify(lib.path, ':~:.'))
    end
  end

  lines[#lines + 1] = ''
  local flags = M.build_flags(root)
  if flags.lflags ~= '' then
    lines[#lines + 1] = '  Active link flags:'
    lines[#lines + 1] = '    LDFLAGS: ' .. flags.lflags
    if flags.iflags ~= '' then
      lines[#lines + 1] = '    IFLAGS:  ' .. flags.iflags
    end
  else
    lines[#lines + 1] = '  No libraries selected for linking.'
    lines[#lines + 1] = '  Use "Link Libraries…" to pick from discovered libs.'
  end

  lines[#lines + 1] = ''
  lines[#lines + 1] = '  Registered search paths:'
  local reg = read_registered(root)
  if #reg == 0 then
    lines[#lines + 1] = '    (none)'
  else
    for _, p in ipairs(reg) do
      lines[#lines + 1] = '    ' .. p
    end
  end
  lines[#lines + 1] = ''

  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

return M

```

### `lua/marvin/makefile_creator.lua`

```lua
-- lua/marvin/makefile_creator.lua
-- Universal interactive Makefile wizard.
-- Supports: C, C++, Go, Rust, and Generic projects.
-- For C/C++: integrates auto-link detection from marvin.creator.cpp
--            AND selected local libraries from marvin.local_libs.
--            AND pkg-config auto-detection for system libraries that
--            cannot be found via simple -l flags (wlroots, wayland,
--            libinput, xkbcommon, cairo, pango, …).

local M = {}

local ui = function() return require('marvin.ui') end

-- ── pkg-config header → package name map ──────────────────────────────────────
-- Each entry: { pattern matched against #include path, pkg-config name }
-- Order matters: more-specific patterns first.

-- ── POSIX headers whose mere inclusion requires _POSIX_C_SOURCE ───────────────
local _posix_hdr_set = {
  ['unistd.h'] = true,
  ['pthread.h'] = true,
  ['sys/types.h'] = true,
  ['sys/stat.h'] = true,
  ['sys/wait.h'] = true,
  ['sys/file.h'] = true,
  ['sys/socket.h'] = true,
  ['sys/mman.h'] = true,
  ['dirent.h'] = true,
  ['fcntl.h'] = true,
  ['signal.h'] = true,
  ['termios.h'] = true,
  ['netinet/in.h'] = true,
  ['arpa/inet.h'] = true,
  ['netdb.h'] = true,
  ['openssl/ssl.h'] = true,
  ['curl/curl.h'] = true,
  ['readline/readline.h'] = true,
}

local _posix_fn_set = {}
for _, fn in ipairs({
  'strtok_r', 'strndup', 'strdup', 'getline', 'getdelim', 'dprintf', 'asprintf', 'vasprintf',
  'fdopen', 'fileno', 'popen', 'pclose', 'ftruncate', 'fchmod', 'fsync', 'fdatasync',
  'openat', 'mkstemp', 'mkdtemp', 'fork', 'vfork', 'execvp', 'execve', 'execle', 'execl', 'execv',
  'setsid', 'setpgid', 'waitpid', 'wait3', 'wait4', 'flock', 'lockf',
  'opendir', 'readdir', 'closedir', 'scandir', 'nftw', 'symlink', 'readlink', 'realpath',
  'dirname', 'basename', 'socket', 'bind', 'listen', 'accept', 'connect', 'send', 'recv',
  'getaddrinfo', 'freeaddrinfo', 'getnameinfo', 'clock_gettime', 'nanosleep', 'timer_create',
  'gethostname', 'sysconf', 'mmap', 'munmap', 'pipe', 'dup', 'dup2', 'dup3',
  'usleep', 'truncate', 'chown', 'chmod', 'lstat', 'getcwd', 'chdir', 'unlink', 'rmdir',
  'setenv', 'unsetenv', 'dlopen', 'dlsym', 'sem_open', 'sem_wait', 'sem_post', 'shm_open',
  'pthread_create', 'pthread_join', 'pthread_mutex_lock',
}) do _posix_fn_set[fn] = true end

-- ── Scan source tree for POSIX usage ─────────────────────────────────────────
local function project_needs_posix(root)
  local patterns = { '*.c', '*.cpp', '*.h', '*.hpp', '*.cxx', '*.hxx' }
  for _, pat in ipairs(patterns) do
    local files = vim.fn.globpath(root, '**/' .. pat, false, true)
    for _, f in ipairs(files) do
      local ok, lines = pcall(vim.fn.readfile, f)
      if ok then
        for _, line in ipairs(lines) do
          local hdr = line:match('#%s*include%s*[<\"]([^>\"]+)[>\"]')
          if hdr and _posix_hdr_set[hdr] then return true end
          for fn in line:gmatch('([%a_][%w_]*)%s*%(') do
            if _posix_fn_set[fn] then return true end
          end
        end
      end
    end
  end
  return false
end

-- ── pkg-config detection ──────────────────────────────────────────────────────
-- Scans all C/C++ source and header files for #include patterns that correspond
-- to libraries best described via pkg-config. Returns a de-duplicated list of
-- pkg-config package names that are actually installed on this system.
-- ── Dynamic pkg-config dependency detection ──────────────────────────────────
-- Builds a header→package reverse map from whatever is installed on this system.
-- No hardcoded list needed — works for any library with a .pc file.

local _hdr_pkg_map_cache = nil
local function get_hdr_pkg_map()
  if _hdr_pkg_map_cache then return _hdr_pkg_map_cache end
  local map = {}

  local h = io.popen('pkg-config --list-all 2>/dev/null')
  if not h then
    _hdr_pkg_map_cache = map; return map
  end
  local pkgs = {}
  for line in h:lines() do
    local name = line:match('^(%S+)')
    if name then pkgs[#pkgs + 1] = name end
  end
  h:close()

  local scanned = {}
  for _, pkg in ipairs(pkgs) do
    local dirs = {}
    -- explicit -I flags
    local ch = io.popen('pkg-config --cflags-only-I ' .. pkg .. ' 2>/dev/null')
    if ch then
      local out = ch:read('*a'); ch:close()
      for token in out:gmatch('%S+') do
        if token:sub(1, 2) == '-I' then dirs[#dirs + 1] = token:sub(3) end
      end
    end
    -- includedir variable
    local ih = io.popen('pkg-config --variable=includedir ' .. pkg .. ' 2>/dev/null')
    if ih then
      local d = vim.trim(ih:read('*l') or ''); ih:close()
      if d ~= '' then dirs[#dirs + 1] = d end
    end
    -- guess <includedir>/<stem> for packages like harfbuzz in /usr/include/harfbuzz/
    local stem = pkg:match('^([%a%d]+)')
    if stem then
      for _, base in ipairs({ '/usr/include', '/usr/local/include' }) do
        if vim.fn.isdirectory(base .. '/' .. stem) == 1 then
          dirs[#dirs + 1] = base
          dirs[#dirs + 1] = base .. '/' .. stem
        end
      end
    end
    for _, dir in ipairs(dirs) do
      if not scanned[dir] and vim.fn.isdirectory(dir) == 1 then
        scanned[dir] = true
        local fh = io.popen('ls ' .. vim.fn.shellescape(dir) .. ' 2>/dev/null')
        if fh then
          for entry in fh:lines() do
            if entry:match('%.h$') then
              if not map[entry] then map[entry] = pkg end
            elseif vim.fn.isdirectory(dir .. '/' .. entry) == 1 then
              local sh = io.popen('ls ' .. vim.fn.shellescape(dir .. '/' .. entry) .. ' 2>/dev/null')
              if sh then
                for hdr in sh:lines() do
                  if hdr:match('%.h$') then
                    local key = entry .. '/' .. hdr
                    if not map[key] then map[key] = pkg end
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
  if map[inc] then return map[inc] end
  local fname = inc:match('([^/]+)$')
  return fname and map[fname] or nil
end


-- Resolve a base pkg-config name to the actual installed name.
-- Handles versioned packages: 'wlroots' → 'wlroots-0.18' etc.
local _pkg_resolve_cache = {}
local function resolve_pkg(base)
  if _pkg_resolve_cache[base] ~= nil then return _pkg_resolve_cache[base] or nil end
  -- 1. Exact name
  if os.execute('pkg-config --exists ' .. base .. ' 2>/dev/null') == 0 then
    _pkg_resolve_cache[base] = base; return base
  end
  -- 2. Versioned variant: e.g. wlroots-0.18
  local h = io.popen(
    "pkg-config --list-all 2>/dev/null | grep -E '^" .. base .. "[-[:space:]]' | head -1 | awk '{print $1}'")
  if h then
    local found = vim.trim(h:read('*l') or ''); h:close()
    if found ~= '' then
      _pkg_resolve_cache[base] = found; return found
    end
  end
  _pkg_resolve_cache[base] = false; return nil
end

local function detect_pkg_deps(root)
  local patterns = { '*.c', '*.cpp', '*.h', '*.hpp', '*.cxx', '*.hxx' }
  local found    = {}
  local ordered  = {}

  for _, pat in ipairs(patterns) do
    for _, f in ipairs(vim.fn.globpath(root, '**/' .. pat, false, true)) do
      if not f:find('/build', 1, true) and not f:find('/builddir', 1, true) then
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            local inc = line:match('#%s*include%s*[<\"]([^>\"]+)[>\"]')
            if inc then
              local pkg = include_to_pkg(inc)
              if pkg and not found[pkg] then
                local resolved = resolve_pkg(pkg)
                if resolved then
                  found[pkg]            = true
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
-- ── wlroots unstable guard ────────────────────────────────────────────────────
local function scan_needs_wlr_unstable(root)
  for _, pat in ipairs({ '**/*.c', '**/*.cpp', '**/*.cxx', '**/*.h', '**/*.hpp' }) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
      if not f:find('/build', 1, true) and not f:find('/builddir', 1, true) then
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            if line:match('#%s*include%s*[<\"]wlr/') then return true end
            if line:match('WLR_USE_UNSTABLE') then return true end
          end
        end
      end
    end
  end
  return false
end

-- ── Language detection helper ─────────────────────────────────────────────────
local function infer_lang(root)
  if vim.fn.filereadable(root .. '/Cargo.toml') == 1 then return 'rust' end
  if vim.fn.filereadable(root .. '/go.mod') == 1 then return 'go' end
  local cpp_files = vim.fn.globpath(root, '**/*.cpp', false, true)
  local cxx_files = vim.fn.globpath(root, '**/*.cxx', false, true)
  local c_files   = vim.fn.globpath(root, '**/*.c', false, true)
  if #cpp_files > 0 or #cxx_files > 0 then return 'cpp' end
  if #c_files > 0 then return 'c' end
  return nil
end

-- ── Auto-link integration ─────────────────────────────────────────────────────
-- Returns { ldflags, iflags, pkg_deps, wlr_guard } merging:
--   1. #include-scanned system libs (non-pkg-config, e.g. -lpthread)
--   2. pkg-config packages detected from includes
--   3. selected local libraries (.a/.so) from local_libs
local function auto_detect_flags(root)
  local ldflags     = ''
  local iflags      = ''

  -- 1. Simple -l flags from #include scanning (creator.cpp / build.lua engine)
  local ok_cr, cr   = pcall(require, 'marvin.creator.cpp')
  local ok_det, det = pcall(require, 'marvin.detector')
  if ok_cr and ok_det then
    local p = det.get()
    if p then
      local links = cr.detect_links(p)
      if links then ldflags = links.ldflags or '' end
    end
  end

  -- 2. Local .a/.so libraries
  local ok_ll, ll = pcall(require, 'marvin.local_libs')
  if ok_ll then
    local lf = ll.build_flags(root)
    if lf.lflags ~= '' then ldflags = vim.trim(ldflags .. ' ' .. lf.lflags) end
    if lf.iflags ~= '' then iflags = vim.trim(iflags .. ' ' .. lf.iflags) end
  end

  -- 3. pkg-config packages — use build.cpp.pkg_config_flags which works correctly
  local pkg_deps    = {}
  local wlr_guard   = false
  local ok_b, build = pcall(require, 'marvin.build')
  if ok_b and build.cpp and build.cpp.pkg_config_flags then
    local ok_f, flags = pcall(build.cpp.pkg_config_flags, root)
    if ok_f then
      pkg_deps = flags.pkg_names or {}
      for _, f in ipairs(flags.iflags or {}) do
        if f == '-DWLR_USE_UNSTABLE' then wlr_guard = true end
      end
    end
  end
  if not wlr_guard then wlr_guard = scan_needs_wlr_unstable(root) end

  return { ldflags = ldflags, iflags = iflags, pkg_deps = pkg_deps, wlr_guard = wlr_guard }
end

-- ── Shared helpers ────────────────────────────────────────────────────────────
local function write_makefile(path, content, name)
  local f = io.open(path, 'w')
  if not f then
    vim.notify('[Marvin] Failed to write Makefile: ' .. path, vim.log.levels.ERROR); return false
  end
  f:write(content); f:close()
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.notify('[Marvin] Makefile created for: ' .. name, vim.log.levels.INFO)
  return true
end

local function check_existing(path, content, opts, root)
  if vim.fn.filereadable(path) == 1 then
    ui().select({
        { id = 'overwrite', label = 'Overwrite', desc = 'Replace the existing Makefile' },
        { id = 'cancel',    label = 'Cancel',    desc = 'Keep the existing file' },
      }, { prompt = 'Makefile already exists', format_item = function(it) return it.label end },
      function(choice)
        if choice and choice.id == 'overwrite' then
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

-- ── C template ────────────────────────────────────────────────────────────────


local function c_template(opts)
  local name         = opts.name
  local cc           = opts.compiler or 'gcc'
  local std          = opts.std or 'c11'
  local src          = opts.src or 'src'
  local inc          = opts.inc or 'include'
  local out          = opts.out or name
  local extra        = opts.cflags or ''
  local lflags       = vim.trim((opts.ldflags or '') .. ' ' .. (opts.libs or ''))
  local iflags       = opts.iflags or ''
  local pkg_deps     = opts.pkg_deps or {}
  local wlr_guard    = opts.wlr_guard or false

  local cflags_parts = { '-std=' .. std, '-Wall -Wextra -pedantic' }
  if opts.needs_posix then cflags_parts[#cflags_parts + 1] = '-D_POSIX_C_SOURCE=200809L' end
  if wlr_guard then cflags_parts[#cflags_parts + 1] = '-DWLR_USE_UNSTABLE' end
  if extra ~= '' then cflags_parts[#cflags_parts + 1] = extra end
  if iflags ~= '' then cflags_parts[#cflags_parts + 1] = iflags end
  local cflags_str = table.concat(cflags_parts, ' ')

  local has_pkg = #pkg_deps > 0
  local pkg_line = has_pkg and table.concat(pkg_deps, ' ') or ''

  local lines = {
    '# ' .. name .. ' — generated by Marvin',
    '#',
    '# Usage:',
    '#   make          Build the binary',
    '#   make test     Run tests (add test runner)',
    '#   make clean    Remove build artefacts',
    '#   make install  Install to /usr/local/bin',
    '#   make dist     Copy binary to dist/',
    '',
    'CC      := ' .. cc,
  }

  if has_pkg then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '# ── pkg-config dependencies (' .. pkg_line .. ') ──'
    lines[#lines + 1] = 'PKG_DEPS    := ' .. pkg_line
    lines[#lines + 1] = 'PKG_CFLAGS  := $(shell pkg-config --cflags $(PKG_DEPS))'
    lines[#lines + 1] = 'PKG_LIBS    := $(shell pkg-config --libs   $(PKG_DEPS))'
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'CFLAGS  := ' .. cflags_str .. ' $(PKG_CFLAGS)'
        .. (opts.protocol_xmls and #opts.protocol_xmls > 0 and ' -Iinclude/protocols' or '')
    lines[#lines + 1] = 'LDFLAGS := ' .. lflags .. ' $(PKG_LIBS)'
  else
    lines[#lines + 1] = 'CFLAGS  := ' .. cflags_str
        .. (opts.protocol_xmls and #opts.protocol_xmls > 0 and ' -Iinclude/protocols' or '')
    lines[#lines + 1] = 'LDFLAGS := ' .. lflags
  end

  local proto_deps = ''
  if opts.protocol_xmls and #opts.protocol_xmls > 0 then
    local ph = {}
    for _, xml in ipairs(opts.protocol_xmls) do
      ph[#ph + 1] = 'include/protocols/' .. xml:gsub('%.xml$', '') .. '-protocol.h'
    end
    proto_deps = ' ' .. table.concat(ph, ' ')
  end

  local rest = {
    '',
    'SRC_DIR := ' .. src,
    'INC_DIR := ' .. inc,
    'OBJ_DIR := build/obj',
    'BIN_DIR := build/bin',
    '',
    'TARGET  := $(BIN_DIR)/' .. out,
    'SRCS    := $(wildcard $(SRC_DIR)/*.c)',
    'OBJS    := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRCS))',
    'DEPS    := $(OBJS:.o=.d)',
    '',
    '.PHONY: all clean test install dist',
    '',
    'all:' .. proto_deps .. ' $(TARGET)',
    '',
    '$(TARGET): $(OBJS) | $(BIN_DIR)',
    '\t$(CC) $^ -o $@ $(LDFLAGS)',
    '',
    '$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)',
    '\t$(CC) $(CFLAGS) -I$(INC_DIR) -MMD -MP -c $< -o $@',
    '',
    '-include $(DEPS)',
    '',
    '$(OBJ_DIR) $(BIN_DIR):',
    '\t@mkdir -p $@',
    '',
    'clean:',
    '\t@rm -rf build/',
    '\t@echo "Cleaned."',
    '',
    'test:',
    '\t@echo "No test runner configured. Add your test command here."',
    '',
    'install: $(TARGET)',
    '\t@install -m 755 $(TARGET) /usr/local/bin/' .. out,
    '\t@echo "Installed → /usr/local/bin/' .. out .. '"',
    '',
    'dist: all',
    '\t@mkdir -p dist',
    '\t@cp $(TARGET) dist/',
    '\t@echo "Distribution ready in dist/"',
    '',
  }
  for _, l in ipairs(rest) do lines[#lines + 1] = l end

  -- Wayland protocol generation rules (appended after rest)
  if opts.protocol_xmls and #opts.protocol_xmls > 0 then
    lines[#lines + 1] = '# ── Wayland protocol generation ─────────────────────────────────────────────'
    for _, xml in ipairs(opts.protocol_xmls) do
      local stem = xml:gsub('%.xml$', '')
      local xml_path = 'include/protocols/' .. xml
      local hdr_path = 'include/protocols/' .. stem .. '-protocol.h'
      local src_path = 'include/protocols/' .. stem .. '-protocol.c'
      lines[#lines + 1] = hdr_path .. ' ' .. src_path .. ': ' .. xml_path
      lines[#lines + 1] = '\t@wayland-scanner client-header $< ' .. hdr_path
      lines[#lines + 1] = '\t@wayland-scanner private-code  $< ' .. src_path
      lines[#lines + 1] = '\t@echo "Generated: ' .. stem .. '-protocol.{h,c}"'
      lines[#lines + 1] = ''
    end
    -- prepend protocol header deps to SRCS so objects rebuild when headers change
    lines[#lines + 1] = '# Protocol headers are listed as explicit dependencies'
    local proto_headers = {}
    for _, xml in ipairs(opts.protocol_xmls) do
      proto_headers[#proto_headers + 1] = 'include/protocols/' .. xml:gsub('%.xml$', '') .. '-protocol.h'
    end
    lines[#lines + 1] = 'PROTO_HEADERS := ' .. table.concat(proto_headers, ' ')
    lines[#lines + 1] = '$(OBJS): $(PROTO_HEADERS)'
    lines[#lines + 1] = ''
  end

  return table.concat(lines, '\n')
end

-- ── C++ template ──────────────────────────────────────────────────────────────
local function cpp_template(opts)
  local name      = opts.name
  local cxx       = opts.compiler or 'g++'
  local std       = opts.std or 'c++17'
  local src       = opts.src or 'src'
  local inc       = opts.inc or 'include'
  local out       = opts.out or name
  local extra     = opts.cflags or ''
  local lflags    = vim.trim((opts.ldflags or '') .. ' ' .. (opts.libs or ''))
  local iflags    = opts.iflags or ''
  local pkg_deps  = opts.pkg_deps or {}
  local wlr_guard = opts.wlr_guard or false

  local san_flags = ''
  if opts.sanitizer == 'asan' then
    san_flags = ' -fsanitize=address -fno-omit-frame-pointer'
  elseif opts.sanitizer == 'tsan' then
    san_flags = ' -fsanitize=thread'
  elseif opts.sanitizer == 'ubsan' then
    san_flags = ' -fsanitize=undefined'
  end

  local cflags_parts = { '-std=' .. std, '-Wall -Wextra -pedantic' }
  if opts.needs_posix then cflags_parts[#cflags_parts + 1] = '-D_POSIX_C_SOURCE=200809L' end
  if wlr_guard then cflags_parts[#cflags_parts + 1] = '-DWLR_USE_UNSTABLE' end
  if extra ~= '' then cflags_parts[#cflags_parts + 1] = extra end
  if san_flags ~= '' then cflags_parts[#cflags_parts + 1] = vim.trim(san_flags) end
  if iflags ~= '' then cflags_parts[#cflags_parts + 1] = iflags end
  local cflags_str      = table.concat(cflags_parts, ' ')

  local has_pkg         = #pkg_deps > 0
  local pkg_line        = has_pkg and table.concat(pkg_deps, ' ') or ''

  local cc_json_section = opts.compile_commands and table.concat({
    '',
    'compile_commands:',
    '\t@if command -v bear >/dev/null 2>&1; then \\',
    '\t  bear -- $(MAKE) all; \\',
    '\telse \\',
    '\t  echo "install bear for compile_commands.json"; \\',
    '\tfi',
  }, '\n') or ''

  local lines           = {
    '# ' .. name .. ' — generated by Marvin',
    '#',
    '# Usage:',
    '#   make                 Build the binary',
    '#   make test            Run tests',
    '#   make clean           Remove build artefacts',
    '#   make install         Install to /usr/local/bin',
    '#   make dist            Copy binary to dist/',
    opts.compile_commands
    and '#   make compile_commands  Regenerate compile_commands.json (requires bear)'
    or '',
    '',
    'CXX      := ' .. cxx,
  }

  if has_pkg then
    lines[#lines + 1] = ''
    lines[#lines + 1] = '# ── pkg-config dependencies (' .. pkg_line .. ') ──'
    lines[#lines + 1] = 'PKG_DEPS    := ' .. pkg_line
    lines[#lines + 1] = 'PKG_CFLAGS  := $(shell pkg-config --cflags $(PKG_DEPS))'
    lines[#lines + 1] = 'PKG_LIBS    := $(shell pkg-config --libs   $(PKG_DEPS))'
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'CXXFLAGS := ' .. cflags_str .. ' $(PKG_CFLAGS)'
        .. (opts.protocol_xmls and #opts.protocol_xmls > 0 and ' -Iinclude/protocols' or '')
    lines[#lines + 1] = 'LDFLAGS  := ' .. lflags .. ' $(PKG_LIBS)'
  else
    lines[#lines + 1] = 'CXXFLAGS := ' .. cflags_str
        .. (opts.protocol_xmls and #opts.protocol_xmls > 0 and ' -Iinclude/protocols' or '')
    lines[#lines + 1] = 'LDFLAGS  := ' .. lflags
  end

  local proto_deps = ''
  if opts.protocol_xmls and #opts.protocol_xmls > 0 then
    local ph = {}
    for _, xml in ipairs(opts.protocol_xmls) do
      ph[#ph + 1] = 'include/protocols/' .. xml:gsub('%.xml$', '') .. '-protocol.h'
    end
    proto_deps = ' ' .. table.concat(ph, ' ')
  end

  local rest = {
    '',
    'SRC_DIR  := ' .. src,
    'INC_DIR  := ' .. inc,
    'OBJ_DIR  := build/obj',
    'BIN_DIR  := build/bin',
    '',
    'TARGET   := $(BIN_DIR)/' .. out,
    'SRCS     := $(wildcard $(SRC_DIR)/*.cpp)',
    'OBJS     := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(SRCS))',
    'DEPS     := $(OBJS:.o=.d)',
    '',
    '.PHONY: all clean test install dist' .. (opts.compile_commands and ' compile_commands' or ''),
    '',
    'all:' .. proto_deps .. ' $(TARGET)',
    '',
    '$(TARGET): $(OBJS) | $(BIN_DIR)',
    '\t$(CXX) $^ -o $@ $(LDFLAGS)',
    '',
    '$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp | $(OBJ_DIR)',
    '\t$(CXX) $(CXXFLAGS) -I$(INC_DIR) -MMD -MP -c $< -o $@',
    '',
    '-include $(DEPS)',
    '',
    '$(OBJ_DIR) $(BIN_DIR):',
    '\t@mkdir -p $@',
    '',
    'clean:',
    '\t@rm -rf build/',
    '\t@echo "Cleaned."',
    '',
    'test:',
    '\t@echo "No test runner configured. Add your test command here."',
    '',
    'install: $(TARGET)',
    '\t@install -m 755 $(TARGET) /usr/local/bin/' .. out,
    '\t@echo "Installed → /usr/local/bin/' .. out .. '"',
    '',
    'dist: all',
    '\t@mkdir -p dist',
    '\t@cp $(TARGET) dist/',
    '\t@echo "Distribution ready in dist/"',
    cc_json_section,
    '',
  }
  for _, l in ipairs(rest) do lines[#lines + 1] = l end

  -- Wayland protocol generation rules (appended after rest)
  if opts.protocol_xmls and #opts.protocol_xmls > 0 then
    lines[#lines + 1] = '# ── Wayland protocol generation ─────────────────────────────────────────────'
    for _, xml in ipairs(opts.protocol_xmls) do
      local stem = xml:gsub('%.xml$', '')
      local xml_path = 'include/protocols/' .. xml
      local hdr_path = 'include/protocols/' .. stem .. '-protocol.h'
      local src_path = 'include/protocols/' .. stem .. '-protocol.c'
      lines[#lines + 1] = hdr_path .. ' ' .. src_path .. ': ' .. xml_path
      lines[#lines + 1] = '\t@wayland-scanner client-header $< ' .. hdr_path
      lines[#lines + 1] = '\t@wayland-scanner private-code  $< ' .. src_path
      lines[#lines + 1] = '\t@echo "Generated: ' .. stem .. '-protocol.{h,c}"'
      lines[#lines + 1] = ''
    end
    -- prepend protocol header deps to SRCS so objects rebuild when headers change
    lines[#lines + 1] = '# Protocol headers are listed as explicit dependencies'
    local proto_headers = {}
    for _, xml in ipairs(opts.protocol_xmls) do
      proto_headers[#proto_headers + 1] = 'include/protocols/' .. xml:gsub('%.xml$', '') .. '-protocol.h'
    end
    lines[#lines + 1] = 'PROTO_HEADERS := ' .. table.concat(proto_headers, ' ')
    lines[#lines + 1] = '$(OBJS): $(PROTO_HEADERS)'
    lines[#lines + 1] = ''
  end

  return table.concat(lines, '\n')
end

-- ── Go wrapper Makefile ───────────────────────────────────────────────────────
local function go_template(opts)
  local name   = opts.name
  local mod    = opts.module or '.'
  local out    = opts.out or name
  local gofmt  = opts.formatter or 'gofmt'
  local linter = opts.linter or 'golangci-lint'
  return table.concat({
    '# ' .. name .. ' — generated by Marvin (Go)',
    '#',
    '# Usage:',
    '#   make          Build binary',
    '#   make test     Run tests',
    '#   make lint     Run linter',
    '#   make fmt      Format source',
    '#   make clean    Remove build artefacts',
    '#   make install  Install binary to GOPATH/bin',
    '',
    'BINARY   := ' .. out,
    'MODULE   := ' .. mod,
    'GOFLAGS  :=',
    'LDFLAGS  := -ldflags="-s -w"',
    '',
    'BUILD_DIR := build',
    '',
    '.PHONY: all build test lint fmt clean install tidy race cover',
    '',
    'all: build',
    '',
    'build:',
    '\t@mkdir -p $(BUILD_DIR)',
    '\tgo build $(GOFLAGS) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY) .',
    '',
    'test:',
    '\tgo test ./...',
    '',
    'race:',
    '\tgo test -race ./...',
    '',
    'cover:',
    '\tgo test -cover -coverprofile=coverage.out ./...',
    '\tgo tool cover -html=coverage.out -o coverage.html',
    '\t@echo "Coverage report: coverage.html"',
    '',
    'lint:',
    '\t' .. linter .. ' run ./...',
    '',
    'fmt:',
    '\t' .. gofmt .. ' -w .',
    '',
    'tidy:',
    '\tgo mod tidy',
    '',
    'clean:',
    '\t@rm -rf $(BUILD_DIR) coverage.out coverage.html',
    '\t@echo "Cleaned."',
    '',
    'install:',
    '\tgo install .',
    '\t@echo "Installed $(BINARY) to GOPATH/bin"',
    '',
  }, '\n')
end

-- ── Rust wrapper Makefile ─────────────────────────────────────────────────────
local function rust_template(opts)
  local name    = opts.name
  local profile = opts.profile or 'dev'
  local out     = opts.out or name
  local pflag   = profile == 'release' and '--release' or ''
  local pdir    = profile == 'release' and 'release' or 'debug'
  return table.concat({
    '# ' .. name .. ' — generated by Marvin (Rust/Cargo)',
    '#',
    '# Usage:',
    '#   make            Build (' .. profile .. ' profile)',
    '#   make test       Run tests',
    '#   make clippy     Lint with Clippy',
    '#   make fmt        Format with rustfmt',
    '#   make clean      cargo clean',
    '#   make release    Force release build',
    '#   make run        Build & run',
    '',
    'CARGO    := cargo',
    'PROFILE  := ' .. profile,
    'PFLAG    := ' .. pflag,
    'BIN      := target/' .. pdir .. '/' .. out,
    '',
    '.PHONY: all build test clippy fmt clean release run doc bench',
    '',
    'all: build',
    '',
    'build:',
    '\t$(CARGO) build $(PFLAG)',
    '',
    'run: build',
    '\t./$(BIN)',
    '',
    'test:',
    '\t$(CARGO) test',
    '',
    'clippy:',
    '\t$(CARGO) clippy -- -D warnings',
    '',
    'fmt:',
    '\t$(CARGO) fmt',
    '',
    'doc:',
    '\t$(CARGO) doc --open',
    '',
    'bench:',
    '\t$(CARGO) bench',
    '',
    'clean:',
    '\t$(CARGO) clean',
    '\t@echo "Cleaned."',
    '',
    'release:',
    '\t$(CARGO) build --release',
    '',
    'install:',
    '\t$(CARGO) install --path .',
    '',
  }, '\n')
end

-- ── Generic Makefile ──────────────────────────────────────────────────────────
local function generic_template(opts)
  local name = opts.name
  return table.concat({
    '# ' .. name .. ' — generated by Marvin',
    '#',
    '# Edit the targets below to fit your project.',
    '',
    '.PHONY: all build test clean install dist',
    '',
    'all: build',
    '',
    'build:',
    '\t@echo "Add your build command here"',
    '',
    'test:',
    '\t@echo "Add your test command here"',
    '',
    'clean:',
    '\t@echo "Add your clean command here"',
    '',
    'install:',
    '\t@echo "Add your install command here"',
    '',
    'dist:',
    '\t@echo "Add your dist command here"',
    '',
  }, '\n')
end

-- ══════════════════════════════════════════════════════════════════════════════
-- WIZARD STEPS
-- ══════════════════════════════════════════════════════════════════════════════

local function step_cflags(opts, root, lang, flags)
  local default = opts.debug and '-g -O0' or '-O2'
  ui().input({
    prompt  = 'Extra compiler flags (optional)',
    default = default,
  }, function(extra)
    opts.cflags      = (extra and extra ~= '') and extra or nil
    opts.ldflags     = flags.ldflags
    opts.iflags      = flags.iflags
    opts.needs_posix = flags.needs_posix
    opts.pkg_deps    = flags.pkg_deps
    opts.wlr_guard   = flags.wlr_guard

    if lang == 'cpp' then
      ui().select({
          { id = 'none',  label = 'None',             desc = 'No sanitizer' },
          { id = 'asan',  label = 'AddressSanitizer', desc = '-fsanitize=address' },
          { id = 'tsan',  label = 'ThreadSanitizer',  desc = '-fsanitize=thread' },
          { id = 'ubsan', label = 'UBSanitizer',      desc = '-fsanitize=undefined' },
        }, { prompt = 'Sanitizer (optional)', format_item = function(it) return it.label end },
        function(san)
          opts.sanitizer = (san and san.id ~= 'none') and san.id or nil
          ui().select({
              { id = 'yes', label = 'Yes — add compile_commands target', desc = 'requires bear' },
              { id = 'no', label = 'No' },
            }, { prompt = 'Add compile_commands.json target?', format_item = function(it) return it.label end },
            function(cc)
              opts.compile_commands = cc and cc.id == 'yes'
              check_existing(root .. '/Makefile', cpp_template(opts), opts, root)
            end)
        end)
    else
      check_existing(root .. '/Makefile', c_template(opts), opts, root)
    end
  end)
end

local function step_c_std(opts, root, flags)
  ui().select({
      { id = 'c11', label = 'C11', desc = 'Recommended modern standard' },
      { id = 'c17', label = 'C17', desc = 'Latest stable' },
      { id = 'c99', label = 'C99', desc = 'Wide compatibility' },
      { id = 'c89', label = 'C89', desc = 'Maximum compatibility' },
    }, { prompt = 'C Standard', format_item = function(it) return it.label end },
    function(choice)
      if not choice then return end
      opts.std = choice.id
      step_cflags(opts, root, 'c', flags)
    end)
end

local function step_cpp_std(opts, root, flags)
  ui().select({
      { id = 'c++17', label = 'C++17', desc = 'Recommended' },
      { id = 'c++20', label = 'C++20', desc = 'Concepts, ranges, coroutines' },
      { id = 'c++23', label = 'C++23', desc = 'Latest (compiler support varies)' },
      { id = 'c++14', label = 'C++14', desc = 'Lambdas, auto' },
      { id = 'c++11', label = 'C++11', desc = 'Move semantics, smart pointers' },
    }, { prompt = 'C++ Standard', format_item = function(it) return it.label end },
    function(choice)
      if not choice then return end
      opts.std = choice.id
      step_cflags(opts, root, 'cpp', flags)
    end)
end

local function step_compiler(opts, root, lang, flags)
  local compilers = lang == 'c'
      and {
        { id = 'gcc',   label = 'gcc',   desc = 'GNU C Compiler (recommended)' },
        { id = 'clang', label = 'clang', desc = 'LLVM Clang' },
        { id = 'cc',    label = 'cc',    desc = 'System default' },
      }
      or {
        { id = 'g++',     label = 'g++',     desc = 'GNU C++ Compiler (recommended)' },
        { id = 'clang++', label = 'clang++', desc = 'LLVM Clang++' },
        { id = 'c++',     label = 'c++',     desc = 'System default' },
      }

  ui().select(compilers, { prompt = 'Compiler', format_item = function(it) return it.label end },
    function(choice)
      if not choice then return end
      opts.compiler = choice.id
      if lang == 'c' then
        step_c_std(opts, root, flags)
      else
        step_cpp_std(opts, root, flags)
      end
    end)
end

local function step_name_binary(lang, root, src, inc, on_back)
  local default = vim.fn.fnamemodify(root, ':t')

  ui().input({ prompt = '󰬷 Project Name', default = default }, function(name)
    if not name or name == '' then return end

    ui().input({ prompt = '󰐊 Output Binary Name', default = name }, function(out)
      if not out or out == '' then out = name end

      local opts = { name = name, out = out, src = src, inc = inc }

      if lang == 'generic' then
        check_existing(root .. '/Makefile', generic_template(opts), opts, root)
      elseif lang == 'go' then
        local mod_default = 'github.com/yourname/' .. name
        local go_mod = root .. '/go.mod'
        if vim.fn.filereadable(go_mod) == 1 then
          for _, line in ipairs(vim.fn.readfile(go_mod)) do
            local m = line:match('^module%s+(%S+)')
            if m then
              mod_default = m; break
            end
          end
        end
        ui().input({ prompt = 'Module path', default = mod_default }, function(mod)
          opts.module = mod
          ui().select({
              { id = 'gofmt',     label = 'gofmt',     desc = 'Standard library formatter' },
              { id = 'goimports', label = 'goimports', desc = 'gofmt + import management' },
            }, { prompt = 'Formatter', format_item = function(it) return it.label end },
            function(fmt)
              opts.formatter = fmt and fmt.id or 'gofmt'
              check_existing(root .. '/Makefile', go_template(opts), opts, root)
            end)
        end)
      elseif lang == 'rust' then
        local cargo_toml = root .. '/Cargo.toml'
        if vim.fn.filereadable(cargo_toml) == 1 then
          for _, line in ipairs(vim.fn.readfile(cargo_toml)) do
            local n = line:match('^name%s*=%s*"([^"]+)"')
            if n then
              opts.out = n; break
            end
          end
        end
        ui().select({
            { id = 'dev',     label = 'dev (debug)', desc = 'Fast compilation, debug symbols' },
            { id = 'release', label = 'release',     desc = 'Optimised binary' },
          }, { prompt = 'Default profile', format_item = function(it) return it.label end },
          function(prof)
            opts.profile = prof and prof.id or 'dev'
            check_existing(root .. '/Makefile', rust_template(opts), opts, root)
          end)
      else
        -- C / C++: run full detection pipeline silently
        local flags = auto_detect_flags(root)
        flags.needs_posix = project_needs_posix(root)

        -- Build notification of what was injected
        local notice = {}
        if #(flags.pkg_deps or {}) > 0 then
          notice[#notice + 1] = 'PKG_DEPS:  ' .. table.concat(flags.pkg_deps, ' ')
          notice[#notice + 1] = '  → PKG_CFLAGS / PKG_LIBS via pkg-config'
        end
        if flags.wlr_guard then
          notice[#notice + 1] = 'CFLAGS:    -DWLR_USE_UNSTABLE (wlroots headers detected)'
        end
        if flags.ldflags ~= '' then
          notice[#notice + 1] = 'LDFLAGS:   ' .. flags.ldflags
        end
        if flags.iflags ~= '' then
          notice[#notice + 1] = 'CFLAGS:    ' .. flags.iflags
        end
        if flags.needs_posix then
          notice[#notice + 1] = 'CFLAGS:    -D_POSIX_C_SOURCE=200809L (POSIX usage detected)'
        end
        if #notice > 0 then
          vim.notify(
            '[Marvin] Auto-injecting flags:\n  ' .. table.concat(notice, '\n  '),
            vim.log.levels.INFO)
        end

        local ok_wp, wl_proto = pcall(require, 'marvin.wayland_protocols')
        if not ok_wp then
          vim.notify('[Marvin] wayland_protocols module error: ' .. tostring(wl_proto), vim.log.levels.WARN)
          wl_proto = nil
        end
        local protocol_xmls = {}
        if wl_proto then
          local ok_r, proto_entries = pcall(wl_proto.resolve, root)
          if ok_r then
            for _, e in ipairs(proto_entries) do
              if e.in_root then
                protocol_xmls[#protocol_xmls + 1] = e.xml
              end
            end
          else
            vim.notify('[Marvin] Protocol scan error: ' .. tostring(proto_entries), vim.log.levels.WARN)
          end
        end
        opts.protocol_xmls = protocol_xmls

        step_compiler(opts, root, lang, flags)
      end
    end)
  end)
end

local function step_dirs(lang, root, on_back)
  if lang ~= 'c' and lang ~= 'cpp' then
    step_name_binary(lang, root, nil, nil, on_back)
    return
  end

  local has_src = vim.fn.isdirectory(root .. '/src') == 1
  local has_inc = vim.fn.isdirectory(root .. '/include') == 1
  local src_default = has_src and 'src' or '.'
  local inc_default = has_inc and 'include' or (has_src and 'src' or '.')

  ui().input({ prompt = 'Source directory', default = src_default }, function(src)
    src = (src and src ~= '') and src or src_default
    ui().input({ prompt = 'Include directory', default = inc_default }, function(inc)
      inc = (inc and inc ~= '') and inc or inc_default
      step_name_binary(lang, root, src, inc, on_back)
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
    { id = 'cpp', label = '󰙲 C++', desc = 'g++/clang++, wildcard *.cpp sources, auto-link detection' },
    { id = 'c', label = '󰙱 C', desc = 'gcc/clang, wildcard *.c sources, auto-link + pkg-config detection' },
    { id = 'go', label = '󰟓 Go', desc = 'go build wrapper with test, lint, fmt, cover targets' },
    { id = 'rust', label = '󱘗 Rust', desc = 'cargo wrapper with clippy, fmt, doc, bench targets' },
    { id = 'generic', label = '󰈙 Generic', desc = 'Minimal skeleton: all, build, test, clean, install, dist' },
  }

  local prompt = 'Makefile Type'
  if detected_lang then
    prompt = 'Makefile Type  (detected: ' .. detected_lang .. ')'
    for i, it in ipairs(lang_items) do
      if it.id == detected_lang then
        table.remove(lang_items, i)
        table.insert(lang_items, 1, vim.tbl_extend('force', it, {
          label = it.label .. '  ✓ detected',
        }))
        break
      end
    end
  end

  ui().select(lang_items, {
    prompt      = prompt,
    on_back     = on_back,
    format_item = function(it) return it.label end,
  }, function(choice)
    if not choice then return end
    vim.cmd('stopinsert')
    vim.schedule(function()
      step_dirs(choice.id, root, on_back)
    end)
  end)
end

return M

```

### `lua/marvin/meson_creator.lua`

```lua
-- lua/marvin/meson_creator.lua
-- Interactive meson.build wizard.
--
-- Detection pipeline:
--   • pkg-config deps         → header scan against dynamic PKG_CONFIG_MAP
--   • find_library() deps     → symbol scan against SYMBOL_LIB_MAP (libm, librt, etc.)
--   • multi-executable guard  → detects multiple main() → splits executables
--   • POSIX define            → source scan for POSIX symbols
--   • wlroots guard           → header scan for #include <wlr/...>
--   • wayland-server guard    → symbol scan for wl_display_* usage
--   • xkbcommon guard         → header scan for <xkbcommon/...>
--   • include dirs            → filesystem walk
--   • sources                 → filesystem walk (explicit files(), no globs)
--
-- Protocol XML strategy:
--   wayland-protocols XMLs  → referenced via wp_dir / 'subpath' (never copied)
--   wlroots protocol XMLs   → referenced via wlr_proto_dir / 'subpath' if installed,
--                             else vendored into include/protocols/ as fallback
--   No .h/.c files are pre-generated — Meson's custom_target() does that at build time.

local M = {}

local function ui() return require('marvin.ui') end
local function plain(it) return it.label end

-- ── write helpers ─────────────────────────────────────────────────────────────

local function write(path, content, name)
  local f = io.open(path, 'w')
  if not f then
    vim.notify('[Marvin] Cannot write ' .. path, vim.log.levels.ERROR)
    return false
  end
  f:write(content); f:close()
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  vim.notify('[Marvin] meson.build created for: ' .. name, vim.log.levels.INFO)
  return true
end

local function check_existing(path, content, name)
  if vim.fn.filereadable(path) == 1 then
    ui().select({
        { id = 'overwrite', label = 'Overwrite', desc = 'Replace existing meson.build' },
        { id = 'cancel',    label = 'Cancel',    desc = 'Keep existing file' },
      }, { prompt = 'meson.build already exists', format_item = plain },
      function(ch)
        if ch and ch.id == 'overwrite' then write(path, content, name) end
      end)
    return
  end
  write(path, content, name)
end

-- ── language detection ────────────────────────────────────────────────────────

local function infer_lang(root)
  if #vim.fn.globpath(root, '**/*.cpp', false, true) > 0 then return 'cpp' end
  if #vim.fn.globpath(root, '**/*.cxx', false, true) > 0 then return 'cpp' end
  if #vim.fn.globpath(root, '**/*.c', false, true) > 0 then return 'c' end
  return nil
end

-- ── source collection ─────────────────────────────────────────────────────────

local SKIP = { '/builddir/', '/build/', '/.marvin%-obj/', '/%.git/' }
local function skip(p)
  for _, pat in ipairs(SKIP) do if p:find(pat, 1, false) then return true end end
  return false
end

local function collect_sources(dir, lang)
  local exts = lang == 'cpp'
      and { '**/*.cpp', '**/*.cxx', '**/*.cc' }
      or { '**/*.c' }
  local seen, rel = {}, {}
  for _, pat in ipairs(exts) do
    for _, f in ipairs(vim.fn.globpath(dir, pat, false, true)) do
      if not skip(f) then
        local r = f:sub(#dir + 2)
        if r ~= '' and not seen[r] then
          seen[r] = true; rel[#rel + 1] = "  '" .. r .. "'"
        end
      end
    end
  end
  if #rel == 0 then return 'files()' end
  table.sort(rel)
  return 'files(\n' .. table.concat(rel, ',\n') .. '\n)'
end

-- ── include directory collection ──────────────────────────────────────────────

local function collect_include_dirs(root)
  local seen, dirs = {}, {}
  for _, pat in ipairs({ '**/*.h', '**/*.hpp', '**/*.hxx' }) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
      if not skip(f) then
        local dir = vim.fn.fnamemodify(f, ':h')
        local rel = dir:sub(#root + 2)
        if rel == '' then rel = '.' end
        if not seen[rel] then
          seen[rel] = true; dirs[#dirs + 1] = rel
        end
      end
    end
  end
  if #dirs == 0 then
    return "include_directories('include')", { 'include' }
  end
  table.sort(dirs)
  local quoted = {}
  for _, d in ipairs(dirs) do quoted[#quoted + 1] = "  '" .. d .. "'" end
  return 'include_directories(\n' .. table.concat(quoted, ',\n') .. '\n)', dirs
end

-- ── wlroots guard ─────────────────────────────────────────────────────────────

local function scan_needs_wlr_unstable(root)
  local h = io.popen(
    'grep -rl --include="*.c" --include="*.cpp" --include="*.h" --include="*.hpp"'
    .. ' --include="*.cxx" --include="*.hxx"'
    .. ' -E ' .. vim.fn.shellescape([=[#\s*include\s*[<"]wlr/|WLR_USE_UNSTABLE]=])
    .. ' ' .. vim.fn.shellescape(root)
    .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
    .. ' 2>/dev/null | head -1')
  if not h then return false end
  local found = h:read('*l'); h:close()
  return found ~= nil and found ~= ''
end

-- ── pkg-config scan ───────────────────────────────────────────────────────────
--
-- Performance strategy: do everything in two bulk shell calls instead of one
-- per package.
--
-- 1. `pkg-config --list-all` → package list
-- 2. One `pkg-config --cflags-only-I <all pkgs...>` batch call per package list
--    chunk, piped through a small awk script that emits "pkg:dir" pairs.
--    This replaces ~500 individual popen() calls with ~1.
-- 3. Walk only the unique -I dirs we actually got back (usually <20).
-- 4. Build a header→pkg reverse map from those dirs using `find`.

local _hdr_pkg_map_cache = nil
local function get_hdr_pkg_map()
  if _hdr_pkg_map_cache then return _hdr_pkg_map_cache end
  local map = {}

  -- Step 1: get all package names in one call
  local h = io.popen('pkg-config --list-all 2>/dev/null')
  if not h then
    _hdr_pkg_map_cache = map; return map
  end
  local pkgs = {}
  for line in h:lines() do
    local name = line:match('^(%S+)')
    if name then pkgs[#pkgs + 1] = name end
  end
  h:close()
  if #pkgs == 0 then
    _hdr_pkg_map_cache = map; return map
  end

  -- Step 2: batch cflags in chunks of 50 to avoid ARG_MAX issues.
  -- For each pkg we emit "PKGNAME TAB dir" lines using an awk wrapper.
  -- We use a shell loop so pkg-config errors on individual packages don't abort.
  local dir_to_pkg = {} -- dir → first pkg that claimed it
  local chunk_size = 50
  for i = 1, #pkgs, chunk_size do
    local chunk = {}
    for j = i, math.min(i + chunk_size - 1, #pkgs) do
      chunk[#chunk + 1] = pkgs[j]
    end
    -- emit "pkg\t-Idir" for each -I flag; one line per (pkg, dir) pair
    local script = [[
      for p in "$@"; do
        flags=$(pkg-config --cflags-only-I "$p" 2>/dev/null)
        for f in $flags; do
          d="${f#-I}"
          [ -n "$d" ] && printf '%s\t%s\n' "$p" "$d"
        done
        inc=$(pkg-config --variable=includedir "$p" 2>/dev/null)
        [ -n "$inc" ] && printf '%s\t%s\n' "$p" "$inc"
      done
    ]]
    local cmd = 'sh -c ' .. vim.fn.shellescape(script) .. ' -- ' .. table.concat(
      vim.tbl_map(vim.fn.shellescape, chunk), ' ')
    local ch = io.popen(cmd .. ' 2>/dev/null')
    if ch then
      for line in ch:lines() do
        local pkg, dir = line:match('^([^\t]+)\t(.+)$')
        if pkg and dir and not dir_to_pkg[dir] then
          dir_to_pkg[dir] = pkg
        end
      end
      ch:close()
    end
  end

  -- Step 3: also add guessed stem dirs (fast filesystem check, no shell)
  for _, pkg in ipairs(pkgs) do
    local stem = pkg:match('^([%a%d]+)')
    if stem then
      for _, base in ipairs({ '/usr/include', '/usr/local/include' }) do
        local d = base .. '/' .. stem
        if not dir_to_pkg[d] and vim.fn.isdirectory(d) == 1 then
          dir_to_pkg[d] = pkg
        end
      end
    end
  end

  -- Step 4: walk unique dirs with a single `find` call to build header→pkg map.
  -- Collect all dirs into one find invocation: find dir1 dir2 ... -maxdepth 2 -name '*.h'
  local dirs = {}
  for d in pairs(dir_to_pkg) do
    if vim.fn.isdirectory(d) == 1 then dirs[#dirs + 1] = d end
  end

  if #dirs > 0 then
    -- find prints "dir/relative/path.h" — we strip the base dir to get the key
    local find_cmd = 'find '
        .. table.concat(vim.tbl_map(vim.fn.shellescape, dirs), ' ')
        .. ' -maxdepth 2 -name "*.h" -print 2>/dev/null'
    local fh = io.popen(find_cmd)
    if fh then
      for fpath in fh:lines() do
        -- match the longest prefix dir
        for _, d in ipairs(dirs) do
          if fpath:sub(1, #d) == d then
            -- key is the path relative to the include dir, e.g. "gtk/gtk.h" or "gtk.h"
            local rel = fpath:sub(#d + 2) -- strip leading /
            if rel ~= '' and not map[rel] then
              map[rel] = dir_to_pkg[d]
            end
            break
          end
        end
      end
      fh:close()
    end
  end

  _hdr_pkg_map_cache = map
  return map
end

local function include_to_pkg(inc)
  local map = get_hdr_pkg_map()
  if map[inc] then return map[inc] end
  -- Also try just the filename without any leading path component
  local fname = inc:match('([^/]+)$')
  return fname and map[fname] or nil
end

-- Resolve a pkg name to its actual installed versioned name.
-- Uses a single pre-built lookup table from pkg-config --list-all instead of
-- spawning one process per package.
local _pkg_list_cache = nil
local function get_pkg_list()
  if _pkg_list_cache then return _pkg_list_cache end
  local set = {}
  local h = io.popen('pkg-config --list-all 2>/dev/null')
  if h then
    for line in h:lines() do
      local name = line:match('^(%S+)')
      if name then set[name] = true end
    end
    h:close()
  end
  _pkg_list_cache = set
  return set
end

local _pkg_resolve_cache = {}
local function resolve_pkg(base)
  if _pkg_resolve_cache[base] ~= nil then return _pkg_resolve_cache[base] or nil end
  local all = get_pkg_list()
  -- exact match
  if all[base] then
    _pkg_resolve_cache[base] = base; return base
  end
  -- versioned variant: find first entry that starts with base followed by - or space
  for name in pairs(all) do
    if name:sub(1, #base + 1) == base .. '-' then
      _pkg_resolve_cache[base] = name; return name
    end
  end
  _pkg_resolve_cache[base] = false; return nil
end

-- Collect all #include lines from the project in one grep, then map them.
local function detect_pkg_deps(root)
  local found    = {}
  local ordered  = {}

  -- One grep across the whole tree is vastly faster than Lua globpath + readfile
  local grep_cmd = 'grep -rh'
      .. ' --include="*.c" --include="*.cpp" --include="*.cxx"'
      .. ' --include="*.h" --include="*.hpp" --include="*.hxx"'
      .. ' -E ' .. vim.fn.shellescape([=[^\s*#\s*include\s*[<"][^>"]+[>"]]=])
      .. ' ' .. vim.fn.shellescape(root)
      .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
      .. ' 2>/dev/null'

  local h        = io.popen(grep_cmd)
  if not h then return ordered end

  for line in h:lines() do
    local inc = line:match('#%s*include%s*[<\"]([^>\"]+)[>\"]')
    if inc then
      local pkg = include_to_pkg(inc)
      if pkg and not found[pkg] then
        local resolved = resolve_pkg(pkg)
        if resolved then
          found[pkg]            = true
          ordered[#ordered + 1] = resolved
        end
      end
    end
  end
  h:close()
  return ordered
end

-- ── meson variable name sanitiser ─────────────────────────────────────────────

local function var(pkg) return pkg:gsub('[%-.]', '_') end

-- ── grep helper ───────────────────────────────────────────────────────────────

local function grep_any(root, pattern)
  local h = io.popen(
    'grep -rl --include="*.c" --include="*.cpp" --include="*.cxx"'
    .. ' --include="*.h" --include="*.hpp" --include="*.hxx"'
    .. ' -E ' .. vim.fn.shellescape(pattern)
    .. ' ' .. vim.fn.shellescape(root)
    .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
    .. ' 2>/dev/null | head -1')
  if not h then return false end
  local found = h:read('*l'); h:close()
  return found ~= nil and found ~= ''
end

-- ── find_library() dependency detection ──────────────────────────────────────

local FIND_LIBRARY_RULES = {
  {
    header_pat = [=[math\.h|complex\.h|fenv\.h|tgmath\.h]=],
    symbol_pat =
    [=[roundf?\s*\(|floorf?\s*\(|ceilf?\s*\(|sqrtf?\s*\(|powf?\s*\(|fabsf?\s*\(|logf?\s*\(|expf?\s*\(|sinf?\s*\(|cosf?\s*\(|fmaf?\s*\(|hypotf?\s*\(|truncf?\s*\(|nanf?\s*\(|isinf\s*\(|isnan\s*\(]=],
    lib = 'm',
    vname = 'm',
  },
  {
    header_pat = [=[time\.h|aio\.h|mqueue\.h]=],
    symbol_pat = [=[clock_gettime\s*\(|clock_nanosleep\s*\(|timer_create\s*\(|shm_open\s*\(|mq_open\s*\(|aio_read\s*\(]=],
    lib = 'rt',
    vname = 'rt',
  },
  {
    header_pat = [=[dlfcn\.h]=],
    symbol_pat = [=[dlopen\s*\(|dlsym\s*\(|dlclose\s*\(|dlerror\s*\(]=],
    lib = 'dl',
    vname = 'dl',
  },
  {
    header_pat = [=[pthread\.h|semaphore\.h]=],
    symbol_pat = [=[pthread_create\s*\(|pthread_mutex_lock\s*\(|pthread_cond_wait\s*\(|sem_init\s*\(]=],
    lib = 'pthread',
    vname = 'pthread',
  },
}

local function detect_find_library_deps(root)
  local result = {}
  for _, rule in ipairs(FIND_LIBRARY_RULES) do
    if grep_any(root, rule.header_pat) and grep_any(root, rule.symbol_pat) then
      result[#result + 1] = { lib = rule.lib, vname = rule.vname }
    end
  end
  return result
end

-- ── wayland-server detection ──────────────────────────────────────────────────
--
-- wlroots wraps wayland-server but --as-needed means we must link it explicitly
-- if we call wl_* functions directly. Detect direct wl_display / wl_event_loop
-- usage in source files.

local WL_SERVER_SYMBOLS = {
  'wl_display_create', 'wl_display_run', 'wl_display_destroy',
  'wl_display_add_socket', 'wl_display_get_event_loop',
  'wl_event_loop_add_fd', 'wl_event_loop_add_timer',
  'wl_event_source_remove', 'wl_global_create',
  'wl_resource_create', 'wl_resource_post_event',
  'wl_list_init', 'wl_list_insert', 'wl_list_remove',
  'wl_signal_init', 'wl_signal_add', 'wl_signal_emit',
}

local function detect_needs_wayland_server(root)
  local syms = table.concat(WL_SERVER_SYMBOLS, '|')
  local h = io.popen(
    'grep -rl --include="*.c" --include="*.cpp" --include="*.h" --include="*.hpp"'
    .. ' -E ' .. vim.fn.shellescape(syms)
    .. ' ' .. vim.fn.shellescape(root)
    .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
    .. ' 2>/dev/null | head -1')
  if not h then return false end
  local found = h:read('*l'); h:close()
  return found ~= nil and found ~= ''
end

-- ── xkbcommon detection ───────────────────────────────────────────────────────

local function detect_needs_xkbcommon(root)
  local h = io.popen(
    'grep -rl --include="*.c" --include="*.cpp" --include="*.h" --include="*.hpp"'
    .. ' -E ' ..
    vim.fn.shellescape([=[#\s*include\s*[<"]xkbcommon/|xkb_context_new|xkb_keymap_|xkb_keysym_|xkb_state_]=])
    .. ' ' .. vim.fn.shellescape(root)
    .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
    .. ' 2>/dev/null | head -1')
  if not h then return false end
  local found = h:read('*l'); h:close()
  return found ~= nil and found ~= ''
end

-- ── multi-main detection ──────────────────────────────────────────────────────
--
-- If multiple .c files each define main(), they cannot be linked into a single
-- executable. We detect this and split them into separate executable() blocks.

local function detect_main_files(root, lang)
  local ext_pats = lang == 'cpp'
      and { '**/*.cpp', '**/*.cxx', '**/*.cc' }
      or { '**/*.c' }

  -- Regex patterns that match a main() definition (not a call or declaration)
  local MAIN_PATS = {
    '^%s*int%s+main%s*%(',
    '^%s*int%s+main%s*%(%s*void%s*%)',
    '^%s*int%s+main%s*%(%s*int%s+argc',
  }

  local mains = {} -- { path = rel_path, file = basename }
  for _, pat in ipairs(ext_pats) do
    for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
      if not skip(f) then
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok then
          for _, line in ipairs(lines) do
            local found = false
            for _, mp in ipairs(MAIN_PATS) do
              if line:match(mp) then
                found = true; break
              end
            end
            if found then
              local rel = f:sub(#root + 2)
              mains[#mains + 1] = {
                path = rel,
                base = vim.fn.fnamemodify(f, ':t:r'),  -- filename without ext
              }
              break
            end
          end
        end
      end
    end
  end
  return mains
end

-- ── POSIX detection ───────────────────────────────────────────────────────────

local POSIX_PATTERN = '_POSIX_C_SOURCE|_XOPEN_SOURCE|getaddrinfo|getnameinfo'
    .. '|setenv|unsetenv|strndup|strsignal|sigaction|strptime'
    .. '|opendir|readdir|scandir|nftw|pthread_|sem_init|mmap|munmap'
    .. '|clock_gettime|nanosleep|usleep|mkstemp|realpath|readlink'

local function detect_needs_posix(root)
  return grep_any(root, POSIX_PATTERN)
end

-- ── multi-main detection ──────────────────────────────────────────────────────
--
-- grep prints "filename:line" for each match. We collect unique filenames
-- that contain a main() definition to detect split-executable projects.

local function detect_main_files(root, lang)
  local include_pat = lang == 'cpp'
      and [=[\.(cpp|cxx|cc)$]=]
      or [=[\.c$]=]

  -- grep -rn prints "file:linenum:content" — we want files containing a main def
  local main_pat    = [=[^\s*int\s+main\s*\(]=]
  local cmd         = 'grep -rn'
      .. ' --include="*.c" --include="*.cpp" --include="*.cxx" --include="*.cc"'
      .. ' -E ' .. vim.fn.shellescape(main_pat)
      .. ' ' .. vim.fn.shellescape(root)
      .. ' --exclude-dir=build --exclude-dir=builddir --exclude-dir=.git'
      .. ' 2>/dev/null'

  local mains       = {}
  local seen        = {}
  local h           = io.popen(cmd)
  if h then
    for line in h:lines() do
      local fpath = line:match('^([^:]+):')
      if fpath and not seen[fpath] and fpath:match(include_pat) then
        seen[fpath] = true
        local rel = fpath:sub(#root + 2)
        mains[#mains + 1] = {
          path = rel,
          base = vim.fn.fnamemodify(fpath, ':t:r'),
        }
      end
    end
    h:close()
  end
  return mains
end

-- ── canonical auto-detection ──────────────────────────────────────────────────

local function auto_detect(root, lang)
  local extra_cargs = {}
  local needs_posix = false
  local wlr_guard   = false
  local pkg_deps    = {}

  -- 1. Try the marvin build module first (existing behaviour)
  local ok_b, build = pcall(require, 'marvin.build')
  if ok_b and build.cpp then
    if build.cpp.pkg_config_flags then
      local ok_f, flags = pcall(build.cpp.pkg_config_flags, root)
      if ok_f then
        pkg_deps = flags.pkg_names or {}
        for _, f in ipairs(flags.iflags or {}) do
          if f == '-DWLR_USE_UNSTABLE' then wlr_guard = true end
        end
      end
    end
    if build.cpp.needs_posix_define then
      local ok_p, res = pcall(build.cpp.needs_posix_define, root)
      if ok_p then needs_posix = res end
    end
  end

  -- 2. Fallback: run our own pkg-config header scan
  if #pkg_deps == 0 then
    pkg_deps = detect_pkg_deps(root)
  end

  -- 3. wlroots guard (own scan, more reliable than build module)
  if not wlr_guard then
    wlr_guard = scan_needs_wlr_unstable(root)
  end

  -- 4. POSIX detection
  if not needs_posix then
    needs_posix = detect_needs_posix(root)
  end

  -- 5. wayland-server: add if not already picked up by pkg-config scan
  local has_wayland_server = false
  for _, d in ipairs(pkg_deps) do
    if d:match('wayland%-server') then
      has_wayland_server = true; break
    end
  end
  if not has_wayland_server and detect_needs_wayland_server(root) then
    pkg_deps[#pkg_deps + 1] = 'wayland-server'
  end

  -- 6. xkbcommon: same pattern
  local has_xkb = false
  for _, d in ipairs(pkg_deps) do
    if d:match('xkbcommon') then
      has_xkb = true; break
    end
  end
  if not has_xkb and detect_needs_xkbcommon(root) then
    pkg_deps[#pkg_deps + 1] = 'xkbcommon'
  end

  -- 7. find_library() deps (libm, librt, libdl, libpthread)
  local find_lib_deps = detect_find_library_deps(root)

  if wlr_guard then
    extra_cargs[#extra_cargs + 1] = '-DWLR_USE_UNSTABLE'
  end

  return {
    pkg_deps      = pkg_deps,
    find_lib_deps = find_lib_deps,
    needs_posix   = needs_posix,
    wlr_guard     = wlr_guard,
    extra_cargs   = extra_cargs,
  }
end

-- ── template ──────────────────────────────────────────────────────────────────

local function meson_template(opts)
  local lines = {}
  local function l(s) lines[#lines + 1] = (s or '') end

  local lang_str = opts.lang == 'cpp' and 'cpp' or 'c'
  local std_key  = opts.lang == 'cpp' and 'cpp_std' or 'c_std'

  -- project()
  l("project('" .. opts.name .. "',")
  l("  '" .. lang_str .. "',")
  l("  version : '" .. (opts.version or '0.1.0') .. "',")
  l("  default_options : [")
  l("    'warning_level=3',")
  l("    '" .. std_key .. '=' .. opts.std .. "',")
  l("    'buildtype=debugoptimized',")
  l("  ]")
  l(')')
  l()

  -- sources
  l('# ── Sources ──────────────────────────────────────────────────────────────────')
  -- If multiple mains were detected, we'll use shared_src for the common files
  local multi_exe = opts.multi_exe and #opts.multi_exe > 1
  if multi_exe then
    l('# Shared sources (no main)')
    l('shared_src = ' .. opts.shared_src_decl)
  else
    l('src = ' .. opts.src_decl)
  end
  l()

  -- include directories
  -- Only inject include/protocols/ if we have vendored XMLs in the project tree.
  -- System-referenced protocols generate their headers into the Meson build dir,
  -- which is already on the include path automatically.
  l('# ── Include directories ──────────────────────────────────────────────────────')
  local inc_decl     = opts.inc_decl
  local has_vendored = false
  for _, p in ipairs(opts.protocol_entries or {}) do
    if p.in_root then
      has_vendored = true; break
    end
  end
  if has_vendored then
    if inc_decl:find("'include/protocols'") == nil then
      inc_decl = inc_decl:gsub('%)', ",\n  'include/protocols'\n)", 1)
    end
  end
  l('inc = ' .. inc_decl)
  l()

  -- dependencies: find_library() first (cc must be declared first)
  local dep_names     = opts.dep_names or {}
  local find_lib_deps = opts.find_lib_deps or {}
  local all_dep_refs  = {}

  -- Determine whether we need wayland-protocols as an explicit dep
  -- (needed when we reference system XMLs via wp_dir variable in Meson)
  local needs_wp_dep  = false
  local needs_wlr_dep = false
  for _, p in ipairs(opts.protocol_entries or {}) do
    if p.xml_ref == 'system_wp' then needs_wp_dep = true end
    if p.xml_ref == 'system_wlr' then needs_wlr_dep = true end
  end

  if #find_lib_deps > 0 or #dep_names > 0 or needs_wp_dep or needs_wlr_dep then
    l('# ── Dependencies ─────────────────────────────────────────────────────────────')

    -- find_library() deps need the compiler object
    if #find_lib_deps > 0 then
      l('cc = meson.get_compiler(\'' .. lang_str .. '\')')
      for _, fd in ipairs(find_lib_deps) do
        l(fd.vname .. "_dep = cc.find_library('" .. fd.lib .. "', required : true)")
        all_dep_refs[#all_dep_refs + 1] = fd.vname .. '_dep'
      end
    end

    -- wayland-protocols system dep (for wp_dir variable)
    if needs_wp_dep then
      l("wayland_protocols_dep = dependency('wayland-protocols', required : true)")
      l("wp_dir = wayland_protocols_dep.get_variable('pkgdatadir')")
    end

    -- wlroots dep for its protocol pkgdatadir (if we reference system wlr XMLs)
    -- Note: wlroots_dep is already in dep_names from pkg-config scan, so we just
    -- capture its pkgdatadir here for the protocol paths.
    if needs_wlr_dep then
      -- find the wlroots dep variable name already in dep_names
      local wlr_varname = nil
      for _, d in ipairs(dep_names) do
        if d:match('^wlroots') then
          wlr_varname = var(d); break
        end
      end
      if wlr_varname then
        l("wlr_proto_dir = " .. wlr_varname .. "_dep.get_variable('pkgdatadir') / 'protocols'")
      else
        -- wlroots not yet in dep_names — declare it here for pkgdatadir only
        l("_wlr_dep_proto = dependency('wlroots-0.18', required : true)")
        l("wlr_proto_dir  = _wlr_dep_proto.get_variable('pkgdatadir') / 'protocols'")
      end
    end

    -- pkg-config deps
    for _, dep in ipairs(dep_names) do
      if dep == 'threads' then
        l(var(dep) .. "_dep = dependency('threads')")
      else
        l(var(dep) .. "_dep = dependency('" .. dep .. "', required : true)")
      end
      all_dep_refs[#all_dep_refs + 1] = var(dep) .. '_dep'
    end
    l()
  end

  -- c_args
  local c_args = vim.deepcopy(opts.extra_cargs or {})
  if opts.needs_posix then
    local has = false
    for _, a in ipairs(c_args) do
      if a == '-D_POSIX_C_SOURCE=200809L' then
        has = true; break
      end
    end
    if not has then c_args[#c_args + 1] = '-D_POSIX_C_SOURCE=200809L' end
  end
  if opts.sanitizer and opts.sanitizer ~= 'none' then
    local sflag = opts.sanitizer == 'asan' and 'address'
        or opts.sanitizer == 'tsan' and 'thread'
        or 'undefined'
    c_args[#c_args + 1] = '-fsanitize=' .. sflag
    c_args[#c_args + 1] = '-fno-omit-frame-pointer'
  end

  -- Wayland protocol generation
  -- Each entry carries xml_ref: 'system_wp' | 'system_wlr' | 'vendored'
  -- which determines how we express the XML path in Meson.
  local protocol_entries = opts.protocol_entries or {}
  if #protocol_entries > 0 then
    l('# ── Wayland protocol generation ──────────────────────────────────────────────')
    l("wayland_scanner = find_program('wayland-scanner')")
    l()
    l('protocol_src = []')
    for _, entry in ipairs(protocol_entries) do
      local stem    = entry.xml:gsub('%.xml$', '')
      local varname = stem:gsub('%-', '_')

      -- Build the Meson XML reference expression
      local xml_meson
      if entry.xml_ref == 'system_wp' then
        -- e.g. wp_dir / 'stable/xdg-shell/xdg-shell.xml'
        xml_meson = "wp_dir / '" .. entry.xml_subpath .. "'"
      elseif entry.xml_ref == 'system_wlr' then
        -- e.g. wlr_proto_dir / 'wlr-layer-shell-unstable-v1.xml'
        xml_meson = "wlr_proto_dir / '" .. entry.xml_subpath .. "'"
      else
        -- vendored into include/protocols/
        xml_meson = "files('include/protocols/" .. entry.xml .. "')"
      end

      l(varname .. '_h = custom_target(')
      l("  '" .. stem .. "-client-header',")
      l("  input   : " .. xml_meson .. ",")
      l("  output  : '" .. stem .. "-protocol.h',")
      l("  command : [wayland_scanner, 'client-header', '@INPUT@', '@OUTPUT@'],")
      l(')')
      l(varname .. '_c = custom_target(')
      l("  '" .. stem .. "-private-code',")
      l("  input   : " .. xml_meson .. ",")
      l("  output  : '" .. stem .. "-protocol.c',")
      l("  command : [wayland_scanner, 'private-code', '@INPUT@', '@OUTPUT@'],")
      l(')')
      l('protocol_src += [' .. varname .. '_h, ' .. varname .. '_c]')
      l()
    end
  end

  -- executable(s)
  l('# ── Executable ───────────────────────────────────────────────────────────────')

  local deps_str = ''
  if #all_dep_refs > 0 then
    deps_str = table.concat(all_dep_refs, ', ')
  end
  local c_args_str = ''
  if #c_args > 0 then
    local quoted = vim.tbl_map(function(a) return "'" .. a .. "'" end, c_args)
    c_args_str = table.concat(quoted, ', ')
  end

  local function write_exe(exename, src_expr)
    l("exe = executable('" .. exename .. "',")
    l('  ' .. src_expr .. ',')
    l('  include_directories : inc,')
    if deps_str ~= '' then
      l('  dependencies        : [' .. deps_str .. '],')
    end
    if c_args_str ~= '' then
      l('  c_args              : [' .. c_args_str .. '],')
    end
    l("  link_args           : ['-Wl,--as-needed'],")
    l('  install             : false,')
    l(')')
  end

  if multi_exe then
    -- One executable per main() file, sharing common sources
    local proto_suffix = #protocol_entries > 0 and ' + protocol_src' or ''
    for _, m in ipairs(opts.multi_exe) do
      write_exe(m.base, "shared_src + files('" .. m.path .. "')" .. proto_suffix)
      l()
    end
  else
    local proto_suffix = #protocol_entries > 0 and 'src + protocol_src' or 'src'
    write_exe(opts.name, proto_suffix)
    l()
  end

  -- optional: tests
  if opts.testing and opts.test_framework ~= 'none' then
    l('# ── Tests ────────────────────────────────────────────────────────────────────')
    if opts.test_framework == 'gtest' then
      l("gtest_dep = dependency('gtest', main : true, required : true)")
      l('test_src = ' .. opts.test_src_decl)
      l("test_exe = executable('" .. opts.name .. "_tests',")
      l('  test_src,')
      l('  include_directories : inc,')
      l('  dependencies        : [gtest_dep],')
      l(')')
      l("test('" .. opts.name .. " unit tests', test_exe)")
    elseif opts.test_framework == 'catch2' then
      l("catch2_dep = dependency('catch2-with-main', required : true)")
      l('test_src = ' .. opts.test_src_decl)
      l("test_exe = executable('" .. opts.name .. "_tests',")
      l('  test_src,')
      l('  include_directories : inc,')
      l('  dependencies        : [catch2_dep],')
      l(')')
      l("test('" .. opts.name .. " unit tests', test_exe)")
    else
      l("# test_exe = executable('" .. opts.name .. "_tests', ...)")
      l("# test('" .. opts.name .. " tests', test_exe)")
    end
    l()
  end

  -- optional: install
  if opts.install then
    local inc_dir = (opts.inc_dirs and #opts.inc_dirs > 0) and opts.inc_dirs[1] or 'include'
    l('# ── Install ──────────────────────────────────────────────────────────────────')
    l("install_subdir('" .. inc_dir .. "',")
    l("  install_dir : get_option('includedir') / '" .. opts.name .. "'")
    l(')')
    l()
  end

  return table.concat(lines, '\n') .. '\n'
end

-- ── wizard ────────────────────────────────────────────────────────────────────

function M.create(root, on_back)
  root                = root or vim.fn.getcwd()
  local default_name  = vim.fn.fnamemodify(root, ':t')
  local detected_lang = infer_lang(root)

  ui().input({ prompt = '󰬷 Project name', default = default_name }, function(name)
    if not name or name == '' then return end

    local lang_items = {
      { id = 'cpp', label = 'C++', desc = 'cpp, .cpp sources' },
      { id = 'c',   label = 'C',   desc = 'c, .c sources' },
    }
    local lang_prompt = 'Language'
    if detected_lang then
      lang_prompt = 'Language  (detected: ' .. detected_lang .. ')'
      for i, it in ipairs(lang_items) do
        if it.id == detected_lang then
          table.remove(lang_items, i)
          table.insert(lang_items, 1, vim.tbl_extend('force', it, {
            label = it.label .. '  ✓ detected',
          }))
          break
        end
      end
    end

    ui().select(lang_items, {
      prompt      = lang_prompt,
      on_back     = on_back,
      format_item = plain,
    }, function(lang_ch)
      if not lang_ch then return end
      local lang = lang_ch.id

      local stds = lang == 'c'
          and {
            { id = 'c11', label = 'C11', desc = 'Recommended' },
            { id = 'c17', label = 'C17', desc = 'Latest stable' },
            { id = 'c99', label = 'C99', desc = 'Wide compat' },
          }
          or {
            { id = 'c++17', label = 'C++17', desc = 'Recommended' },
            { id = 'c++20', label = 'C++20', desc = 'Concepts, ranges' },
            { id = 'c++23', label = 'C++23', desc = 'Latest' },
            { id = 'c++14', label = 'C++14', desc = 'Lambdas, auto' },
          }

      ui().select(stds, { prompt = 'Language standard', format_item = plain },
        function(std_ch)
          if not std_ch then return end

          ui().select({
              { id = 'none',  label = 'None' },
              { id = 'asan',  label = 'AddressSanitizer', desc = '-fsanitize=address' },
              { id = 'tsan',  label = 'ThreadSanitizer',  desc = '-fsanitize=thread' },
              { id = 'ubsan', label = 'UBSanitizer',      desc = '-fsanitize=undefined' },
            }, { prompt = 'Sanitizer (optional)', format_item = plain },
            function(san_ch)
              ui().select({
                  { id = 'none',   label = 'No tests' },
                  { id = 'gtest',  label = 'GoogleTest',  desc = "dependency('gtest')" },
                  { id = 'catch2', label = 'Catch2',      desc = "dependency('catch2-with-main')" },
                  { id = 'custom', label = 'Custom stub', desc = 'Placeholder comments only' },
                }, { prompt = 'Test framework', format_item = plain },
                function(test_ch)
                  ui().select({
                      { id = 'no', label = 'No' },
                      { id = 'yes', label = 'Yes — add install_subdir()', desc = 'install_subdir() rule' },
                    }, { prompt = 'Add install rules?', format_item = plain },
                    function(inst_ch)
                      -- Run full detection pipeline
                      local detected   = auto_detect(root, lang)

                      -- Detect multiple main() files
                      local main_files = detect_main_files(root, lang)
                      local multi_exe  = #main_files > 1 and main_files or nil

                      -- Notify what was injected
                      local notices    = {}
                      if #detected.pkg_deps > 0 then
                        notices[#notices + 1] = 'pkg-config deps: ' .. table.concat(detected.pkg_deps, ' ')
                      end
                      if #detected.find_lib_deps > 0 then
                        local names = vim.tbl_map(function(d) return d.lib end, detected.find_lib_deps)
                        notices[#notices + 1] = 'find_library() deps: ' .. table.concat(names, ' ')
                      end
                      if detected.wlr_guard then
                        notices[#notices + 1] = 'wlroots headers → c_args: -DWLR_USE_UNSTABLE'
                      end
                      if detected.needs_posix then
                        notices[#notices + 1] = 'POSIX usage → c_args: -D_POSIX_C_SOURCE=200809L'
                      end
                      if multi_exe then
                        local bnames = vim.tbl_map(function(m) return m.base end, multi_exe)
                        notices[#notices + 1] = 'Multiple main() found → splitting executables: ' ..
                        table.concat(bnames, ', ')
                      end
                      if #notices > 0 then
                        vim.notify('[Marvin] Auto-injecting:\n  ' .. table.concat(notices, '\n  '), vim.log.levels.INFO)
                      end

                      local src_decl           = collect_sources(root, lang)
                      local test_src_decl      = collect_sources(root .. '/tests', lang)
                      local inc_decl, inc_dirs = collect_include_dirs(root)

                      -- For multi-exe: build shared_src by excluding the main() files
                      local shared_src_decl    = src_decl
                      if multi_exe then
                        local main_paths = {}
                        for _, m in ipairs(multi_exe) do main_paths[m.path] = true end
                        local shared = {}
                        for _, pat in ipairs({ '**/*.c', '**/*.cpp', '**/*.cxx' }) do
                          for _, f in ipairs(vim.fn.globpath(root, pat, false, true)) do
                            if not skip(f) then
                              local rel = f:sub(#root + 2)
                              if rel ~= '' and not main_paths[rel] then
                                shared[#shared + 1] = "  '" .. rel .. "'"
                              end
                            end
                          end
                        end
                        table.sort(shared)
                        shared_src_decl = #shared > 0
                            and 'files(\n' .. table.concat(shared, ',\n') .. '\n)'
                            or 'files()'
                      end

                      if #inc_dirs > 0 then
                        vim.notify('[Marvin] Include dirs:\n  ' .. table.concat(inc_dirs, '\n  '), vim.log.levels.INFO)
                      end

                      local ok_wp, wl_proto = pcall(require, 'marvin.wayland_protocols')
                      if not ok_wp then
                        vim.notify('[Marvin] wayland_protocols module error: ' .. tostring(wl_proto), vim.log.levels
                        .WARN)
                        wl_proto = nil
                      end
                      local protocol_entries = {}
                      if wl_proto then
                        local ok_r, proto_results = pcall(wl_proto.resolve, root)
                        if ok_r then
                          protocol_entries = proto_results
                          -- Notify which protocols were resolved and how
                          local sys_wp, sys_wlr, vendored_list = {}, {}, {}
                          for _, e in ipairs(protocol_entries) do
                            if e.xml_ref == 'system_wp' then
                              sys_wp[#sys_wp + 1] = e.xml
                            elseif e.xml_ref == 'system_wlr' then
                              sys_wlr[#sys_wlr + 1] = e.xml
                            else
                              vendored_list[#vendored_list + 1] = e.xml
                            end
                          end
                          if #sys_wp > 0 then
                            notices[#notices + 1] = 'wayland-protocols (system): ' .. #sys_wp .. ' XMLs via wp_dir'
                          end
                          if #sys_wlr > 0 then
                            notices[#notices + 1] = 'wlroots protocols (system): ' ..
                            #sys_wlr .. ' XMLs via wlr_proto_dir'
                          end
                          if #vendored_list > 0 then
                            notices[#notices + 1] = 'vendored protocols (fallback): ' ..
                            table.concat(vendored_list, ', ')
                          end
                        else
                          vim.notify('[Marvin] Protocol scan error: ' .. tostring(proto_results), vim.log.levels.WARN)
                        end
                      end

                      local opts = {
                        name             = name,
                        version          = '0.1.0',
                        lang             = lang,
                        std              = std_ch.id,
                        sanitizer        = san_ch and san_ch.id or 'none',
                        testing          = test_ch and test_ch.id ~= 'none',
                        test_framework   = test_ch and test_ch.id or 'none',
                        install          = inst_ch and inst_ch.id == 'yes',
                        dep_names        = detected.pkg_deps,
                        find_lib_deps    = detected.find_lib_deps,
                        needs_posix      = detected.needs_posix,
                        wlr_guard        = detected.wlr_guard,
                        extra_cargs      = detected.extra_cargs,
                        src_decl         = src_decl,
                        shared_src_decl  = shared_src_decl,
                        test_src_decl    = test_src_decl,
                        inc_decl         = inc_decl,
                        inc_dirs         = inc_dirs,
                        protocol_entries = protocol_entries,
                        multi_exe        = multi_exe,
                      }

                      local content = meson_template(opts)
                      check_existing(root .. '/meson.build', content, name)
                    end)
                end)
            end)
        end)
    end)
  end)
end

return M

```

### `lua/marvin/parser.lua`

```lua
-- lua/marvin/parser.lua
-- Marvin side: Maven compilation errors and test failures.
-- Jason side:  Java (javac), Rust, Go, C/C++ error patterns.

local M = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- Shared: populate quickfix and dispatch
-- ══════════════════════════════════════════════════════════════════════════════

function M.parse_output(lines)
  local errors = {}
  for _, line in ipairs(lines) do
    local err = M.parse_compilation_error(line) -- Marvin: Maven [ERROR]
        or M.parse_java_error(line)             -- Jason: javac style
        or M.parse_rust_error(line)
        or M.parse_go_error(line)
        or M.parse_cpp_error(line)
    if err then errors[#errors + 1] = err end

    local test_err = M.parse_test_failure(line) -- Marvin: Maven test
    if test_err then errors[#errors + 1] = test_err end
  end
  if #errors > 0 then M.populate_quickfix(errors) end
end

function M.populate_quickfix(errors)
  vim.fn.setqflist(errors, 'r')
  local config = require('marvin').config
  if config.quickfix.auto_open then
    vim.cmd('copen ' .. config.quickfix.height)
  end
  require('marvin.ui').notify(
    string.format('Found %d error(s). Use :cnext/:cprev to navigate.', #errors),
    vim.log.levels.WARN)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- MARVIN — Maven-specific patterns
-- ══════════════════════════════════════════════════════════════════════════════

-- [ERROR] /path/file.java:[line,col] message
function M.parse_compilation_error(line)
  local file, lnum, col, message =
      line:match('%[ERROR%]%s+(.-):%[(%d+),(%d+)%]%s+(.+)')
  if file then
    return { filename = file, lnum = tonumber(lnum), col = tonumber(col), text = message, type = 'E' }
  end
end

-- [ERROR]   TestClass.testMethod:line message
function M.parse_test_failure(line)
  local class, method, lnum, message =
      line:match('%[ERROR%]%s+(.-)%.(.-):(.-)[%s:]+(.*)')
  if class and method then
    local file = M.find_test_file(class)
    if file then
      return {
        filename = file,
        lnum     = tonumber(lnum),
        text     = string.format('%s.%s: %s', class, method, message),
        type     = 'E',
      }
    end
  end
end

function M.find_test_file(class_name)
  local project = require('marvin.project').get()
  if not project then return nil end
  local rel  = class_name:gsub('%.', '/') .. '.java'
  local path = project.root .. '/src/test/java/' .. rel
  if vim.fn.filereadable(path) == 1 then return path end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- JASON — Multi-language patterns
-- ══════════════════════════════════════════════════════════════════════════════

-- Java (javac): /path/File.java:10: error: message
-- Also catches Maven [ERROR] /path/File.java:[l,c] (duplicate with above, but
-- the combined dispatcher tries parse_compilation_error first, so no double-hit).
function M.parse_java_error(line)
  local file, lnum, message = line:match('([^:]+%.java):(%d+):%s*error:%s*(.+)')
  if file and lnum then
    return { filename = file, lnum = tonumber(lnum), col = 1, text = message, type = 'E' }
  end
  local mf, ml, mc, mm = line:match('%[ERROR%]%s+(.-):%[(%d+),(%d+)%]%s+(.+)')
  if mf then
    return { filename = mf, lnum = tonumber(ml), col = tonumber(mc), text = mm, type = 'E' }
  end
end

-- Rust: multi-line (stash the error line, resolve on the --> line)
function M.parse_rust_error(line)
  if line:match('^error%[') then
    M._rust_error_msg = line; return nil
  end
  if M._rust_error_msg then
    local file, lnum, col = line:match('%-%->%s+([^:]+):(%d+):(%d+)')
    if file and lnum then
      local err = {
        filename = file,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = M._rust_error_msg,
        type = 'E'
      }
      M._rust_error_msg = nil
      return err
    end
  end
end

-- Go: ./main.go:10:5: message
function M.parse_go_error(line)
  local file, lnum, col, message = line:match('([^:]+%.go):(%d+):(%d+):%s*(.+)')
  if file and lnum then
    return { filename = file, lnum = tonumber(lnum), col = tonumber(col) or 1, text = message, type = 'E' }
  end
end

-- C/C++: file.cpp:10:5: error/warning: message
function M.parse_cpp_error(line)
  local file, lnum, col, level, message =
      line:match('([^:]+%.[ch]p?p?):(%d+):(%d+):%s*(%w+):%s*(.+)')
  if file and lnum then
    return {
      filename = file,
      lnum     = tonumber(lnum),
      col      = tonumber(col) or 1,
      text     = message,
      type     = level == 'warning' and 'W' or 'E',
    }
  end
end

return M

```

### `lua/marvin/project.lua`

```lua
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

```

### `lua/marvin/tasks.lua`

```lua
-- lua/marvin/tasks.lua
-- .jason.lua task definitions: loading, menu building, execution, watch mode.
-- (Was jason.tasks — absorbed into marvin namespace.)

local M     = {}
M._cache    = {}
M._watchers = {}

local function mtime(path)
  local s = vim.loop.fs_stat(path); return s and s.mtime.sec or 0
end

function M.load(root)
  if not root then return {} end
  local path = root .. '/.jason.lua'
  if vim.fn.filereadable(path) == 0 then return {} end
  local mt = mtime(path)
  local c  = M._cache[root]
  if c and c.mtime == mt then return c.tasks end
  local ok, result = pcall(dofile, path)
  if not ok or type(result) ~= 'table' then
    vim.notify('[jason] .jason.lua error: ' .. tostring(result), vim.log.levels.WARN)
    return {}
  end
  local tasks = result.tasks or {}
  M._cache[root] = { tasks = tasks, mtime = mt }
  return tasks
end

function M.to_menu_items(tasks)
  local items = {}
  for _, t in ipairs(tasks) do
    local watching = M._watchers['__task__' .. t.name]
    items[#items + 1] = {
      id    = '__task__' .. t.name,
      icon  = watching and '󰓛' or (t.restart and '󰑖' or '󰐊'),
      label = t.name,
      desc  = t.desc or t.cmd,
      badge = watching and 'watching' or (t.restart and 'watch' or nil),
      _task = t,
    }
  end
  return items
end

function M.run(task_def, project, term_cfg)
  term_cfg     = term_cfg or require('marvin').config.terminal
  local runner = require('core.runner')
  local id     = '__task__' .. task_def.name
  local title  = task_def.title or task_def.name
  local cwd    = task_def.cwd and (project.root .. '/' .. task_def.cwd) or project.root

  local cmd    = task_def.cmd
  if task_def.env then
    local parts = {}
    for k, v in pairs(task_def.env) do
      parts[#parts + 1] = k .. '=' .. vim.fn.shellescape(tostring(v))
    end
    cmd = table.concat(parts, ' ') .. ' ' .. cmd
  end

  if task_def.depends and #task_def.depends > 0 then
    local all   = M.load(project.root)
    local steps = {}
    for _, dep in ipairs(task_def.depends) do
      for _, t in ipairs(all) do
        if t.name == dep then
          steps[#steps + 1] = { cmd = t.cmd, title = t.title or t.name }; break
        end
      end
    end
    steps[#steps + 1] = { cmd = cmd, title = title }
    runner.execute_sequence(steps, {
      cwd = cwd, term_cfg = term_cfg, plugin = 'jason', action_id = id })
    return
  end

  if task_def.restart then
    M._start_watch(id, cmd, cwd, title, term_cfg)
  else
    runner.execute({
      cmd = cmd,
      cwd = cwd,
      title = title,
      term_cfg = term_cfg,
      plugin = 'jason',
      action_id = id
    })
  end
end

function M._start_watch(id, cmd, cwd, title, term_cfg)
  M._watchers[id] = true
  require('core.runner').execute_watch({
    cmd = cmd,
    cwd = cwd,
    title = '󰑖 ' .. title,
    term_cfg = term_cfg,
    plugin = 'jason',
    action_id = id,
  })
end

function M.stop_watch(id)
  M._watchers[id] = nil
  require('core.runner').stop_watch(id)
  vim.notify('[jason] Watch stopped: ' .. id:sub(9), vim.log.levels.INFO)
end

function M.handle_action(id, project)
  if not id or not id:match('^__task__') then return false end
  local name  = id:sub(9)
  local tasks = M.load(project.root)
  for _, t in ipairs(tasks) do
    if t.name == name then
      if t.restart and M._watchers[id] then
        M.stop_watch(id)
      else
        M.run(t, project)
      end
      return true
    end
  end
  return false
end

return M

```

### `lua/marvin/templates.lua`

```lua
local M = {}

-- Get package from current file path
function M.get_package_from_path()
  local current_file = vim.api.nvim_buf_get_name(0)
  local project = require('marvin.project').get()

  if not project then return nil end

  -- Try to extract package from current Java file
  if current_file:match('%.java$') then
    local lines = vim.api.nvim_buf_get_lines(0, 0, 20, false)
    for _, line in ipairs(lines) do
      local package = line:match('^%s*package%s+([%w%.]+)')
      if package then
        return package
      end
    end
  end

  -- Try to extract from path
  local src_main = current_file:match('/src/main/java/(.+)')
  local src_test = current_file:match('/src/test/java/(.+)')
  local src_path = src_main or src_test

  if src_path then
    local package = src_path:match('(.+)/[^/]+$')
    if package then
      return package:gsub('/', '.')
    end
  end

  return nil
end

-- Get default package
function M.get_default_package()
  local project = require('marvin.project').get()
  if project and project.info and project.info.group_id then
    return project.info.group_id
  end
  return 'com.example'
end

-- Class template
function M.class_template(name, package, options)
  options = options or {}
  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  if options.imports then
    for _, import in ipairs(options.imports) do
      table.insert(lines, "import " .. import .. ";")
    end
    table.insert(lines, "")
  end

  -- Get config setting for javadoc
  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * " .. (options.description or name))
    table.insert(lines, " */")
  end

  local modifier = options.modifier or "public"
  local extends = options.extends and (" extends " .. options.extends) or ""
  local implements = ""
  if options.implements and #options.implements > 0 then
    implements = " implements " .. table.concat(options.implements, ", ")
  end

  table.insert(lines, modifier .. " class " .. name .. extends .. implements .. " {")

  if options.main then
    table.insert(lines, "  public static void main(String[] args) {")
    table.insert(lines, "    // TODO: Implementation")
    table.insert(lines, "  }")
  else
    table.insert(lines, "  // TODO: Implementation")
  end

  table.insert(lines, "}")

  return lines
end

-- Interface template
function M.interface_template(name, package, options)
  options = options or {}
  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  if options.imports then
    for _, import in ipairs(options.imports) do
      table.insert(lines, "import " .. import .. ";")
    end
    table.insert(lines, "")
  end

  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * " .. (options.description or name))
    table.insert(lines, " */")
  end

  local extends = ""
  if options.extends and #options.extends > 0 then
    extends = " extends " .. table.concat(options.extends, ", ")
  end

  table.insert(lines, "public interface " .. name .. extends .. " {")
  table.insert(lines, "  // TODO: Define methods")
  table.insert(lines, "}")

  return lines
end

-- Enum template
function M.enum_template(name, package, options)
  options = options or {}
  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * " .. (options.description or name))
    table.insert(lines, " */")
  end

  table.insert(lines, "public enum " .. name .. " {")

  local values = options.values or { "VALUE1", "VALUE2", "VALUE3" }
  for i, value in ipairs(values) do
    local comma = i < #values and "," or ";"
    table.insert(lines, "  " .. value .. comma)
  end

  table.insert(lines, "}")

  return lines
end

-- Record template (Java 14+)
function M.record_template(name, package, options)
  options = options or {}
  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  if options.imports then
    for _, import in ipairs(options.imports) do
      table.insert(lines, "import " .. import .. ";")
    end
    table.insert(lines, "")
  end

  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * " .. (options.description or name))
    table.insert(lines, " */")
  end

  local fields = options.fields or {
    { type = "String", name = "name" },
    { type = "int",    name = "value" }
  }

  local field_list = {}
  for _, field in ipairs(fields) do
    table.insert(field_list, field.type .. " " .. field.name)
  end

  table.insert(lines, "public record " .. name .. "(" .. table.concat(field_list, ", ") .. ") {")
  table.insert(lines, "}")

  return lines
end

-- Abstract class template
function M.abstract_class_template(name, package, options)
  options = options or {}
  options.modifier = "public abstract"
  return M.class_template(name, package, options)
end

-- Exception template
function M.exception_template(name, package, options)
  options = options or {}
  options.extends = options.extends or "Exception"
  options.imports = options.imports or {}

  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * " .. (options.description or name))
    table.insert(lines, " */")
  end

  table.insert(lines, "public class " .. name .. " extends " .. options.extends .. " {")
  table.insert(lines, "  public " .. name .. "() {")
  table.insert(lines, "    super();")
  table.insert(lines, "  }")
  table.insert(lines, "")
  table.insert(lines, "  public " .. name .. "(String message) {")
  table.insert(lines, "    super(message);")
  table.insert(lines, "  }")
  table.insert(lines, "")
  table.insert(lines, "  public " .. name .. "(String message, Throwable cause) {")
  table.insert(lines, "    super(message, cause);")
  table.insert(lines, "  }")
  table.insert(lines, "}")

  return lines
end

-- JUnit test template
function M.test_template(name, package, options)
  options = options or {}
  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  table.insert(lines, "import org.junit.jupiter.api.Test;")
  table.insert(lines, "import org.junit.jupiter.api.BeforeEach;")
  table.insert(lines, "import org.junit.jupiter.api.AfterEach;")
  table.insert(lines, "import static org.junit.jupiter.api.Assertions.*;")
  table.insert(lines, "")

  if options.imports then
    for _, import in ipairs(options.imports) do
      table.insert(lines, "import " .. import .. ";")
    end
    table.insert(lines, "")
  end

  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * Tests for " .. (options.class_under_test or "class"))
    table.insert(lines, " */")
  end

  table.insert(lines, "public class " .. name .. " {")
  table.insert(lines, "  @BeforeEach")
  table.insert(lines, "  public void setUp() {")
  table.insert(lines, "    // Setup test fixtures")
  table.insert(lines, "  }")
  table.insert(lines, "")
  table.insert(lines, "  @AfterEach")
  table.insert(lines, "  public void tearDown() {")
  table.insert(lines, "    // Cleanup")
  table.insert(lines, "  }")
  table.insert(lines, "")
  table.insert(lines, "  @Test")
  table.insert(lines, "  public void testExample() {")
  table.insert(lines, "    // TODO: Implement test")
  table.insert(lines, "    fail(\"Not yet implemented\");")
  table.insert(lines, "  }")
  table.insert(lines, "}")

  return lines
end

-- Builder pattern template
function M.builder_template(name, package, options)
  options = options or {}
  local lines = {}

  if package and package ~= "" then
    table.insert(lines, "package " .. package .. ";")
    table.insert(lines, "")
  end

  local fields = options.fields or {
    { type = "String", name = "name",  required = true },
    { type = "int",    name = "value", required = false }
  }

  local config = require('marvin').config
  local enable_javadoc = config.java and config.java.enable_javadoc or false

  local should_add_javadoc = options.javadoc
  if should_add_javadoc == nil then
    should_add_javadoc = enable_javadoc
  end

  if should_add_javadoc then
    table.insert(lines, "/**")
    table.insert(lines, " * " .. (options.description or name))
    table.insert(lines, " */")
  end

  table.insert(lines, "public class " .. name .. " {")

  -- Fields
  for _, field in ipairs(fields) do
    table.insert(lines, "  private final " .. field.type .. " " .. field.name .. ";")
  end
  table.insert(lines, "")

  -- Private constructor
  table.insert(lines, "  private " .. name .. "(Builder builder) {")
  for _, field in ipairs(fields) do
    table.insert(lines, "    this." .. field.name .. " = builder." .. field.name .. ";")
  end
  table.insert(lines, "  }")
  table.insert(lines, "")

  -- Getters
  for _, field in ipairs(fields) do
    local getter_name = "get" .. field.name:sub(1, 1):upper() .. field.name:sub(2)
    table.insert(lines, "  public " .. field.type .. " " .. getter_name .. "() {")
    table.insert(lines, "    return " .. field.name .. ";")
    table.insert(lines, "  }")
    table.insert(lines, "")
  end

  -- Builder class
  table.insert(lines, "  public static class Builder {")
  for _, field in ipairs(fields) do
    table.insert(lines, "    private " .. field.type .. " " .. field.name .. ";")
  end
  table.insert(lines, "")

  -- Builder methods
  for _, field in ipairs(fields) do
    table.insert(lines, "    public Builder " .. field.name .. "(" .. field.type .. " " .. field.name .. ") {")
    table.insert(lines, "      this." .. field.name .. " = " .. field.name .. ";")
    table.insert(lines, "      return this;")
    table.insert(lines, "    }")
    table.insert(lines, "")
  end

  table.insert(lines, "    public " .. name .. " build() {")
  -- Add validation for required fields
  for _, field in ipairs(fields) do
    if field.required then
      table.insert(lines, "      if (" .. field.name .. " == null) {")
      table.insert(lines, "        throw new IllegalStateException(\"" .. field.name .. " is required\");")
      table.insert(lines, "      }")
    end
  end
  table.insert(lines, "      return new " .. name .. "(this);")
  table.insert(lines, "    }")
  table.insert(lines, "  }")
  table.insert(lines, "}")

  return lines
end

return M

```

### `lua/marvin/trixie_bridge.lua`

```lua
-- lua/marvin/trixie.lua
-- Bidirectional bridge between the Marvin nvim plugin and the Trixie compositor.
--
-- COMPOSITOR → NVIM  (compositor writes a line to the IPC socket):
--   marvin_cmd <action>         e.g. build / run / test / clean / build_run
--   marvin_cmd focus\t<f>\t<l>  open file:line in nvim
--   marvin_cmd reload           re-read project config
--
-- NVIM → COMPOSITOR  (we write IPC commands to the Unix socket):
--   marvin_project <json>
--   marvin_build   <json>
--   marvin_diag    <json>
--   marvin_git     <json>
--   marvin_buffers <json>
--   marvin_cursor  <json>
--   marvin_actions <json>

local M            = {}
local uv           = vim.uv or vim.loop
local runner       = require('core.runner')

-- ── Config ────────────────────────────────────────────────────────────────
local SOCK_PATH    = os.getenv('TRIXIE_IPC') or '/tmp/trixie.sock'
local RECONNECT_MS = 3000

-- ── State ─────────────────────────────────────────────────────────────────
local _client      = nil -- uv TCP/pipe handle
local _connected   = false
local _send_queue  = {} -- queued while disconnected
local _recv_buf    = '' -- partial line buffer

-- ── Low-level send ────────────────────────────────────────────────────────
local function raw_send(line)
  if _connected and _client then
    _client:write(line .. '\n')
  else
    _send_queue[#_send_queue + 1] = line
  end
end

-- ── Flush queue after connect ─────────────────────────────────────────────
local function flush_queue()
  local q = _send_queue
  _send_queue = {}
  for _, line in ipairs(q) do
    _client:write(line .. '\n')
  end
end

-- ── Inbound dispatcher ────────────────────────────────────────────────────
-- Lines arriving from compositor have the form:
--   {"event":"marvin_cmd","action":"build"}
--   {"event":"marvin_cmd","action":"focus","file":"…","line":42}
local function dispatch_event(line)
  local ok, obj = pcall(vim.json.decode, line)
  if not ok or type(obj) ~= 'table' then return end
  if obj.event ~= 'marvin_cmd' then return end

  local act = obj.action
  if not act then return end

  if act == 'build' then
    M.trigger_build()
  elseif act == 'run' then
    M.trigger_run()
  elseif act == 'test' then
    M.trigger_test()
  elseif act == 'clean' then
    M.trigger_clean()
  elseif act == 'build_run' then
    M.trigger_build_run()
  elseif act == 'reload' then
    M.push_project()
    M.push_actions()
  elseif act == 'focus' then
    local f = obj.file
    local l = obj.line or 0
    if f and f ~= '' then
      vim.schedule(function()
        vim.cmd('edit ' .. vim.fn.fnameescape(f))
        if l > 0 then
          vim.api.nvim_win_set_cursor(0, { l, 0 })
        end
      end)
    end
  end
end

-- ── Connect ───────────────────────────────────────────────────────────────
local function on_read(err, data)
  if err or not data then
    _connected = false
    if _client then _client:close() end
    _client = nil
    vim.defer_fn(M.connect, RECONNECT_MS)
    return
  end
  _recv_buf = _recv_buf .. data
  while true do
    local nl = _recv_buf:find('\n', 1, true)
    if not nl then break end
    local line = _recv_buf:sub(1, nl - 1)
    _recv_buf = _recv_buf:sub(nl + 1)
    if line ~= '' then
      vim.schedule(function() dispatch_event(line) end)
    end
  end
end

function M.connect()
  local pipe = uv.new_pipe(false)
  pipe:connect(SOCK_PATH, function(err)
    if err then
      pipe:close()
      vim.defer_fn(M.connect, RECONNECT_MS)
      return
    end
    _client    = pipe
    _connected = true
    pipe:read_start(on_read)
    vim.schedule(function()
      flush_queue()
      -- Announce ourselves immediately
      M.push_project()
      M.push_actions()
      M.push_git()
      M.push_buffers()
    end)
  end)
end

function M.disconnect()
  _connected = false
  if _client then
    _client:close()
    _client = nil
  end
end

-- ── Push helpers ──────────────────────────────────────────────────────────
local function send_json(cmd, obj)
  local ok, enc = pcall(vim.json.encode, obj)
  if ok then raw_send(cmd .. ' ' .. enc) end
end

-- ── Project ───────────────────────────────────────────────────────────────
function M.push_project()
  local root = vim.fn.getcwd()
  -- Detect project type
  local ptype = 'generic'
  if vim.fn.filereadable(root .. '/Cargo.toml') == 1 then
    ptype = 'cargo'
  elseif vim.fn.filereadable(root .. '/go.mod') == 1 then
    ptype = 'go'
  elseif vim.fn.filereadable(root .. '/pom.xml') == 1 then
    ptype = 'maven'
  elseif vim.fn.filereadable(root .. '/CMakeLists.txt') == 1 then
    ptype = 'cmake'
  elseif vim.fn.filereadable(root .. '/package.json') == 1 then
    ptype = 'npm'
  elseif vim.fn.filereadable(root .. '/Makefile') == 1 then
    ptype = 'make'
  elseif vim.fn.filereadable(root .. '/build.zig') == 1 then
    ptype = 'zig'
  end

  -- Project name from directory basename
  local name = vim.fn.fnamemodify(root, ':t')

  -- Default commands per type
  local build_cmds = {
    cargo = 'cargo build',
    go = 'go build ./...',
    maven = 'mvn compile',
    cmake = 'cmake --build build',
    npm = 'npm run build',
    make = 'make',
    zig = 'zig build',
    generic = 'make',
  }
  local run_cmds = {
    cargo = 'cargo run',
    go = 'go run .',
    maven = 'mvn exec:java',
    cmake = './build/app',
    npm = 'npm start',
    make = 'make run',
    zig = 'zig build run',
    generic = '',
  }

  send_json('marvin_project', {
    root      = root,
    name      = name,
    type      = ptype,
    build_cmd = build_cmds[ptype] or '',
    run_cmd   = run_cmds[ptype] or '',
  })
end

-- ── Cursor / symbol ───────────────────────────────────────────────────────
function M.push_cursor()
  local buf        = vim.api.nvim_get_current_buf()
  local win        = vim.api.nvim_get_current_win()
  local pos        = vim.api.nvim_win_get_cursor(win)
  local file       = vim.api.nvim_buf_get_name(buf)
  -- Try to get LSP symbol at cursor (non-blocking best-effort)
  local sym        = ''
  local ok, params = pcall(vim.lsp.util.make_position_params)
  if ok and params then
    -- We can't block; just use treesitter node text as fallback
    local ts_ok, node = pcall(function()
      return vim.treesitter.get_node({ pos = { pos[1] - 1, pos[2] } })
    end)
    if ts_ok and node then sym = node:type() end
  end
  send_json('marvin_cursor', {
    file   = file,
    line   = pos[1],
    col    = pos[2],
    symbol = sym,
  })
end

-- ── Diagnostics ───────────────────────────────────────────────────────────
function M.push_diag()
  local diag = vim.diagnostic.get(nil) -- all buffers
  local items = {}
  for _, d in ipairs(diag) do
    items[#items + 1] = {
      file     = vim.api.nvim_buf_get_name(d.bufnr or 0),
      lnum     = d.lnum + 1,
      col      = d.col,
      severity = d.severity,
      message  = d.message,
      source   = d.source,
    }
    if #items >= 200 then break end
  end
  send_json('marvin_diag', items)
end

-- ── Git ───────────────────────────────────────────────────────────────────
function M.push_git()
  -- Try gitsigns first, fall back to shelling out
  local ok, gs = pcall(require, 'gitsigns')
  if ok and gs.get_hunks then
    local status = vim.b.gitsigns_status_dict
    if status then
      send_json('marvin_git', {
        branch = status.head or '',
        status = (status.added == 0 and status.changed == 0 and status.removed == 0)
            and 'clean' or 'dirty',
        ahead  = 0,
        behind = 0,
      })
      return
    end
  end
  -- Shell fallback (async)
  vim.fn.jobstart({ 'git', 'status', '--porcelain', '-b' }, {
    cwd             = vim.fn.getcwd(),
    stdout_buffered = true,
    on_stdout       = function(_, data)
      local branch, dirty = '', false
      for _, l in ipairs(data) do
        if l:match('^##') then
          branch = l:match('## ([^%.%.]+)') or ''
        elseif l:match('^[^ ]') then
          dirty = true
        end
      end
      send_json('marvin_git', {
        branch = branch,
        status = dirty and 'dirty' or 'clean',
        ahead = 0,
        behind = 0,
      })
    end,
  })
end

-- ── Buffers ───────────────────────────────────────────────────────────────
function M.push_buffers()
  local bufs = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
      bufs[#bufs + 1] = {
        bufnr    = b,
        name     = vim.api.nvim_buf_get_name(b),
        modified = vim.bo[b].modified,
        filetype = vim.bo[b].filetype,
      }
    end
  end
  send_json('marvin_buffers', bufs)
end

-- ── Actions ───────────────────────────────────────────────────────────────
-- Populated by Marvin's action registry; default to project-type actions.
function M.push_actions()
  local ok, marvin = pcall(require, 'marvin')
  local actions    = {}
  if ok and marvin.get_actions then
    actions = marvin.get_actions()
  else
    actions = { 'build', 'run', 'test', 'clean', 'build_run' }
  end
  -- send as a plain JSON array of action id strings
  local ok2, enc = pcall(vim.json.encode, actions)
  if ok2 then raw_send('marvin_actions ' .. enc) end
end

-- ── Build notifications (runner.lua integration) ──────────────────────────
runner.on_start(function(entry)
  if entry.plugin ~= 'marvin' then return end
  send_json('marvin_build', {
    status    = 'running',
    exit_code = 0,
    errors    = 0,
    warnings  = 0,
    timestamp = entry.timestamp,
  })
end)

runner.on_finish(function(entry)
  if entry.plugin ~= 'marvin' then return end
  -- Count diag severity from LSP after a short settle delay
  vim.defer_fn(function()
    local diag     = vim.diagnostic.get(nil)
    local errors   = 0; local warnings = 0
    for _, d in ipairs(diag) do
      if d.severity == vim.diagnostic.severity.ERROR then
        errors = errors + 1
      elseif d.severity == vim.diagnostic.severity.WARN then
        warnings = warnings + 1
      end
    end
    send_json('marvin_build', {
      status    = entry.success and 'ok' or 'failed',
      exit_code = entry.success and 0 or 1,
      errors    = errors,
      warnings  = warnings,
      timestamp = entry.timestamp,
    })
    M.push_diag()
  end, 500)
end)

-- ── Trigger helpers (called by compositor key events or Marvin UI) ─────────
function M.trigger_build()
  local ok, marvin = pcall(require, 'marvin')
  if ok and marvin.build then
    marvin.build()
  else
    runner.execute({
      cmd = 'make',
      title = 'Build',
      plugin = 'marvin',
      action_id = 'build',
      term_cfg = { position = 'background' }
    })
  end
end

function M.trigger_run()
  local ok, marvin = pcall(require, 'marvin')
  if ok and marvin.run then
    marvin.run()
  else
    runner.execute({
      cmd = 'make run',
      title = 'Run',
      plugin = 'marvin',
      action_id = 'run',
      term_cfg = { position = 'background' }
    })
  end
end

function M.trigger_test()
  local ok, marvin = pcall(require, 'marvin')
  if ok and marvin.test then
    marvin.test()
  else
    runner.execute({
      cmd = 'make test',
      title = 'Test',
      plugin = 'marvin',
      action_id = 'test',
      term_cfg = { position = 'background' }
    })
  end
end

function M.trigger_clean()
  local ok, marvin = pcall(require, 'marvin')
  if ok and marvin.clean then
    marvin.clean()
  else
    runner.execute({
      cmd = 'make clean',
      title = 'Clean',
      plugin = 'marvin',
      action_id = 'clean',
      term_cfg = { position = 'background' }
    })
  end
end

function M.trigger_build_run()
  runner.execute_sequence(
    { { cmd = 'make', title = 'Build' },
      { cmd = 'make run', title = 'Run' } },
    { plugin = 'marvin', term_cfg = { position = 'background' } }
  )
end

-- ── Autocommands ──────────────────────────────────────────────────────────
function M.setup_autocmds()
  local g = vim.api.nvim_create_augroup('MarvinTrixie', { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufEnter' }, {
    group    = g,
    callback = function() vim.defer_fn(M.push_cursor, 80) end,
  })
  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group    = g,
    callback = function() vim.defer_fn(M.push_diag, 300) end,
  })
  vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete', 'BufWipeout' }, {
    group    = g,
    callback = function() vim.defer_fn(M.push_buffers, 100) end,
  })
  vim.api.nvim_create_autocmd('DirChanged', {
    group    = g,
    callback = function()
      vim.defer_fn(M.push_project, 50)
      vim.defer_fn(M.push_git, 200)
      vim.defer_fn(M.push_actions, 100)
    end,
  })
end

-- ── Setup entry point ─────────────────────────────────────────────────────
function M.setup(opts)
  opts = opts or {}
  if opts.sock_path then SOCK_PATH = opts.sock_path end
  M.connect()
  M.setup_autocmds()
end

return M

```

### `lua/marvin/ui.lua`

```lua
-- lua/marvin/ui.lua
local M = {}
M.backend = nil

local C = {
  bg       = '#1e1e2e',
  bg3      = '#11111b',
  surface0 = '#313244',
  surface1 = '#45475a',
  surface2 = '#585b70',
  text     = '#cdd6f4',
  sub1     = '#bac2de',
  sub0     = '#a6adc8',
  ov0      = '#6c7086',
  ov1      = '#7f849c',
  blue     = '#89b4fa',
  mauve    = '#cba6f7',
  green    = '#a6e3a1',
  yellow   = '#f9e2af',
  peach    = '#fab387',
  red      = '#f38ba8',
  sky      = '#89dceb',
}

local function setup_highlights()
  local function hl(n, o) vim.api.nvim_set_hl(0, n, o) end
  hl('MarvinWin', { bg = C.bg, fg = C.text })
  hl('MarvinBorder', { fg = C.surface1, bg = C.bg })
  hl('MarvinTitle', { fg = C.mauve, bold = true })
  hl('MarvinSelected', { bg = C.mauve, fg = C.bg, bold = true })
  hl('MarvinItem', { fg = C.sub1 })
  hl('MarvinItemIcon', { fg = C.text })
  hl('MarvinDesc', { fg = C.ov0 })
  hl('MarvinSepLine', { fg = C.surface1 })
  hl('MarvinSepLabel', { fg = C.ov1, italic = true })
  hl('MarvinSearch', { fg = C.sky, bold = true })
  hl('MarvinSearchBox', { fg = C.ov0 })
  hl('MarvinFooter', { fg = C.ov0 })
  hl('MarvinFooterKey', { fg = C.peach, bold = true })
  hl('MarvinBadge', { fg = C.yellow })
  hl('MarvinHiddenCursor', { fg = C.bg, bg = C.bg, blend = 100 })
  hl('MarvinInputText', { fg = C.sky })
  hl('MarvinInputHint', { fg = C.ov0 })
end

function M.detect_backend()
  if pcall(require, 'snacks') then
    return 'snacks'
  elseif pcall(require, 'dressing') then
    return 'dressing'
  else
    return 'builtin'
  end
end

-- cfg is passed in from marvin.init to avoid a circular require.
function M.init(cfg)
  cfg = cfg or {}
  local backend = cfg.ui_backend or 'auto'
  M.backend = backend == 'auto' and M.detect_backend() or backend
  setup_highlights()
end

-- ── Fuzzy match ───────────────────────────────────────────────────────────────
local function fuzzy(str, pat)
  if pat == '' then return true, 0 end
  str = str:lower(); pat = pat:lower()
  local sc, s, p, con = 0, 1, 1, 0
  while p <= #pat and s <= #str do
    if str:sub(s, s) == pat:sub(p, p) then
      sc = sc + 1 + con * 5; con = con + 1; p = p + 1
    else
      con = 0
    end
    s = s + 1
  end
  if p > #pat then
    if str:sub(1, #pat) == pat then sc = sc + 20 end
    return true, sc
  end
  return false, 0
end

-- ── Main select ───────────────────────────────────────────────────────────────
function M.select(items, opts, callback)
  opts                = opts or {}
  local prompt        = opts.prompt or 'Select'
  local enable_search = opts.enable_search ~= false
  local on_back       = opts.on_back or nil
  local format_fn     = opts.format_item or function(it)
    return type(it) == 'table' and (it.label or it.name or tostring(it)) or tostring(it)
  end

  local all           = {}
  for i, it in ipairs(items) do
    all[i] = {
      idx     = i,
      item    = it,
      display = format_fn(it),
      icon    = type(it) == 'table' and it.icon or nil,
      desc    = type(it) == 'table' and it.desc or nil,
      badge   = type(it) == 'table' and it.badge or nil,
      is_sep  = type(it) == 'table' and (it.is_separator == true) or false,
    }
  end

  local vis    = vim.deepcopy(all)
  local search = ''
  local screen = vim.api.nvim_list_uis()[1]
  local LIST_W = math.min(80, math.max(60, math.floor(screen.width * 0.55)))

  local function sel_total()
    local n = 0
    for _, f in ipairs(vis) do if not f.is_sep then n = n + 1 end end
    return n
  end

  local function content_lines()
    return #vis + (enable_search and 3 or 1) + 4
  end

  local function win_h()
    return math.max(10, math.min(content_lines(), math.floor(screen.height * 0.82)))
  end

  local WIN_H = win_h()
  local ROW   = math.floor((screen.height - WIN_H) / 2)
  local COL   = math.floor((screen.width - LIST_W) / 2)

  local lbuf  = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = lbuf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = lbuf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = lbuf })
  vim.api.nvim_set_option_value('modifiable', false, { buf = lbuf })

  local saved_gc = vim.o.guicursor
  vim.o.guicursor = 'a:MarvinHiddenCursor'

  local lwin = vim.api.nvim_open_win(lbuf, true, {
    relative  = 'editor',
    width     = LIST_W,
    height    = WIN_H,
    row       = ROW,
    col       = COL,
    style     = 'minimal',
    zindex    = 50,
    border    = 'single',
    title     = { { ' ' .. prompt .. ' ', 'MarvinTitle' } },
    title_pos = 'left',
  })
  vim.api.nvim_set_option_value('winhl',
    'Normal:MarvinWin,FloatBorder:MarvinBorder', { win = lwin })
  for k, v in pairs({
    cursorline = false, wrap = false,
    number = false, relativenumber = false,
    signcolumn = 'no', scrolloff = 0,
  }) do vim.api.nvim_set_option_value(k, v, { win = lwin }) end

  local ns      = vim.api.nvim_create_namespace('marvin_select')
  local sel_pos = 1
  local vt      = 1

  local function visible_rows()
    return math.max(1, WIN_H - (enable_search and 3 or 1) - 4)
  end

  local function desc_col()
    local mx = 0
    for _, f in ipairs(vis) do
      if not f.is_sep and f.desc then
        local w = 3 + (f.icon and 2 or 0) + vim.fn.strdisplaywidth(f.display)
        mx = math.max(mx, w + 2)
      end
    end
    return math.min(mx, math.floor((LIST_W - 2) * 0.55))
  end

  local function redraw()
    local lines, hls = {}, {}
    local VR         = visible_rows()
    local total      = sel_total()
    local DC         = desc_col()

    local function ahl(l, h, cs, ce)
      hls[#hls + 1] = { line = l, hl = h, cs = cs, ce = ce }
    end

    sel_pos = math.max(1, math.min(sel_pos, math.max(1, total)))
    if sel_pos < vt then vt = sel_pos end
    if sel_pos > vt + VR - 1 then vt = sel_pos - VR + 1 end
    vt = math.max(1, vt)

    if enable_search then
      if search == '' then
        lines[#lines + 1] = '  _'
        ahl(#lines - 1, 'MarvinSearchBox', 0, -1)
      else
        lines[#lines + 1] = '  ' .. search .. '_'
        ahl(#lines - 1, 'MarvinSearch', 0, -1)
      end
      lines[#lines + 1] = string.rep('-', LIST_W)
      ahl(#lines - 1, 'MarvinSepLine', 0, -1)
      lines[#lines + 1] = ''
    else
      lines[#lines + 1] = ''
    end

    if #vis == 0 then
      lines[#lines + 1] = '  No matches found'
      ahl(#lines - 1, 'MarvinDesc', 0, -1)
    else
      local view_end  = math.min(vt + VR - 1, total)
      local show_up   = vt > 1
      local show_down = view_end < total
      local rank      = 0

      for _, f in ipairs(vis) do
        if f.is_sep then
          local ln          = #lines
          local t           = ' ' .. f.display .. ' '
          local tw          = vim.fn.strdisplaywidth(t)
          local rem         = math.max(0, LIST_W - tw)
          local ll          = math.floor(rem / 2)
          local lr          = rem - ll
          lines[#lines + 1] = string.rep('-', ll) .. t .. string.rep('-', lr)
          ahl(ln, 'MarvinSepLine', 0, -1)
          ahl(ln, 'MarvinSepLabel', ll, ll + tw)
        else
          rank = rank + 1
          if rank >= vt and rank <= view_end then
            local is_sel   = (rank == sel_pos)
            local caret    = is_sel and '>> ' or '   '
            local icon_str = f.icon and (f.icon .. ' ') or ''
            local label    = f.display
            local lw       = vim.fn.strdisplaywidth(label)
            local iw       = vim.fn.strdisplaywidth(icon_str)

            local body
            if f.desc then
              local gap = math.max(1, DC - (#caret + iw + lw))
              body = icon_str .. label .. string.rep(' ', gap) .. '* ' .. f.desc
            else
              body = icon_str .. label
            end
            if f.badge then body = body .. '  ' .. f.badge end

            local row = caret .. body
            local rw  = vim.fn.strdisplaywidth(row)
            if rw < LIST_W - 2 then
              row = row .. string.rep(' ', LIST_W - 2 - rw)
            end

            local ln = #lines
            lines[#lines + 1] = row

            if is_sel then
              ahl(ln, 'MarvinSelected', 0, -1)
            else
              if f.icon then ahl(ln, 'MarvinItemIcon', #caret, #caret + iw) end
              ahl(ln, 'MarvinItem', #caret + iw, #caret + iw + lw)
              if f.desc then ahl(ln, 'MarvinDesc', DC + 2, -1) end
              if f.badge then
                ahl(ln, 'MarvinBadge', -vim.fn.strdisplaywidth(f.badge) - 2, -1)
              end
            end

            if rank == vt and show_up then ahl(ln, 'MarvinFooter', LIST_W - 3, LIST_W - 2) end
            if rank == view_end and show_down then ahl(ln, 'MarvinFooter', LIST_W - 3, LIST_W - 2) end
          end
        end
      end
    end

    lines[#lines + 1] = string.rep('-', LIST_W)
    ahl(#lines - 1, 'MarvinSepLine', 0, -1)
    local info = string.format('  %d/%d items', sel_pos, sel_total())
    if search ~= '' then info = info .. '  "' .. search .. '"' end
    lines[#lines + 1] = info
    ahl(#lines - 1, 'MarvinFooter', 0, -1)
    local hint = '  j/k Navigate | <CR> Select | <Esc> Cancel'
    if on_back then hint = hint .. ' | <BS> Back' end
    lines[#lines + 1] = hint
    ahl(#lines - 1, 'MarvinFooterKey', 0, -1)

    vim.api.nvim_set_option_value('modifiable', true, { buf = lbuf })
    vim.api.nvim_buf_set_lines(lbuf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = lbuf })
    vim.api.nvim_buf_clear_namespace(lbuf, ns, 0, -1)
    for _, h in ipairs(hls) do
      pcall(vim.api.nvim_buf_add_highlight, lbuf, ns, h.hl, h.line, h.cs, h.ce)
    end
    pcall(vim.api.nvim_win_set_cursor, lwin, { 1, 0 })
  end

  local function move(d)
    local total = sel_total()
    if total == 0 then return end
    if d == 'dn' then
      sel_pos = sel_pos % total + 1
    elseif d == 'up' then
      sel_pos = sel_pos - 1; if sel_pos < 1 then sel_pos = total end
    elseif d == 'pgd' then
      sel_pos = math.min(sel_pos + 8, total)
    elseif d == 'pgu' then
      sel_pos = math.max(sel_pos - 8, 1)
    elseif d == 'top' then
      sel_pos = 1
    elseif d == 'bot' then
      sel_pos = total
    end
    redraw()
  end

  local function do_search(c)
    if c == '<BS>' then
      search = search:sub(1, -2)
    elseif c == '<C-u>' then
      search = ''
    else
      search = search .. c
    end
    vis = {}
    for _, f in ipairs(all) do
      if f.is_sep then
        if search == '' then vis[#vis + 1] = vim.deepcopy(f) end
      else
        local ok, sc = fuzzy(f.display, search)
        if ok then
          local fc = vim.deepcopy(f); fc.score = sc; vis[#vis + 1] = fc
        end
      end
    end
    if search ~= '' then
      table.sort(vis, function(a, b) return (a.score or 0) > (b.score or 0) end)
    end
    sel_pos = 1; vt = 1
    pcall(vim.api.nvim_win_set_height, lwin, win_h())
    redraw()
  end

  local function close()
    vim.o.guicursor = saved_gc
    pcall(vim.api.nvim_win_close, lwin, true)
  end

  local function pick()
    local rank = 0
    for _, f in ipairs(vis) do
      if not f.is_sep then
        rank = rank + 1
        if rank == sel_pos then
          local chosen = f.item; close(); callback(chosen); return
        end
      end
    end
  end

  local mo = { noremap = true, silent = true, buffer = lbuf }
  vim.keymap.set('n', 'j', function() move('dn') end, mo)
  vim.keymap.set('n', 'k', function() move('up') end, mo)
  vim.keymap.set('n', '<Down>', function() move('dn') end, mo)
  vim.keymap.set('n', '<Up>', function() move('up') end, mo)
  vim.keymap.set('n', '<C-d>', function() move('pgd') end, mo)
  vim.keymap.set('n', '<C-u>', function() move('pgu') end, mo)
  vim.keymap.set('n', '<C-n>', function() move('dn') end, mo)
  vim.keymap.set('n', '<C-p>', function() move('up') end, mo)
  vim.keymap.set('n', 'G', function() move('bot') end, mo)
  vim.keymap.set('n', 'gg', function() move('top') end, mo)
  vim.keymap.set('n', '<CR>', pick, mo)
  vim.keymap.set('n', '<Space>', pick, mo)
  vim.keymap.set('n', 'l', pick, mo)
  vim.keymap.set('n', '<Esc>', function()
    close(); callback(nil)
  end, mo)
  vim.keymap.set('n', 'q', function()
    close(); callback(nil)
  end, mo)
  vim.keymap.set('n', '<BS>', function()
    if on_back and search == '' then
      close(); on_back()
    elseif enable_search then
      do_search('<BS>')
    end
  end, mo)

  if enable_search then
    local nav = { j = true, k = true, q = true, l = true, G = true, g = true }
    vim.keymap.set('n', '<C-u>', function() do_search('<C-u>') end, mo)
    for i = 32, 126 do
      local c = string.char(i)
      if not nav[c] then
        vim.keymap.set('n', c, function() do_search(c) end, mo)
      end
    end
  end

  for _, k in ipairs({ 'i', 'I', 'a', 'A', 'o', 'O', 'c', 'C', 's', 'S' }) do
    vim.keymap.set('n', k, '<Nop>', mo)
  end

  vim.api.nvim_create_autocmd('WinLeave', {
    buffer   = lbuf,
    once     = true,
    callback = function() vim.o.guicursor = saved_gc end,
  })

  redraw()
end

-- ── Input popup ───────────────────────────────────────────────────────────────
function M.input(opts, cb)
  opts          = opts or {}
  local prompt  = opts.prompt or 'Input'
  local default = opts.default or ''
  local screen  = vim.api.nvim_list_uis()[1]
  local W       = math.min(60, math.floor(screen.width * 0.5))
  local ROW     = math.floor((screen.height - 4) / 2)
  local COL     = math.floor((screen.width - W) / 2)

  local ibuf    = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = ibuf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = ibuf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = ibuf })

  local iwin = vim.api.nvim_open_win(ibuf, true, {
    relative  = 'editor',
    width     = W,
    height    = 4,
    row       = ROW,
    col       = COL,
    style     = 'minimal',
    border    = 'single',
    title     = { { ' ' .. prompt .. ' ', 'MarvinTitle' } },
    title_pos = 'left',
    zindex    = 60,
  })
  vim.api.nvim_set_option_value('winhl',
    'Normal:MarvinWin,FloatBorder:MarvinBorder', { win = iwin })

  vim.api.nvim_buf_set_lines(ibuf, 0, -1, false, {
    '',
    default,
    '',
    '  <CR> confirm | <Esc> cancel',
  })

  local ns = vim.api.nvim_create_namespace('marvin_input')
  vim.api.nvim_buf_add_highlight(ibuf, ns, 'MarvinInputText', 1, 0, -1)
  vim.api.nvim_buf_add_highlight(ibuf, ns, 'MarvinInputHint', 3, 0, -1)

  vim.api.nvim_win_set_cursor(iwin, { 2, #default })
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(iwin) then
      vim.cmd('startinsert!')
    end
  end)

  local submitted = false

  local function close_and_call(value)
    if submitted then return end
    submitted = true
    vim.cmd('stopinsert')
    pcall(vim.api.nvim_win_close, iwin, true)
    vim.schedule(function() cb(value) end)
  end

  local function submit()
    local text = vim.trim(vim.api.nvim_buf_get_lines(ibuf, 1, 2, false)[1] or '')
    close_and_call(text ~= '' and text or nil)
  end

  local function cancel()
    close_and_call(nil)
  end

  local mo = { noremap = true, silent = true, buffer = ibuf }
  vim.keymap.set('i', '<CR>', submit, mo)
  vim.keymap.set('i', '<Esc>', cancel, mo)
  vim.keymap.set('i', '<C-c>', cancel, mo)
  vim.keymap.set('n', '<CR>', submit, mo)
  vim.keymap.set('n', '<Esc>', cancel, mo)
  vim.keymap.set('n', 'q', cancel, mo)
  vim.keymap.set('i', '<Up>', '<Nop>', mo)
  vim.keymap.set('i', '<Down>', '<Nop>', mo)
end

-- ── Notify ────────────────────────────────────────────────────────────────────
function M.notify(msg, level, opts)
  opts  = opts or {}
  level = level or vim.log.levels.INFO
  if M.backend == 'snacks' then
    local ok, snacks = pcall(require, 'snacks')
    if ok then
      local lm = {
        [vim.log.levels.ERROR] = 'error',
        [vim.log.levels.WARN]  = 'warn',
        [vim.log.levels.INFO]  = 'info',
      }
      snacks.notify(msg, { level = lm[level] or 'info', title = opts.title or 'Marvin' })
      return
    end
  end
  vim.notify(msg, level, { title = opts.title or 'Marvin' })
end

-- ── Maven goal menu (used by marvin.ui directly) ──────────────────────────────
function M.show_goal_menu(on_back)
  local project = require('marvin.project')
  if not project.validate_environment() then return end
  M.select(M.get_common_goals(), {
    prompt        = 'Maven Goal',
    on_back       = on_back,
    enable_search = true,
    format_item   = function(g) return g.label end,
  }, function(choice)
    if not choice then return end
    if choice.needs_profile then
      M.show_profile_menu(choice.goal, function() M.show_goal_menu(on_back) end)
    elseif choice.needs_options then
      M.show_options_menu()
    else
      require('marvin.executor').run(choice.goal)
    end
  end)
end

function M.get_common_goals()
  return {
    { label = 'Build Lifecycle', is_separator = true },
    { goal = 'clean', label = 'Clean', icon = '󰃢 ', desc = 'Delete target/ directory' },
    { goal = 'compile', label = 'Compile', icon = '󰑕 ', desc = 'Compile source code' },
    { goal = 'test', label = 'Test', icon = '󰙨 ', desc = 'Run unit tests' },
    { goal = 'package', label = 'Package', icon = '󰏗 ', desc = 'Create JAR/WAR file' },
    { goal = 'verify', label = 'Verify', icon = '󰄬 ', desc = 'Run integration tests' },
    { goal = 'install', label = 'Install', icon = '󰇚 ', desc = 'Install to ~/.m2/repository' },
    { label = 'Common Tasks', is_separator = true },
    { goal = 'clean install', label = 'Clean & Install', icon = '󰑓 ', desc = 'Full rebuild and install' },
    { goal = 'clean package', label = 'Clean & Package', icon = '󰑓 ', desc = 'Fresh build to JAR' },
    { goal = 'test -DskipTests', label = 'Skip Tests', icon = '󰒭 ', desc = 'Build without running tests' },
    { label = 'Dependencies', is_separator = true },
    { goal = 'dependency:tree', label = 'Dependency Tree', icon = '󰙅 ', desc = 'Show full dependency graph' },
    { goal = 'dependency:resolve', label = 'Resolve Deps', icon = '󰚰 ', desc = 'Download all dependencies' },
    { goal = 'dependency:analyze', label = 'Analyze Deps', icon = '󰍉 ', desc = 'Find unused/undeclared deps' },
    { goal = 'versions:display-dependency-updates', label = 'Check for Updates', icon = '󰚰 ', desc = 'Find newer dependency versions' },
    { label = 'Information', is_separator = true },
    { goal = 'help:effective-pom', label = 'Effective POM', icon = '󰈙 ', desc = 'Show resolved configuration' },
    { goal = 'help:effective-settings', label = 'Effective Settings', icon = '󰈙', desc = 'Show Maven settings' },
    { label = 'Custom', is_separator = true },
    { goal = nil, label = 'Custom Goal', icon = '', desc = 'Enter any Maven command', needs_options = true },
  }
end

function M.show_profile_menu(goal, on_back)
  local project = require('marvin.project').get()
  if not project or not project.info or #project.info.profiles == 0 then
    vim.notify('No profiles found in pom.xml', vim.log.levels.WARN)
    require('marvin.executor').run(goal); return
  end
  local profiles = { { id = nil, label = '(default)', icon = '', desc = 'No profile selected' } }
  for _, pid in ipairs(project.info.profiles) do
    profiles[#profiles + 1] = { id = pid, label = pid, icon = '', desc = 'Maven profile' }
  end
  M.select(profiles, { prompt = 'Select Profile', on_back = on_back },
    function(choice)
      if choice then require('marvin.executor').run(goal, { profile = choice.id }) end
    end)
end

function M.show_options_menu()
  M.input({ prompt = 'Maven goal(s)' }, function(custom_goal)
    if not custom_goal then return end
    M.input({ prompt = 'Additional options (optional)' }, function(extra)
      local full = custom_goal
      if extra then full = full .. ' ' .. extra end
      require('marvin.executor').run(full)
    end)
  end)
end

return M

```

### `lua/marvin/wayland_protocols.lua`

```lua
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

```

### `marvin_dump.md`

```md
