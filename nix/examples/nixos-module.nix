{
  description = "marvin.nvim as standalone NixOS module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    marvin-nvim.url = "github:jless/marvin.nvim";
  };

  outputs = { self, nixpkgs, home-manager, marvin-nvim }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      nixosModules.marvin-nvim = import ../modules/marvin-nvim.nix {
        lib = nixpkgs.lib;
      };

      nixosConfigurations.myConfig = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jless = {
              imports = [
                (import ../modules/home-manager-integration.nix {
                  inherit marvin-nvim;
                  lib = nixpkgs.lib;
                })
              ];

              programs.home-manager.enable = true;

              programs.neovim = {
                enable = true;
                plugins = [ marvin-nvim.packages.x86_64-linux.default ];
              };

              programs.marvin-nvim = {
                enable = true;
                ui-backend = "snacks";
              };
            };
          }
        ];
      };
    };
}
