{...}: {
  imports = [
    ./base.nix
  ];

  system.defaults.CustomUserPreferences = {
    "com.brave.Browser" = {
      BraveRewardsDisabled = true;
      BraveWalletDisabled = true;
      BraveVPNDisabled = true;
      BraveAIChatEnabled = false;
      BraveNewsDisabled = true;
      BraveTalkDisabled = true;
      TorDisabled = true;
      DnsOverHttpsMode = "automatic";
    };
  };

  homebrew = {
    enable = true;
    enableZshIntegration = false;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
    global = {
      autoUpdate = true;
    };

    brews = [
      "coreutils"
    ];

    casks = [
      # Development Tools
      "orbstack"
      "beekeeper-studio"
      "yaak"
      "ghostty"
      "zed"

      # Productivity Tools
      "sol"

      # Browsers
      "brave-browser"
      "helium-browser"

      # Utility Tools
      "unnaturalscrollwheels"
      "caffeine"
      "rectangle"

      "spotify"
    ];
    greedyCasks = true;
    masApps = {
      "runcat" = 1429033973;
    };
  };
}
