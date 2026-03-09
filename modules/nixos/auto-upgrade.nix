{
  globals,
  pkgs,
  ...
}: let
  flakePath = "/home/${globals.user}/.dotfiles/nixos-config";
in {
  # Auto flake update + rebuild (weekly)
  system.autoUpgrade = {
    enable = true;
    flake = flakePath;
    dates = "weekly";
    allowReboot = false;
    operation = "switch";
  };

  # Update flake inputs before the auto-upgrade
  systemd.services.nixos-upgrade.preStart = ''
    cd ${flakePath}
    ${pkgs.nix}/bin/nix flake update --commit-lock-file
  '';
}
