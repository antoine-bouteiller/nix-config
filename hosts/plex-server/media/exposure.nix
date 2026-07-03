{
  config,
  lib,
  ...
}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCaddyVirtualHost mkCloudflaredIngress;

  exposedServices = config.local.media;
  publicServices = lib.filterAttrs (_: svc: svc.public) exposedServices;

  # Catch exposed services that forgot to specify a port.
  servicesMissingPort = lib.filterAttrs (_: svc: svc.port == null) exposedServices;
in {
  options.local.media = lib.mkOption {
    default = {};
    description = "Media service hostnames and exposure settings.";
    type = lib.types.attrsOf (
      lib.types.submodule (
        {
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

            port = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              default = null;
              description = "Service port to expose through Caddy and optional Cloudflare Tunnel.";
            };

            auth = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether this Caddy route should import the auth proxy snippet.";
            };

            public = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether this service should also be exposed through Cloudflare Tunnel.";
            };

            extraProxyConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Extra Caddy reverse_proxy configuration for this service.";
            };

            domain = lib.mkOption {
              type = lib.types.str;
              default =
                if config.host == ""
                then constants.network.domain
                else "${config.host}.${constants.network.domain}";
              readOnly = true;
              description = "Computed domain for this service.";
            };
          };
        }
      )
    );
  };

  config = {
    assertions = [
      {
        assertion = servicesMissingPort == {};
        message = "Every local.media.<name> service must define port. Missing: ${builtins.concatStringsSep ", " (builtins.attrNames servicesMissingPort)}";
      }
    ];

    services.caddy.virtualHosts =
      lib.concatMapAttrs (
        _: svc:
          mkCaddyVirtualHost {
            inherit (svc) domain;
            inherit (svc) port;
            inherit (svc) auth;
            inherit (svc) extraProxyConfig;
          }
      )
      exposedServices;

    services.cloudflared.tunnels.${constants.cloudflared.tunnelId}.ingress =
      lib.concatMapAttrs (
        _: svc:
          mkCloudflaredIngress {
            name = svc.host;
            inherit (svc) port;
          }
      )
      publicServices;
  };
}
