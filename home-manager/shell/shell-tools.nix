{...}: {
  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
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
  };
}
