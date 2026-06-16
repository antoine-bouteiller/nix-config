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

  virtualisation.oci-containers.containers = {
    # Proton VPN WireGuard tunnel. Owns the network namespace shared below.
    gluetun = {
      image = "qmcgaw/gluetun:latest";
      autoStart = true;
      environment = {
        VPN_SERVICE_PROVIDER = "protonvpn";
        VPN_TYPE = "wireguard";
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
      image = "tailscale/tailscale:latest";
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
