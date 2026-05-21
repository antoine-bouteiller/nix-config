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
}
