{
  pkgs,
  config,
  lib,
  options,
  ...
}: let
  cfg = config.autoUpgrade;

  isDarwin = options ? launchd;

  updateFlakeScript = pkgs.writeShellScript "update-flake" ''
    cd "${cfg.flakePath}"
    ${pkgs.git}/bin/git pull --ff-only origin main
  '';
in {
  options.autoUpgrade = {
    enable = lib.mkEnableOption "automatic system upgrades";
    flakePath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the flake directory";
    };
    allowReboot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to allow automatic reboots after upgrade (NixOS only)";
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "Sun *-*-* 01:00:00";
      description = "Systemd calendar schedule for auto-upgrade (NixOS only)";
    };
  };

  config = lib.mkIf cfg.enable (
    if isDarwin
    then {
      launchd.daemons.nix-auto-upgrade = {
        script = ''
          export PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH
          ${updateFlakeScript}
          darwin-rebuild switch --flake .
        '';
        serviceConfig = {
          StartCalendarInterval = [
            {
              Weekday = 0;
              Hour = 3;
              Minute = 0;
            }
          ];
          StandardOutPath = "/tmp/nix-auto-upgrade.log";
          StandardErrorPath = "/tmp/nix-auto-upgrade.err";
        };
      };
    }
    else {
      systemd.services.flake-pull = {
        description = "Pull latest flake.lock from remote";
        stopIfChanged = false;
        restartIfChanged = false;

        wants = ["network-online.target"];
        after = ["network-online.target"];
        before = ["nixos-upgrade.service"];

        unitConfig = {
          StartLimitIntervalSec = 300;
          StartLimitBurst = 5;
        };

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${updateFlakeScript}";
          Restart = "on-failure";
          RestartSec = "30";
        };
      };

      system.autoUpgrade =
        {
          enable = true;
          dates = cfg.schedule;
          flake = cfg.flakePath;
          flags = ["-L"];
          allowReboot = cfg.allowReboot;
        }
        // lib.optionalAttrs cfg.allowReboot {
          rebootWindow = {
            lower = "01:00";
            upper = "03:00";
          };
        };

      systemd.services.nixos-upgrade = {
        after = ["flake-pull.service"];
        wants = ["flake-pull.service"];

        unitConfig = {
          StartLimitIntervalSec = 600;
          StartLimitBurst = 2;
        };

        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "120";
          MemoryMax = "2G";
          Nice = 19;
          IOSchedulingClass = "idle";
        };
      };
    }
  );
}
