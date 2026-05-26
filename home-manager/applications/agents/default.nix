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
  syncAgentSettingsPython = pkgs.python3.withPackages (pythonPkgs: [
    pythonPkgs.tomli-w
  ]);

  syncAgentSettings = pkgs.writeText "sync-agent-settings.py" ''
    import json
    import os
    import shutil
    import sys
    import tempfile
    import tomllib

    import tomli_w


    def read_json(path):
        if not os.path.exists(path) or os.path.getsize(path) == 0:
            return {}
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)


    def write_json(path, value):
        atomic_write(path, json.dumps(value, indent=2, sort_keys=True) + "\n")


    def read_toml(path):
        if not os.path.exists(path) or os.path.getsize(path) == 0:
            return {}
        with open(path, "rb") as f:
            return tomllib.load(f)


    def write_toml(path, value):
        atomic_write(path, tomli_w.dumps(value, multiline_strings=True))


    def atomic_write(path, content):
        directory = os.path.dirname(path)
        fd, tmp_path = tempfile.mkstemp(prefix=".tmp-", dir=directory, text=True)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                f.write(content)
            os.replace(tmp_path, path)
        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)


    def get_path(value, path):
        current = value
        for key in path:
            if not isinstance(current, dict) or key not in current:
                return None
            current = current[key]
        return current


    def set_path(value, path, managed):
        current = value
        for key in path[:-1]:
            child = current.get(key)
            if not isinstance(child, dict):
                child = {}
                current[key] = child
            current = child
        current[path[-1]] = managed


    def delete_path(value, path):
        current = value
        parents = []
        for key in path[:-1]:
            if not isinstance(current, dict) or key not in current:
                return
            parents.append((current, key))
            current = current[key]
        if isinstance(current, dict):
            current.pop(path[-1], None)
        for parent, key in reversed(parents):
            child = parent.get(key)
            if isinstance(child, dict) and not child:
                parent.pop(key, None)
            else:
                break


    def encode_paths(paths):
        return [list(path) for path in sorted(paths)]


    def decode_paths(paths):
        return {tuple(path) for path in paths}


    def json_managed_paths(managed):
        return {(key,) for key in managed.keys()}


    def toml_managed_paths(managed):
        paths = set()
        for key, value in managed.items():
            if isinstance(value, dict):
                paths.update((key, child_key) for child_key in value.keys())
            else:
                paths.add((key,))
        return paths


    def replace_symlink(path):
        if os.path.islink(path):
            target = os.path.realpath(path)
            os.unlink(path)
            if os.path.exists(target):
                shutil.copyfile(target, path)


    def sync(kind, target_path, fragment_path, state_path):
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        os.makedirs(os.path.dirname(state_path), exist_ok=True)
        replace_symlink(target_path)

        if kind == "json":
            read_config = read_json
            write_config = write_json
            infer_paths = json_managed_paths
        elif kind == "toml":
            read_config = read_toml
            write_config = write_toml
            infer_paths = toml_managed_paths
        else:
            raise ValueError(f"Unsupported config kind: {kind}")

        config = read_config(target_path)
        managed = read_config(fragment_path)
        state = read_json(state_path)

        if not isinstance(config, dict):
            raise TypeError(f"{target_path} must contain a top-level object/table")
        if not isinstance(managed, dict):
            raise TypeError(f"{fragment_path} must contain a top-level object/table")

        previous_paths = decode_paths(state.get("managed_paths", []))
        current_paths = infer_paths(managed)

        for path in sorted(previous_paths - current_paths, key=len, reverse=True):
            if kind == "json" and path == ("$schema",):
                continue
            delete_path(config, path)

        for path in sorted(current_paths, key=len):
            set_path(config, path, get_path(managed, path))

        write_config(target_path, config)
        write_json(state_path, {"managed_paths": encode_paths(current_paths)})


    if __name__ == "__main__":
        sync(*sys.argv[1:])
  '';

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
        run ${syncAgentSettingsPython}/bin/python ${syncAgentSettings} json "$HOME/.claude/settings.json" ${claudeManagedJson} "$HOME/.local/state/home-manager/agents/claude-settings-managed-paths.json"
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
        run ${syncAgentSettingsPython}/bin/python ${syncAgentSettings} toml "$HOME/.codex/config.toml" ${codexManagedToml} "$HOME/.local/state/home-manager/agents/codex-config-managed-paths.json"
      '';

      home.file = codexFiles;
    })

    (lib.mkIf cfg.antigravity.enable {
      home.packages = [cfg.antigravity.package];
      home.file = antigravityFiles;
    })
  ];
}
