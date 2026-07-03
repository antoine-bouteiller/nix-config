#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell -c nu

const repo = "dmtrKovalenko/fff"
const platforms = {
  "aarch64-darwin": "aarch64-apple-darwin"
  "x86_64-linux": "x86_64-unknown-linux-gnu"
  "aarch64-linux": "aarch64-unknown-linux-gnu"
}

def root_dir []: nothing -> string {
  $env.FILE_PWD
}

def fetch_latest_tag []: nothing -> string {
  http get $"https://api.github.com/repos/($repo)/releases/latest"
  | get tag_name
}

def main [] {
  let sources_path = root_dir | path join "sources.json"
  let current_version = open $sources_path | get version
  let latest_tag = fetch_latest_tag
  let latest_version = $latest_tag | str replace -r '^v' ''

  print $"Current version: ($current_version)"
  print $"Latest version:  ($latest_version)"

  if $current_version == $latest_version {
    print "Already up to date."
    return
  }

  let base = $"https://github.com/($repo)/releases/download/($latest_tag)"

  mut platforms_data = {}
  for platform in ($platforms | transpose nix_platform target) {
    let url = $"($base)/fff-mcp-($platform.target)"
    let hex = http get $"($url).sha256" | str trim | split row " " | first
    let hash = nix hash convert --hash-algo sha256 $hex | str trim
    $platforms_data = $platforms_data | insert $platform.nix_platform {url: $url, hash: $hash}
    print $"  ($platform.nix_platform): ($hash)"
  }

  { version: $latest_version, platforms: $platforms_data }
  | to json --indent 2
  | $"($in)\n"
  | save --force $sources_path

  print $"Updated fff-mcp to version ($latest_version)"
}
