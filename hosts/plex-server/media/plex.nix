{...}: let
  constants = import ./constants.nix;
in {
  services.plex = {
    enable = true;
    openFirewall = true;
    dataDir = constants.plex.dataDir;
  };

  systemd.tmpfiles.rules = [
    "d '${constants.paths.mediaDir}/library'        0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
    "d '${constants.paths.mediaDir}/library/movies' 0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
    "d '${constants.paths.mediaDir}/library/tv'     0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
    "d '${constants.paths.mediaDir}/transcode'      0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
  ];

  users.users.plex.extraGroups = [constants.libraryOwner.group];
}
