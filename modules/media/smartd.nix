{
  pkgs,
  config,
  ...
}: let
  cfg = config.mediaServer;
  smartdWebhook = pkgs.writeShellScript "smartd-webhook" ''
        ALERT_TEXT="SMART Disk Warning
    Device: $SMARTD_DEVICE
    Event: $SMARTD_FAILTYPE
    Details: $SMARTD_MESSAGE"

        PAYLOAD=$(${pkgs.jq}/bin/jq -n \
          --arg msg "$ALERT_TEXT" \
          '{ "text": $msg }')

        ${pkgs.curl}/bin/curl -s -X POST \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD" \
          "https://localhost:${toString cfg.autoscan.port}/send-message" > /dev/null
  '';
in {
  services.smartd = {
    enable = true;
    autodetect = true;
    defaults.monitored = "-a -o on -s (S/../.././02|L/../../6/03) -m <nomailer> -M exec ${smartdWebhook}";
    notifications.mail.enable = false;
  };
}
