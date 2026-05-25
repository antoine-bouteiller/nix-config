#!/usr/bin/env bash
set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

readonly GITHUB_REPO="openai/codex"
readonly NPM_REGISTRY_URL="https://registry.npmjs.org"
readonly NPM_PACKAGE_NAME="@openai/codex"
readonly GITHUB_RELEASE_BASE="https://github.com/${GITHUB_REPO}/releases/download"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly SOURCES_FILE="$SCRIPT_DIR/sources.json"

readonly NATIVE_PLATFORMS=("aarch64-apple-darwin" "x86_64-apple-darwin" "x86_64-unknown-linux-musl" "aarch64-unknown-linux-musl")
readonly NODE_PLATFORMS=("darwin-arm64" "darwin-x64" "linux-x64" "linux-arm64")

TARGET_VERSION=""
CHECK_ONLY=false

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

get_current_version() {
    if [[ -f "$SOURCES_FILE" ]]; then
        jq -r '.version // "unknown"' "$SOURCES_FILE"
    else
        echo "unknown"
    fi
}

get_latest_version() {
    local tag
    tag=$(gh release view --repo "$GITHUB_REPO" --json tagName -q '.tagName' 2>/dev/null || echo "")
    if [[ -z "$tag" ]]; then
        log_error "Failed to fetch latest version from GitHub"
        exit 1
    fi
    echo "$tag" | sed 's/^rust-v//'
}

prefetch_url() {
    local url="$1"
    local hash
    hash=$(nix-prefetch-url "$url" 2>/dev/null | tail -1)
    echo "$hash" | tr -d '\n'
}

fetch_native_hash() {
    local version="$1"
    local platform="$2"
    prefetch_url "${GITHUB_RELEASE_BASE}/rust-v${version}/codex-${platform}.tar.gz"
}

fetch_npm_hash() {
    local version="$1"
    prefetch_url "${NPM_REGISTRY_URL}/${NPM_PACKAGE_NAME}/-/codex-${version}.tgz"
}

fetch_node_optional_dep_hash() {
    local version="$1"
    local platform="$2"
    prefetch_url "${GITHUB_RELEASE_BASE}/rust-v${version}/codex-npm-${platform}-${version}.tgz"
}

write_sources_json() {
    local version="$1"
    local npm_hash="$2"
    local native_hashes="$3"
    local node_optional_dep_hashes="$4"
    local temp_file

    temp_file=$(mktemp)
    jq -n \
        --arg version "$version" \
        --arg npmTarballHash "$npm_hash" \
        --argjson nativeHashes "$native_hashes" \
        --argjson nodeOptionalDepHashes "$node_optional_dep_hashes" \
        '{
          version: $version,
          nativeHashes: $nativeHashes,
          npmTarballHash: $npmTarballHash,
          nodeOptionalDepHashes: $nodeOptionalDepHashes
        }' > "$temp_file"
    mv "$temp_file" "$SOURCES_FILE"
}

update_to_version() {
    local new_version="$1"
    local native_hashes="{}"
    local node_optional_dep_hashes="{}"

    log_info "Updating to version $new_version..."

    log_info "Fetching native binary hashes..."
    for platform in "${NATIVE_PLATFORMS[@]}"; do
        log_info "  Fetching hash for $platform..."
        local native_hash
        native_hash=$(fetch_native_hash "$new_version" "$platform")
        if [[ -z "$native_hash" ]]; then
            log_error "Failed to fetch native hash for $platform"
            exit 1
        fi
        log_info "  $platform: $native_hash"
        native_hashes=$(jq \
            --arg platform "$platform" \
            --arg hash "$native_hash" \
            '.[$platform] = $hash' <<< "$native_hashes")
    done

    log_info "Fetching npm tarball hash..."
    local npm_hash
    npm_hash=$(fetch_npm_hash "$new_version")
    if [[ -z "$npm_hash" ]]; then
        log_error "Failed to fetch npm tarball hash"
        exit 1
    fi
    log_info "NPM tarball hash: $npm_hash"

    log_info "Fetching node platform-specific dependency hashes..."
    for node_platform in "${NODE_PLATFORMS[@]}"; do
        log_info "  Fetching hash for $node_platform..."
        local node_dep_hash
        node_dep_hash=$(fetch_node_optional_dep_hash "$new_version" "$node_platform")
        if [[ -z "$node_dep_hash" ]]; then
            log_error "Failed to fetch node optional dep hash for $node_platform"
            exit 1
        fi
        log_info "  $node_platform: $node_dep_hash"
        node_optional_dep_hashes=$(jq \
            --arg platform "$node_platform" \
            --arg hash "$node_dep_hash" \
            '.[$platform] = $hash' <<< "$node_optional_dep_hashes")
    done

    write_sources_json "$new_version" "$npm_hash" "$native_hashes" "$node_optional_dep_hashes"

    log_info "Verifying builds..."

    log_info "  Building codex (native)..."
    if ! nix build "$REPO_ROOT#codex" > /dev/null 2>&1; then
        log_error "Native build verification failed"
        return 1
    fi

    log_info "  Building codex-node..."
    if ! nix build "$REPO_ROOT#codex-node" > /dev/null 2>&1; then
        log_error "Node build verification failed"
        return 1
    fi

    log_info "All builds successful."
    return 0
}

ensure_in_repository_root() {
    if [[ ! -f "$REPO_ROOT/flake.nix" ]] || [[ ! -f "$SOURCES_FILE" ]]; then
        log_error "Could not locate flake.nix or pkgs/codex/sources.json."
        exit 1
    fi
}

ensure_required_tools_installed() {
    command -v gh >/dev/null 2>&1 || { log_error "gh (GitHub CLI) is required but not installed."; exit 1; }
    command -v jq >/dev/null 2>&1 || { log_error "jq is required but not installed."; exit 1; }
    command -v nix >/dev/null 2>&1 || { log_error "nix is required but not installed."; exit 1; }
    command -v nix-prefetch-url >/dev/null 2>&1 || { log_error "nix-prefetch-url is required but not installed."; exit 1; }
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --version VERSION  Update to specific version"
    echo "  --check            Only check for updates, don't apply"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Update to latest version"
    echo "  $0 --check            # Check if update is available"
    echo "  $0 --version 0.133.0  # Update to specific version"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                if [[ $# -lt 2 ]]; then
                    log_error "--version requires a value"
                    exit 1
                fi
                TARGET_VERSION="$2"
                shift 2
                ;;
            --check)
                CHECK_ONLY=true
                shift
                ;;
            --help)
                print_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
}

show_changes() {
    echo ""
    log_info "Changes made:"
    git -C "$REPO_ROOT" diff --stat pkgs/codex/sources.json flake.lock 2>/dev/null || true
}

main() {
    parse_arguments "$@"
    ensure_in_repository_root
    ensure_required_tools_installed

    local current_version
    current_version=$(get_current_version)
    local latest_version
    latest_version=$(get_latest_version)

    if [[ -n "$TARGET_VERSION" ]]; then
        latest_version="$TARGET_VERSION"
    fi

    log_info "Current version: $current_version"
    log_info "Latest version: $latest_version"

    if [[ "$current_version" = "$latest_version" ]]; then
        log_info "Already up to date!"
        exit 0
    fi

    if [[ "$CHECK_ONLY" = true ]]; then
        log_info "Update available: $current_version -> $latest_version"
        exit 1
    fi

    update_to_version "$latest_version"

    log_info "Successfully updated codex from $current_version to $latest_version"
    show_changes
}

main "$@"
