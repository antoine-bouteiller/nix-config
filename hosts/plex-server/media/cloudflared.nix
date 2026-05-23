{config, ...}: let
  constants = import ./constants.nix;
in {
  # cloudflared runs as a systemd DynamicUser and consumes the credentials
  # file via `LoadCredential`, which is read as root before privileges drop.
  # The default root-owned 0400 mode is what we want — no owner override.
  sops.secrets."cloudflared/credentials" = {};

  services.cloudflared = {
    enable = true;

    tunnels.${constants.cloudflared.tunnelId} = {
      credentialsFile = config.sops.secrets."cloudflared/credentials".path;
      default = "http_status:404";
    };
  };
}
