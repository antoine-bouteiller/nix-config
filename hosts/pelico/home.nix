{
  globals,
  pkgs,
  config,
  ...
}: let
  inherit (config.home) homeDirectory;
in {
  imports = [
    ../../home-manager
  ];

  local.home-manager = {
    zed.enable = true;
    agents = {
      claude-code.enable = true;
      codex.enable = true;
    };
    tmux.enable = true;
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
