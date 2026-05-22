{...}: {
  imports = [
    ./cloudflared.nix
    ./cloudflare-warp.nix
    ./tailscale.nix
    ./adguard.nix
    ./postgres.nix
    ./plex.nix
    ./seerr.nix
    ./sonarr.nix
    ./radarr.nix
    ./prowlarr.nix
    ./bazarr.nix
    ./transmission.nix
    ./recyclarr.nix
    ./homepage.nix
    ./byparr.nix
    ./coolercontrol.nix
    ./autoscan.nix
    ./immich.nix
    ./smartd.nix
  ];
}
