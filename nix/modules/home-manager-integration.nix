{ marvin-nvim, lib }:

{ config, ... }:

let
  cfg = config.programs.marvin-nvim;
  moduleLib = import ../modules/marvin-nvim.nix { inherit lib; };

  settingsModule = lib.evalModules {
    modules = [
      (import ../modules/marvin-nvim.nix { inherit lib; }).configModule
      {
        _moduleArgs = { inherit config; };
      }
      {
        programs.marvin-nvim = {
          enable = cfg.enable;
          ui-backend = cfg.ui-backend;
          terminal = cfg.terminal;
          quickfix = cfg.quickfix;
          keymaps = cfg.keymaps;
          java = cfg.java;
          rust = cfg.rust;
          go = cfg.go;
          cpp = cfg.cpp;
          graalvm = cfg.graalvm;
        };
      }
    ];
  };
in
{
  options = {
    programs.marvin-nvim = lib.mkOption {
      type = lib.types.submodule (import ../modules/marvin-nvim.nix { inherit lib; }).options.programs.marvin-nvim;
    };
  };

  config = {
    programs.marvin-nvim = lib.mkIf cfg.enable {
      settings = {
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
        rust = { profile = cfg.rust.profile; };
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
