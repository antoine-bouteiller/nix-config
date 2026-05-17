{
  lib,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  jq,
  nix-update,
  writeShellScript,
}:
rustPlatform.buildRustPackage rec {
  pname = "rtk";
  version = "0.40.0";

  src = fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    rev = "v${version}";
    hash = "sha256-xWHIOZRpSyyOPQe/db9dxoODcnheBlpXrnKET010vVg=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = [makeWrapper];

  doCheck = false;

  postInstall = ''
    mkdir -p $out/libexec/rtk
    cp -r $src/hooks $out/libexec/rtk/hooks
    chmod -R +w $out/libexec/rtk/hooks
    find $out/libexec/rtk/hooks -name '*.sh' -exec chmod 755 {} \;
    for f in $(find $out/libexec/rtk/hooks -name '*.sh'); do
      wrapProgram "$f" \
        --prefix PATH : ${lib.makeBinPath [jq]}:$out/bin
    done
  '';

  passthru.updateScript = writeShellScript "${pname}-update" ''
    exec ${nix-update}/bin/nix-update --flake
  '';

  meta = with lib; {
    description = "CLI proxy that reduces LLM token consumption by 60-90% on common dev commands";
    homepage = "https://github.com/rtk-ai/rtk";
    changelog = "https://github.com/rtk-ai/rtk/releases/tag/v${version}";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [fromSource];
    mainProgram = "rtk";
    platforms = platforms.unix;
  };
}
