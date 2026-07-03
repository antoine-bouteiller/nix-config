{
  config,
  lib,
  pkgs,
  osConfig,
  inputs,
  ...
}: let
  cfg = config.local.home-manager.gitHooks;

  dotfilesDir = osConfig.flakePath;
  treefmt = inputs.self.formatter.${pkgs.stdenv.hostPlatform.system};

  preCommit = pkgs.writeShellScript "dotfiles-pre-commit" ''
    set -euo pipefail
    staged=$(git diff --cached --name-only --diff-filter=ACMR)
    [ -z "$staged" ] && exit 0

    # Block staged secrets before anything else.
    ${pkgs.gitleaks}/bin/gitleaks protect --staged --config "${dotfilesDir}/.gitleaks.toml"

    # Format staged files, then re-stage whatever treefmt touched.
    ${treefmt}/bin/treefmt --no-cache -- $staged
    for f in $staged; do
      [ -f "$f" ] && git add -- "$f"
    done
  '';
in {
  options.local.home-manager.gitHooks.enable =
    lib.mkEnableOption "dotfiles git pre-commit hook (gitleaks + treefmt)";

  config = lib.mkIf cfg.enable {
    home.activation.installDotfilesGitHooks = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -d "${dotfilesDir}/.git" ]; then
        run mkdir -p "${dotfilesDir}/.git/hooks"
        run ln -sf "${preCommit}" "${dotfilesDir}/.git/hooks/pre-commit"
      fi
    '';
  };
}
