{
  pkgs,
  config,
  lib,
  options,
  ...
}: let
  cfg = config.autoUpgrade;
  flakePath = config.flakePath;

  isDarwin = options ? launchd;

  githubKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk="
  ];

  sshOpts = "-i ${cfg.sshKeyPath} -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o BatchMode=yes";

  updateFlakeScript = pkgs.writeShellApplication {
    name = "update-flake";
    runtimeInputs = [pkgs.git pkgs.openssh pkgs.coreutils];
    text = ''
      cd "${flakePath}"
      export GIT_SSH_COMMAND="ssh ${sshOpts}"
      owner=$(stat -c '%u:%g' "${flakePath}")
      trap 'chown -R "$owner" "${flakePath}"' EXIT
      git -c safe.directory="${flakePath}" pull --ff-only origin "${cfg.flakeBranch}"
    '';
  };

  darwinInterval =
    {
      Hour = cfg.schedule.hour;
      Minute = cfg.schedule.minute;
    }
    // lib.optionalAttrs (cfg.schedule.weekday != null) {
      Weekday = cfg.schedule.weekday;
    };

  systemdDays = ["Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun"];
  systemdDayStr =
    if cfg.schedule.weekday == null
    then ""
    else "${builtins.elemAt systemdDays (cfg.schedule.weekday - 1)} ";

  padZero = num:
    if num < 10
    then "0${toString num}"
    else toString num;
  systemdTimeStr = "${padZero cfg.schedule.hour}:${padZero cfg.schedule.minute}:00";

  systemdCalendar = "${systemdDayStr}*-*-* ${systemdTimeStr}";
in {
  options.autoUpgrade = {
    enable = lib.mkEnableOption "automatic system upgrades";
    flakeBranch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Branch to pull updates from";
    };
    sshKeyPath = lib.mkOption {
      type = lib.types.str;
      description = "SSH private key path used by root to pull the flake (must be readable by root and unencrypted)";
    };
    allowReboot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to allow automatic reboots after upgrade (NixOS only)";
    };
    schedule = {
      hour = lib.mkOption {
        type = lib.types.ints.between 0 23;
        default = 1;
        description = "Hour of the day to run the upgrade (0-23).";
      };
      minute = lib.mkOption {
        type = lib.types.ints.between 0 59;
        default = 0;
        description = "Minute of the hour to run the upgrade (0-59).";
      };
      weekday = lib.mkOption {
        type = lib.types.nullOr (lib.types.ints.between 1 7);
        default = 1;
        description = "Day of the week to run the upgrade (1=Monday, 7=Sunday). Leave null for every day.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    if isDarwin
    then {
      environment.etc."ssh/ssh_known_hosts".text = lib.concatStringsSep "\n" (map (key: "github.com ${key}") githubKeys);

      launchd.daemons.nix-auto-upgrade = {
        script = ''
          export PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH
          ${lib.getExe updateFlakeScript}
          darwin-rebuild switch --flake "${flakePath}#${config.networking.hostName}"
        '';
        serviceConfig = {
          StartCalendarInterval = [darwinInterval];
          StandardOutPath = "/tmp/nix-auto-upgrade.log";
          StandardErrorPath = "/tmp/nix-auto-upgrade.err";
          ProcessType = "Background";
        };
      };
    }
    else {
      programs.ssh.knownHosts = lib.listToAttrs (lib.imap0 (i: key:
        lib.nameValuePair "github-${toString i}" {
          hostNames = ["github.com"];
          publicKey = key;
        })
      githubKeys);

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
          ExecStart = "${lib.getExe updateFlakeScript}";
          Restart = "on-failure";
          RestartSec = "30";
        };
      };

      system.autoUpgrade =
        {
          enable = true;
          dates = systemdCalendar;
          flake = "${flakePath}#${config.networking.hostName}";
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
