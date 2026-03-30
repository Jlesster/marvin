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
