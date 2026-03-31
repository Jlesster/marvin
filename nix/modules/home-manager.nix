{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.marvin-nvim;
in
{
  options.programs.marvin-nvim = import ../modules/marvin-nvim.nix { inherit lib; } // {
    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "The marvin.nvim package to use";
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."nvim/lua/marvin-config.lua" = {
      text = builtins.toJSON cfg.settings;
    };
  };
}
