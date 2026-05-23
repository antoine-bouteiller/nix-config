#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GITHUB_REPO="caddy-dns/cloudflare"
FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

current_version=$(jq -r '.version' "$SCRIPT_DIR/sources.json")
current_hash=$(jq -r '.hash' "$SCRIPT_DIR/sources.json")
latest_version=$(curl -sf "https://api.github.com/repos/$GITHUB_REPO/tags?per_page=1" \
  | jq -r '.[0].name' | sed 's/^v//')

echo "Current version: $current_version"
echo "Latest version:  $latest_version"

# Always recompute the hash: caddy.withPlugins is a FOD whose contents depend on
# the nixpkgs caddy version, so the hash can drift even when the plugin version
# is unchanged.
jq --arg v "$latest_version" --arg h "$FAKE_HASH" \
  '.version = $v | .hash = $h' "$SCRIPT_DIR/sources.json" > "$SCRIPT_DIR/sources.json.tmp"
mv "$SCRIPT_DIR/sources.json.tmp" "$SCRIPT_DIR/sources.json"

echo "Building to compute new hash..."
system=$(nix eval --raw --impure --expr builtins.currentSystem)
OUTPUT=$(nix build ".#packages.$system.caddy-cloudflare" --no-link --impure 2>&1 || true)
NEW_HASH=$(echo "$OUTPUT" | grep -oE 'sha256-[A-Za-z0-9+/=]{44}' | grep -v "$FAKE_HASH" | tail -1 || true)

echo "$OUTPUT"

if [[ -z "$NEW_HASH" ]]; then
  echo "ERROR: Failed to extract new hash" >&2
  # Restore previous sources.json so a failed run doesn't leave FAKE_HASH committed.
  jq --arg v "$current_version" --arg h "$current_hash" \
    '.version = $v | .hash = $h' "$SCRIPT_DIR/sources.json" > "$SCRIPT_DIR/sources.json.tmp"
  mv "$SCRIPT_DIR/sources.json.tmp" "$SCRIPT_DIR/sources.json"
  exit 1
fi

jq --arg h "$NEW_HASH" '.hash = $h' "$SCRIPT_DIR/sources.json" > "$SCRIPT_DIR/sources.json.tmp"
mv "$SCRIPT_DIR/sources.json.tmp" "$SCRIPT_DIR/sources.json"

if [[ "$current_version" == "$latest_version" && "$current_hash" == "$NEW_HASH" ]]; then
  echo "caddy-cloudflare $latest_version already up to date (hash unchanged)"
else
  echo "Updated caddy-cloudflare to version $latest_version (hash: $NEW_HASH)"
fi
