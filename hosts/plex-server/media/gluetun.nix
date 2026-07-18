{
  config,
  pkgs,
  ...
}: {
  # podman + oci-containers backend are already enabled by ./byparr.nix.

  # proton/private_key + proton/address come from the Proton WireGuard config.
  sops.secrets."proton/private_key" = {};
  sops.secrets."proton/address" = {};

  sops.templates."gluetun.env".content = ''
    WIREGUARD_PRIVATE_KEY=${config.sops.placeholder."proton/private_key"}
    WIREGUARD_ADDRESSES=${config.sops.placeholder."proton/address"}
  '';

  # Bind-mount source for the tailscale node's state; podman won't create it.
  systemd.tmpfiles.rules = ["d /var/lib/tailscale-exit 0700 root root -"];

  # gluetun's policy routing (rule 101) sends everything via tun0, so un-NAT'd
  # replies to exit-node clients get routed out eth0 instead of back through
  # tailscale0 -> handshakes hang in SYN_RECV. Insert a higher-priority rule
  # (90 < gluetun's 98-101) sending the tailnet CGNAT range to tailscale's
  # routing table (52), where 100.64.0.0/10 correctly resolves to tailscale0.
  systemd.services.tailscale-exit-route = {
    description = "Return tailnet traffic via tailscale0 inside gluetun's netns";
    after = ["podman-tailscale-exit.service"];
    bindsTo = ["podman-tailscale-exit.service"];
    wantedBy = ["podman-tailscale-exit.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      pid=$(${pkgs.podman}/bin/podman inspect -f '{{.State.Pid}}' gluetun)
      nsip() { ${pkgs.util-linux}/bin/nsenter -t "$pid" -n ${pkgs.iproute2}/bin/ip "$@"; }
      # IPv4 and IPv6 tailnet ranges both get hijacked by gluetun's rule 101.
      nsip rule del to 100.64.0.0/10 lookup 52 priority 90 2>/dev/null || true
      nsip rule add to 100.64.0.0/10 lookup 52 priority 90
      nsip -6 rule del to fd7a:115c:a1e0::/48 lookup 52 priority 90 2>/dev/null || true
      nsip -6 rule add to fd7a:115c:a1e0::/48 lookup 52 priority 90
    '';
  };

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
      # Expose gluetun's control server (public IP / VPN status) for the
      # homepage gluetun widget; localhost-only since homepage runs on the host.
      ports = ["127.0.0.1:8000:8000"];
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
      image = "tailscale/tailscale@sha256:f15d5d3f4a68773a853180b72496f70ba614b64de0878c43fe3da39fe0afba47"; # v1.98.9
      autoStart = true;
      dependsOn = ["gluetun"];
      environment = {
        TS_HOSTNAME = "proton-exit";
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_EXTRA_ARGS = "--advertise-exit-node";
        TS_USERSPACE = "false";
        # gluetun manages the netns firewall via nftables; tailscaled defaults to
        # iptables-legacy, whose tables don't exist here, so it installs no
        # forward/masquerade rules and client traffic is dropped. Match nft.
        TS_DEBUG_FIREWALL_MODE = "nftables";
      };
      # Authenticated once; state persists in the volume, so no authkey needed.
      volumes = ["/var/lib/tailscale-exit:/var/lib/tailscale"];
      extraOptions = [
        "--network=container:gluetun"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
        # Kernel-mode tailscaled (TS_USERSPACE=false) opens /dev/net/tun to make
        # its tailscale0 iface; devices aren't shared via the netns, so mount it.
        "--device=/dev/net/tun:/dev/net/tun"
      ];
    };
  };
}
