{ lib }:

with lib;

let
  module = import ./marvin-nvim.nix { inherit lib; };
  cfg = config.programs.marvin-nvim;
in
{
  options.programs.marvin-nvim = module.options.programs.marvin-nvim // {
    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "The marvin.nvim package to use";
    };
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      plugins.marvin-nvim = {
        enable = true;
      };
    };

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."nvim/lua/marvin-config.lua" = {
      text = builtins.toJSON {
        ui_backend = cfg.ui-backend;
        terminal = {
          position = cfg.terminal.position;
          size = cfg.terminal.size;
          close_on_success = cfg.terminal.close-on-success;
        };
        quickfix = {
          auto_open = cfg.quickfix.auto-open;
          height = cfg.quickfix.height;
        };
        keymaps = {
          dashboard = cfg.keymaps.dashboard;
          jason = cfg.keymaps.jason;
          jason_build = cfg.keymaps.jason-build;
          jason_run = cfg.keymaps.jason-run;
          jason_test = cfg.keymaps.jason-test;
          jason_clean = cfg.keymaps.jason-clean;
          jason_console = cfg.keymaps.jason-console;
        };
        java = {
          enable_javadoc = cfg.java.enable-javadoc;
          maven_command = cfg.java.maven-command;
          build_tool = cfg.java.build-tool;
          main_class_finder = cfg.java.main-class-finder;
          archetypes = cfg.java.archetypes;
        };
        rust = {
          profile = cfg.rust.profile;
        };
        go = { };
        cpp = {
          build_tool = cfg.cpp.build-tool;
          compiler = cfg.cpp.compiler;
          standard = cfg.cpp.standard;
          nix = {
            cc = cfg.cpp.nix.cc;
            cxx = cfg.cpp.nix.cxx;
            extra_inc_dirs = cfg.cpp.nix.extra-inc-dirs;
          };
        };
        graalvm = {
          extra_build_args = cfg.graalvm.extra-build-args;
          output_dir = cfg.graalvm.output-dir;
          no_fallback = cfg.graalvm.no-fallback;
          g1gc = cfg.graalvm.g1gc;
          pgo = cfg.graalvm.pgo;
          report_size = cfg.graalvm.report-size;
          agent_output_dir = cfg.graalvm.agent-output-dir;
        };
      };
    };
  };
}
