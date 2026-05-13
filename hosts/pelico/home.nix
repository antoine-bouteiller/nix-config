{
  globals,
  pkgs,
  config,
  inputs,
  ...
}: let
  inherit (config.home) homeDirectory;
in {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../home-manager
  ];

  local.home-manager = {
    zed.enable = true;
    claudeCode = {
      enable = true;
      mcpConfigFile = config.sops.templates."claude-mcp-config".path;
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

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

    secrets = {
      github_pat = {};
      gitlab_token = {};
      ai_agent_hub = {};
      azure_openai_api_key = {};
      linear_token = {};
      "deskbird/refresh_token" = {};
      "deskbird/google_api_key" = {};
    };

    templates."claude-mcp-config".content = builtins.toJSON {
      mcpServers = {
        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp";
          headers.Authorization = "Bearer ${config.sops.placeholder.github_pat}";
        };
        ai_agent_hub = {
          type = "http";
          url = "https://mcp-server.ai-service.pelico.best/mcp";
          headers.Authorization = "Bearer ${config.sops.placeholder.ai_agent_hub}";
        };
      };
    };

    templates."secrets.env" = {
      content = ''
        export GITHUB_PAT=${config.sops.placeholder.github_pat}
        export GITLAB_TOKEN=${config.sops.placeholder.gitlab_token}
        export AZURE_OPENAI_API_KEY=${config.sops.placeholder.azure_openai_api_key}
        export LINEAR_TOKEN=${config.sops.placeholder.linear_token}
        export DESKBIRD_REFRESH_TOKEN=${config.sops.placeholder."deskbird/refresh_token"}
        export DESKBIRD_GOOGLE_API_KEY=${config.sops.placeholder."deskbird/google_api_key"}
      '';
    };
  };

  programs.zsh.envExtra = ''
    # Source sops-nix decrypted secrets
    [[ -f "${config.sops.templates."secrets.env".path}" ]] && source "${config.sops.templates."secrets.env".path}"
  '';

  manual.manpages.enable = false;
}
