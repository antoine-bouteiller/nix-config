#!/usr/bin/env bash
#
# Update script for claude package.
#
# Fetches the latest version from npm registry and retrieves
# platform-specific binaries with checksums from manifest.json.

set -euo pipefail

readonly BASE_URL="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly SOURCES_FILE="$SCRIPT_DIR/sources.json"

# nix-platform:manifest-platform
readonly PLATFORMS=(
  "x86_64-linux:linux-x64"
  "aarch64-linux:linux-arm64"
  "x86_64-darwin:darwin-x64"
  "aarch64-darwin:darwin-arm64"
)

fetch_latest_version() {
  curl -fsSL "https://registry.npmjs.org/@anthropic-ai/claude-code/latest" \
    | jq -r '.version'
}

fetch_manifest() {
  curl -fsSL "$BASE_URL/$1/manifest.json"
}

current_version=""
if [[ -f "$SOURCES_FILE" ]]; then
  current_version=$(jq -r '.version' "$SOURCES_FILE")
fi

latest_version=$(fetch_latest_version)
if [[ -z "$latest_version" ]]; then
  echo "Failed to fetch latest version from npm registry" >&2
  exit 1
fi

echo "Current version: ${current_version:-<none>}"
echo "Latest version:  $latest_version"

if [[ "$current_version" == "$latest_version" ]]; then
  echo "Already up to date."
  exit 0
fi

echo "Updating claude-code from ${current_version:-<none>} to $latest_version"

manifest=$(fetch_manifest "$latest_version")

platforms_json='{}'
for entry in "${PLATFORMS[@]}"; do
  nix_platform="${entry%%:*}"
  manifest_platform="${entry#*:}"
  checksum=$(jq -r --arg p "$manifest_platform" '.platforms[$p].checksum // empty' <<<"$manifest")
  if [[ -z "$checksum" ]]; then
    echo "Missing platform $manifest_platform in manifest for $latest_version" >&2
    exit 1
  fi
  # `nix hash convert` (modern Nix) and `nix hash to-sri` (Lix, older Nix)
  # both produce SRI form. Stderr is silenced to hide the to-sri deprecation
  # warning emitted by recent Nix.
  hash=$(nix hash convert --hash-algo sha256 --to sri "$checksum" 2>/dev/null \
    || nix hash to-sri --type sha256 "$checksum" 2>/dev/null \
    || true)
  if [[ -z "$hash" ]]; then
    echo "Failed to compute SRI hash for $manifest_platform" >&2
    exit 1
  fi
  url="$BASE_URL/$latest_version/$manifest_platform/claude"
  platforms_json=$(jq \
    --arg p "$nix_platform" \
    --arg url "$url" \
    --arg hash "$hash" \
    '.[$p] = {url: $url, hash: $hash}' <<<"$platforms_json")
done

jq -n \
  --arg version "$latest_version" \
  --argjson platforms "$platforms_json" \
  '{version: $version, platforms: $platforms}' \
  >"$SOURCES_FILE"

echo "Updated claude-code to version $latest_version"
