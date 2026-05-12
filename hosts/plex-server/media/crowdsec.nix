{...}: let
  constants = import ./constants.nix;
  # Country codes allowed in addition to any country flagged as EU member
  # by the GeoIP enricher. Edit this list to widen / narrow the geofence.
  allowedIsoCodes = ["US"];
  isoCodeList = "[" + builtins.concatStringsSep ", " (map (c: "'${c}'") allowedIsoCodes) + "]";
in {
  users.users.crowdsec.extraGroups = [
    constants.caddy.group
    "systemd-journal"
  ];

  services.crowdsec = {
    enable = true;

    settings = {
      general = {
        common.log_level = "warn";
        api.server = {
          enable = true;
          log_level = "warn";
          listen_uri = "127.0.0.1:${toString constants.crowdsec.port}";
          console_path = "/var/lib/crowdsec/state/console.yaml";
        };
      };
      capi.credentialsFile = "/var/lib/crowdsec/capi-credentials.yaml";
      lapi.credentialsFile = "/var/lib/crowdsec/lapi-credentials.yaml";
    };

    hub = {
      collections = [
        "crowdsecurity/linux"
        "crowdsecurity/caddy"
        "crowdsecurity/sshd"
        "LePresidente/authelia"
        "crowdsecurity/plex"
        "gauth-fr/immich"
        "crowdsecurity/appsec-virtual-patching"
        "crowdsecurity/appsec-generic-rules"
      ];

      parsers = [
        "crowdsecurity/geoip-enrich"
      ];
    };

    localConfig.parsers.s02Enrich = [
      {
        name = "local/homepage-whitelist";
        description = "Whitelist Homepage dashboard /api/services/proxy calls";
        whitelist = {
          reason = "Homepage dashboard widget API proxy calls";
          expression = [
            "evt.Parsed.uri startsWith '/api/services/proxy'"
          ];
        };
      }
      {
        name = "local/loopback-whitelist";
        description = "Never act on events whose source is the local proxy";
        # Backends behind Caddy that don't honor X-Forwarded-For will log
        # 127.0.0.1 / ::1 as the client. Whitelisting here prevents any
        # scenario from generating a self-ban against the reverse proxy.
        whitelist = {
          reason = "loopback — events sourced from Caddy itself, not real clients";
          ip = ["127.0.0.1" "::1"];
        };
      }
    ];

    localConfig.scenarios = [
      {
        type = "trigger";
        name = "local/country-block";
        description = "Ban IPs geolocated outside the EU and the allowed country list";
        # Skip events without GeoIP enrichment (LAN / unresolved) so we
        # don't ban our own traffic when the MMDB lookup misses.
        filter = "evt.Enriched.IsoCode != '' && evt.Enriched.IsInEU != 'true' && evt.Enriched.IsoCode not in ${isoCodeList}";
        groupby = "evt.Meta.source_ip";
        labels = {
          type = "country_block";
          remediation = true;
        };
        blackhole = "30s";
      }
    ];

    localConfig.acquisitions = [
      {
        filename = "${constants.caddy.logDir}/*.log";
        labels.type = "caddy";
      }
      {
        source = "journalctl";
        journalctl_filter = ["_SYSTEMD_UNIT=sshd.service"];
        labels.type = "syslog";
      }
      {
        source = "journalctl";
        journalctl_filter = ["_SYSTEMD_UNIT=authelia-main.service"];
        labels.type = "authelia";
      }
      {
        source = "journalctl";
        journalctl_filter = ["_SYSTEMD_UNIT=immich-server.service"];
        labels.type = "immich";
      }
      {
        appsec_config = "crowdsecurity/appsec-default";
        source = "appsec";
        labels.type = "appsec";
        listen_addr = "127.0.0.1:${toString constants.crowdsec.appsecPort}";
      }
    ];
  };
}
