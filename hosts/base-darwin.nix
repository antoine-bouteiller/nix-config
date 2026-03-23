{...}: {
  imports = [
    ./base.nix
    ../modules/dock.nix
  ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
    global = {
      autoUpdate = true;
    };
    casks = [
      # Development Tools
      "orbstack"
      "beekeeper-studio"
      "yaak"
      "ghostty"

      # Productivity Tools
      "sol"

      # Browsers
      "zen"
      "brave-browser"

      # Utility Tools
      "unnaturalscrollwheels"
      "rectangle"
      "caffeine"

      # Entertainment Tools
      "spotify"
    ];
    greedyCasks = true;
    masApps = {};
  };
}
