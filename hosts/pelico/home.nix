{
  globals,
  pkgs,
  config,
  inputs,
  ...
}: let
  inherit (config.home) homeDirectory;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
  mcpConfig = pkgs.writeText "mcp-servers.json" (
    builtins.toJSON {
      mcpServers.fff.command = "${customPkgs.fff-mcp}/bin/fff-mcp";
    }
  );
in {
  imports = [
    ../../home-manager
  ];

  local.home-manager = {
    zed.enable = true;
    gitHooks.enable = true;
    claudeCode = {
      enable = true;
      mcpConfigFile = mcpConfig;
    };
    tmux.enable = true;
    runenv = {
      enable = true;
      secretsDir = "${homeDirectory}/.dotfiles/hosts/pelico/secrets";
    };
  };

  home = {
    enableNixpkgsReleaseCheck = false;
    packages = [pkgs.dockutil];
    stateVersion = "25.11";
  };

  home.sessionPath = [
    "${homeDirectory}/.npm-packages/bin"
  ];
  home.sessionVariables = {
    NODE_PATH = "${homeDirectory}/.npm-packages/lib/node_modules";
  };

  programs.git = {
    settings.user.email = "antoine.bouteiller@pelico.io";
    includes = [
      {
        condition = "hasconfig:remote.*.url:git@github.com:*/**";
        path = "~/.gitconfig-github";
      }
      {
        condition = "hasconfig:remote.*.url:https://github.com/**";
        path = "~/.gitconfig-github";
      }
    ];
  };

  home.file.".gitconfig-github" = {
    text = ''
      [user]
        email = ${globals.email}
    '';
  };

  home.file.".npmrc".text = ''
    @pelico:registry=http://nexus.pelico.best/repository/npm/
    prefix=${homeDirectory}/.npm-packages
  '';

  manual.manpages.enable = false;
}
