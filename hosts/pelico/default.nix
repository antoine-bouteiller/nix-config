{
  inputs,
  globals,
  config,
  pkgs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    ../base-darwin.nix
  ];

  autoUpgrade = {
    enable = true;
    flakePath = "${config.users.users.${globals.user}.home}/.dotfiles";
  };

  environment.variables = {
    NODE_OPTIONS = "--max-old-space-size=4096";
  };

  environment.systemPackages = with pkgs; [
    # Node.js development tools
    nodejs_24
    bun
    pnpm
    customPkgs.vite-plus

    # Java
    jdk25_headless

    # Python
    (python313.withPackages (ps:
      with ps; [
        python-gitlab
      ]))
    uv

    # Agents
    customPkgs.comment-checker
    customPkgs.rtk
    customPkgs._1mcp
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
      "t3-code"
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = {inherit inputs globals;};
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
