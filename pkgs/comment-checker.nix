{
  buildGoModule,
  fetchFromGitHub,
  nix-update,
  writeShellScript,
}:
buildGoModule rec {
  pname = "comment-checker";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "code-yeongyu";
    repo = "go-claude-code-comment-checker";
    rev = "v${version}";
    hash = "sha256-RyZlVPJ+G3Vvt5Mhja7mxSe8bd+BfsYqbbrfqjjCbYE=";
  };

  vendorHash = "sha256-cW/cWo6k7aA/Z2w6+CBAdNKhEiWN1cZiv/hl2Mto6Gw=";

  proxyVendor = true;

  doCheck = false;

  passthru.updateScript = writeShellScript "${pname}-update" ''
    exec ${nix-update}/bin/nix-update --flake
  '';
}
