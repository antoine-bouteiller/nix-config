#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq pnpm_10
set -euo pipefail

NPM_REGISTRY="https://registry.npmjs.org"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

declare -A PLATFORMS=(
  ["x86_64-linux"]="linux-x64-gnu"
  ["aarch64-linux"]="linux-arm64-gnu"
  ["x86_64-darwin"]="darwin-x64"
  ["aarch64-darwin"]="darwin-arm64"
)

current_version=$(jq -r '.version' "$SCRIPT_DIR/sources.json")
latest_version=$(curl -sf "$NPM_REGISTRY/vite-plus/latest" | jq -r '.version')

echo "Current version: $current_version"
echo "Latest version:  $latest_version"

if [[ "$current_version" == "$latest_version" ]]; then
  echo "Already up to date."
  exit 0
fi

echo "Updating vite-plus from $current_version to $latest_version"

platforms_json="{}"
for nix_platform in "${!PLATFORMS[@]}"; do
  npm_suffix="${PLATFORMS[$nix_platform]}"
  pkg="@voidzero-dev/vite-plus-cli-${npm_suffix}"
  dist=$(curl -sf "$NPM_REGISTRY/$pkg/$latest_version" | jq '.dist')
  url=$(echo "$dist" | jq -r '.tarball')
  hash=$(echo "$dist" | jq -r '.integrity')
  platforms_json=$(echo "$platforms_json" | jq \
    --arg p "$nix_platform" --arg u "$url" --arg h "$hash" \
    '.[$p] = {url: $u, hash: $h}')
  echo "  $nix_platform: $hash"
done

echo ""
echo "Updating pnpm lockfile..."
npm_dir="$SCRIPT_DIR/npm"

jq -n --arg v "$latest_version" '{
  name: "vp-wrapper",
  version: $v,
  private: true,
  dependencies: { "vite-plus": $v }
}' > "$npm_dir/package.json"

pnpm install --lockfile-only --dir "$npm_dir"

echo "Computing pnpm deps hash..."
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

cat > "$tmp_dir/default.nix" <<NIXEOF
let pkgs = import (builtins.getFlake "nixpkgs") {};
in pkgs.fetchPnpmDeps {
  pname = "vp-wrapper";
  version = "0";
  src = $npm_dir;
  hash = "";
  fetcherVersion = 3;
  pnpm = pkgs.pnpm_10;
}
NIXEOF

pnpm_hash=$(nix build --impure --no-link -f "$tmp_dir/default.nix" 2>&1 || true)
pnpm_hash=$(echo "$pnpm_hash" \
  | sed -n 's/.*got:[[:space:]]*\(sha256-[A-Za-z0-9+/]*=*\).*/\1/p')

if [[ -z "$pnpm_hash" ]]; then
  echo "ERROR: Failed to extract pnpm deps hash" >&2
  exit 1
fi
echo "  pnpm deps hash: $pnpm_hash"

jq -n --arg v "$latest_version" --arg h "$pnpm_hash" --argjson p "$platforms_json" \
  '{version: $v, hash: $h, platforms: $p}' > "$SCRIPT_DIR/sources.json"

echo "Updated vite-plus to version $latest_version"
