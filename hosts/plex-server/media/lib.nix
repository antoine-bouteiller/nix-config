let
  constants = import ./constants.nix;
in {
  # Build a single-entry Cloudflare Tunnel ingress map for a public service.
  # Internal services skip this entirely — they're reachable via the
  # Cloudflare WARP mesh (see ./cloudflare-warp.nix), not the tunnel.
  mkCloudflaredIngress = {
    name,
    port,
  }: let
    host =
      if name == ""
      then constants.network.domain
      else "${name}.${constants.network.domain}";
  in {
    "${host}" = "http://localhost:${toString port}";
  };

  mkCaddyVirtualHost = {
    domain,
    port,
    auth ? false,
    extraProxyConfig ? "",
  }: {
    "${domain}" = {
      extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
          resolvers 1.1.1.1 8.8.8.8
        }
        ${
          if auth
          then "import auth_proxy"
          else ""
        }
        ${
          if extraProxyConfig != ""
          then ''
            reverse_proxy localhost:${toString port} {
              ${extraProxyConfig}
            }
          ''
          else ''
            reverse_proxy localhost:${toString port}
          ''
        }
      '';
      logFormat = ''
        output file ${constants.caddy.logDir}/access-${domain}.log {
          roll_size 10MiB
          roll_keep 3
        }
      '';
    };
  };
}
