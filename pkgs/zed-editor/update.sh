#!/usr/bin/env bash
#
# Update script for the zed-editor flake input.
#
# Finds the latest *stable* tag (vX.Y.Z, no -pre/-rc/-beta suffix) from
# the zed-industries/zed GitHub repo and rewrites the zed-editor input
# URL in flake.nix, then refreshes flake.lock for that input.
#
# Stable tags are the only ones built by zed CI, so pinning to them
# keeps livekit-libwebrtc & friends fetched from the cache instead of
# rebuilt from source.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
FLAKE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly FLAKE_DIR
readonly FLAKE_FILE="$FLAKE_DIR/flake.nix"

fetch_latest_stable_tag() {
  curl -fsSL 'https://api.github.com/repos/zed-industries/zed/tags?per_page=100' \
    | jq -r '.[].name' \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V \
    | tail -1
}

current_tag=$(grep -oE 'github:zed-industries/zed/[^"]+' "$FLAKE_FILE" | head -1 | sed 's|.*/||' || true)

latest_tag=$(fetch_latest_stable_tag)
if [[ -z "$latest_tag" ]]; then
  echo "Failed to find a stable zed tag" >&2
  exit 1
fi

echo "Current zed-editor tag: ${current_tag:-<unpinned>}"
echo "Latest stable tag:      $latest_tag"

if [[ "$current_tag" == "$latest_tag" ]]; then
  echo "Already up to date."
  exit 0
fi

echo "Updating zed-editor: ${current_tag:-<unpinned>} -> $latest_tag"

sed -i -E "s|(url = \"github:zed-industries/zed)(/[^\"]*)?(\")|\1/$latest_tag\3|" "$FLAKE_FILE"

(cd "$FLAKE_DIR" && nix flake update zed-editor)
