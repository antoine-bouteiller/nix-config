{
  config,
  lib,
  modulesPath,
  ...
}: let
  constants = import ./media/constants.nix;
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Hardware
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [
    "kvm-intel"
    "coretemp"
    "nct6775"
  ];
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
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems.${constants.paths.mediaDir} = {
    device = "/dev/disk/by-uuid/8059153a-838e-4bfd-82aa-5831c1f5047a";
    fsType = "ext4";
  };

  fileSystems."/mnt/backup" = {
    device = "/dev/disk/by-uuid/20af820e-357e-49fe-a62c-38b6039bffc5";
    fsType = "ext4";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4096;
      priority = 5;
    }
  ];

  boot.kernel.sysctl = {
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;

    # Smooth disk writeback on the single /mnt/media HDD so Transmission's
    # completion fsync() doesn't stall the daemon. Flush early and cap dirty
    # pages low → continuous writeback instead of one bursty flush at 100%.
    "vm.dirty_background_bytes" = 67108864; # 64 MiB
    "vm.dirty_bytes" = 268435456; # 256 MiB
  };
}
