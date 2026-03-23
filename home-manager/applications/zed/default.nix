{config, ...}: let
  inherit (config.home) homeDirectory;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  zedDit = "${homeDirectory}/.dotfiles/home-manager/applications/zed";
in {
  home.file = {
    ".config/zed/settings.json".source = mkOutOfStoreSymlink "${zedDit}/settings.json";
    ".config/zed/keymap.json".source = mkOutOfStoreSymlink "${zedDit}/keymap.json";
  };
}
