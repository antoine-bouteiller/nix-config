{
  caddy,
  lib,
  writeShellScript,
}: let
  sources = lib.importJSON ./sources.json;
  pkg =
    (caddy.withPlugins {
      plugins = [
        "github.com/hslatman/caddy-crowdsec-bouncer/http@v${sources.version}"
        "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v${sources.version}"
      ];
      inherit (sources) hash;
    })
    .overrideAttrs (_: {
      doInstallCheck = false;
    });
in
  pkg.overrideAttrs (old: {
    passthru =
      (old.passthru or {})
      // {
        updateScript = writeShellScript "caddy-crowdsec-update" ''
          set -e
          cd "$PWD/pkgs/caddy-crowdsec"
          exec ./update.sh
        '';
      };
  })
