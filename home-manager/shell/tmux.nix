{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      sensible
      yank
      prefix-highlight
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-dir '$HOME/.cache/tmux/resurrect'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-pane-contents-area 'visible'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5' # minutes
        '';
      }
    ];
    terminal = "screen-256color";
    prefix = "C-x";
    escapeTime = 10;
    historyLimit = 50000;
    extraConfig = ''
      # Remove Vim mode delays
      set -g focus-events on

      # Enable full mouse support
      set -g mouse on

      # -----------------------------------------------------------------------------
      # Key bindings
      # -----------------------------------------------------------------------------

      # Unbind default keys
      unbind C-b
      unbind '"'
      unbind %

      # Split panes, vertical or horizontal
      bind-key x split-window -v
      bind-key v split-window -h

      # Move around panes with vim-like bindings (h,j,k,l)
      bind-key -n M-k select-pane -U
      bind-key -n M-h select-pane -L
      bind-key -n M-j select-pane -D
      bind-key -n M-l select-pane -R

      # Smart pane switching with awareness of Vim splits.
      # This is copy paste from https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l

      # -----------------------------------------------------------------------------
      # Theme
      # -----------------------------------------------------------------------------
      # Palette
      # background=#282A36  foreground=#F8F8F2  current_line=#44475A
      # primary=#1E1F29  green=#50FA7B  pink=#FF79C6  purple=#BD93F9
      # yellow=#F1FA8C  blue=#6272A4  red=#FF5555  orange=#FFB86C

      # General
      set -g status-position bottom
      set -g status-style "bg=#282A36"
      set -g status-left-length 50
      set -g status-right-length 100
      set -g status-justify left
      set -g window-status-separator ""

      # Pane borders
      set -g pane-border-style "fg=#44475A"
      set -g pane-active-border-style "fg=#BD93F9"

      # Messages
      set -g message-style "fg=#F8F8F2,bg=#44475A"
      set -g message-command-style "fg=#F8F8F2,bg=#44475A"

      # Status left: session pill (green)
      set -g status-left "#[fg=#50FA7B,bg=#282A36]#[fg=#1E1F29,bg=#50FA7B]  #[fg=#50FA7B,bg=#44475A]#[fg=#F8F8F2,bg=#44475A] #S #[fg=#44475A,bg=#282A36]"

      # Inactive window (muted single pill)
      set -g window-status-format "#[fg=#44475A,bg=#282A36]─#[fg=#F8F8F2,bg=#44475A] #I #[fg=#44475A,bg=#282A36]"

      # Active window (pink icon pill + box text pill)
      set -g window-status-current-format "#[fg=#44475A,bg=#282A36]─#[fg=#FF79C6,bg=#282A36]#[fg=#1E1F29,bg=#FF79C6] #I #[fg=#FF79C6,bg=#44475A]#[fg=#F8F8F2,bg=#44475A] #W #[fg=#44475A,bg=#282A36]"

      # Status right: time (purple) + user (yellow)
      set -g status-right "#[fg=#BD93F9,bg=#282A36]#[fg=#1E1F29,bg=#BD93F9] 󰦖 #[fg=#BD93F9,bg=#44475A]#[fg=#F8F8F2,bg=#44475A] %H:%M #[fg=#44475A,bg=#282A36]#[fg=#44475A,bg=#282A36]─#[fg=#F1FA8C,bg=#282A36]#[fg=#1E1F29,bg=#F1FA8C]  #[fg=#F1FA8C,bg=#44475A]#[fg=#F8F8F2,bg=#44475A] #h #[fg=#44475A,bg=#282A36] "
    '';
  };
}
