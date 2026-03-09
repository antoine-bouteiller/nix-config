{pkgs}:
with pkgs; [
  # General packages for development and system management
  bash-completion
  bat
  btop
  coreutils
  killall
  openssh
  wget
  zip

  # Encryption and security tools
  gnupg

  # Cloud-related tools and SDKs
  docker
  docker-compose

  dejavu_fonts
  fd
  font-awesome
  hack-font
  noto-fonts
  noto-fonts-color-emoji
  meslo-lgs-nf

  # Node.js development tools
  mise

  # Text and terminal utilities
  htop
  jetbrains-mono
  jq
  ripgrep
  tree
  tmux
  unzip
  eza

  # Shell tools
  zoxide
  carapace
  direnv
  fzf

  # Development tools
  curl
  gh
  lazygit
  alejandra
  nixd
  comment-checker
]
