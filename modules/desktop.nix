{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.desktop;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  options.desktop = {
    enable = lib.mkEnableOption "COSMIC Desktop";
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.cosmic-greeter.enable = true;
    services.desktopManager.cosmic.enable = true;

    environment.sessionVariables.NIXOS_OZONE_WL = 1;
    environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

    services.system76-scheduler.enable = true;

    environment.systemPackages = [
      customPkgs.whitesur-icon-theme
    ];

    environment.cosmic.excludePackages = with pkgs; [
      cosmic-edit
      cosmic-term
      cosmic-player
    ];

    fonts.packages = [
      pkgs.nerd-fonts.jetbrains-mono
    ];
  };
}
