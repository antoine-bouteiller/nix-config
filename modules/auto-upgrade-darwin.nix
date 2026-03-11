{globals, ...}: let
  flakePath = "/Users/${globals.user}/.dotfiles/nixos-config";
in {
  launchd.daemons.nix-auto-upgrade = {
    script = ''
      export PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH
      cd ${flakePath}
      nix flake update --commit-lock-file
      darwin-rebuild switch --flake .
    '';
    serviceConfig = {
      StartCalendarInterval = [{
        Weekday = 0;
        Hour = 3;
        Minute = 0;
      }];
      StandardOutPath = "/tmp/nix-auto-upgrade.log";
      StandardErrorPath = "/tmp/nix-auto-upgrade.err";
    };
  };
}
