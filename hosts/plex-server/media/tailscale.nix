{config, ...}: {
  # One-time bootstrap after first deploy:
  #   sudo tailscale up
  #
  # Then configure Tailscale DNS in the admin console:
  #   - Add a restricted nameserver for the "home" domain.
  #   - Use this host's `tailscale ip -4` address as the nameserver.
  services.tailscale = {
    enable = true;
  };

  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  networking.firewall = {
    trustedInterfaces = [config.services.tailscale.interfaceName];
    allowedUDPPorts = [config.services.tailscale.port];
  };

  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;
}
