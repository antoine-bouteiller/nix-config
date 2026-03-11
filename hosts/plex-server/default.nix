{
  globals,
  pkgs,
  ...
}: let
  user = "antoineb";
in {
  imports = [
    ../base-nixos.nix
    ../../modules/auto-upgrade-nixos.nix
    ../../modules/media
    ./hardware-configuration.nix
  ];

  # Media server
  mediaServer = {
    network.domain = "antoinebouteiller.fr";
    paths.mediaDir = "/mnt/media";
  };

  # Home manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit globals;
      hostUser = user;
    };
    users.${user} = import ./home.nix;
  };

  # Auto upgrade
  autoUpgrade = {
    flakePath = "/etc/nixos";
    allowReboot = true;
    schedule = "Sun *-*-* 01:00:00";
  };

  # Nix
  nix.gc = {
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    lm_sensors
    ffmpeg
  ];

  system.stateVersion = "25.11";

  # Security
  security.polkit.enable = true;

  environment.etc."sysconfig/lm_sensors".text = ''
    HWMON_MODULES="coretemp nct6775"
  '';

  # Secrets
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };

  # Users
  users.defaultUserShell = pkgs.zsh;
  users.users.${user} = {
    isNormalUser = true;
    description = "Antoine Bouteiller";
    extraGroups = ["networkmanager" "wheel" "media"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICUZ+rb5WpsUv/4wVWlQ0aCRiNzZCIQngxXiNAJx6hJs antob@DESKTOP-ANTOINE"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHhSmVRhMXbxDkDOaUk0udibjBos2nDg6byvZ//dzMwL antob@DESKTOP-3R8RBJU"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIfK4sKI0QpEbaADjQm/7bK3DlNY/akOh+6yC+q3aG17 antoine.bouteiller@pelico.io"
    ];
  };
  users.groups.media = {};

  # SSH
  services.openssh = {
    ports = [22];
    settings.PermitRootLogin = "no";
  };

  # Journald
  services.journald.extraConfig = ''
    MaxRetentionSec=1week
  '';
}
