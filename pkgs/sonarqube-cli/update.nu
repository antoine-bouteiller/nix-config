#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell -c nu

const base_url = "https://binaries.sonarsource.com/Distribution/sonarqube-cli"
const platforms = {
  "aarch64-darwin": "macos/sonarqube-cli-VERSION-macos-arm64"
  "x86_64-linux": "linux/sonarqube-cli-VERSION-linux-x86-64"
  "aarch64-linux": "linux/sonarqube-cli-VERSION-linux-arm64"
}

def root_dir []: nothing -> string {
  # When run as a flake updateScript, FILE_PWD is the read-only /nix/store
  # copy — write to the git checkout (CWD = repo root) instead.
  if ($env.FILE_PWD | str starts-with "/nix/store") {
    $env.PWD | path join "pkgs" ($env.FILE_PWD | path basename)
  } else {
    $env.FILE_PWD
  }
}

def fetch_latest_version []: nothing -> string {
  http get "https://api.github.com/repos/SonarSource/sonarqube-cli/releases/latest"
  | get tag_name
}

def prefetch_hash [url: string]: nothing -> string {
  let hex = nix-prefetch-url --type sha256 $url | lines | last
  nix hash convert --hash-algo sha256 --to sri $hex | str trim
}

def main [] {
  let sources_path = root_dir | path join "sources.json"
  let current_version = open $sources_path | get version
  let latest_version = fetch_latest_version

  print $"Current version: ($current_version)"
  print $"Latest version:  ($latest_version)"

  if $current_version == $latest_version {
    print "Already up to date."
    return
  }

  print $"Updating sonarqube-cli from ($current_version) to ($latest_version)"

  mut platforms_data = {}
  for platform in ($platforms | transpose nix_platform path_template) {
    let path = $platform.path_template | str replace "VERSION" $latest_version
    let bin_url = $"($base_url)/($latest_version)/($path).bin"
    let entry = try {
      {url: $bin_url, hash: (prefetch_hash $bin_url)}
    } catch {
      let exe_url = $"($base_url)/($latest_version)/($path).exe"
      {url: $exe_url, hash: (prefetch_hash $exe_url)}
    }
    $platforms_data = $platforms_data | insert $platform.nix_platform $entry
    print $"  ($platform.nix_platform): ($entry.hash)"
  }

  { version: $latest_version, platforms: $platforms_data }
  | to json --indent 2
  | $"($in)\n"
  | save --force $sources_path

  print $"Updated sonarqube-cli to version ($latest_version)"
}
