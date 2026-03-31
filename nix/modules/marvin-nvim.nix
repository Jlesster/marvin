{ lib }:

with lib;
with lib.types;

let
  inherit (types) str bool int float listOf enum submodule;
in
{
  options.programs.marvin-nvim = {
    enable = mkEnableOption "marvin.nvim - multi-language development plugin for Neovim";

    package = mkOption {
      type = package;
      default = null;
      example = literalExpression "pkgs.vimUtils.buildVimPlugin { src = ./.;; }";
      description = "The marvin.nvim package to use. Set to null to use the package from the flake.";
    };

    ui-backend = mkOption {
      type = enum [ "auto" "snacks" "dressing" "builtin" ];
      default = "auto";
      description = "Which UI backend to use for dialogs and selections";
    };

    terminal = {
      position = mkOption {
        type = enum [ "float" "split" "vsplit" "background" ];
        default = "float";
        description = "Where to open the terminal";
      };

      size = mkOption {
        type = float;
        default = 0.4;
        description = "Size of the terminal (as fraction of screen for float, or rows for split)";
      };

      close-on-success = mkOption {
        type = bool;
        default = false;
        description = "Close terminal automatically when command succeeds";
      };
    };

    quickfix = {
      auto-open = mkOption {
        type = bool;
        default = true;
        description = "Automatically open quickfix list after build";
      };

      height = mkOption {
        type = int;
        default = 10;
        description = "Height of the quickfix window";
      };
    };

    keymaps = {
      dashboard = mkOption {
        type = str;
        default = "<leader>m";
        description = "Keymap to open the marvin dashboard";
      };

      jason = mkOption {
        type = str;
        default = "<leader>j";
        description = "Keymap prefix for Java commands";
      };

      jason-build = mkOption {
        type = str;
        default = "<leader>jc";
        description = "Keymap to build Java project";
      };

      jason-run = mkOption {
        type = str;
        default = "<leader>jr";
        description = "Keymap to run Java project";
      };

      jason-test = mkOption {
        type = str;
        default = "<leader>jt";
        description = "Keymap to run Java tests";
      };

      jason-clean = mkOption {
        type = str;
        default = "<leader>jx";
        description = "Keymap to clean Java build artifacts";
      };

      jason-console = mkOption {
        type = str;
        default = "<leader>jo";
        description = "Keymap to open Java debug console";
      };
    };

    java = {
      enable-javadoc = mkOption {
        type = bool;
        default = false;
        description = "Generate Javadoc comments for Java code";
      };

      maven-command = mkOption {
        type = str;
        default = "mvn";
        description = "Maven command to use";
      };

      build-tool = mkOption {
        type = enum [ "auto" "maven" "gradle" ];
        default = "auto";
        description = "Java build tool to use";
      };

      main-class-finder = mkOption {
        type = enum [ "auto" "maven" "gradle" ];
        default = "auto";
        description = "Method to find main class";
      };

      archetypes = mkOption {
        type = listOf str;
        default = [
          "maven-archetype-quickstart"
          "maven-archetype-webapp"
          "maven-archetype-simple"
          "jless-schema-archetype"
        ];
        description = "Maven archetypes available for project creation";
      };
    };

    rust = {
      profile = mkOption {
        type = enum [ "dev" "release" ];
        default = "dev";
        description = "Cargo profile to use";
      };
    };

    go = { };

    cpp = {
      build-tool = mkOption {
        type = enum [ "auto" "cmake" "make" "gcc" ];
        default = "auto";
        description = "C++ build tool to use";
      };

      compiler = mkOption {
        type = str;
        default = "g++";
        description = "C++ compiler to use";
      };

      standard = mkOption {
        type = enum [ "c++98" "c++11" "c++14" "c++17" "c++20" "c++23" ];
        default = "c++17";
        description = "C++ standard to use";
      };

      nix = {
        cc = mkOption {
          type = nullOr str;
          default = null;
          description = "Force C compiler (e.g. 'clang'). null = auto-detect";
        };

        cxx = mkOption {
          type = nullOr str;
          default = null;
          description = "Force C++ compiler (e.g. 'clang++'). null = auto-detect";
        };

        extra-inc-dirs = mkOption {
          type = nullOr (listOf str);
          default = null;
          description = "Extra include directories. null = read from NIX_CFLAGS_COMPILE";
        };
      };
    };

    graalvm = {
      extra-build-args = mkOption {
        type = str;
        default = "";
        description = "Extra arguments for native-image";
      };

      output-dir = mkOption {
        type = str;
        default = "target/native";
        description = "Output directory for native images";
      };

      no-fallback = mkOption {
        type = bool;
        default = true;
        description = "Fail if native image cannot be built without fallback";
      };

      g1gc = mkOption {
        type = bool;
        default = false;
        description = "Use G1 garbage collector";
      };

      pgo = mkOption {
        type = enum [ "none" "instrument" "optimize" ];
        default = "none";
        description = "Profile-Guided Optimization mode";
      };

      report-size = mkOption {
        type = bool;
        default = true;
        description = "Report size of generated native image";
      };

      agent-output-dir = mkOption {
        type = str;
        default = "src/main/resources/META-INF/native-image";
        description = "Directory for agent output";
      };
    };
  };

  config = mkEnableOption "" // { visible = false; };

  configModule = { config, ... }: {
    options = {
      programs.marvin-nvim.settings = mkOption {
        type = attrsOf anything;
        default = { };
        description = "Internal option for generated settings";
        visible = false;
      };
    };

    config = {
      programs.marvin-nvim.settings = {
        ui_backend = config.programs.marvin-nvim.ui-backend;
        terminal = {
          position = config.programs.marvin-nvim.terminal.position;
          size = config.programs.marvin-nvim.terminal.size;
          close_on_success = config.programs.marvin-nvim.terminal.close-on-success;
        };
        quickfix = {
          auto_open = config.programs.marvin-nvim.quickfix.auto-open;
          height = config.programs.marvin-nvim.quickfix.height;
        };
        keymaps = {
          dashboard = config.programs.marvin-nvim.keymaps.dashboard;
          jason = config.programs.marvin-nvim.keymaps.jason;
          jason_build = config.programs.marvin-nvim.keymaps.jason-build;
          jason_run = config.programs.marvin-nvim.keymaps.jason-run;
          jason_test = config.programs.marvin-nvim.keymaps.jason-test;
          jason_clean = config.programs.marvin-nvim.keymaps.jason-clean;
          jason_console = config.programs.marvin-nvim.keymaps.jason-console;
        };
        java = {
          enable_javadoc = config.programs.marvin-nvim.java.enable-javadoc;
          maven_command = config.programs.marvin-nvim.java.maven-command;
          build_tool = config.programs.marvin-nvim.java.build-tool;
          main_class_finder = config.programs.marvin-nvim.java.main-class-finder;
          archetypes = config.programs.marvin-nvim.java.archetypes;
        };
        rust = {
          profile = config.programs.marvin-nvim.rust.profile;
        };
        go = { };
        cpp = {
          build_tool = config.programs.marvin-nvim.cpp.build-tool;
          compiler = config.programs.marvin-nvim.cpp.compiler;
          standard = config.programs.marvin-nvim.cpp.standard;
          nix = {
            cc = config.programs.marvin-nvim.cpp.nix.cc;
            cxx = config.programs.marvin-nvim.cpp.nix.cxx;
            extra_inc_dirs = config.programs.marvin-nvim.cpp.nix.extra-inc-dirs;
          };
        };
        graalvm = {
          extra_build_args = config.programs.marvin-nvim.graalvm.extra-build-args;
          output_dir = config.programs.marvin-nvim.graalvm.output-dir;
          no_fallback = config.programs.marvin-nvim.graalvm.no-fallback;
          g1gc = config.programs.marvin-nvim.graalvm.g1gc;
          pgo = config.programs.marvin-nvim.graalvm.pgo;
          report_size = config.programs.marvin-nvim.graalvm.report-size;
          agent_output_dir = config.programs.marvin-nvim.graalvm.agent-output-dir;
        };
      };
    };
  };
}
