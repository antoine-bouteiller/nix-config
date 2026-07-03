{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.local.home-manager.runenv;
in {
  options.local.home-manager.runenv = {
    enable = lib.mkEnableOption "runenv (per-command sops secret injection)";

    secretsDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory holding per-namespace sops-encrypted <ns>.yaml files.";
    };

    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      description = "Path to the age private key sops uses to decrypt.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.sops
      pkgs.age
    ];
    home.sessionVariables.SOPS_AGE_KEY_FILE = cfg.ageKeyFile;

    # runenv <namespace> <cmd> [args...] — decrypts secrets/<namespace>.yaml into the
    # environment of that one command (in memory), never the parent shell or disk.
    programs.zsh.initContent = lib.mkAfter ''
      runenv() {
        emulate -L zsh
        local ns="$1"; shift
        # ''${(@q)@} quotes each arg so spaces survive sops's single command string
        sops exec-env ${lib.escapeShellArg cfg.secretsDir}/"$ns".yaml "''${(j: :)''${(@q)@}}"
      }
    '';
  };
}
