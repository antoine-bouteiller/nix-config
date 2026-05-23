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

  mkLocalCaddyVirtualHost = {
    domain,
    port,
    extraProxyConfig ? "",
  }: {
    "${domain}" = {
      extraConfig =
        if extraProxyConfig == ""
        then ''
          tls internal
          reverse_proxy 127.0.0.1:${toString port}
        ''
        else ''
          tls internal
          reverse_proxy 127.0.0.1:${toString port} {
            ${extraProxyConfig}
          }
        '';
    };
  };
}
