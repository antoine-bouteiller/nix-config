{lib, ...}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
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
      palette = "catppuccin-mocha";
      add_newline = true;

      palettes.catppuccin-mocha = {
        foreground = "#cdd6f4";
        background = "#1e1e2e";
        current_line = "#45475a";
        primary = "#11111b";
        box = "#45475a";
        blue = "#89b4fa";
        cyan = "#89dceb";
        green = "#a6e3a1";
        orange = "#fab387";
        pink = "#f5c2e7";
        purple = "#cba6f7";
        red = "#f38ba8";
        yellow = "#f9e2af";
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
