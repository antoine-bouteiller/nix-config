#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Validates that every non-empty line in $1 matches $2 — guards against
# captive portals, HTML error pages, or other malformed responses.
fetch_ips() {
  local family=$1
  local pattern=$2
  local target="$SCRIPT_DIR/cloudflare-ips-${family}.txt"

  local new
  new=$(curl -sf --retry 3 --max-time 30 "https://www.cloudflare.com/ips-${family}")

  if [[ -z "$new" ]]; then
    echo "ERROR: empty response from cloudflare.com/ips-${family}" >&2
    return 1
  fi

  printf '%s\n' "$new" > "$target.tmp"

  if grep -qvE "${pattern}|^$" "$target.tmp"; then
    echo "ERROR: cloudflare ${family} response contains non-CIDR lines" >&2
    rm -f "$target.tmp"
    return 1
  fi

  mv "$target.tmp" "$target"
  echo "Wrote $(wc -l < "$target") prefixes to $target"
}

fetch_ips v4 '^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$'
fetch_ips v6 '^[0-9a-fA-F:]+/[0-9]+$'
