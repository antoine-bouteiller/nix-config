{
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "rtk";
  version = "0.34.0";

  src = fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    rev = "v${version}";
    hash = "sha256-jPV0/rROaZdVn8gLhhZIhI0ZqMfSvRnNxplYYuboJeE=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  doCheck = false;

  meta = {
    description = "High-performance CLI proxy to reduce LLM token consumption";
    homepage = "https://github.com/rtk-ai/rtk";
    mainProgram = "rtk";
  };
}
