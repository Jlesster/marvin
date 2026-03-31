{
  description = "marvin.nvim — project manager and build tool plugin for Neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # The plugin itself — installed into neovim's runtimepath
        marvin-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "marvin-nvim";
          version = "0.1.0";
          src = ./.;
        };

      in
      {
        # ── packages ──────────────────────────────────────────────────────────
        packages.default = marvin-nvim;

        # ── devShell ──────────────────────────────────────────────────────────
        # `nix develop` drops you into a shell where:
        #   • gcc/g++/clang are the NixOS cc-wrappers (NIX_CFLAGS_COMPILE is set)
        #   • pkg-config finds headers from buildInputs
        #   • make, cmake, meson, cargo, go, mvn are all on PATH
        #   • marvin.nix.is_nix() returns true
        #   • marvin.nix.system_inc_dirs() returns the correct /nix/store paths
        devShells.default = pkgs.mkShell {
          name = "marvin-dev";

          # ── build tools ───────────────────────────────────────────────────
          nativeBuildInputs = with pkgs; [
            # Compilers / wrappers  (cc-wrapper sets NIX_CFLAGS_COMPILE)
            gcc
            clang
            # Build systems
            gnumake
            cmake
            meson
            ninja
            pkg-config
            # Language toolchains
            rustup # cargo / rustc via rustup (sets CARGO_HOME)
            go
            # JVM (for Maven users)
            jdk21
            maven
            # Helpers used by marvin internals
            bear # compile_commands.json wrapper
            python3 # compile_commands rewriter script
            curl # wayland protocol XML downloads
            git
          ];

          # ── C/C++ example libraries so pkg-config tests work ──────────────
          buildInputs = with pkgs; [
            openssl
            curl
            sqlite
            zlib
          ];

          # ── env ───────────────────────────────────────────────────────────
          # Tell marvin.nix explicitly we're in a Nix shell so is_nix()
          # is true even on non-NixOS hosts (e.g. nix-darwin, Ubuntu + nix).
          shellHook = ''
            export IN_NIX_SHELL=1

            # Convenience: print what marvin will see
            echo "marvin devShell ready"
            echo "  CC  = $(which cc)"
            echo "  CXX = $(which c++)"
            echo "  PKG_CONFIG_PATH = $PKG_CONFIG_PATH"
            echo "  NIX_CFLAGS_COMPILE (first 120 chars): ''${NIX_CFLAGS_COMPILE:0:120}…"
          '';
        };

        # ── checks ────────────────────────────────────────────────────────────
        # Run with `nix flake check`
        checks.plugin-files = pkgs.runCommand "marvin-check-files" { } ''
          set -e
          ls ${self}/lua/marvin/init.lua    >/dev/null
          ls ${self}/lua/marvin/nix.lua     >/dev/null
          ls ${self}/plugin/marvin.vim      >/dev/null
          touch $out
        '';
      }
    );
}
