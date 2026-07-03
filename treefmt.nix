{pkgs, ...}: {
  projectRootFile = ".git/config";

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;
    typos = {
      enable = true;
      excludes = ["*.svg" "hosts/*/secrets/*.yaml"];
    };
    oxfmt.enable = true;
  };

  settings.formatter.renovate-config-validator = {
    command = "${pkgs.renovate}/bin/renovate-config-validator";
    options = ["--strict"];
    includes = ["renovate.json"];
  };
}
