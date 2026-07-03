{
  config,
  globals,
  inputs,
  pkgs,
  ...
}: let
  user = "antoineb";
in {
  imports = [
    ../base-nixos.nix
    ./media
    ./hardware-configuration.nix
  ];

  flakePath = "${config.users.users.${user}.home}/nixconfig";

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Home manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs globals;
      hostUser = user;
    };
    users.${user} = import ./home.nix;
  };

  # Auto upgrade
  autoUpgrade = {
    enable = true;
    sshKeyPath = "${config.users.users.${user}.home}/.ssh/id_ed25519";
  };

  # Nix
  nix.gc = {
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  environment.systemPackages = with pkgs; [
    lm_sensors
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
  users.users.${user} = {
    isNormalUser = true;
    description = globals.name;
    extraGroups = [
      "networkmanager"
      "wheel"
      "media"
    ];
    openssh.authorizedKeys.keys = globals.sshKeys;
  };
  users.groups.media = {};

  # Journald
  services.journald.extraConfig = ''
    MaxRetentionSec=1week
    MaxFileSec=1day
  '';

  # Early OOM killer — prefers killing Nix rebuild processes over media services
  services.earlyoom = {
    enable = true;
    extraArgs = [
      "--prefer"
      "^(nix|nix-daemon|nix-build|nixos-rebuild|home-manager)$"
      "--avoid"
      "^(sshd|systemd|init|postgres|pgbouncer|plex|immich-.*)$"
    ];
  };

  systemd.services.nix-daemon.serviceConfig.MemoryMax = "2G";
}
