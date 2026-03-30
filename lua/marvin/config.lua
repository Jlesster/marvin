-- lua/marvin/config.lua
local M = {}

M.defaults = {
	ui_backend = "auto", -- auto | snacks | dressing | builtin

	terminal = {
		position = "float", -- float | split | vsplit | background
		size = 0.4,
		close_on_success = false,
	},

	quickfix = {
		auto_open = true,
		height = 10,
	},

	keymaps = {
		dashboard = "<leader>m",
		jason = "<leader>j",
		jason_build = "<leader>jc",
		jason_run = "<leader>jr",
		jason_test = "<leader>jt",
		jason_clean = "<leader>jx",
		jason_console = "<leader>jo",
	},

	-- ── Java ──────────────────────────────────────────────────────────────────
	java = {
		enable_javadoc = false,
		maven_command = "mvn",
		build_tool = "auto",
		main_class_finder = "auto",
		archetypes = {
			"maven-archetype-quickstart",
			"maven-archetype-webapp",
			"maven-archetype-simple",
			"jless-schema-archetype",
		},
	},

	-- ── Rust ──────────────────────────────────────────────────────────────────
	rust = {
		profile = "dev", -- dev | release
	},

	-- ── Go ────────────────────────────────────────────────────────────────────
	go = {},

	-- ── C / C++ ───────────────────────────────────────────────────────────────
	cpp = {
		build_tool = "auto", -- auto | cmake | make | gcc
		compiler = "g++",
		standard = "c++17",

		-- Nix-specific overrides. All nil = auto-detected via marvin.nix.
		-- Only needed when auto-detection fails (e.g. outside a nix develop shell).
		nix = {
			cc = nil, -- force C compiler,   e.g. 'clang'
			cxx = nil, -- force C++ compiler, e.g. 'clang++'
			extra_inc_dirs = nil, -- nil = read from NIX_CFLAGS_COMPILE automatically
		},
	},

	-- ── GraalVM ───────────────────────────────────────────────────────────────
	graalvm = {
		extra_build_args = "",
		output_dir = "target/native",
		no_fallback = true,
		g1gc = false,
		pgo = "none", -- none | instrument | optimize
		report_size = true,
		agent_output_dir = "src/main/resources/META-INF/native-image",
	},
}

function M.setup(opts)
	return vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
