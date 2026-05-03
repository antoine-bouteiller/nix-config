{
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [inputs.cosmic-manager.homeManagerModules.cosmic-manager];

  config = lib.mkIf (osConfig.desktop.enable or false) {
    wayland.desktopManager.cosmic = {
      enable = true;

      applets.app-list = {
        settings = {
          favorites = [
            "ghostty"
            "brave-browser"
            "zed"
            "plex-desktop"
            "telegram"
          ];
        };
      };

      panels = [
        {
          name = "Panel";
          anchor = {
            __type = "enum";
            variant = "Top";
          };
          expand_to_edges = true;
          anchor_gap = false;
          margin = 0;
          opacity = 0.8;
          size = {
            __type = "enum";
            variant = "XS";
          };
          plugins_center = {
            __type = "optional";
            value = ["com.system76.CosmicAppletTime"];
          };
          plugins_wings = {
            __type = "optional";
            value = {
              __type = "tuple";
              value = [
                [
                  "com.system76.CosmicPanelWorkspacesButton"
                  "com.system76.CosmicPanelAppButton"
                ]
                [
                  "com.system76.CosmicAppletStatusArea"
                  "com.system76.CosmicAppletAudio"
                  "com.system76.CosmicAppletNetwork"
                  "com.system76.CosmicAppletNotifications"
                  "com.system76.CosmicAppletBattery"
                  "com.system76.CosmicAppletPower"
                ]
              ];
            };
          };
        }
        {
          name = "Dock";
          anchor = {
            __type = "enum";
            variant = "Bottom";
          };
          expand_to_edges = false;
          anchor_gap = true;
          margin = 8;
          opacity = 0.6;
          size = {
            __type = "enum";
            variant = "M";
          };
          plugins_center = {
            __type = "optional";
            value = ["com.system76.CosmicAppList" "com.system76.CosmicAppletWorkspace"];
          };
          plugins_wings = {
            __type = "optional";
            value = {
              __type = "tuple";
              value = [[] []];
            };
          };
          autohide = {
            __type = "optional";
            value = {
              handle_size = 4;
              transition_time = 200;
              wait_time = 1000;
            };
          };
        }
      ];

      compositor.active_hint = false;

      shortcuts = [
        {
          key = "Alt+Space";
          action = {
            __type = "enum";
            variant = "System";
            value = [
              {
                __type = "enum";
                variant = "Launcher";
              }
            ];
          };
        }
      ];

      appearance.toolkit = {
        monospace_font = {
          family = "JetBrainsMono Nerd Font";
          stretch = {
            __type = "enum";
            variant = "Normal";
          };
          style = {
            __type = "enum";
            variant = "Normal";
          };
          weight = {
            __type = "enum";
            variant = "Normal";
          };
        };
      };
    };

    gtk = {
      enable = true;
      gtk2.force = true;
      iconTheme = {
        name = "WhiteSur";
        package = customPkgs.whitesur-icon-theme;
      };
    };

    home.packages = [
      pkgs.nixos-icons
    ];
  };
}
