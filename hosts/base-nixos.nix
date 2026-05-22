{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./base.nix
    ../modules/desktop.nix
    ../modules/gaming.nix
  ];

  networking = {
    networkmanager = {
      enable = true;
      dns = "none";
    };
    hosts = {
      "192.168.1.254" = ["mabbox.bytel.fr"];
    };
    nftables.enable = true;
    firewall.enable = true;
  };

  environment.etc."resolv.conf".text = ''
    nameserver 1.1.1.1
    nameserver 9.9.9.9
  '';

  boot.loader = {
    systemd-boot = {
      enable = lib.mkDefault true;
      consoleMode = "max";
    };
    efi.canTouchEfiVariables = lib.mkDefault true;
  };

  services.xserver.xkb = {
    layout = "fr";
    variant = "azerty";
  };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "fr";

  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    home-manager
  ];
}
