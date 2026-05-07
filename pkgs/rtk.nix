{
  lib,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  jq,
  nix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "rtk";
  version = "0.39.0";

  src = fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    rev = "v${version}";
    hash = "sha256-TX4MtR/rq61wxHWYJAO2x3CYvZtkCoXynf45dRC+MVo=";
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

  passthru.updateScript = nix-update-script {
    extraArgs = ["--flake"];
  };

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
