{pkgs, ...}: {
  imports = [
    ./base.nix
    ../modules/desktop.nix
  ];

  networking = {
    networkmanager = {
      enable = true;
      dns = "none";
    };
    hosts = {
      "192.168.1.254" = ["mabbox.bytel.fr"];
    };
  };

  environment.etc."resolv.conf".text = ''
    nameserver 1.1.1.1
    nameserver 9.9.9.9
  '';

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.xserver.xkb = {
    layout = "fr";
    variant = "azerty";
  };

  programs.zsh.enable = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "fr";

  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    home-manager
  ];
}
