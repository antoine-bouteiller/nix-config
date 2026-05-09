{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.gaming;
in {
  options.gaming = {
    enable = lib.mkEnableOption "Steam, Heroic and gaming utilities";
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;
      extraCompatPackages = [pkgs.proton-ge-bin];
      # HiDPI workaround: 3840x2400 panel at 200% COSMIC scale renders Steam's
      # CEF bootstrap UI off-center and crops it. Force Steam's own 2x scaling.
      package = pkgs.steam.override {
        extraEnv = {
          STEAM_FORCE_DESKTOPUI_SCALING = "2";
        };
      };
    };

    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };

    programs.gamemode.enable = true;

    environment.systemPackages = with pkgs; [
      protonup-qt
      heroic
      mangohud
    ];
  };
}
