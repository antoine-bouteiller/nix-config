{...}: let
  constants = import ./constants.nix;
in {
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.byparr = {
      image = "ghcr.io/thephaseless/byparr:latest";
      autoStart = true;
      ports = ["127.0.0.1:${toString constants.byparr.port}:8191"];
      extraOptions = ["--init"];
    };
  };
}
