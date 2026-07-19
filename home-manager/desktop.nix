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

    # runAsService wires up the walker + elephant systemd user services for
    # fast shortcut-based launching.
    programs.walker = {
      enable = true;
      runAsService = true;
      config.theme = "raycast";
      themes.raycast.style = ''
        /* ================= */
        /* COLORS */
        /* ================= */

        @define-color bg #1c1c1f;
        @define-color bg2 #242427;
        @define-color border #2e2e33;

        @define-color text #e6e6e6;
        @define-color muted #8e8e93;

        @define-color accent #3b82f6;


        /* ================= */
        /* RESET */
        /* ================= */

        *{ all:unset; }

        *{
          color:@text;
          font-family: Inter, JetBrains Mono, monospace;
          font-size:16px;
        }

        scrollbar{ opacity:0; }


        /* ================= */
        /* MAIN WINDOW */
        /* ================= */

        .box-wrapper{
          background:@bg;
          border-radius:16px;
          border:1px solid @border;
          padding:18px;
          min-width:650px;
        }


        /* ================= */
        /* SEARCH BAR */
        /* ================= */

        .search-container{
          background:@bg2;
          border-radius:12px;
          padding:14px;
        }


        /* ================= */
        /* INPUT */
        /* ================= */

        .input{
          font-size:18px;
        }

        .input placeholder{
          color:@muted;
        }

        .input:focus,
        .input:active{
          outline:none;
          box-shadow:none;
        }


        /* ================= */
        /* CENTER RESULTS */
        /* ================= */

        .list{
          padding-top:12px;
        }

        /* center each item */
        .item-box{
          padding:14px;
          border-radius:10px;
          transition:
            transform 140ms ease,
            background 140ms ease,
            opacity 140ms ease;
        }


        /* hover animation */
        child:hover .item-box{
          background:@bg2;
          transform: scale(1.02);
        }


        /* selected animation */
        child:selected .item-box{
          background:@bg2;
          transform: scale(1.04);
        }


        /* ================= */
        /* ICON */
        /* ================= */

        .item-image{
          margin-right:12px;
          -gtk-icon-transform: scale(1.1);
        }


        /* ================= */
        /* TEXT */
        /* ================= */

        .item-text{
          font-weight:500;
        }

        .item-subtext{
          color:@muted;
          font-size:12px;
        }
      '';
    };
  };
}
