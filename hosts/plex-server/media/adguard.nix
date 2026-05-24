{
  config,
  lib,
  pkgs,
  ...
}: let
  localDomains =
    lib.unique
    (map
      (service: service.domain)
      (lib.attrValues config.local.media));
in {
  config = {
    local.media.adguard = {
      port = config.services.adguardhome.port;
    };

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

    systemd.services.adguardhome-tailscale-rewrites = {
      description = "Point AdGuard Home local DNS rewrites at the Tailscale IP";

      after = ["tailscaled.service"];
      wants = ["tailscaled.service"];
      before = ["adguardhome.service"];
      wantedBy = ["multi-user.target"];

      path = [
        pkgs.coreutils
        pkgs.tailscale
        (pkgs.python3.withPackages (ps: [ps.pyyaml]))
      ];

      environment.LOCAL_DNS_DOMAINS = builtins.concatStringsSep " " localDomains;

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        set -euo pipefail

        echo "Waiting for Tailscale IPv4 address..."
        while true; do
          tailscale_ip=$(tailscale ip -4 2>/dev/null || true)
          if [ -n "$tailscale_ip" ]; then
            break
          fi
          sleep 2
        done
        export tailscale_ip
        echo "Tailscale IP found: $tailscale_ip"

        python - <<'PY'
        import os
        import sys
        import tempfile
        from pathlib import Path
        import yaml

        config_path = Path("/var/lib/AdGuardHome/AdGuardHome.yaml")
        tailscale_ip = os.environ["tailscale_ip"]
        domains = os.environ.get("LOCAL_DNS_DOMAINS", "").split()

        if config_path.exists():
            with config_path.open() as f:
                config = yaml.safe_load(f) or {}
        else:
            config = {}

        filtering = config.setdefault("filtering", {})
        rewrites = filtering.get("rewrites") or []
        managed_domains = set(domains)

        unmanaged_rewrites = [
            rw for rw in rewrites if rw.get("domain") not in managed_domains
        ]
        managed_rewrites = [
            {"domain": domain, "answer": tailscale_ip, "enabled": True}
            for domain in domains
        ]
        next_rewrites = unmanaged_rewrites + managed_rewrites

        if filtering.get("rewrites") == next_rewrites and filtering.get("rewrites_enabled", True):
            print("Configuration is already up to date.")
            sys.exit(0)

        filtering["rewrites_enabled"] = True
        filtering["rewrites"] = next_rewrites

        config_path.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile("w", dir=config_path.parent, delete=False) as tf:
            yaml.safe_dump(config, tf, sort_keys=False)
            temp_name = tf.name

        os.replace(temp_name, config_path)

        # Inherit ownership from the systemd-managed parent folder
        dir_stat = config_path.parent.stat()
        os.chown(config_path, dir_stat.st_uid, dir_stat.st_gid)
        os.chmod(config_path, 0o600)

        print("AdGuard Home configuration updated successfully.")
        PY
      '';
    };
  };
}
