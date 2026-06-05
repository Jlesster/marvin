# Marvin + Jason

A unified Neovim plugin for project management and task execution, supporting
Java (Maven/Gradle), Rust (Cargo), Go, and C/C++ (CMake, Meson, Makefile).

**Marvin** handles project detection, dependency management, file creation, and
build system generation.  
**Jason** is the task runner — build, run, test, and watch with a live output
console.

---

## Features

- **Automatic project detection** — walks up the directory tree from the current
  buffer; supports Maven, Gradle, Cargo, Go modules, CMake, Meson, and Makefile
  projects
- **Multi-language support** — Java, Rust, Go, C, C++, with single-file fallback
- **Dependency management** — add, remove, update, audit crates/modules/Maven
  deps from inside Neovim
- **File creation wizards** — scaffolding for classes, interfaces, structs,
  traits, modules, tests, and more
- **Build system generation** — interactive wizards for Makefile,
  CMakeLists.txt, and meson.build with automatic pkg-config, POSIX, and wlroots
  detection
- **Live task console** — two-panel output viewer with history, re-run, and
  dismiss
- **Wayland compositor support** — first-class handling of protocol XML
  generation, wlroots headers, and `WLR_USE_UNSTABLE`
- **Nix/NixOS aware** — resolves compilers and include dirs through PATH and
  `NIX_CFLAGS_COMPILE`; no hardcoded FHS paths
- **GraalVM native image** — build, run, and agent-instrumentation support for
  Java projects
- **Local static library management** — build, export, register, and link
  `.a`/`.so` files from within Neovim
- **Monorepo / workspace support** — sub-project picker for Cargo workspaces, Go
  workspaces, and multi-module Maven projects

---

## Requirements

- Neovim ≥ 0.10
- Language toolchains as needed (`cargo`, `go`, `mvn`/`gradle`,
  `gcc`/`g++`/`clang`, `cmake`, `meson`)
- Optional: `pkg-config`, `bear`, `compiledb`, `govulncheck`, `cargo-audit`,
  `cargo-outdated`

---

## Installation

### lazy.nvim

```lua
{
  'Jlesster/marvin',
  config = function()
    require('marvin').setup()
  end,
}
```

### With custom options

```lua
{
  'Jlesster/marvin',
  config = function()
    require('marvin').setup({
      terminal = {
        position = 'float',   -- float | split | vsplit | background
        size     = 0.4,
        close_on_success = false,
      },
      keymaps = {
        dashboard    = '<leader>m',
        jason        = '<leader>j',
        jason_build  = '<leader>jc',
        jason_run    = '<leader>jr',
        jason_test   = '<leader>jt',
        jason_clean  = '<leader>jx',
        jason_console = '<leader>jo',
      },
      cpp = {
        compiler = 'g++',
        standard = 'c++17',
      },
      rust = {
        profile = 'dev',   -- dev | release
      },
      java = {
        maven_command = 'mvn',
      },
    })
  end,
}
```

---

## Configuration

Full default configuration:

```lua
require('marvin').setup({
  ui_backend = 'auto',          -- auto | snacks | dressing | builtin

  ui = {
    theme = 'auto',             -- 'auto' or a table of highlight overrides
  },

  terminal = {
    position        = 'float', -- float | split | vsplit | background
    size            = 0.4,
    close_on_success = false,
  },

  quickfix = {
    auto_open = true,
    height    = 10,
  },

  keymaps = {
    dashboard     = '<leader>m',
    jason         = '<leader>j',
    jason_build   = '<leader>jc',
    jason_run     = '<leader>jr',
    jason_test    = '<leader>jt',
    jason_clean   = '<leader>jx',
    jason_console = '<leader>jo',
  },

  java = {
    enable_javadoc   = false,
    maven_command    = 'mvn',
    build_tool       = 'auto',
  },

  rust = {
    profile = 'dev',            -- dev | release
  },

  cpp = {
    build_tool = 'auto',        -- auto | cmake | make | gcc
    compiler   = 'g++',
    standard   = 'c++17',
    nix = {
      cc              = nil,   -- force C compiler,   e.g. 'clang'
      cxx             = nil,   -- force C++ compiler, e.g. 'clang++'
      extra_inc_dirs  = nil,   -- nil = read from NIX_CFLAGS_COMPILE
    },
  },

  graalvm = {
    extra_build_args  = '',
    output_dir        = 'target/native',
    no_fallback       = true,
    g1gc              = false,
    pgo               = 'none',   -- none | instrument | optimize
    report_size       = true,
    agent_output_dir  = 'src/main/resources/META-INF/native-image',
  },
})
```

---

## Usage

### Dashboards

| Command         | Description                                                      |
| --------------- | ---------------------------------------------------------------- |
| `:Marvin`       | Open the project dashboard (create files, manage deps, settings) |
| `:Jason`        | Open the task runner dashboard (build, run, test, format, lint)  |
| `:JasonConsole` | Toggle the live task output console                              |

### Direct build actions

| Command            | Description                                  |
| ------------------ | -------------------------------------------- |
| `:JasonBuild`      | Build the current project                    |
| `:JasonRun`        | Run the current project                      |
| `:JasonTest`       | Run tests                                    |
| `:JasonClean`      | Clean build artifacts                        |
| `:JasonBuildRun`   | Build then run                               |
| `:JasonFmt`        | Format source files                          |
| `:JasonLint`       | Run linter                                   |
| `:JasonPackage`    | Create distributable package                 |
| `:JasonInstall`    | Install to local registry                    |
| `:JasonBuildArgs`  | Build with custom arguments (prompted)       |
| `:JasonRunArgs`    | Run with custom arguments (prompted)         |
| `:JasonTestFilter` | Run a specific test by name/pattern          |
| `:JasonExec <cmd>` | Run an arbitrary command in the project root |
| `:JasonStop`       | Stop the current running task                |
| `:JasonStopAll`    | Stop all running tasks                       |

### Maven commands

| Command         | Description        |
| --------------- | ------------------ |
| `:Maven <goal>` | Run any Maven goal |
| `:MavenCompile` | `mvn compile`      |
| `:MavenTest`    | `mvn test`         |
| `:MavenPackage` | `mvn package`      |
| `:MavenInstall` | `mvn install`      |
| `:MavenClean`   | `mvn clean`        |
| `:MavenVerify`  | `mvn verify`       |

### Project management

| Command              | Description                                    |
| -------------------- | ---------------------------------------------- |
| `:MarvinInfo`        | Show detected project type, root, and language |
| `:MarvinReload`      | Re-parse the project manifest                  |
| `:MarvinSwitch`      | Switch active sub-project (monorepo)           |
| `:JavaNew`           | New Java file wizard                           |
| `:MavenNew`          | New Maven project from archetype               |
| `:CppNew`            | New C/C++ file wizard                          |
| `:RustNew`           | New Cargo crate                                |
| `:MarvinNewMakefile` | Create a Makefile from the interactive wizard  |
| `:JasonNewMakefile`  | Same as above (Jason alias)                    |

### GraalVM

| Command       | Description                                  |
| ------------- | -------------------------------------------- |
| `:GraalBuild` | Build a native image                         |
| `:GraalRun`   | Run the native binary                        |
| `:GraalInfo`  | Show GraalVM status and install instructions |

---

## Project Detection

Marvin walks up from the current buffer's directory (or `cwd`) looking for these
marker files, in priority order:

| Type       | Marker                              | Language |
| ---------- | ----------------------------------- | -------- |
| `cargo`    | `Cargo.toml`                        | Rust     |
| `go_mod`   | `go.mod`                            | Go       |
| `cmake`    | `CMakeLists.txt`                    | C/C++    |
| `meson`    | `meson.build`                       | C/C++    |
| `makefile` | `Makefile` / `makefile`             | C/C++    |
| `maven`    | `pom.xml`                           | Java     |
| `gradle`   | `build.gradle` / `build.gradle.kts` | Java     |

If no marker is found, it falls back to a **single-file** mode based on the
current buffer's filetype (`java`, `rust`, `go`, `c`, `cpp`).

---

## Language-Specific Features

### Java (Maven / Gradle)

- Build lifecycle actions: compile, test, package, verify, install, clean
- Dependency management: add/remove from catalogue, OWASP audit, outdated check
- File creation: Class, Interface, Enum, Record, Abstract Class, Exception,
  JUnit Test, Builder pattern
- Package picker with sub-package navigation
- GraalVM native image integration
- Maven archetype project generation with local catalogue scanning

### Rust (Cargo)

- Build, run, test, clippy, fmt, doc, bench
- Dev/release profile toggle
- Dependency management: `cargo add`/`cargo remove` with catalogue,
  `cargo audit`, `cargo outdated`
- File creation: Struct (with derives/impl/tests), Trait, Impl, Module,
  Integration Test, Binary target
- Workspace member navigation

### Go

- Build, run, vet, fmt, lint, clean, godoc
- Test with race detector, coverage, benchmarks, and filter
- Dependency management: `go get`/`go get @none`, tidy, `go list -u`,
  `govulncheck`
- File creation: Struct (with constructor, JSON tags, methods), Interface (with
  mock), Test, Command, Package
- `cmd/` multi-entry-point navigation

### C / C++ (CMake, Meson, Makefile)

- Build, run, test, clean, install, format, lint
- Automatic detection of:
  - `pkg-config` dependencies from `#include` scanning
  - POSIX symbol/header usage (`-D_POSIX_C_SOURCE=200809L`)
  - Linker flags from well-known libraries (`-lpthread`, `-lssl`, `-lm`, etc.)
  - Multiple `main()` files (split into separate executables in Meson/CMake)
  - wlroots headers (`-DWLR_USE_UNSTABLE`)
- File creation: Class (header+source), Abstract Class, Struct, Enum,
  Header-only, Test (gtest/Catch2), main.cpp
- Local static library management (build `.a`, export, register search paths,
  link picker)
- `compile_commands.json` generation via CMake, Meson, bear, or compiledb
- Interactive build system wizards (Makefile, CMakeLists.txt, meson.build)
- Wayland protocol XML resolution and `custom_target()` generation

---

## Task Console

Open with `:JasonConsole` or `<leader>jo`.

The console shows a two-panel view — task history on the left, output on the
right.

| Key              | Action                     |
| ---------------- | -------------------------- |
| `j` / `k`        | Navigate history           |
| `<CR>` / `<Tab>` | Jump to output panel       |
| `r`              | Re-run selected task       |
| `d`              | Dismiss entry from history |
| `q` / `<Esc>`    | Close console              |

Running jobs are shown at the top of the history list with a live spinner. The
console auto-opens when a task starts and auto-refreshes every 500ms while open.

---

## Custom Tasks (`.jason.lua`)

Place a `.jason.lua` file in your project root to define custom tasks:

```lua
return {
  tasks = {
    {
      name    = 'dev-server',
      desc    = 'Start development server',
      cmd     = 'npm run dev',
      restart = true,   -- watch mode: auto-restart on exit
    },
    {
      name    = 'generate',
      desc    = 'Run code generator',
      cmd     = 'go generate ./...',
      cwd     = 'internal',   -- relative to project root
      env     = { GO_ENV = 'development' },
    },
    {
      name    = 'test-ci',
      desc    = 'Full CI test suite',
      cmd     = 'make test-all',
      depends = { 'generate' },   -- runs 'generate' first
    },
  },
}
```

Tasks appear in the Jason dashboard under a **Tasks** section. Tasks with
`restart = true` run in watch mode — clicking again stops the watcher.

---

## Build System Wizards

### Makefile wizard (`:MarvinNewMakefile`)

Interactive prompts for language (C, C++, Go, Rust, Generic), compiler,
standard, source/include directories, binary name, sanitizer, and extra flags.
Auto-detects pkg-config deps, POSIX usage, and wlroots guard.

### meson.build wizard (`:Jason` → Build System → New meson.build)

Full auto-detection pipeline:

- `pkg-config` deps from header scanning
- `find_library()` deps (libm, librt, libdl, libpthread) from symbol scanning
- Wayland protocol XML resolution (system paths via `wp_dir` / `wlr_proto_dir`,
  vendored fallback)
- Multi-executable splitting when multiple `main()` files are detected
- POSIX define, wlroots unstable guard, xkbcommon

### CMakeLists.txt wizard

Interactive wizard with auto-link detection from `#include` scanning, pkg-config
integration, test target (CTest + gtest/Catch2), and install rules.

---

## compile_commands.json

Access via Jason → Build System → Generate compile_commands.json.

Available methods:

- **Meson** — `meson setup builddir`, then a Python rewriter resolves all
  relative `-I` flags to absolute paths, injects `builddir/` and per-target
  `.p/` dirs, and runs `pkg-config --cflags` for detected libraries
- **CMake** — `cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -S .`
- **bear** — wraps any build command (`bear -- make`)
- **compiledb** — `compiledb make`
- **.clangd config** — writes a `.clangd` file with `-I` flags from detected
  includes and pkg-config; no build required

After generation, clangd is restarted automatically.

---

## Wayland Protocol Support

Marvin scans source files for `#include "*-protocol.h"` patterns and resolves
each needed XML:

- **wayland-protocols** XMLs are referenced via the system `pkgdatadir` — never
  copied into the project
- **wlroots protocol** XMLs are resolved from the wlroots
  `pkgdatadir/protocols/`, with a download fallback from the wlroots GitLab if
  not installed
- Protocol `.h`/`.c` files are **not** pre-generated — `custom_target()` blocks
  in `meson.build` handle generation at build time

---

## Nix / NixOS

On NixOS, Marvin:

- Resolves all compilers through `PATH` (picks up the cc-wrapper, not raw store
  paths)
- Parses `NIX_CFLAGS_COMPILE` for system include directories
- Parses `NIX_LDFLAGS` for system library directories
- Uses `~/.local` as the install prefix (instead of `/usr/local`)
- Falls back to querying the compiler directly (`-E -x c /dev/null -v`) if env
  vars are unset

No special configuration is needed inside a `nix develop` shell.

---

## Architecture

```
marvin/
├── init.lua            Plugin entry point, setup(), keymaps, autocommands
├── detector.lua        Project detection and manifest parsing
├── build.lua           Multi-language build command engine (C/C++ core + language table)
├── runner.lua          (core/) Terminal/background job execution, history, watch mode
├── console.lua         Two-panel task output console
├── dashboard.lua       Marvin project dashboard
├── jason_dashboard.lua Jason task runner dashboard
├── ui.lua              Fuzzy-search select/input popups (builtin, no deps required)
├── color.lua           Highlight group definitions
├── commands.lua        User command registrations
├── keymaps.lua         Keymap registrations
├── config.lua          Default configuration
├── nix.lua             Nix/NixOS compatibility helpers
├── executor.lua        Maven goal executor
├── parser.lua          Error output → quickfix list
├── templates.lua       Java file templates
├── tasks.lua           .jason.lua custom task loader/runner
├── wayland_protocols.lua  Protocol XML resolution
├── lang/
│   ├── java.lua        Java dashboard module
│   ├── rust.lua        Rust dashboard module
│   ├── go.lua          Go dashboard module
│   └── cpp.lua         C/C++ dashboard module
├── creator/
│   ├── java.lua        Java file creation wizard
│   ├── rust.lua        Rust file creation wizard
│   ├── go.lua          Go file creation wizard
│   └── cpp.lua         C/C++ file creation wizard
├── deps/
│   ├── java.lua        Java dependency management
│   ├── rust.lua        Rust dependency management
│   └── go.lua          Go dependency management
├── makefile_creator.lua   Makefile wizard
├── meson_creator.lua      meson.build wizard
├── cmake_creator.lua      CMakeLists.txt wizard
├── local_libs.lua      Local static library management
└── graalvm.lua         GraalVM native image helpers
```

---

## License

MIT
