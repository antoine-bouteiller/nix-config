{
  globals,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/darwin/auto-upgrade.nix
    ../../modules/shared
  ];

  nix = {
    package = pkgs.lixPackageSets.stable.lix;

    settings = {
      trusted-users = ["@admin" "${globals.user}"];
      substituters = ["https://nix-community.cachix.org" "https://cache.nixos.org"];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Host-specific homebrew casks
  homebrew.casks = pkgs.callPackage ./casks.nix {};

  # Host-specific git email override
  home-manager.users.${globals.user} = {
    programs.git = {
      settings.user.email = "antoine.bouteiller@pelico.io";
      includes = [
        {
          condition = "hasconfig:remote.*.url:git@github.com:*/**";
          path = "~/.gitconfig-github";
        }
        {
          condition = "hasconfig:remote.*.url:https://github.com/**";
          path = "~/.gitconfig-github";
        }
      ];
    };

    home.file.".gitconfig-github" = {
      text = ''
        [user]
          email = ${globals.email}
      '';
    };
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
