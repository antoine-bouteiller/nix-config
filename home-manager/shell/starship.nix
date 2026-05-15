{
  pkgs,
  lib,
  ...
}: let
  starshipInit = pkgs.runCommand "starship-init.zsh" {} ''
    ${pkgs.starship}/bin/starship init zsh --print-full-init > $out
  '';
in {
  programs.zsh.initContent = ''
    if [[ $TERM != "dumb" ]]; then
      source ${starshipInit}
    fi
  '';

  programs.starship = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      format = lib.concatStrings [
        "[╭](fg:current_line)"
        "$os"
        "$directory"
        "$git_branch"
        "$git_status"
        "$fill"
        "$nodejs"
        "$dotnet"
        "$python"
        "$java"
        "$c"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];
      palette = "dracula";
      add_newline = true;

      palettes.dracula = {
        foreground = "#F8F8F2";
        background = "#282A36";
        current_line = "#44475A";
        primary = "#1E1F29";
        box = "#44475A";
        blue = "#6272A4";
        cyan = "#8BE9FD";
        green = "#50FA7B";
        orange = "#FFB86C";
        pink = "#FF79C6";
        purple = "#BD93F9";
        red = "#FF5555";
        yellow = "#F1FA8C";
      };

      os = {
        format = "(fg:current_line)[](fg:red)[$symbol ](fg:primary bg:red)[](fg:red)";
        disabled = false;
      };

      os.symbols = {
        Macos = "";
        NixOS = "";
      };

      directory = {
        format = "[─](fg:current_line)[](fg:pink)[󰷏 ](fg:primary bg:pink)[](fg:pink bg:box)[ $read_only$truncation_symbol$path](fg:foreground bg:box)[](fg:box)";
        home_symbol = " ~/";
        truncation_symbol = " ";
        truncation_length = 2;
        read_only = "󱧵 ";
        read_only_style = "";
      };

      git_branch = {
        format = "[─](fg:current_line)[](fg:green)[$symbol](fg:primary bg:green)[](fg:green bg:box)[ $branch](fg:foreground bg:box)";
        symbol = " ";
      };

      git_status = {
        format = "[$all_status$ahead_behind](fg:green bg:box)[](fg:box)";
        conflicted = " =";
        up_to_date = "";
        untracked = " ?\${count}";
        stashed = " ≡\${count}";
        modified = " !\${count}";
        staged = " +";
        renamed = " »";
        deleted = " ✘";
        ahead = " ⇡\${count}";
        diverged = " ⇡\${ahead_count}⇣\${behind_count}";
        behind = " ⇣\${count}";
      };

      nodejs = {
        format = "[─](fg:current_line)[](fg:green)[$symbol](fg:primary bg:green)[](fg:green bg:box)[ $version](fg:foreground bg:box)[](fg:box)";
        symbol = "󰎙 Node.js";
      };

      dotnet = {
        format = "[─](fg:current_line)[](fg:purple)[$symbol](fg:primary bg:purple)[](fg:purple bg:box)[ $tfm](fg:foreground bg:box)[](fg:box)";
        symbol = " .NET";
      };

      python = {
        format = "[─](fg:current_line)[](fg:green)[$symbol](fg:primary bg:green)[](fg:green bg:box)[ $version $virtualenv](fg:foreground bg:box)[](fg:box)";
        symbol = " python";
      };

      java = {
        format = "[─](fg:current_line)[](fg:red)[$symbol](fg:primary bg:red)[](fg:red bg:box)[ $version](fg:foreground bg:box)[](fg:box)";
        symbol = " Java";
      };

      c = {
        format = "[─](fg:current_line)[](fg:blue)[$symbol](fg:primary bg:blue)[](fg:blue bg:box)[ $version](fg:foreground bg:box)[](fg:box)";
        symbol = " C";
      };

      fill = {
        symbol = "─";
        style = "fg:current_line";
      };

      cmd_duration = {
        min_time = 500;
        format = "[─](fg:current_line)[](fg:orange)[](fg:primary bg:orange)[](fg:orange bg:box)[ $duration ](fg:foreground bg:box)[](fg:box)";
      };

      shell = {
        format = "[─](fg:current_line)[](fg:blue)[ ](fg:primary bg:blue)[](fg:blue bg:box)[ $indicator](fg:foreground bg:box)[](fg:box)";
        unknown_indicator = "shell";
        powershell_indicator = "powershell";
        fish_indicator = "fish";
        disabled = false;
      };

      time = {
        format = "[─](fg:current_line)[](fg:purple)[󰦖 ](fg:primary bg:purple)[](fg:purple bg:box)[ $time](fg:foreground bg:box)[](fg:box)";
        time_format = "%H:%M";
        disabled = false;
      };

      username = {
        format = "[─](fg:current_line)[](fg:yellow)[](fg:primary bg:yellow)[](fg:yellow bg:box)[ $user](fg:foreground bg:box)[](fg:box) ";
        show_always = true;
      };

      character = {
        format = lib.concatStrings [
          ""
          "[╰─$symbol](fg:current_line) "
        ];
        success_symbol = "[](fg:bold white)";
        error_symbol = "[×](fg:bold red)";
      };
    };
  };
}
