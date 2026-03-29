{
  config,
  lib,
  ...
}: let
  cfg = config.mediaServer;
in {
  config = lib.mkIf cfg.enable {
    services.caddy = {
    enable = true;

    extraConfig = ''
      (auth_proxy) {
        forward_auth localhost:${toString cfg.authelia.port} {
          uri /api/authz/forward-auth
          copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
          header_down -Authorization
        }
      }
    '';
  };
  };
}
