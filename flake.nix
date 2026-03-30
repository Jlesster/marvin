{
  description = "marvin.nvim — project manager + task runner for Neovim";

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
      in
      {
        # The plugin itself as a derivation — what nixvim consumes
        packages.default = pkgs.vimUtils.buildVimPlugin {
          pname = "marvin-nvim";
          version = "0.1.0";
          src = ./.;
          meta = {
            description = "Maven / multi-language project manager for Neovim";
            homepage = "https://github.com/yourusername/marvin.nvim";
            license = pkgs.lib.licenses.mit;
          };
        };

        # Dev shell with all the tools marvin.lua expects on PATH
        devShells.default = pkgs.mkShell {
          name = "marvin-dev";
          buildInputs = with pkgs; [
            # Editors / Neovim itself for testing
            neovim

            # Java / Maven
            jdk21
            maven

            # Rust
            rustup

            # Go
            go

            # C / C++
            gcc
            clang
            cmake
            gnumake
            pkg-config
            bear # compile_commands.json generation

            # Wayland (for wayland_protocols.lua)
            wayland
            wayland-protocols
            wlroots
            wayland-scanner

            # Useful extras marvin can call
            golangci-lint
            cargo-audit
            cargo-outdated
          ];

          # Expose NIX_STORE so marvin.nix.is_nix() detects the environment
          NIX_STORE = builtins.storeDir;

          shellHook = ''
            echo "marvin.nvim dev shell"
            echo "Neovim: $(nvim --version | head -1)"
          '';
        };
      }
    );
}
