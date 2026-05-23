{
  config,
  pkgs,
  ...
}: {
  sops.secrets."caddy/cloudflare_token" = {
    key = "cloudflare_token";
  };

  sops.templates."caddy-cloudflare.env" = {
    content = ''
      CLOUDFLARE_API_TOKEN=${config.sops.placeholder."caddy/cloudflare_token"}
    '';
    owner = "caddy";
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = [
    config.sops.templates."caddy-cloudflare.env".path
  ];

  services.caddy = {
    enable = true;
    package = pkgs.callPackage ../../../pkgs/caddy-cloudflare {};
  };
}
