{
  config,
  pkgs,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  inherit (config.home) homeDirectory;
  claudeDir = "${homeDirectory}/.dotfiles/home-manager/applications/claude-code";
in {
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

    memory.source =
      config.lib.file.mkOutOfStoreSymlink
      "${claudeDir}/CLAUDE.md";
  };

  home.file = {
    ".claude/settings.json".source = mkOutOfStoreSymlink "${claudeDir}/settings.json";
    ".claude/RTK.md".source = mkOutOfStoreSymlink "${claudeDir}/RTK.md";
    ".claude/hooks".source = mkOutOfStoreSymlink "${claudeDir}/hooks";
  };
}
