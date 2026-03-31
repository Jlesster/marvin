{
  description = "Minimal marvin.nvim configuration example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    marvin-nvim.url = "github:jless/marvin.nvim";
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, marvin-nvim }:
    let
      inherit (nixpkgs.lib) genAttrs;
    in
    {
      homeConfigurations."jless@${flake-utils.lib.system}" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          marvin-nvim.homeManagerModules.marvin-nvim

          {
            programs.neovim = {
              enable = true;
              plugins = [ marvin-nvim.packages.x86_64-linux.default ];
            };

            programs.marvin-nvim = {
              enable = true;
              ui-backend = "snacks";
              java.build-tool = "maven";
              rust.profile = "dev";
            };
          }
        ];
      };
    };
}
