{
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.local.home-manager.claudeCode;

  inherit (config.lib.file) mkOutOfStoreSymlink;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};

  claudeDir = "${osConfig.flakePath}/home-manager/applications/claude-code";

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

  topLevelFiles = [
    "CLAUDE.md"
    "settings.json"
    "hooks"
    "rules"
  ];
in {
  options.local.home-manager.claudeCode = {
    enable = lib.mkEnableOption "claude code";

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {};
      description = ''
        MCP servers attrset, forwarded to the shared `programs.mcp.servers`.
        Every agent CLI with enableMcpIntegration = true (claude-code today;
        codex/antigravity-cli later) picks these up.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.mcp = {
      enable = cfg.mcpServers != {};
      servers = cfg.mcpServers;
    };

    # Native HM module owns the package (wrapped with --plugin-dir for MCP),
    # the shared programs.mcp servers, and the pinned upstream skills.
    # Everything hand-edited (settings.json, hooks, rules, CLAUDE.md, local
    # skills) stays on mkOutOfStoreSymlink below: edit-and-go, no rebuild.
    programs.claude-code = {
      enable = true;
      package = customPkgs.claude-code;
      enableMcpIntegration = true;

      # External skills pinned as flake inputs, symlinked per-skill via
      # home.file so they coexist with the local skill symlinks below.
      skills = {
        agent-browser = "${inputs.agent-browser-skill}/skills/agent-browser";
        resolving-merge-conflicts = "${inputs.mattpocock-skills}/skills/engineering/resolving-merge-conflicts";
        grill-me = "${inputs.mattpocock-skills}/skills/productivity/grill-me";
        grilling = "${inputs.mattpocock-skills}/skills/productivity/grilling";
        writing-great-skills = "${inputs.mattpocock-skills}/skills/productivity/writing-great-skills";
        tdd = "${inputs.mattpocock-skills}/skills/productivity/tdd";
      };
    };

    home.packages = with pkgs; [
      # Utils
      customPkgs.comment-checker
      rtk
    ];

    home.file = builtins.listToAttrs (
      (map (name: {
          name = ".claude/${name}";
          value = {
            source = mkOutOfStoreSymlink "${claudeDir}/${name}";
          };
        })
        topLevelFiles)
      ++ (map (skill: {
          name = ".claude/skills/${skill.name}";
          value = {
            source = mkOutOfStoreSymlink "${claudeDir}/skills/${skill.path}";
          };
        })
        skills)
      ++ [
        {
          name = ".config/ccstatusline/settings.json";
          value = {
            source = mkOutOfStoreSymlink "${claudeDir}/ccstatusline.json";
          };
        }
      ]
    );
  };
}
