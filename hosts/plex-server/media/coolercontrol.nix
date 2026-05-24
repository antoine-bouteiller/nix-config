_: let
  constants = import ./constants.nix;
in {
  programs.coolercontrol.enable = true;

  local.media.coolercontrol = {
    port = constants.coolercontrol.port;
    auth = true;
  };
}
