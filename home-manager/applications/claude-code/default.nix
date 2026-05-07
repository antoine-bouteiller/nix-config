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
    lib.concatLists (lib.mapAttrsToList (name: _: let
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
      else findSkills subRelPath)
    dirs);

  skills = findSkills "";

  topLevelFiles = ["CLAUDE.md" "settings.json" "hooks"];
in {
  options.local.home-manager.claudeCode = {
    enable = lib.mkEnableOption "claude code";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.claude-code

      # Utils
      customPkgs.comment-checker
      customPkgs.rtk
    ];

    home.activation.cleanClaudeSkillsSymlink = lib.hm.dag.entryBefore ["writeBoundary"] ''
      if [ -L "$HOME/.claude/skills" ]; then
        run rm "$HOME/.claude/skills"
      fi
    '';

    home.file = builtins.listToAttrs (
      (map (name: {
          name = ".claude/${name}";
          value = {source = mkOutOfStoreSymlink "${claudeDir}/${name}";};
        })
        topLevelFiles)
      ++ (map (skill: {
          name = ".claude/skills/${skill.name}";
          value = {source = mkOutOfStoreSymlink "${claudeDir}/skills/${skill.path}";};
        })
        skills)
    );
  };
}
