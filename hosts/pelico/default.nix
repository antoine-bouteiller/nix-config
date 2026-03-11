{
  inputs,
  globals,
  config,
  pkgs,
  ...
}: {
  imports = [
    ../base-darwin.nix
    ../../modules/auto-upgrade-darwin.nix
  ];

  nix-homebrew = {
    inherit (globals) user;
    enable = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
    };
    mutableTaps = false;
    autoMigrate = false;
  };

  users.users.${globals.user} = {
    name = globals.user;
    home = "/Users/${globals.user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  nix = {
    settings = {
      trusted-users = ["@admin" "${globals.user}"];
    };

    gc = {
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
    };
  };

  homebrew = {
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = [
      "tailscale-app"
      "codex"
      "slack"
      "zed"
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {inherit globals;};
    users.${globals.user} = import ./home.nix;
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

  system = {
    checks.verifyNixPath = false;
    primaryUser = globals.user;
    stateVersion = 5;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        KeyRepeat = 2;
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = true;
        show-recents = true;
        launchanim = true;
        orientation = "bottom";
        tilesize = 56;
      };

      finder = {
        _FXShowPosixPathInTitle = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = false;
      };
    };
  };
}
