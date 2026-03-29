{
  config,
  lib,
  ...
}: let
  cfg = config.mediaServer;
in {
  config = lib.mkIf cfg.enable {
    programs.coolercontrol.enable = true;

  services.caddy.virtualHosts."coolercontrol.${cfg.network.domain}" = {
    extraConfig = ''
      import auth_proxy
      reverse_proxy localhost:${toString cfg.coolercontrol.port}
    '';
  };
  };
}
