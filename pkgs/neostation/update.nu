#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell -c nu

const github_repo = "misobadev/neostation-frontend"

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
  http get $"https://api.github.com/repos/($github_repo)/releases/latest"
  | get tag_name
  | str replace -r '^v' ''
}

def prefetch_hash [version: string, arch: string]: nothing -> string {
  let url = $"https://github.com/($github_repo)/releases/download/v($version)/neostation-linux-($arch)-($version).AppImage"
  nix store prefetch-file --json $url | from json | get hash
}

def main [] {
  let sources_path = root_dir | path join "sources.json"
  let sources = open $sources_path
  let latest_version = fetch_latest_version

  print $"Current version: ($sources.version)"
  print $"Latest version:  ($latest_version)"

  if $sources.version == $latest_version {
    print $"neostation ($latest_version) already up to date"
    return
  }

  let platforms = (
    $sources.platforms
    | transpose system data
    | each {|row|
        print $"Prefetching ($row.data.arch)..."
        {system: $row.system, data: ($row.data | update hash (prefetch_hash $latest_version $row.data.arch))}
      }
    | reduce --fold {} {|row, acc| $acc | insert $row.system $row.data}
  )

  $sources
  | update version $latest_version
  | update platforms $platforms
  | save --force $sources_path

  print $"Updated neostation to version ($latest_version)"
}
