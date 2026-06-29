#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq
set -euo pipefail

REPO="dmtrKovalenko/fff"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

declare -A PLATFORMS=(
  ["aarch64-darwin"]="aarch64-apple-darwin"
  ["x86_64-linux"]="x86_64-unknown-linux-gnu"
  ["aarch64-linux"]="aarch64-unknown-linux-gnu"
)

current_version=$(jq -r '.version' "$SCRIPT_DIR/sources.json")
latest_tag=$(curl -sf "https://api.github.com/repos/$REPO/releases/latest" | jq -r '.tag_name')
latest_version="${latest_tag#v}"

echo "Current version: $current_version"
echo "Latest version:  $latest_version"

if [[ "$current_version" == "$latest_version" ]]; then
  echo "Already up to date."
  exit 0
fi

base="https://github.com/$REPO/releases/download/$latest_tag"
platforms_json="{}"
for nix_platform in "${!PLATFORMS[@]}"; do
  target="${PLATFORMS[$nix_platform]}"
  url="$base/fff-mcp-$target"
  hex=$(curl -sfL "$url.sha256" | awk '{print $1}')
  sri_hash=$(nix hash convert --hash-algo sha256 "$hex")
  platforms_json=$(echo "$platforms_json" | jq \
    --arg p "$nix_platform" --arg u "$url" --arg h "$sri_hash" \
    '.[$p] = {url: $u, hash: $h}')
  echo "  $nix_platform: $sri_hash"
done

jq -n --arg v "$latest_version" --argjson p "$platforms_json" \
  '{version: $v, platforms: $p}' > "$SCRIPT_DIR/sources.json"

echo "Updated fff-mcp to version $latest_version"
