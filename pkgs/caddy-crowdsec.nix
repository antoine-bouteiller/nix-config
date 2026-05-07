{
  caddy,
  writeShellScript,
}: let
  pkg =
    (caddy.withPlugins {
      plugins = [
        "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.12.0"
        "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.12.0"
      ];
      hash = "sha256-ZDGq4YMVDVwgHd09HGiwI6kTnxbFMNwGWjkothXX5X8=";
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
          PKG_FILE="$PWD/pkgs/caddy-crowdsec.nix"
          FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

          sed -i -E "s|hash = \"sha256-[A-Za-z0-9+/=]+\";|hash = \"$FAKE_HASH\";|" "$PKG_FILE"

          OUTPUT=$(nix build .#packages.x86_64-linux.caddy-crowdsec --no-link --impure 2>&1 || true)
          NEW_HASH=$(echo "$OUTPUT" | grep -oE 'sha256-[A-Za-z0-9+/=]{44}' | grep -v "$FAKE_HASH" | tail -1 || true)

          echo "$OUTPUT"

          if [ -z "$NEW_HASH" ]; then
            echo "Failed to extract new hash."
            exit 1
          fi

          echo "New caddy-crowdsec hash: $NEW_HASH"
          sed -i -E "s|hash = \"$FAKE_HASH\";|hash = \"$NEW_HASH\";|" "$PKG_FILE"
        '';
      };
  })
