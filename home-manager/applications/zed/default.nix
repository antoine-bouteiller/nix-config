{config, ...}: let
  dotfilesPath = "home-manager/applications/zed";
in {
  home.file = {
    ".config/zed/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/${dotfilesPath}/settings.json";
    ".config/zed/keymap.json".source =
      config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/${dotfilesPath}/keymap.json";
  };
}
