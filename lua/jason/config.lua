-- lua/jason/config.lua
local M = {}

M.defaults = {
  ui_backend = 'auto',

  terminal = {
    position = 'float', -- float, split, vsplit, background
    size = 0.4,
    close_on_success = false,
  },

  quickfix = {
    auto_open = true,
    height = 10,
  },

  keymaps = {
    dashboard = '<leader>jb',
    build = '<leader>jc',
    run = '<leader>jr',
    test = '<leader>jt',
    clean = '<leader>jx',
  },

  -- Language-specific configs
  java = {
    build_tool = 'auto',        -- auto, maven, gradle, javac
    main_class_finder = 'auto', -- auto, prompt
  },

  rust = {
    build_tool = 'cargo',
    profile = 'dev', -- dev, release
  },

  go = {
    build_tool = 'go',
  },

  cpp = {
    build_tool = 'auto', -- auto, cmake, make, gcc
    compiler = 'g++',
    standard = 'c++17',
  },

  graalvm = {
    extra_build_args = '',               -- extra flags passed to native-image
    output_dir       = 'target/native',  -- relative to project root
    no_fallback      = true,             -- --no-fallback (pure native, no JVM backup)
    g1gc             = false,            -- --gc=G1  (GraalVM EE only)
    pgo              = 'none',           -- 'none' | 'instrument' | 'optimize'
    report_size      = true,             -- -H:+PrintAnalysisCallTree
    agent_output_dir = 'src/main/resources/META-INF/native-image',
  },
}

function M.setup(opts)
  return vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M
