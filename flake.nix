{
  description = "marvin.nvim - A feature-rich Neovim plugin for multi-language development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , home-manager
    }:
    let
      nixpkgs-lib = nixpkgs.lib;
      inherit (nixpkgs-lib) genAttrs;
    in
    {
      lib = nixpkgs-lib;

      packages = genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          marvin-nvim = pkgs.vimUtils.buildVimPlugin {
            pname = "marvin-nvim";
            version = "0.1.0";
            src = ./.;
          };

          default = self.packages.${system}.marvin-nvim;
        }
      );

      devShells = genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "marvin-nvim-dev";

            packages = with pkgs; [
              neovim-unwrapped

              lua-language-server
              stylua

              cmake
              gcc
              gdb
              make
              maven
              gradle
              rustc
              cargo
              go
              jdk
              graalvm-ce

              ripgrep
              fd
              fzf
              nil
            ];

            shellHook = ''
              export NVIM_APPNAME=marvin-nvim-dev
              echo "marvin.nvim development environment"
              echo "Neovim config: $NVIM_APPNAME"
            '';
          };
        }
      );

      overlays = {
        default = final: prev: {
          marvin-nvim = prev.marvin-nvim.overrideAttrs (oldAttrs: { });
        };

        addDeps = final: prev: {
          marvin-nvim = prev.marvin-nvim.overrideAttrs (oldAttrs: {
            postInstall = (oldAttrs.postInstall or "") + ''
              mkdir -p $out/parser
            '';
          });
        };
      };

      homeManagerModules.marvin-nvim = import ./nix/modules/marvin-nvim.nix { lib = nixpkgs-lib; };

      marvin-nvim-module = genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (system: {
        options = import ./nix/modules/marvin-nvim.nix { lib = nixpkgs-lib; };
      });
    };
}
