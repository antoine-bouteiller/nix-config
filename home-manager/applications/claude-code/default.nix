{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
  inherit (config.lib.file) mkOutOfStoreSymlink;
  inherit (config.home) homeDirectory;
  inherit (pkgs.stdenv) isDarwin;
  claudeDir = "${homeDirectory}/.dotfiles/home-manager/applications/claude-code";
  mcpPort = "3050";
in
  lib.mkMerge [
    {
      programs.claude-code = {
        enable = true;
        package = pkgs.claude-code;

        memory.source =
          config.lib.file.mkOutOfStoreSymlink
          "${claudeDir}/CLAUDE.md";

        mcpServers = {
          "1mcp" = {
            type = "http";
            url = "http://127.0.0.1:${mcpPort}/mcp?app=claude-code";
          };
        };
      };

      home.file = {
        ".claude/settings.json".source = mkOutOfStoreSymlink "${claudeDir}/settings.json";
        ".claude/RTK.md".source = mkOutOfStoreSymlink "${claudeDir}/RTK.md";
        ".claude/hooks".source = mkOutOfStoreSymlink "${claudeDir}/hooks";
      };
    }
    (lib.mkIf isDarwin {
      # 1MCP LaunchAgent - keeps the aggregator running when secrets are available
      # Uses PathState to only run when 1Password has mounted the secrets file
      launchd.agents."1mcp" = {
        enable = true;
        config = {
          Label = "fr.antoinebouteiller.1mcp";
          ProgramArguments = ["${customPkgs._1mcp}/bin/1mcp" "--enable-auth"];
          EnvironmentVariables = {
            PATH = lib.makeBinPath [pkgs.nodejs_24 pkgs.coreutils pkgs.bash];
          };
          RunAtLoad = true;
          StandardOutPath = "${homeDirectory}/Library/Logs/1mcp.log";
          StandardErrorPath = "${homeDirectory}/Library/Logs/1mcp.error.log";
        };
      };
    })
  ]
