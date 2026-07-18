#!/usr/bin/env nix
#! nix shell --inputs-from . nixpkgs#nushell -c nu

const github_repo = "azahar-emu/azahar"
const fake_hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

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

def set_sources [version: string, hash: string] {
  let sources_path = root_dir | path join "sources.json"
  open $sources_path
  | update version $version
  | update hash $hash
  | save --force $sources_path
}

def main [] {
  let sources_path = root_dir | path join "sources.json"
  let sources = open $sources_path
  let current_version = $sources.version
  let current_hash = $sources.hash
  let latest_version = fetch_latest_version

  print $"Current version: ($current_version)"
  print $"Latest version:  ($latest_version)"

  if $current_version == $latest_version {
    print $"retroarch ($latest_version) already up to date"
    return
  }

  set_sources $latest_version $fake_hash

  print "Building to compute new hash..."
  let system = (nix eval --raw --impure --expr "builtins.currentSystem" | str trim)
  let build = (do {
    nix build $".#packages.($system).retroarch" --no-link --impure
  } | complete)

  print $build.stdout
  print $build.stderr

  let candidates = ($build.stdout + $build.stderr
    | parse --regex '(?<hash>sha256-[A-Za-z0-9+/=]{44})'
    | get hash
    | where $it != $fake_hash)

  if ($candidates | is-empty) {
    print -e "ERROR: Failed to extract new hash"
    # Restore previous sources.json so a failed run doesn't leave fake_hash committed.
    set_sources $current_version $current_hash
    exit 1
  }
  let new_hash = ($candidates | last)

  set_sources $latest_version $new_hash
  print $"Updated retroarch to version ($latest_version) \(hash: ($new_hash)\)"
}
