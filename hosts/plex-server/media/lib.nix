let
  constants = import ./constants.nix;
in {
  # Build a single-entry Cloudflare Tunnel ingress map for a service.
  #
  # `public = true`  → hostname on the public zone, served from any client.
  # `public = false` → hostname on the private zone, reachable only from
  #                    devices enrolled in the Cloudflare Zero Trust org
  #                    (WARP).
  mkCloudflaredIngress = {
    name,
    port,
    public ? false,
  }: let
    domain =
      if public
      then constants.network.domain
      else constants.network.internalDomain;
    host =
      if name == ""
      then domain
      else "${name}.${domain}";
  in {
    "${host}" = "http://localhost:${toString port}";
  };
}
