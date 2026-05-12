{
  config,
  lib,
  pkgs,
  ...
}: let
  constants = import ../constants.nix;
  readIps = file:
    builtins.filter (s: s != "")
    (lib.splitString "\n" (builtins.readFile file));
  cloudflareIps = readIps ./cloudflare-ips-v4.txt ++ readIps ./cloudflare-ips-v6.txt;
  trustedProxies = builtins.concatStringsSep " " cloudflareIps;
in {
  sops.secrets."crowdsec/caddy-bouncer" = {};

  sops.templates."caddy-crowdsec.env" = {
    content = ''
      CROWDSEC_API_KEY=${config.sops.placeholder."crowdsec/caddy-bouncer"}
    '';
    owner = "caddy";
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = [
    config.sops.templates."caddy-crowdsec.env".path
  ];

  systemd.tmpfiles.rules = [
    "d ${constants.caddy.logDir} 0750 ${constants.caddy.user} ${constants.caddy.group} - -"
    "a+ ${constants.caddy.logDir} - - - - group:${constants.caddy.group}:r--"
    "a+ ${constants.caddy.logDir} - - - - group:${constants.caddy.group}:r-x"
  ];

  services.caddy = {
    enable = true;

    package = pkgs.callPackage ../../../../pkgs/caddy-crowdsec {};

    globalConfig = ''
      order crowdsec first
      order appsec after crowdsec

      crowdsec {
        api_url http://127.0.0.1:${toString constants.crowdsec.port}
        api_key {$CROWDSEC_API_KEY:dummy_key}
        ticker_interval 15s
        appsec_url http://127.0.0.1:${toString constants.crowdsec.appsecPort}
      }
      servers {
        trusted_proxies static 127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 ${trustedProxies}
      }
    '';

    extraConfig = ''
      (crowdsec_proxy) {
        crowdsec
        appsec
      }

      (auth_proxy) {
        import crowdsec_proxy
        forward_auth localhost:${toString constants.authelia.port} {
          uri /api/authz/forward-auth
          copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
          header_down -Authorization
        }
      }
    '';
  };
}
