-- lua/marvin/color.lua
-- Central highlight definitions for all Marvin + Jason UI components.
-- Links to standard Neovim highlight groups so the plugin matches any
-- colorscheme.  User overrides can be provided via config.ui.theme.

local M = {}

local _config = nil

local HIGHLIGHTS = {
  -- ── Marvin UI (float select / input) ──────────────────────────────────
  MarvinWin          = { link = 'NormalFloat',   default = true },
  MarvinBorder       = { link = 'FloatBorder',   default = true },
  MarvinTitle        = { link = 'Title',          default = true },
  MarvinSelected     = { link = 'PmenuSel',      default = true },
  MarvinItem         = { link = 'NormalFloat',   default = true },
  MarvinItemIcon     = { link = 'Special',       default = true },
  MarvinDesc         = { link = 'Comment',       default = true },
  MarvinSepLine      = { link = 'NonText',       default = true },
  MarvinSepLabel     = { link = 'NonText',       default = true },
  MarvinSearch       = { link = 'Search',        default = true },
  MarvinSearchBox    = { link = 'NonText',       default = true },
  MarvinFooter       = { link = 'Comment',       default = true },
  MarvinFooterKey    = { link = 'MoreMsg',       default = true },
  MarvinBadge        = { link = 'WarningMsg',    default = true },
  MarvinHiddenCursor = { blend = 100,              default = true },
  MarvinInputText    = { link = 'Normal',        default = true },
  MarvinInputHint    = { link = 'Comment',       default = true },

  -- ── Jason Console (task history + output) ─────────────────────────────
  JasonConWin        = { link = 'NormalFloat',   default = true },
  JasonConBorder     = { link = 'FloatBorder',   default = true },
  JasonConTitle      = { link = 'Title',          default = true },
  JasonConOutWin     = { link = 'NormalFloat',   default = true },
  JasonConOutBorder  = { link = 'FloatBorder',   default = true },
  JasonConOutTitle   = { link = 'Title',          default = true },
  JasonConSep        = { link = 'NonText',       default = true },
  JasonConSepLbl     = { link = 'NonText',       default = true },
  JasonConSel        = { link = 'PmenuSel',      default = true },
  JasonConOk         = { link = 'DiagnosticOk',  default = true },
  JasonConFail       = { link = 'DiagnosticError', default = true },
  JasonConRunning    = { link = 'DiagnosticWarn',  default = true },
  JasonConDim        = { link = 'NonText',       default = true },
  JasonConCmd        = { link = 'Identifier',    default = true },
  JasonConTime       = { link = 'Constant',      default = true },
  JasonConFooter     = { link = 'Comment',       default = true },
  JasonConFooterKey  = { link = 'MoreMsg',       default = true },
}

function M.setup(config)
  if config then _config = config end

  local hl = vim.api.nvim_set_hl

  -- Apply base definitions (default=true preserves any user pre-sets)
  for name, opts in pairs(HIGHLIGHTS) do
    hl(0, name, opts)
  end

  -- Apply user overrides unconditionally
  if _config and _config.ui and type(_config.ui.theme) == 'table' then
    for name, opts in pairs(_config.ui.theme) do
      if type(name) == 'string' and type(opts) == 'table' then
        hl(0, name, opts)
      end
    end
  end
end

-- Re-apply after :colorscheme (groups are wiped by `hi clear`)
function M.reload()
  M.setup()
end

return M
