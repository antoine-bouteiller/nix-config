{...}: {
  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = ["--cmd" "cd"];
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    mise = {
      enable = true;
      enableZshIntegration = true;
    };

    carapace = {
      enable = true;
      enableZshIntegration = true;
    };

    vite-plus.enable = true;
  };
}
