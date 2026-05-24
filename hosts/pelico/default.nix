{
  inputs,
  globals,
  config,
  pkgs,
  ...
}: let
  user = globals.user;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    ../base-darwin.nix
  ];

  flakePath = "${config.users.users.${user}.home}/.dotfiles";

  autoUpgrade = {
    enable = true;
    sshKeyPath = "${config.users.users.${user}.home}/.ssh/id_ed25519";
  };

  environment.variables = {
    NODE_OPTIONS = "--max-old-space-size=4096";
  };

  environment.systemPackages = with pkgs; [
    # tools
    customPkgs.vite-plus

    # CLI
    agent-browser
    customPkgs.sonarqube-cli
    gh
    glab
    envchain
  ];

  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  nix = {
    settings = {
      trusted-users = ["@admin" "${user}"];
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
    taps = [
      "homebrew/homebrew-core"
      "homebrew/homebrew-cask"
      "homebrew/homebrew-bundle"
    ];
    casks = [
      "tailscale-app"
      "cmux"
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs globals;
      hostUser = user;
    };
    users.${user} = import ./home.nix;
  };

  system = {
    checks.verifyNixPath = false;
    primaryUser = user;
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

        persistent-apps = [
          "/Applications/Slack.app/"
          "/Applications/Cmux.app/"
          "/Applications/Brave Browser.app/"
          "/Applications/Zed.app/"
          "/Applications/Telegram.app/"
        ];
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
