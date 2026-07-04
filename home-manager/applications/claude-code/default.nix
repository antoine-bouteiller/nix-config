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
        mattpocock = {
          path = inputs.mattpocock-skills;
          subdir = "skills";
        };
        vercel = {
          path = inputs.vercel-agent-skills;
          subdir = "skills";
        };
      };
      skills = {
        enableAll = ["ast-grep" "agent-browser"];
        # Pin specific upstream skills, renaming to our engineering: convention.
        explicit = {
          "tdd" = {
            from = "mattpocock";
            path = "engineering/tdd";
          };
          "domain-modeling" = {
            from = "mattpocock";
            path = "engineering/domain-modeling";
          };
          "codebase-design" = {
            from = "mattpocock";
            path = "engineering/codebase-design";
          };
          "resolving-merge-conflicts" = {
            from = "mattpocock";
            path = "engineering/resolving-merge-conflicts";
          };
          "improve-codebase-architecture" = {
            from = "mattpocock";
            path = "engineering/improve-codebase-architecture";
          };
          "grill-me" = {
            from = "mattpocock";
            path = "productivity/grill-me";
          };
          "grilling" = {
            from = "mattpocock";
            path = "productivity/grilling";
          };
          "vercel-react-best-practices" = {
            from = "vercel";
            path = "react-best-practices";
          };
          "web-design-guidelines" = {
            from = "vercel";
            path = "web-design-guidelines";
          };
        };
      };
      targets.claude = {
        enable = true;
        structure = "link";
      };
    };

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
