_: let
  constants = import ./constants.nix;
in {
  programs.coolercontrol.enable = true;

  local.media.coolercontrol.localDns = {
    enable = true;
    port = constants.coolercontrol.port;
    auth = true;
  };
}
