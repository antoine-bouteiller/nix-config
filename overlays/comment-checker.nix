{comment-checker-src}: final: prev: {
  comment-checker = prev.buildGoModule {
    pname = "comment-checker";
    version = "unstable";

    src = comment-checker-src;
    vendorHash = "sha256-cW/cWo6k7aA/Z2w6+CBAdNKhEiWN1cZiv/hl2Mto6Gw=";

    proxyVendor = true;

    doCheck = false;
  };
}
