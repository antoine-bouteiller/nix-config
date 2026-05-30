{
  osConfig,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    history = {
      size = 10000;
      share = true;
    };

    plugins = [
      {
        name = "powerlevel10k-config";
        src = ./p10k-config;
        file = "p10k.zsh";
      }
      {
        name = "zsh-powerlevel10k";
        src = "${pkgs.zsh-powerlevel10k}/share/zsh/themes/powerlevel10k/";
        file = "powerlevel10k.zsh-theme";
      }
    ];

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
      zdot = "cd ${osConfig.flakePath}";
    };

    envExtra = ''
      export XDG_CONFIG_HOME=''${XDG_CONFIG_HOME:-$HOME/.config}
      export XDG_DATA_HOME=''${XDG_DATA_HOME:-$HOME/.local/share}
      export XDG_CACHE_HOME=''${XDG_CACHE_HOME:-$HOME/.cache}
      typeset -gU path fpath
    '';

    profileExtra = ''
      # OrbStack integration
      [[ -f ~/.orbstack/shell/init.zsh ]] && source ~/.orbstack/shell/init.zsh 2>/dev/null || :
    '';

    initExtraFirst = ''
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      # Initialization code that may require console input (password prompts, [y/n]
      # confirmations, etc.) must go above this block; everything else may go below.
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
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


      # History substring key binding
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      bindkey '^[OA' history-substring-search-up
      bindkey '^[OB' history-substring-search-down

      # Completion styles
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'

      # Source local/work config
      [[ -f ${osConfig.flakePath}/.zlocal ]] && source ${osConfig.flakePath}/.zlocal

    '';
  };
}
