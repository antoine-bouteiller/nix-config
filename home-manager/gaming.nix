{
  osConfig,
  lib,
  ...
}: {
  config = lib.mkIf (osConfig.gaming.enable or false) {
    home.activation.fixSteamIcons = lib.hm.dag.entryAfter ["writeBoundary"] ''
      for f in ~/.local/share/applications/*.desktop; do
        id=$(grep -Eo 'steam://rungameid/[0-9]+' "$f" | sed 's#.*/##') || true
        [ -n "$id" ] || continue
        last=$(tail -n1 "$f" || true)
        want="StartupWMClass=steam_app_$id"
        [ "$last" = "$want" ] || echo "$want" >> "$f"
      done
    '';
  };
}
