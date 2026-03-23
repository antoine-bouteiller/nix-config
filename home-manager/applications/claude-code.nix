{
  config,
  pkgs,
  lib,
  ...
}: let
  claudeConfig = ../../config/claude;
in {
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

    settings = {
      permissions = {
        allow = lib.concatStrings [
          "Bash(git add *)"
          "Bash(git branch *)"
          "Bash(git diff *)"
          "Bash(git init *)"
          "Bash(git log *)"
          "Bash(git show *)"
          "Bash(git status *)"
          "Bash(cat *)"
          "Bash(du *)"
          "Bash(find *)"
          "Bash(grep *)"
          "Bash(head *)"
          "Bash(launchctl list *)"
          "Bash(ls *)"
          "Bash(sort *)"
          "Bash(tree *)"
          "Bash(unzip *)"
          "Bash(wc *)"
          "Bash(xxd *)"
          "Bash(nix build *)"
          "Bash(nix develop *)"
          "Bash(nix eval *)"
          "Bash(nix flake *)"
          "Bash(nix path-info *)"
          "Bash(nix-prefetch-github *)"
          "Bash(nix-prefetch-url *)"
          "Bash(nix-build *)"
          "Bash(brew info *)"
          "Bash(brew search *)"
          "Bash(lsof *)"
          "Bash(open *)"
          "Bash(pbcopy)"
          "Bash(ps *)"
          "Bash(pnpm *)"
          "Bash(bun *)"
          "Bash(bunx *)"
          "Bash(vp *)"
          "Bash(npx *)"
          "Bash(uv *)"
          "Read(//nix/store/**)"
          "Read(//tmp/**)"
          "Write(//tmp/**)"
          "Edit(//tmp/**)"
        ];
        additionalDirectories = [
          "~/.claude"
        ];
      };
      hooks = {
        PostToolUse = [
          {
            matcher = "Write|Edit|MultiEdit";
            hooks = [
              {
                type = "command";
                command = "comment-checker";
              }
            ];
          }
        ];
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "~/.claude/hooks/rtk-rewrite.sh";
              }
            ];
          }
        ];
        Notification = [
          {
            hooks = [
              {
                type = "command";
                command = "~/.claude/hooks/notify-ghostty.sh";
              }
            ];
          }
        ];
      };
      statusLine = {
        type = "command";
        command = "bunx -y ccstatusline@latest";
        padding = 0;
      };
      enabledPlugins = {
        "claude-mem@thedotmack" = true;
        "pyright-lsp@claude-plugins-official" = true;
        "pua-unicode@dotfiles-plugins" = true;
      };
      extraKnownMarketplaces = {
        dotfiles-plugins = {
          source = {
            source = "directory";
            path = "${claudeConfig}/plugins";
          };
        };
        thedotmack = {
          source = {
            source = "github";
            repo = "thedotmack/claude-mem";
          };
        };
      };
      skipDangerousModePermissionPrompt = true;
    };

    memory.source =
      config.lib.file.mkOutOfStoreSymlink
      "${claudeConfig}/CLAUDE.md";
  };

  home.file.".claude/RTK.md".source =
    config.lib.file.mkOutOfStoreSymlink
    "${claudeConfig}/RTK.md";
}
