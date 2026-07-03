_: {
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.byparr = {
      # renovate: datasource=docker depName=ghcr.io/thephaseless/byparr
      image = "ghcr.io/thephaseless/byparr@sha256:01a46a2865d9a6db5eb8ead04ec0dd33b8fbe233e8565ae70b50d4cc0af4cfb0"; # latest
      autoStart = true;
      ports = ["127.0.0.1:8191:8191"];
      extraOptions = ["--init"];
    };
  };
}
