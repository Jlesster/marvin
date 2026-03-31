{
  description = "marvin.nvim configuration using NixOS/nixvim module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    marvin-nvim.url = "github:jless/marvin.nvim";
  };

  outputs = { self, nixpkgs, nixvim, marvin-nvim }:
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        nixvim.nixosModules.nixvim

        marvin-nvim.homeManagerModules.marvin-nvim

        {
          environment.systemPackages = with nixpkgs.legacyPackages.x86_64-linux; [
            neovim
            gcc
            cmake
            maven
            rustc
            cargo
            go
            jdk
          ];

          programs.nixvim = {
            enable = true;
          };

          programs.marvin-nvim = {
            enable = true;
            ui-backend = "snacks";
            java = {
              build-tool = "maven";
              enable-javadoc = true;
            };
            cpp = {
              build-tool = "cmake";
              standard = "c++20";
            };
            rust.profile = "dev";
          };
        }
      ];
    };
}
