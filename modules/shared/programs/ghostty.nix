{ ... }: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    package = null; # Installed via Homebrew cask on macOS
    settings = {
      keybind = "shift+enter=text:\\x1b\\r";
      shell-integration-features = true;
    };
  };
}
