{
  config,
  lib,
  ...
}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCaddyVirtualHost;

  # Filter services that have local DNS configuration enabled
  dnsEnabledServices = lib.filterAttrs (_: svc: svc.localDns.enable) config.local.media;

  # Catch enabled services that forgot to specify a port
  servicesMissingPort = lib.filterAttrs (_: svc: svc.localDns.port == null) dnsEnabledServices;
in {
  options.local.media = lib.mkOption {
    default = {};
    description = "Local media service hostnames and DNS publication settings.";
    type = lib.types.attrsOf (lib.types.submodule ({
      name,
      config,
      ...
    }: {
      options = {
        host = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Local DNS label for this service.";
        };

        localDns = {
          enable = lib.mkEnableOption "AdGuard Home local DNS rewrite";

          port = lib.mkOption {
            type = lib.types.nullOr lib.types.port;
            default = null;
            description = "Local service port to expose through Caddy when local DNS is enabled.";
          };

          auth = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this local Caddy route should import the auth proxy snippet.";
          };

          extraProxyConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Extra Caddy reverse_proxy configuration for this local service.";
          };
        };

        localDomain = lib.mkOption {
          type = lib.types.str;
          default = "${config.host}.${constants.network.domain}";
          readOnly = true;
          description = "Computed local domain for this service.";
        };
      };
    }));
  };

  config = {
    assertions = [
      {
        assertion = servicesMissingPort == {};
        message = "Every local.media.<name>.localDns.enable service must define localDns.port. Missing: ${builtins.concatStringsSep ", " (builtins.attrNames servicesMissingPort)}";
      }
    ];

    services.caddy.virtualHosts =
      lib.concatMapAttrs (
        _: svc:
          mkCaddyVirtualHost {
            domain = svc.localDomain;
            port = svc.localDns.port;
            auth = svc.localDns.auth;
            extraProxyConfig = svc.localDns.extraProxyConfig;
          }
      )
      dnsEnabledServices;
  };
}
