{pkgs}:
with pkgs; let
  shared-packages = import ../shared/packages.nix {inherit pkgs;};
in
  shared-packages
  ++ [
    # App and package management
    appimage-run
    home-manager

    # Media and design tools
    fontconfig

    # File and system utilities
    sqlite
    xdg-utils

    # Wayland utilities
    wl-clipboard # Clipboard (replaces xclip)
    wlr-randr # Display config (replaces xrandr)
    grim # Screenshot tool
    slurp # Region selection for screenshots
    wofi # Application launcher (replaces rofi)
    swaylock # Screen locker
    mako # Notification daemon

    # Development tools
    ghostty
    zed-editor

    # Music and entertainment
    spotify
    vlc
  ]
