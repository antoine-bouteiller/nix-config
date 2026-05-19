{
  rustPlatform,
  fetchFromGitHub,
  nix-update,
  writeShellScript,
}:
rustPlatform.buildRustPackage rec {
  pname = "comment-checker";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "code-yeongyu";
    repo = "go-claude-code-comment-checker";
    rev = "v${version}";
    hash = "sha256-rV51+vo+6BEU3vh4/WVZxRbNXmvqyrAjMwl872+4MW0=";
  };

  cargoHash = "sha256-OieMIlyo4ENmakJIiqHVwSF7wk96TN15FnjbrVYTyaA=";

  doCheck = false;

  passthru.updateScript = writeShellScript "${pname}-update" ''
    exec ${nix-update}/bin/nix-update --flake
  '';
}
