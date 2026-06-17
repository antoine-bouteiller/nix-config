{config, ...}: {
  # podman + oci-containers backend are already enabled by ./byparr.nix.

  # proton/private_key + proton/address come from the Proton WireGuard config.
  # tailscale_exit_authkey (env-file form): TS_AUTHKEY=tskey-auth-...
  sops.secrets."proton/private_key" = {};
  sops.secrets."proton/address" = {};
  sops.secrets."tailscale_exit_authkey" = {};

  sops.templates."gluetun.env".content = ''
    WIREGUARD_PRIVATE_KEY=${config.sops.placeholder."proton/private_key"}
    WIREGUARD_ADDRESSES=${config.sops.placeholder."proton/address"}
  '';

  # Bind-mount source for the tailscale node's state; podman won't create it.
  systemd.tmpfiles.rules = ["d /var/lib/tailscale-exit 0700 root root -"];

  virtualisation.oci-containers.containers = {
    # Proton VPN WireGuard tunnel. Owns the network namespace shared below.
    gluetun = {
      # renovate: datasource=docker depName=qmcgaw/gluetun
      image = "qmcgaw/gluetun@sha256:1a5bf4b4820a879cdf8d93d7ef0d2d963af56670c9ebff8981860b6804ebc8ab"; # v3.41.1
      autoStart = true;
      environment = {
        VPN_SERVICE_PROVIDER = "protonvpn";
        VPN_TYPE = "wireguard";
        # DNS-over-TLS to 1.1.1.1:853 times out in this netns; use plaintext DNS
        # over the tunnel instead (fixes "lookup cloudflare.com: i/o timeout").
        DOT = "off";
      };
      environmentFiles = [config.sops.templates."gluetun.env".path];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--device=/dev/net/tun:/dev/net/tun"
        # Exit-node forwarding happens in this netns, so set the sysctls here.
        "--sysctl=net.ipv4.ip_forward=1"
        "--sysctl=net.ipv6.conf.all.forwarding=1"
      ];
    };

    # Tailscale node sharing gluetun's netns -> all its egress exits via Proton.
    tailscale-exit = {
      # renovate: datasource=docker depName=tailscale/tailscale
      image = "tailscale/tailscale@sha256:25cde9ad76020b0e29229136d0c38b5962e9a0e1774ffac9b0df68e4a37d6cf0"; # v1.98.4
      autoStart = true;
      dependsOn = ["gluetun"];
      environment = {
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_EXTRA_ARGS = "--advertise-exit-node";
        TS_USERSPACE = "false";
      };
      environmentFiles = [config.sops.secrets."tailscale_exit_authkey".path];
      volumes = ["/var/lib/tailscale-exit:/var/lib/tailscale"];
      extraOptions = [
        "--network=container:gluetun"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
    };
  };
}
