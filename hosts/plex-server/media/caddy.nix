{...}: {
  services.caddy = {
    enable = true;
    globalConfig = ''
      pki {
        certs {
          local {
            disable_trust
          }
        }
      }
    '';
  };
}
