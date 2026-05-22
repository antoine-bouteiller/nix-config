{lib, ...}: let
  constants = import ./constants.nix;
in {
  options.local.media.localServices = lib.mkOption {
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

        localDns.enable = lib.mkEnableOption "AdGuard Home local DNS rewrite";

        localDomain = lib.mkOption {
          type = lib.types.str;
          default = "${config.host}.${constants.network.localDomain}";
          readOnly = true;
          description = "Computed local domain for this service.";
        };
      };
    }));
    default = {};
    description = "Local media service hostnames and DNS publication settings.";
  };
}
