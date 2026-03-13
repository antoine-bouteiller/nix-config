{
  lib,
  config,
  hostUser,
  ...
}: let
  dotfilesPath = "${config.home.homeDirectory}/.dotfiles";
  winHome = "/mnt/c/Users/${hostUser}";
  winZedConfig = "${winHome}/AppData/Roaming/Zed";
  winStarshipConfig = "${winHome}/.config";
in {
  imports = [
    ../../home-manager/common.nix
    ../../home-manager/applications/vim.nix
    ../../home-manager/applications/zed
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = hostUser;
    homeDirectory = lib.mkForce "/home/${hostUser}";
    stateVersion = "25.11";

    # Copy Zed and Starship configs to Windows on activation
    activation.copyWindowsConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Zed config
      if [ -d "/mnt/c" ]; then
        run mkdir -p "${winZedConfig}"
        run cp -f "${dotfilesPath}/home-manager/applications/zed/settings.json" "${winZedConfig}/settings.json"
        run cp -f "${dotfilesPath}/home-manager/applications/zed/keymap.json" "${winZedConfig}/keymap.json"

        # Starship config
        run mkdir -p "${winStarshipConfig}"
        if [ -f "${config.home.homeDirectory}/.config/starship.toml" ]; then
          run cp -f "${config.home.homeDirectory}/.config/starship.toml" "${winStarshipConfig}/starship.toml"
        fi
      fi
    '';
  };
}
