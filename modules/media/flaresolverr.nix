{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.mediaServer.enable {
    services.flaresolverr = {
      enable = true;
    };
  };
}
