{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: let
  cfg = config.local.home-manager.oneMcp;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
  inherit (config.home) homeDirectory;
  inherit (pkgs.stdenv) isDarwin;
in {
  options.local.home-manager.oneMcp = {
    enable = lib.mkEnableOption "1mcp MCP proxy server";

    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the 1mcp JSON configuration file.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf isDarwin {
      launchd.agents."1mcp" = {
        enable = true;
        config = {
          Label = "fr.antoinebouteiller.1mcp";
          ProgramArguments = ["${customPkgs._1mcp}/bin/1mcp" "--enable-auth" "--config" cfg.configFile];
          EnvironmentVariables = {
            PATH = lib.makeBinPath [pkgs.nodejs_24 pkgs.coreutils pkgs.bash];
          };
          RunAtLoad = true;
          StandardOutPath = "${homeDirectory}/Library/Logs/1mcp.log";
          StandardErrorPath = "${homeDirectory}/Library/Logs/1mcp.error.log";
        };
      };
    })
  ]);
}
