{
  globals,
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.autoUpgrade;
  flakePath = cfg.flakePath;
in {
  options.autoUpgrade = {
    flakePath = lib.mkOption {
      type = lib.types.str;
      default = "/home/${globals.user}/.dotfiles/nixos-config";
      description = "Path to the flake directory";
    };
    allowReboot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to allow automatic reboots after upgrade";
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "Sun *-*-* 01:00:00";
      description = "Systemd calendar schedule for auto-upgrade";
    };
  };

  config = {
    # Separate flake-update service with retry logic
    systemd.services.flake-update = {
      stopIfChanged = false;
      restartIfChanged = false;

      unitConfig = {
        Description = "Update flake inputs";
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };

      serviceConfig = {
        WorkingDirectory = flakePath;

        ExecStart = pkgs.writeShellScript "flake-update-script" ''
          ${pkgs.nix}/bin/nix flake update

          if ! ${pkgs.git}/bin/git diff --exit-code flake.lock > /dev/null; then
              ${pkgs.git}/bin/git add flake.lock
              ${pkgs.git}/bin/git commit -m "chore(deps): auto-update flake.lock"
          fi
        '';
        Restart = "on-failure";
        RestartSec = "30";
        Type = "oneshot";

        Environment = [
          "GIT_AUTHOR_NAME='${globals.name}'"
          "GIT_AUTHOR_EMAIL=${globals.email}"
          "GIT_COMMITTER_NAME='${globals.name}'"
          "GIT_COMMITTER_EMAIL=${globals.email}"
        ];
      };

      before = ["nixos-upgrade.service"];
      path = [pkgs.nix pkgs.git pkgs.host];
    };

    system.autoUpgrade = {
      enable = true;
      dates = cfg.schedule;
      flake = flakePath;
      flags = ["-L"];
      allowReboot = cfg.allowReboot;
    } // lib.optionalAttrs cfg.allowReboot {
      rebootWindow = {
        lower = "01:00";
        upper = "03:00";
      };
    };

    systemd.services.nixos-upgrade = {
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "120";
      };
      unitConfig = {
        StartLimitIntervalSec = 600;
        StartLimitBurst = 2;
      };
      after = ["flake-update.service"];
      wants = ["flake-update.service"];
      path = [pkgs.host];
    };
  };
}
