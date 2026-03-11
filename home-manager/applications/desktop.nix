{pkgs, ...}: {
  # Use a dark theme
  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
  };

  # Hyprland configuration
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";

      monitor = ",preferred,auto,1";

      input = {
        kb_layout = "us";
        kb_options = "ctrl:nocaps";
        follow_mouse = 1;
        touchpad.natural_scroll = true;
      };

      general = {
        gaps_in = 8;
        gaps_out = 16;
        border_size = 2;
        "col.active_border" = "rgba(546e7aee)";
        "col.inactive_border" = "rgba(1f1f1faa)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 12;
        blur = {
          enabled = true;
          size = 8;
          passes = 2;
        };
        shadow = {
          enabled = true;
          range = 8;
          render_power = 2;
        };
        inactive_opacity = 0.8;
        active_opacity = 1.0;
      };

      animations = {
        enabled = true;
        bezier = "ease, 0.25, 0.1, 0.25, 1";
        animation = [
          "windows, 1, 4, ease, slide"
          "windowsOut, 1, 4, ease, slide"
          "fade, 1, 4, ease"
          "workspaces, 1, 4, ease, slide"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, Q, killactive"
        "$mod, F, fullscreen"
        "$mod, D, togglefloating"
        "$mod, Space, exec, wofi --show drun"
        "$mod CTRL, L, exec, swaylock -f"

        # Move focus (vim-like)
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # Move windows
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"

        # Move to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"

        # Screenshots
        '', Print, exec, grim -g "$(slurp)" - | wl-copy''
        ''SHIFT, Print, exec, grim - | wl-copy''
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      exec-once = [
        "waybar"
        "mako"
      ];
    };
  };

  # Notification daemon (Wayland-native)
  services = {
    mako = {
      enable = true;
      settings = {
        font = "Noto Sans 10";
        background-color = "#1f1f1fdd";
        text-color = "#ffffff";
        border-color = "#546e7a";
        border-radius = 8;
        default-timeout = 5000;
      };
    };

    # Auto mount devices
    udiskie.enable = true;
  };

  programs = {
    # Swaylock (screen locker for Wayland)
    swaylock = {
      enable = true;
      settings = {
        color = "1f1f1f";
        show-failed-attempts = true;
      };
    };

    # Waybar (status bar)
    waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 40;
          margin-top = 8;
          margin-left = 16;
          margin-right = 16;
          modules-left = ["hyprland/workspaces"];
          modules-center = ["clock"];
          modules-right = ["pulseaudio" "memory" "cpu" "tray"];

          "hyprland/workspaces" = {
            format = "{id}";
          };
          clock = {
            format = "{:%a %b %d  %H:%M}";
            tooltip-format = "{:%Y-%m-%d}";
          };
          pulseaudio = {
            format = "VOL {volume}%";
            format-muted = "MUTED";
          };
          memory = {
            format = "MEM {}%";
            interval = 5;
          };
          cpu = {
            format = "CPU {usage}%";
            interval = 5;
          };
        };
      };
      style = ''
        * {
          font-family: "JetBrains Mono", "Font Awesome 6 Free";
          font-size: 13px;
          color: #ffffff;
        }

        window#waybar {
          background: rgba(31, 31, 31, 0.9);
          border-radius: 8px;
        }

        #workspaces button {
          padding: 0 8px;
          color: #888888;
        }

        #workspaces button.active {
          color: #ffffff;
          background: rgba(84, 110, 122, 0.6);
          border-radius: 4px;
        }

        #clock, #pulseaudio, #memory, #cpu, #tray {
          padding: 0 12px;
        }
      '';
    };
  };
}
