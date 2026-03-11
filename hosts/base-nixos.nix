{pkgs, ...}: {
  imports = [./base.nix];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "fr";

  environment.systemPackages = with pkgs; [
    appimage-run
    home-manager
    fontconfig
    sqlite
    xdg-utils
  ];
}
