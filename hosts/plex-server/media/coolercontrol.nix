{config, ...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkLocalCaddyVirtualHost;
in {
  local.media.localServices.coolercontrol.localDns.enable = true;

  programs.coolercontrol.enable = true;

  services.caddy.virtualHosts = mkLocalCaddyVirtualHost {
    domain = config.local.media.localServices.coolercontrol.localDomain;
    port = constants.coolercontrol.port;
  };
}
