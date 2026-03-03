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
