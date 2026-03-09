{
  globals,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./dock
  ];

  users.users.${globals.user} = {
    name = globals.user;
    home = "/Users/${globals.user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [];
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
    casks = pkgs.callPackage ./casks.nix {};
    masApps = {};
  };

  home-manager = {
    useGlobalPkgs = true;
    users.${globals.user} = {
      pkgs,
      config,
      ...
    }: {
      imports = [
        ../shared/home-manager.nix
      ];

      home = {
        enableNixpkgsReleaseCheck = false;
        packages = pkgs.callPackage ./packages.nix {};
        file = import ../shared/files.nix {inherit config;};
        stateVersion = "23.11";
      };

      manual.manpages.enable = false;
    };
  };

  # Shared dock configuration for all Macs
  local.dock = {
    enable = true;
    username = globals.user;
    entries = [
      {path = "/Applications/Slack.app/";}
      {path = "/Applications/Ghostty.app/";}
      {path = "/Applications/Zen.app/";}
      {path = "/Applications/Zed.app/";}
      {path = "/Applications/Telegram.app/";}
    ];
  };
}
