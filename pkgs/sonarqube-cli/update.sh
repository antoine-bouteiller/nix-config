#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq
set -euo pipefail

BASE_URL="https://binaries.sonarsource.com/Distribution/sonarqube-cli"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

declare -A PLATFORMS=(
  ["aarch64-darwin"]="macos/sonarqube-cli-VERSION-macos-arm64.exe"
  ["x86_64-linux"]="linux/sonarqube-cli-VERSION-linux-x86-64.exe"
  ["aarch64-linux"]="linux/sonarqube-cli-VERSION-linux-arm64.exe"
)

current_version=$(jq -r '.version' "$SCRIPT_DIR/sources.json")
latest_version=$(curl -sf "$BASE_URL/latest-version.txt" | tr -d '[:space:]')

if [[ -z "$latest_version" ]]; then
  echo "ERROR: could not determine the latest version." >&2
  exit 1
fi

echo "Current version: $current_version"
echo "Latest version:  $latest_version"

if [[ "$current_version" == "$latest_version" ]]; then
  echo "Already up to date."
  exit 0
fi

echo "Updating sonarqube-cli from $current_version to $latest_version"

platforms_json="{}"
for nix_platform in "${!PLATFORMS[@]}"; do
  path_template="${PLATFORMS[$nix_platform]}"
  path="${path_template//VERSION/$latest_version}"
  url="$BASE_URL/$latest_version/$path"

  hash=$(nix-prefetch-url --type sha256 "$url" 2>/dev/null)
  sri_hash=$(nix hash to-sri --type sha256 "$hash")
  platforms_json=$(echo "$platforms_json" | jq \
    --arg p "$nix_platform" --arg u "$url" --arg h "$sri_hash" \
    '.[$p] = {url: $u, hash: $h}')
  echo "  $nix_platform: $sri_hash"
done

jq -n --arg v "$latest_version" --argjson p "$platforms_json" \
  '{version: $v, platforms: $p}' > "$SCRIPT_DIR/sources.json"

echo "Updated sonarqube-cli to version $latest_version"
