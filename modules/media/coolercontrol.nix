{config, ...}: let
  cfg = config.mediaServer;
in {
  programs.coolercontrol.enable = true;

  services.caddy.virtualHosts."coolercontrol.${cfg.network.domain}" = {
    extraConfig = ''
      import auth_proxy
      reverse_proxy localhost:${toString cfg.coolercontrol.port}
    '';
  };
}
