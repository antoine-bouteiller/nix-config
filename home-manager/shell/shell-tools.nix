{...}: {
  programs = {
    zoxide = {
      enable = true;
      options = ["--cmd" "cd"];
    };

    carapace = {
      enable = true;
      enableZshIntegration = true;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh.initContent = ''
      if [[ -o interactive ]]; then
        eval "$(zoxide init zsh --cmd cd)"
      fi
    '';
  };
}
