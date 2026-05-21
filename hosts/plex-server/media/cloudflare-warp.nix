{...}: {
  # Enrolls plex-server in the Cloudflare Zero Trust mesh. Internal
  # services (sonarr, radarr, prowlarr, bazarr, transmission, homepage)
  # are reachable from other WARP-enrolled devices directly over the
  # mesh — no public tunnel, no reverse proxy.
  #
  # One-time bootstrap after first deploy:
  #   sudo warp-cli registration new <team-name>
  #   sudo warp-cli mode warp
  #   sudo warp-cli connect
  services.cloudflare-warp.enable = true;
}
