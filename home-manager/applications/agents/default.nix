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

  findSkills = relPath: let
    fullPath = ./skills + (lib.optionalString (relPath != "") "/${relPath}");
    entries = builtins.readDir fullPath;
    dirs = lib.filterAttrs (_: type: type == "directory") entries;
  in
    lib.concatLists (
      lib.mapAttrsToList (
        name: _: let
          subRelPath =
            if relPath == ""
            then name
            else "${relPath}/${name}";
          subEntries = builtins.readDir (./skills + "/${subRelPath}");
          hasSkillMd = subEntries ? "SKILL.md";
        in
          if hasSkillMd
          then [
            {
              name = lib.replaceStrings ["/"] [":"] subRelPath;
              path = subRelPath;
            }
          ]
          else findSkills subRelPath
      )
      dirs
    );

  skills = findSkills "";

  # External skills pinned as flake inputs, symlinked into every agent's
  # skills dir so they stay available even without claude-code.
  externalSkills = {
    agent-browser = "${inputs.agent-browser-skill}/skills/agent-browser";
    resolving-merge-conflicts = "${inputs.mattpocock-skills}/skills/engineering/resolving-merge-conflicts";
    grill-me = "${inputs.mattpocock-skills}/skills/productivity/grill-me";
    grilling = "${inputs.mattpocock-skills}/skills/productivity/grilling";
    writing-great-skills = "${inputs.mattpocock-skills}/skills/productivity/writing-great-skills";
    tdd = "${inputs.mattpocock-skills}/skills/productivity/tdd";
    improve = "${inputs.shadcn-improve-skills}/skills/improve";
  };

  # skill name -> home.file entries for a given target dir (".agents" / ".claude")
  skillFiles = dir:
    builtins.listToAttrs (
      (map (skill: {
          name = "${dir}/skills/${skill.name}";
          value.source = mkOutOfStoreSymlink "${agentsDir}/skills/${skill.path}";
        })
        skills)
      ++ lib.mapAttrsToList (name: path: {
        name = "${dir}/skills/${name}";
        value.source = path;
      })
      externalSkills
    );

  claudeTopLevelFiles = [
    "CLAUDE.md"
    "settings.json"
    "hooks"
    "agents"
  ];

  piTopLevelFiles = [
    "extensions"
    "settings.json"
  ];
in {
  options.local.home-manager.agents = {
    enable = lib.mkEnableOption "agent CLIs";

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {};
      description = ''
        MCP servers attrset, forwarded to the shared `programs.mcp.servers`.
        Every agent CLI with enableMcpIntegration = true (claude-code today;
        codex/antigravity-cli later) picks these up.
      '';
    };

    claude-code.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Deploy claude-code with its config and ~/.claude/skills.";
    };

    pi.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Deploy pi's settings.json and hand-vendored extensions (edit-and-go symlinks).";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Always: shared MCP servers, util packages, skills into ~/.agents
    {
      programs.mcp = {
        enable = cfg.mcpServers != {};
        servers = cfg.mcpServers;
      };

      home.packages = with pkgs; [
        # Utils
        customPkgs.comment-checker
        rtk
      ];

      home.file = skillFiles ".agents";
    }

    # Claude-specific: native HM module owns the package (wrapped with
    # --plugin-dir for MCP). Everything hand-edited (settings.json, hooks,
    # CLAUDE.md, local skills) stays on mkOutOfStoreSymlink: edit-and-go,
    # no rebuild.
    (lib.mkIf cfg.claude-code.enable {
      programs.claude-code = {
        enable = true;
        package = customPkgs.claude-code;
        enableMcpIntegration = true;
      };

      home.file =
        skillFiles ".claude"
        // builtins.listToAttrs (map (name: {
            name = ".claude/${name}";
            value.source = mkOutOfStoreSymlink "${agentsDir}/claude-code/${name}";
          })
          claudeTopLevelFiles)
        // {
          ".config/ccstatusline/settings.json".source =
            mkOutOfStoreSymlink "${agentsDir}/claude-code/ccstatusline.json";
        };
    })

    # Pi: bun-installed binary (not nix); we only own settings + vendored
    # extensions via edit-and-go symlinks. ponytail: skip nix packaging, add
    # when pi ships a nixpkgs derivation.
    (lib.mkIf cfg.pi.enable {
      home.file = builtins.listToAttrs (map (name: {
          name = ".pi/agent/${name}";
          value.source = mkOutOfStoreSymlink "${agentsDir}/pi/${name}";
        })
        piTopLevelFiles);
    })
  ]);
}
