{
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm,
  pnpmConfigHook,
  makeWrapper,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "1mcp";
  version = "0.31.0";

  src = fetchFromGitHub {
    owner = "1mcp-app";
    repo = "agent";
    rev = "v${finalAttrs.version}";
    hash = "sha256-48Z/VLgQl5RoRhiOhXW98rtD+tX3Jd1Jc0aI6cIOUu8=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    makeWrapper
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-jLd1CO5Wbgq3NUuDHqFJEuxg3aJd1hRL6jkm9AVzLWw=";
    fetcherVersion = 3;
  };

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/1mcp $out/bin
    cp -r build node_modules package.json $out/lib/1mcp/
    makeWrapper ${nodejs}/bin/node $out/bin/1mcp \
      --add-flags "$out/lib/1mcp/build/index.js"

    runHook postInstall
  '';

  meta = {
    description = "One MCP server to aggregate them all";
    homepage = "https://github.com/1mcp-app/agent";
    mainProgram = "1mcp";
  };
})
