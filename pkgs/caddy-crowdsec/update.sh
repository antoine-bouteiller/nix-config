#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GITHUB_REPO="hslatman/caddy-crowdsec-bouncer"
FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

current_version=$(jq -r '.version' "$SCRIPT_DIR/sources.json")
latest_version=$(curl -sf "https://api.github.com/repos/$GITHUB_REPO/releases/latest" \
  | jq -r '.tag_name' | sed 's/^v//')

echo "Current version: $current_version"
echo "Latest version:  $latest_version"

if [[ "$current_version" == "$latest_version" ]]; then
  echo "Already up to date."
  exit 0
fi

echo "Updating caddy-crowdsec from $current_version to $latest_version"

jq --arg v "$latest_version" --arg h "$FAKE_HASH" \
  '.version = $v | .hash = $h' "$SCRIPT_DIR/sources.json" > "$SCRIPT_DIR/sources.json.tmp"
mv "$SCRIPT_DIR/sources.json.tmp" "$SCRIPT_DIR/sources.json"

echo "Building to compute new hash..."
OUTPUT=$(nix build .#packages.x86_64-linux.caddy-crowdsec --no-link --impure 2>&1 || true)
NEW_HASH=$(echo "$OUTPUT" | grep -oE 'sha256-[A-Za-z0-9+/=]{44}' | grep -v "$FAKE_HASH" | tail -1 || true)

echo "$OUTPUT"

if [[ -z "$NEW_HASH" ]]; then
  echo "ERROR: Failed to extract new hash" >&2
  exit 1
fi

echo "  new hash: $NEW_HASH"

jq --arg h "$NEW_HASH" '.hash = $h' "$SCRIPT_DIR/sources.json" > "$SCRIPT_DIR/sources.json.tmp"
mv "$SCRIPT_DIR/sources.json.tmp" "$SCRIPT_DIR/sources.json"

echo "Updated caddy-crowdsec to version $latest_version"
