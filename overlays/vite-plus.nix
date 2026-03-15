final: prev: {
  vite-plus = prev.stdenv.mkDerivation rec {
    pname = "vite-plus";
    version = "0.1.11";

    src = let
      platform =
        {
          "aarch64-darwin" = "darwin-arm64";
          "x86_64-darwin" = "darwin-x64";
          "x86_64-linux" = "linux-x64-gnu";
          "aarch64-linux" = "linux-arm64-gnu";
        }
        .${
          prev.stdenv.hostPlatform.system
        };
      hash =
        {
          "aarch64-darwin" = "sha256-1HOZiB5YME5z17zT77igxn2JvOd4XF5cQFrstpty/Sg=";
          "x86_64-darwin" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          "x86_64-linux" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          "aarch64-linux" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        }
        .${
          prev.stdenv.hostPlatform.system
        };
    in
      prev.fetchurl {
        url = "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-${platform}/-/vite-plus-cli-${platform}-${version}.tgz";
        inherit hash;
      };

    sourceRoot = ".";

    unpackPhase = ''
      tar xzf $src --strip-components=1
    '';

    installPhase = ''
      install -Dm755 vp $out/bin/vp
    '';

    dontFixup = true;

    meta = {
      description = "Vite+ unified web development toolchain CLI";
      homepage = "https://viteplus.dev";
      platforms = ["aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux"];
      mainProgram = "vp";
    };
  };
}
