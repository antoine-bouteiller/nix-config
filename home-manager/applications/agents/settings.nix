{claudePluginsDir}: let
  allowedBashCommands = [
    "git add *"
    "git branch *"
    "git diff *"
    "git init *"
    "git log *"
    "git show *"
    "git status *"
    "cat *"
    "du *"
    "find *"
    "grep *"
    "head *"
    "launchctl list *"
    "ls *"
    "sort *"
    "tree *"
    "unzip *"
    "wc *"
    "xxd *"
    "xargs *"
    "nix build *"
    "nix develop *"
    "nix eval *"
    "nix flake *"
    "nix path-info *"
    "nix-prefetch-github *"
    "nix-prefetch-url *"
    "nix-build *"
    "brew info *"
    "brew search *"
    "lsof *"
    "open *"
    "pbcopy"
    "ps *"
    "pnpm *"
    "bun *"
    "bunx *"
    "vp *"
    "npx *"
    "uv *"
  ];

  allowedFileAccess = [
    "Read(//nix/store/**)"
    "Read(//tmp/**)"
    "Write(//tmp/**)"
    "Edit(//tmp/**)"
  ];

  allowedWebTools = [
    "WebFetch"
    "WebSearch"
  ];

  commandHook = command: {
    type = "command";
    inherit command;
  };

  allowedBashInstructions = ''
    Allowed bash command patterns:
    ${builtins.concatStringsSep "\n" (map (command: "- ${command}") allowedBashCommands)}
  '';
in {
  shared = {
    inherit allowedBashCommands allowedFileAccess allowedWebTools;
  };

  claude = {
    permissions = {
      allow = map (command: "Bash(${command})") allowedBashCommands ++ allowedFileAccess ++ allowedWebTools;
      defaultMode = "auto";
      additionalDirectories = ["~/.claude"];
    };

    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            (commandHook "~/.claude/hooks/rtk-rewrite.sh")
          ];
        }
      ];
      Notification = [
        {
          hooks = [
            (commandHook "~/.claude/hooks/notify-ghostty.sh")
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
      "typescript-lsp@claude-plugins-official" = true;
      "sonarqube@claude-plugins-official" = true;
      "jdtls-lsp@claude-plugins-official" = true;
      "pua-unicode@dotfiles-plugins" = true;
    };

    extraKnownMarketplaces = {
      dotfiles-plugins = {
        source = {
          source = "directory";
          path = toString claudePluginsDir;
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
    skipAutoPermissionPrompt = true;

    skillOverrides = {
      claude-api = "off";
      review = "off";
      simplify = "off";
    };
  };

  codex = {
    model = "gpt-5.5";
    model_provider = "azure";
    model_reasoning_effort = "medium";

    developer_instructions = allowedBashInstructions;

    model_providers.azure = {
      name = "pelico/azure";
      base_url = "https://pelico-openai-poc.openai.azure.com/openai";
      env_key = "AZURE_OPENAI_API_KEY";
      query_params = {
        api-version = "2025-04-01-preview";
      };
      wire_api = "responses";
    };

    notice.model_migrations = {
      "gpt-5.2-codex" = "gpt-5.4";
      "gpt-5.3-codex" = "gpt-5.4";
    };

    tui.model_availability_nux = {
      "gpt-5.5" = 4;
    };
  };
}
