{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.vite-plus;
  home = config.home.homeDirectory;
  vpNix = "${pkgs.vite-plus}/bin/vp";
  installDir = "${home}/.vite-plus";
  vpBin = "${installDir}/bin/vp";
  version = pkgs.vite-plus.version;
  versionDir = "${installDir}/${version}";
in {
  options.programs.vite-plus = {
    enable = lib.mkEnableOption "Vite+ unified web development toolchain";

    manageNode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether Vite+ manages the global Node.js runtime and package manager.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Set up the vite-plus directory structure and run vp install
    home.activation.setupVitePlus = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create directory structure
      run mkdir -p "${installDir}/bin" "${versionDir}"

      # Copy the binary so vp resolves node_modules relative to ~/.vite-plus
      run rm -f "${vpBin}"
      run cp "${vpNix}" "${vpBin}"
      run chmod +x "${vpBin}"

      # Create package.json and install deps at root so vp finds node_modules
      if [ ! -d "${installDir}/node_modules/vite-plus" ]; then
        cat > "${installDir}/package.json" <<WRAPPER_EOF
      {
        "dependencies": {
          "vite-plus": "${version}"
        }
      }
      WRAPPER_EOF
        run --quiet bash -c 'cd "${installDir}" && CI=true "${vpBin}" install --silent'
      fi

      # Generate env files
      run --quiet "${vpBin}" env setup --env-only

      ${lib.optionalString (!cfg.manageNode) ''
        run --quiet "${vpBin}" env off
      ''}
    '';

    # Source the vite-plus environment in zsh
    programs.zsh.initContent = ''
      # Vite+
      [[ -f "$HOME/.vite-plus/env" ]] && . "$HOME/.vite-plus/env"
    '';
  };
}
