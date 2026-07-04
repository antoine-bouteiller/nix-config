{
  globals,
  pkgs,
  config,
  inputs,
  ...
}: let
  inherit (config.home) homeDirectory;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    ../../home-manager
  ];

  local.home-manager = {
    zed.enable = true;
    claudeCode = {
      enable = true;
      mcpServers = {
        fff.command = "${customPkgs.fff-mcp}/bin/fff-mcp";
        sonarqube = {
          command = "docker";
          args = ["run" "-i" "--rm" "--init" "--pull=always" "-e" "SONARQUBE_TOKEN" "-e" "SONARQUBE_URL" "sonarsource/sonarqube-mcp"];
          env = {
            "SONARQUBE_URL" = "https://sonarqube.pelico.tech";
          };
        };
        linear = {
          type = "streamable-http";
          url = "https://mcp.linear.app/mcp";
        };
        slack = {
          type = "http";
          url = "https://mcp.slack.com/mcp";
          oauth = {
            clientId = "1601185624273.8899143856786";
            callbackPort = 3118;
          };
        };
      };
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
