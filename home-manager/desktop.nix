{
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    inputs.cosmic-manager.homeManagerModules.cosmic-manager
    inputs.walker.homeManagerModules.default
  ];

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
            value = [
              "com.system76.CosmicAppList"
              "com.system76.CosmicAppletWorkspace"
            ];
          };
          plugins_wings = {
            __type = "optional";
            value = {
              __type = "tuple";
              value = [
                []
                []
              ];
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

      compositor = {
        active_hint = false;

        # COSMIC deserializes input_touchpad as one whole struct; omitting the
        # required top-level `state` field makes cosmic-comp/cosmic-settings
        # reject the file and fall back to defaults (i.e. the settings appear to
        # reset). Mirror the exact struct COSMIC writes itself.
        input_touchpad = {
          state = {
            __type = "enum";
            variant = "Enabled";
          };
          click_method = {
            __type = "optional";
            value = {
              __type = "enum";
              variant = "Clickfinger";
            };
          };
          tap_config = {
            __type = "optional";
            value = {
              enabled = true;
              button_map = {
                __type = "optional";
                value = {
                  __type = "enum";
                  variant = "LeftRightMiddle";
                };
              };
              drag = true;
              drag_lock = false;
            };
          };
          scroll_config = {
            __type = "optional";
            value = {
              method = {
                __type = "optional";
                value = {
                  __type = "enum";
                  variant = "TwoFinger";
                };
              };
              natural_scroll = {
                __type = "optional";
                value = true;
              };
              scroll_button = {
                __type = "optional";
                value = null;
              };
              scroll_factor = {
                __type = "optional";
                value = null;
              };
            };
          };
        };
      };

      shortcuts = [
        {
          key = "Alt+Space";
          action = {
            __type = "enum";
            variant = "Spawn";
            value = ["walker"];
          };
        }
        {
          key = "Alt+Ctrl+Q";
          action = {
            __type = "enum";
            variant = "System";
            value = [
              {
                __type = "enum";
                variant = "LockScreen";
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

    # walker's flake module installs walker + elephant and, with runAsService,
    # wires up both systemd user services (walker --gapplication-service, which
    # Requires the elephant backend) for fast shortcut-based launching.
    programs.walker = {
      enable = true;
      runAsService = true;
    };
  };
}
