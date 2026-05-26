{
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.local.home-manager.agents;

  inherit (config.lib.file) mkOutOfStoreSymlink;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};

  agentsDir = "${osConfig.flakePath}/home-manager/applications/agents";
  sharedDir = "${agentsDir}/shared";
  claudeDir = "${agentsDir}/claude-code";
  agentSettings = import ./settings.nix {
    claudePluginsDir = "${claudeDir}/plugins";
  };

  claudeManagedJson = pkgs.writeText "claude-managed-settings.json" (builtins.toJSON agentSettings.claude);
  codexManagedToml = (pkgs.formats.toml {}).generate "codex-managed-config.toml" agentSettings.codex;

  syncAgentSettings = pkgs.writers.writePython3Bin "sync-agent-settings" {
    libraries = [pkgs.python3Packages.tomli-w];
  } (builtins.readFile ./sync-agent-settings.py);

  findSkills = basePath: relPath: let
    fullPath = basePath + (lib.optionalString (relPath != "") "/${relPath}");
    entries = builtins.readDir fullPath;
    dirs = lib.filterAttrs (_: type: type == "directory") entries;
  in
    lib.concatLists (lib.mapAttrsToList (name: _: let
      subRelPath =
        if relPath == ""
        then name
        else "${relPath}/${name}";
      subEntries = builtins.readDir (basePath + "/${subRelPath}");
      hasSkillMd = subEntries ? "SKILL.md";
    in
      if hasSkillMd
      then [
        {
          name = lib.replaceStrings ["/"] [":"] subRelPath;
          path = subRelPath;
        }
      ]
      else findSkills basePath subRelPath)
    dirs);

  skills = findSkills ./shared/skills "";

  mcpJson = pkgs.writeText "agent-mcp.json" (builtins.toJSON {
    mcpServers = cfg.mcpServers;
  });

  antigravitySharedPlugin = pkgs.runCommandLocal "dotfiles-shared-agent-plugin" {} ''
    mkdir -p "$out/skills" "$out/rules"
    ln -s "${sharedDir}/skills"/* "$out/skills/"
    ln -s "${sharedDir}/rules"/* "$out/rules/"
    cp "${pkgs.writeText "plugin.json" (builtins.toJSON {name = "dotfiles-shared";})}" "$out/plugin.json"
    ${lib.optionalString (cfg.mcpServers != {}) ''
      cp "${mcpJson}" "$out/mcp_config.json"
    ''}
  '';

  sharedHookPackages = lib.optionals (cfg.claude-code.enable || cfg.codex.enable || cfg.antigravity.enable) [
    customPkgs.comment-checker
    pkgs.rtk
  ];

  claudeFiles =
    {
      ".claude/CLAUDE.md".source = mkOutOfStoreSymlink "${sharedDir}/AGENTS.md";
      ".claude/hooks".source = mkOutOfStoreSymlink "${sharedDir}/hooks";
      ".claude/rules".source = mkOutOfStoreSymlink "${sharedDir}/rules";
    }
    // builtins.listToAttrs (map (skill: {
        name = ".claude/skills/${skill.name}";
        value = {source = mkOutOfStoreSymlink "${sharedDir}/skills/${skill.path}";};
      })
      skills);

  codexFiles =
    {
      ".codex/AGENTS.md".source = mkOutOfStoreSymlink "${sharedDir}/AGENTS.md";
      ".codex/rules".source = mkOutOfStoreSymlink "${sharedDir}/rules";
      ".codex/hooks".source = mkOutOfStoreSymlink "${sharedDir}/hooks";
    }
    // builtins.listToAttrs (map (skill: {
        name = ".codex/skills/${skill.name}";
        value = {source = mkOutOfStoreSymlink "${sharedDir}/skills/${skill.path}";};
      })
      skills);

  antigravityFiles = {
    ".gemini/GEMINI.md".source = mkOutOfStoreSymlink "${sharedDir}/AGENTS.md";
    ".gemini/antigravity/skills".source = mkOutOfStoreSymlink "${sharedDir}/skills";
    ".gemini/config/plugins/dotfiles-shared".source = antigravitySharedPlugin;
  };
in {
  options.local.home-manager.agents = {
    mcpServers = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Shared MCP server declarations rendered to each enabled agent's native
        configuration format.
      '';
    };

    claude-code = {
      enable = lib.mkEnableOption "Claude Code";

      package = lib.mkOption {
        type = lib.types.package;
        default = customPkgs.claude-code;
        defaultText = "customPkgs.claude-code";
        description = "Claude Code package to install.";
      };
    };

    codex = {
      enable = lib.mkEnableOption "Codex";

      package = lib.mkOption {
        type = lib.types.package;
        default = customPkgs.codex;
        defaultText = "customPkgs.codex";
        description = "Codex package to install.";
      };
    };

    antigravity = {
      enable = lib.mkEnableOption "Antigravity";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.antigravity;
        defaultText = "pkgs.antigravity";
        description = "Antigravity package to install.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.claude-code.enable || cfg.codex.enable || cfg.antigravity.enable) {
      home.packages = sharedHookPackages;
    })

    (lib.mkIf (cfg.mcpServers != {}) {
      programs.mcp = {
        enable = true;
        servers = cfg.mcpServers;
      };
    })

    (lib.mkIf cfg.claude-code.enable {
      programs.claude-code = {
        enable = true;
        package = cfg.claude-code.package;
        enableMcpIntegration = cfg.mcpServers != {};
      };

      home.activation.cleanClaudeSkillsSymlink = lib.hm.dag.entryBefore ["writeBoundary"] ''
        if [ -L "$HOME/.claude/skills" ]; then
          run rm "$HOME/.claude/skills"
        fi
      '';

      home.activation.syncClaudeAgentSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${lib.getExe syncAgentSettings} json "$HOME/.claude/settings.json" ${claudeManagedJson} "$HOME/.local/state/home-manager/agents/claude-settings-managed-paths.json"
      '';

      home.file = claudeFiles;
    })

    (lib.mkIf cfg.codex.enable {
      programs.codex = {
        enable = true;
        package = cfg.codex.package;
        enableMcpIntegration = cfg.mcpServers != {};
      };

      home.activation.syncCodexAgentSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${lib.getExe syncAgentSettings} toml "$HOME/.codex/config.toml" ${codexManagedToml} "$HOME/.local/state/home-manager/agents/codex-config-managed-paths.json"
      '';

      home.file = codexFiles;
    })

    (lib.mkIf cfg.antigravity.enable {
      home.packages = [cfg.antigravity.package];
      home.file = antigravityFiles;
    })
  ];
}
