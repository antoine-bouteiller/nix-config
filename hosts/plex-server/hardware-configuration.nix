{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  cfg = config.mediaServer;
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Hardware
  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel" "coretemp" "nct6775"];
  boot.extraModulePackages = [];
  boot.kernelParams = ["reboot=pci"];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Filesystems
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/e2766e63-46f5-4ddd-8bd6-36572d615226";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/18D5-EF75";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  fileSystems.${cfg.paths.mediaDir} = {
    device = "/dev/disk/by-uuid/8059153a-838e-4bfd-82aa-5831c1f5047a";
    fsType = "ext4";
  };

  fileSystems."/mnt/backup" = {
    device = "/dev/disk/by-uuid/20af820e-357e-49fe-a62c-38b6039bffc5";
    fsType = "ext4";
  };

  swapDevices = [];

  # Backup disk spindown
  systemd.services.backup-disk-spindown = {
    description = "Set spindown timeout for backup disk";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.hdparm}/bin/hdparm -S 180 /dev/disk/by-uuid/20af820e-357e-49fe-a62c-38b6039bffc5";
    };
  };

  # Networking
  networking = {
    hostName = "plex-server";
    nameservers = ["1.1.1.1" "9.9.9.9"];
    hosts = {
      "192.168.1.254" = ["mabbox.bytel.fr"];
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        80 # HTTP (Caddy)
        443 # HTTPS (Caddy)
      ];
    };
  };

  boot.kernel.sysctl = {
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
  };
}
