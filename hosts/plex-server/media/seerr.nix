{...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCloudflaredIngress;
in {
  services.seerr = {
    enable = true;
    configDir = constants.seerr.dataDir;
  };

  services.cloudflared.tunnels.${constants.cloudflared.tunnelId}.ingress = mkCloudflaredIngress {
    name = "";
    port = constants.seerr.port;
  };

  systemd.services.seerr = {
    environment = {
      LOG_LEVEL = "info";
    };
  };
}
