{
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
}: let
  version = "0.8.0";

  # comment-checker links tree-sitter-language-pack, whose build.rs fetches its
  # parser grammars at build time from a GitHub release tagged with the crate's
  # own version (the URL is built from CARGO_PKG_VERSION). The Nix sandbox has no
  # network, so we pre-fetch that release and hand it over via
  # TSLP_SOURCE_BUNDLE_URL.
  #
  # tslpVersion MUST equal the tree-sitter-language-pack version pinned in
  # comment-checker's Cargo.lock — a mismatch fetches the wrong grammars (or a
  # 404). ./update.nu re-derives both values below from Cargo.lock on every
  # `version` bump, so `nix run .#update` can never leave a stale parser bundle
  # behind. Do not edit these two lines by hand; run the update script instead.
  tslpVersion = "1.8.1";
  parserSourcesHash = "sha256-Kcds8n8X7dE5gRhVPd3pvouemXDAAXs4fFNGbPLkhxc=";

  parserSources = fetchurl {
    url = "https://github.com/kreuzberg-dev/tree-sitter-language-pack/releases/download/v${tslpVersion}/parser-sources-${tslpVersion}.tar.zst";
    hash = parserSourcesHash;
  };
in
  rustPlatform.buildRustPackage {
    pname = "comment-checker";
    inherit version;

    src = fetchFromGitHub {
      owner = "code-yeongyu";
      repo = "go-claude-code-comment-checker";
      rev = "v${version}";
      hash = "sha256-rV51+vo+6BEU3vh4/WVZxRbNXmvqyrAjMwl872+4MW0=";
    };

    cargoHash = "sha256-OieMIlyo4ENmakJIiqHVwSF7wk96TN15FnjbrVYTyaA=";

    env.TSLP_SOURCE_BUNDLE_URL = "file://${parserSources}";

    doCheck = false;

    passthru = {
      inherit tslpVersion;
      updateScript = ./update.nu;
    };
  }
