{ config, ... }:
let
  mkLink = config.lib.file.mkOutOfStoreSymlink;
  dotfilesPath = "${config.home.homeDirectory}/.dotfiles/nixos-config/modules/shared/files";
in
{
  # Zed editor configuration (editable via out-of-store symlinks)
  ".config/zed/settings.json" = {
    source = mkLink "${dotfilesPath}/zed/settings.json";
  };
  ".config/zed/keymap.json" = {
    source = mkLink "${dotfilesPath}/zed/keymap.json";
  };
}
