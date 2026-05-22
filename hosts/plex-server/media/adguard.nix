{
  config,
  lib,
  pkgs,
  ...
}: let
  constants = import ./constants.nix;
  python = pkgs.python3.withPackages (ps: [ps.pyyaml]);
  localDomains =
    map
    (service: "${service}.${constants.network.localDomain}")
    (lib.unique config.local.adguard.localDnsServices);
in {
  options.local.adguard.localDnsServices = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Local service names to publish under the .${constants.network.localDomain} DNS zone.";
  };

  config = {
    local.adguard.localDnsServices = ["adguard"];

    services.adguardhome = {
      enable = true;
      host = "0.0.0.0";
      port = 3000;
      mutableSettings = true;
      settings = {
        dns = {
          bind_hosts = ["0.0.0.0"];
          port = 53;
          upstream_dns = [
            "1.1.1.1"
            "9.9.9.9"
          ];
          bootstrap_dns = [
            "1.1.1.1"
            "9.9.9.9"
          ];
        };
      };
    };

    networking.firewall.interfaces.tailscale0 = {
      allowedTCPPorts = [
        config.services.adguardhome.settings.dns.port
        config.services.adguardhome.port
      ];
      allowedUDPPorts = [config.services.adguardhome.settings.dns.port];
    };

    systemd.services.adguardhome-tailscale-rewrites = {
      description = "Point AdGuard Home local DNS rewrites at the Tailscale IP";
      after = ["tailscaled.service" "adguardhome.service"];
      wants = ["tailscaled.service" "adguardhome.service"];
      wantedBy = ["multi-user.target"];
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = "30s";
      };
      path = [
        pkgs.coreutils
        pkgs.tailscale
        pkgs.systemd
        python
      ];
      environment.LOCAL_DNS_DOMAINS = builtins.concatStringsSep " " localDomains;
      script = ''
        set -euo pipefail

        tailscale_ip="$(tailscale ip -4)"
        if [ -z "$tailscale_ip" ]; then
          echo "Tailscale does not have an IPv4 address yet"
          exit 1
        fi
        export tailscale_ip

        python - <<'PY'
        import os
        import shutil
        import sys
        from pathlib import Path

        import yaml

        config_path = Path("/var/lib/AdGuardHome/AdGuardHome.yaml")
        tailscale_ip = os.environ["tailscale_ip"]
        domains = os.environ["LOCAL_DNS_DOMAINS"].split()

        if not config_path.exists():
            print(f"{config_path} does not exist yet", file=sys.stderr)
            sys.exit(1)

        with config_path.open() as f:
            config = yaml.safe_load(f) or {}

        filtering = config.setdefault("filtering", {})
        rewrites = filtering.get("rewrites") or []
        managed_domains = set(domains)
        unmanaged_rewrites = [
            rewrite
            for rewrite in rewrites
            if rewrite.get("domain") not in managed_domains
        ]
        managed_rewrites = [
            {"domain": domain, "answer": tailscale_ip, "enabled": True}
            for domain in domains
        ]
        next_rewrites = unmanaged_rewrites + managed_rewrites

        if filtering.get("rewrites") == next_rewrites and filtering.get("rewrites_enabled", True):
            sys.exit(0)

        filtering["rewrites_enabled"] = True
        filtering["rewrites"] = next_rewrites

        backup_path = config_path.with_suffix(".yaml.bak")
        shutil.copy2(config_path, backup_path)
        with config_path.open("w") as f:
            yaml.safe_dump(config, f, sort_keys=False)
        PY

        systemctl restart adguardhome.service
      '';
    };
  };
}
