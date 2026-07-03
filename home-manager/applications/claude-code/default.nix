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

  claudePackage = customPkgs.claude-code.override {
    inherit (cfg) mcpConfigFile;
  };
in {
  imports = [inputs.agent-skills.homeManagerModules.default];

  options.local.home-manager.claudeCode = {
    enable = lib.mkEnableOption "claude code";

    package = claudePackage;

    mcpConfigFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to an MCP servers JSON config file. When set, the wrapped
        `claude` binary is invoked with `--mcp-config <path>` on every call.
        The custom package also disables Claude Code's auto-installer so
        it cannot shadow this binary from `~/.local/bin`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      claudePackage
      # Utils
      customPkgs.comment-checker
      rtk
      ast-grep # binary used by the pinned ast-grep skill
    ];

    # External skills pinned as flake inputs, deployed via agent-skills-nix.
    # Local skills stay on mkOutOfStoreSymlink below (edit-and-go, no rebuild);
    # structure = "link" uses home.file so the store bundle coexists with them
    # instead of rsync --delete wiping the local skill symlinks.
    programs.agent-skills = {
      enable = true;
      sources = {
        ast-grep = {
          path = inputs.ast-grep-skill;
          subdir = "ast-grep/skills";
        };
        agent-browser = {
          path = inputs.agent-browser-skill;
          subdir = "skills";
        };
      };
      skills.enableAll = ["ast-grep" "agent-browser"];
      targets.claude = {
        enable = true;
        structure = "link";
      };
    };

    home.activation.cleanClaudeSkillsSymlink = lib.hm.dag.entryBefore ["writeBoundary"] ''
      if [ -L "$HOME/.claude/skills" ]; then
        run rm "$HOME/.claude/skills"
      fi
    '';

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
            source = ./ccstatusline.json;
          };
        }
      ]
    );
  };
}
