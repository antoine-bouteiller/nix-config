{pkgs, ...}: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    package =
      if pkgs.stdenv.isDarwin
      then null
      else pkgs.ghostty;
    settings = {
      keybind = "shift+enter=text:\\x1b\\r";
      shell-integration-features = true;
    };
  };
}
