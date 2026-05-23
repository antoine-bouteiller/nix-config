_: let
  constants = import ./constants.nix;
in {
  local.media.coolercontrol.localDns = {
    enable = true;
    port = constants.coolercontrol.port;
  };

  programs.coolercontrol.enable = true;
}
