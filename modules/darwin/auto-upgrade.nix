{globals, ...}: {
  # Auto flake update + rebuild (weekly, Sunday 3am — like NixOS system.autoUpgrade)
  launchd.daemons.nix-auto-upgrade = {
    script = ''
      export PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH
      cd /Users/${globals.user}/.dotfiles/nixos-config
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
