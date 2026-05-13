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
readonly VERSIONS_DIR="$SCRIPT_DIR/versions"

# nix-platform:manifest-platform
readonly PLATFORMS=(
  "x86_64-linux:linux-x64"
  "aarch64-linux:linux-arm64"
  "x86_64-darwin:darwin-x64"
  "aarch64-darwin:darwin-arm64"
)

mkdir -p "$VERSIONS_DIR"

fetch_all_versions() {
  curl -fsSL "https://registry.npmjs.org/@anthropic-ai/claude-code" \
    | jq -r '.versions | keys[]' \
    | sort -V
}

fetch_manifest() {
  curl -fsSL "$BASE_URL/$1/manifest.json"
}

list_existing_versions() {
  shopt -s nullglob
  local files=("$VERSIONS_DIR"/*.json)
  shopt -u nullglob
  ((${#files[@]} == 0)) && return
  printf '%s\n' "${files[@]}" \
    | xargs -n1 basename \
    | sed 's/\.json$//' \
    | sort -V
}

# Return 0 if $1 >= $2 (semver-aware)
ver_ge() {
  [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" == "$1" ]]
}

process_version() {
  local version="$1"
  local manifest
  if ! manifest=$(fetch_manifest "$version" 2>/dev/null); then
    echo "  Skipping $version: manifest not available" >&2
    return 1
  fi

  local platforms_json='{}'
  local entry nix_platform manifest_platform checksum hash url
  for entry in "${PLATFORMS[@]}"; do
    nix_platform="${entry%%:*}"
    manifest_platform="${entry#*:}"
    checksum=$(jq -r --arg p "$manifest_platform" '.platforms[$p].checksum // empty' <<<"$manifest")
    if [[ -z "$checksum" ]]; then
      echo "  Skipping $version: missing platform $manifest_platform" >&2
      return 1
    fi
    # `nix hash convert` (modern Nix) and `nix hash to-sri` (Lix, older Nix)
    # both produce SRI form. Stderr is silenced to hide the to-sri deprecation
    # warning emitted by recent Nix.
    hash=$(nix hash convert --hash-algo sha256 --to sri "$checksum" 2>/dev/null \
      || nix hash to-sri --type sha256 "$checksum" 2>/dev/null \
      || true)
    if [[ -z "$hash" ]]; then
      echo "  Failed to compute SRI hash for $manifest_platform on $version" >&2
      return 1
    fi
    url="$BASE_URL/$version/$manifest_platform/claude"
    platforms_json=$(jq \
      --arg p "$nix_platform" \
      --arg url "$url" \
      --arg hash "$hash" \
      '.[$p] = {url: $url, hash: $hash}' <<<"$platforms_json")
  done

  jq -n \
    --arg version "$version" \
    --argjson platforms "$platforms_json" \
    '{version: $version, platforms: $platforms}' \
    >"$VERSIONS_DIR/$version.json"
}

mapfile -t existing < <(list_existing_versions)
mapfile -t all_versions < <(fetch_all_versions)

if ((${#all_versions[@]} == 0)); then
  echo "Failed to fetch versions from npm registry" >&2
  exit 1
fi

latest_version="${all_versions[${#all_versions[@]}-1]}"
current_version=""
earliest=""
if ((${#existing[@]} > 0)); then
  current_version="${existing[${#existing[@]}-1]}"
  earliest="${existing[0]}"
fi

echo "Current version: ${current_version:-<none>}"
echo "Latest version:  $latest_version"

# On first run (no existing versions), only seed with the latest.
# Otherwise backfill anything newer than the earliest version we already track.
missing=()
if [[ -z "$earliest" ]]; then
  missing=("$latest_version")
else
  declare -A existing_set=()
  for v in "${existing[@]}"; do existing_set["$v"]=1; done
  for v in "${all_versions[@]}"; do
    if [[ -z "${existing_set[$v]:-}" ]] && ver_ge "$v" "$earliest"; then
      missing+=("$v")
    fi
  done
fi

if ((${#missing[@]} == 0)); then
  echo "All versions are up to date!"
else
  echo "Found ${#missing[@]} missing version(s): ${missing[*]}"
  for v in "${missing[@]}"; do
    echo "Processing $v..."
    if process_version "$v"; then
      echo "  Added $v"
    fi
  done
fi

echo "Done!"

# Final line for CI consumption
echo "$latest_version"
