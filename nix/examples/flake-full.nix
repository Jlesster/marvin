{
  description = "Complete marvin.nvim configuration example with all options";

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

              terminal = {
                position = "float";
                size = 0.5;
                close-on-success = false;
              };

              quickfix = {
                auto-open = true;
                height = 12;
              };

              keymaps = {
                dashboard = "<leader>m";
                jason = "<leader>j";
                jason-build = "<leader>jc";
                jason-run = "<leader>jr";
                jason-test = "<leader>jt";
                jason-clean = "<leader>jx";
                jason-console = "<leader>jo";
              };

              java = {
                enable-javadoc = true;
                maven-command = "mvn";
                build-tool = "maven";
                main-class-finder = "maven";
                archetypes = [
                  "maven-archetype-quickstart"
                  "maven-archetype-webapp"
                  "maven-archetype-simple"
                ];
              };

              rust = {
                profile = "dev";
              };

              cpp = {
                build-tool = "cmake";
                compiler = "g++";
                standard = "c++20";
                nix = {
                  cc = null;
                  cxx = null;
                  extra-inc-dirs = null;
                };
              };

              graalvm = {
                extra-build-args = "--initialize-at-build-time=org.example.Main";
                output-dir = "target/native";
                no-fallback = true;
                g1gc = false;
                pgo = "instrument";
                report-size = true;
                agent-output-dir = "src/main/resources/META-INF/native-image";
              };
            };
          }
        ];
      };
    };
}
