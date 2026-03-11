{
  globals,
  pkgs,
  ...
}: {
  imports = [
    ../../home-manager/common.nix
    ../../home-manager/applications/ghostty.nix
    ../../home-manager/applications/vim.nix
    ../../home-manager/applications/zed
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    packages = [pkgs.dockutil];
    stateVersion = "23.11";
  };

  # Host-specific git email override
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

  manual.manpages.enable = false;
}
