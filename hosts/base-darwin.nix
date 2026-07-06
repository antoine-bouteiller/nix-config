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

  # Both the system manual and the uninstaller's embedded system eval build
  # darwin-manual-html, which fails on current nixpkgs (nixos-render-docs
  # dropped --toc-depth; nix-darwin master not yet fixed). Re-enable once
  # nix-darwin passes --sidebar-depth. Uninstaller stays available via
  # `nix run nix-darwin#darwin-uninstaller`.
  documentation.doc.enable = false;
  system.tools.darwin-uninstaller.enable = false;

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
