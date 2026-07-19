{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.gaming;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};

  # Pegasus reports Wayland app_id "org.pegasus-frontend." but ships a desktop
  # file named org.pegasus_frontend.Pegasus.desktop, so COSMIC can't match the
  # running window to its launcher and shows a generic taskbar icon. Declare the
  # real app_id as StartupWMClass so the compositor associates the two.
  pegasus-frontend = pkgs.pegasus-frontend.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        echo "StartupWMClass=org.pegasus-frontend." \
          >> $out/share/applications/org.pegasus_frontend.Pegasus.desktop
      '';
  });
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
      azahar
      melonDS
      customPkgs.neostation
    ];
  };
}
