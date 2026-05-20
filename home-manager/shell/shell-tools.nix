{pkgs, ...}: let
  zoxideInit = pkgs.runCommand "zoxide-init.zsh" {} ''
    ${pkgs.zoxide}/bin/zoxide init zsh --cmd cd > $out
  '';
  direnvInit = pkgs.runCommand "direnv-init.zsh" {} ''
    ${pkgs.direnv}/bin/direnv hook zsh > $out
  '';
  carapaceInit = pkgs.runCommand "carapace-init.zsh" {} ''
    ${pkgs.carapace}/bin/carapace _carapace zsh > $out
  '';
  miseInit = pkgs.runCommand "mise-init.zsh" {} ''
    ${pkgs.mise}/bin/mise activate zsh > $out
  '';
in {
  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = false;
      options = ["--cmd" "cd"];
    };

    carapace = {
      enable = true;
      enableZshIntegration = false;
    };

    direnv = {
      enable = true;
      enableZshIntegration = false;
    };

    mise = {
      enable = true;
      enableZshIntegration = false;
    };

    zsh.envExtra = ''
      export CARAPACE_BRIDGES='zsh,bash'
    '';

    zsh.initContent = ''
      if [[ -o interactive ]]; then
        source ${zoxideInit}
      fi
      source ${direnvInit}
      source ${carapaceInit}
      source ${miseInit}
    '';
  };
}
