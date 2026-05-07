{
  globals,
  inputs,
  pkgs,
  ...
}: let
  user = globals.user;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    ../base-nixos.nix
    ./hardware-configuration.nix
  ];

  flakePath = "/home/${user}/nix-config";

  desktop.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  environment.systemPackages = with pkgs; [
    # Node.js development tools
    nodejs_24
    bun
    # customPkgs.vite-plus

    brave
    customPkgs.nearby-file-share

    plex-desktop
    telegram-desktop
  ];

  services.logind.settings.Login.HandleLidSwitch = "hybernate";

  environment.etc."brave/policies/managed/policies.json".text = builtins.toJSON {
    BraveRewardsDisabled = true;
    BraveWalletDisabled = true;
    BraveVPNDisabled = true;
    BraveAIChatEnabled = false;
    BraveNewsDisabled = true;
    BraveTalkDisabled = true;
    TorDisabled = true;
    DnsOverHttpsMode = "automatic";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs globals;
      hostUser = user;
    };
    users.${user} = import ./home.nix;
  };

  users.defaultUserShell = pkgs.zsh;
  users.users.${user} = {
    isNormalUser = true;
    description = globals.name;
    extraGroups = ["networkmanager" "wheel"];
  };

  system.stateVersion = "25.11";
}
