{
  pkgs,
  lib,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
      path = "$HOME/.zsh_history";
    };

    oh-my-zsh = {
      enable = true;
      plugins =
        [
          "git"
          "sudo"
          "dirhistory"
          "colorize"
          "extract"
        ]
        ++ lib.optionals pkgs.stdenv.isDarwin ["brew"];
    };

    shellAliases = {
      "_" = "sudo";
      l = "ls";
      cat = "bat";
      g = "git";
      vi = "vim";
      ll = "ls -lh";
      la = "ls -lAh";
      ldot = "ls -ld .*";
      gclean = "git fetch -p && for branch in $(git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | awk '$2 == \"[gone]\" {sub(\"refs/heads/\", \"\", $1); print $1}'); do git branch -D $branch; done";
      quit = "exit";
      "cd.." = "cd ..";
      tarls = "tar -tvf";
      untar = "tar -xf";
      bua = "bup && bcup --greedy && bcn";
      please = "sudo";
      zshrc = "\${EDITOR:-vim} $HOME/.zshrc";
      zdot = "cd $HOME/.dotfiles";
    };

    envExtra = ''
      export XDG_CONFIG_HOME=''${XDG_CONFIG_HOME:-$HOME/.config}
      export XDG_DATA_HOME=''${XDG_DATA_HOME:-$HOME/.local/share}
      export XDG_CACHE_HOME=''${XDG_CACHE_HOME:-$HOME/.cache}
      export DOTDIR=''${DOTDIR:-$HOME/.dotfiles}
      export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
      typeset -gU path fpath
    '';

    profileExtra = ''
      # OrbStack integration
      [[ -f ~/.orbstack/shell/init.zsh ]] && source ~/.orbstack/shell/init.zsh 2>/dev/null || :
    '';

    initContent = ''
      # PATH setup
      export path=(
        $HOME/{,s}bin(N)
        $HOME/.local/{,s}bin(N)
        /opt/{homebrew,local}/{,s}bin(N)
        /usr/local/{,s}bin(N)
        $path
      )

      # Emacs keybindings
      bindkey -e

      # Completion styles
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'

      export PATH="''${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

      # Source local/work config
      [[ -f $HOME/.zlocal ]] && source $HOME/.zlocal
    '';
  };
}
