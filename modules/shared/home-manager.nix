{ ... }: {
  imports = [
    ./programs/zsh.nix
    ./programs/git.nix
    ./programs/vim.nix
    ./programs/tmux.nix
    ./programs/ssh.nix
    ./programs/ghostty.nix
    ./programs/starship.nix
    ./programs/shell-tools.nix
  ];
}
