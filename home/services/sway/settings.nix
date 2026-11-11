{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.ar.home;
  focused = config.lib.stylix.colors.withHashtag.base0D;
  helpers = import ../wayland/helpers.nix {inherit config lib pkgs;};
  modifier = "Mod4";
  scripts = import ./scripts.nix {inherit config lib pkgs;};
  unfocused = config.lib.stylix.colors.withHashtag.base03;
  urgent = config.lib.stylix.colors.withHashtag.base08;
in {
  enable = true;
  checkConfig = true;
  wrapperFeatures.gtk = true;
  systemd = {
    enable = true;

    extraCommands = lib.mkDefault [
      "systemctl --user stop sway-session.target"
      "systemctl --user start sway-session.target"
    ];

    variables = ["--all"];
  };

  config = {
    bars = [];
    inherit modifier;
    inherit (cfg.defaultApps) terminal;

    colors = {
      focused.indicator = lib.mkForce focused;
      focusedInactive.indicator = lib.mkForce unfocused;
      placeholder.indicator = lib.mkForce unfocused;
      unfocused.indicator = lib.mkForce unfocused;
      urgent.indicator = lib.mkForce urgent;
    };

    defaultWorkspace = "workspace number 1";

    floating.criteria = [
      {app_id = ".blueman-manager-wrapped";}
      {app_id = "com.github.wwmm.easyeffects";}
      {app_id = "nm-connection-editor";}
      {app_id = "pavucontrol";}
      {app_id = "solaar";}
      {title = "Open File";}
      {title = "Open Folder";}
      {window_role = "bubble";}
      {window_role = "dialog";}
      {window_role = "pop-up";}
      {window_type = "dialog";}
    ];

    focus = {
      followMouse = "always";
      newWindow = "focus";
    };

    gaps = {
      inner = 3;
      outer = 3;
    };

    input = {
      "type:touchpad" = {
        click_method = "clickfinger";
        dwt = "enabled";
        natural_scroll = "enabled";
        scroll_method = "two_finger";
        tap = "enabled";
        tap_button_map = "lrm";
      };

      "type:keyboard" = {
        xkb_layout = "us";
        xkb_variant = "altgr-intl";
      };
    };

    keybindings =
      {
        "${modifier}+B" = "exec ${lib.getExe cfg.defaultApps.webBrowser}";
        "${modifier}+T" = "exec ${lib.getExe pkgs.wlr-randr} --output Unknown-1 --toggle";
        "${modifier}+Shift+Q" = "kill";
        "${modifier}+Comma" = "workspace prev";
        "${modifier}+Shift+X" = "exec ${lib.getExe pkgs.swaylock} -i ${config.home.homeDirectory}/Pictures/wallpaper/wallpaper.jpg";
        "${modifier}+E" = "exec ${lib.getExe cfg.defaultApps.editor}";
        "${modifier}+F" = "fullscreen toggle";
        "${modifier}+F11" = "exec pkill -SIGUSR1 waybar"; # Show/hide waybar
        "${modifier}+M" = ''exec ${lib.getExe config.programs.rofi.package} -show power-menu -modes "power-menu:${lib.getExe pkgs.rofi-power-menu} --choices=logout/lockscreen/suspend/shutdown/reboot"'';
        "${modifier}+Period" = "workspace next";
        "${modifier}+R" = "exec ${lib.getExe config.programs.rofi.package} -modes combi -show combi";
        "${modifier}+S" = "scratchpad show";
        "${modifier}+Shift+Backslash" = "layout toggle split";
        "${modifier}+Shift+Comma" = "move container to workspace prev; workspace prev";
        "${modifier}+Shift+G" = "layout toggle splitv tabbed";
        "${modifier}+Shift+Period" = "move container to workspace next; workspace next";
        "${modifier}+Shift+R" = "exec ${lib.getExe config.programs.rofi.package} -modes run -show run";
        "${modifier}+Shift+S" = "move scratchpad";
        "${modifier}+Shift+V" = "floating toggle";
        "${modifier}+Shift+W" = "fullscreen toggle";
        "${modifier}+Return" = "exec ${lib.getExe cfg.defaultApps.terminal}";
        # "${modifier}+Tab" = "exec ${lib.getExe config.programs.rofi.package} -show window";
        "${modifier}+D" = "exec ${lib.getExe config.programs.rofi.package} -show drun";
        "${modifier}+Ctrl+greater" = "move workspace to output right";
        "${modifier}+Ctrl+less" = "move workspace to output left";
        "${modifier}+Shift+Ctrl+greater" = "move window to output right";
        "${modifier}+Shift+Ctrl+less" = "move window to output left";
        "${modifier}+P" = "exec ${lib.getExe scripts.screenshotClipboard}";
        "${modifier}+Shift+P" = "exec ${lib.getExe config.services.flameshot.package} gui";
        "${modifier}+Tab" = "fullscreen toggle , focus right, fullscreen toggle";
        "${modifier}+Shift+Tab" = "fullscreen toggle , focus left, fullscreen toggle";
        "${modifier}+Shift+d" = "exec ${lib.getExe config.programs.rofi.package} -modes window -show window";
        "Control+F12" = "exec ${helpers.screenshot}";
        "Ctrl+Mod1+M" = "mode move";
        "Ctrl+Mod1+R" = "mode resize";
        "PRINT" = "exec ${helpers.screenshot}";
      }
      // builtins.listToAttrs (
        builtins.concatMap (workspace: [
          {
            name = "${modifier}+${toString workspace}";
            value = "workspace number ${toString workspace}";
          }
          {
            name = "${modifier}+Shift+${toString workspace}";
            value = "move container to workspace number ${toString workspace}; workspace ${toString workspace}";
          }
        ]) [1 2 3 4 5 6 7 8 9]
      )
      // lib.attrsets.concatMapAttrs
      (key: direction: {
        "${modifier}+${key}" = "focus ${direction}";
        "${modifier}+Shift+${key}" = "move ${direction}";
        "${modifier}+Control+Shift+${key}" = "move workspace to output ${direction}";
      })
      cfg.desktop.windowManagerBinds;

    modes = {
      move =
        {
          Comma = "move container to workspace prev; workspace prev";
          Escape = "mode default";
          Period = "move container to workspace next; workspace next";
          S = "move scratchpad";
        }
        // builtins.listToAttrs (
          builtins.concatMap (workspace: [
            {
              name = toString workspace;
              value = "move container to workspace number ${toString workspace}; workspace ${toString workspace}";
            }
          ]) [1 2 3 4 5 6 7 8 9]
        )
        // lib.attrsets.concatMapAttrs
        (key: direction: {"${key}" = "move ${direction}";})
        cfg.desktop.windowManagerBinds;

      resize = {
        Escape = "mode default";
        Left = "resize shrink width 10 px";
        Down = "resize grow height 10 px";
        Up = "resize shrink height 10 px";
        Right = "resize grow width 10 px";
      };
    };

    startup = [
      {
        command = "swaymsg 'workspace 1; exec wezterm'";
        always = false;
      }
      {
        command = "swaymsg 'workspace 2; exec ${lib.getExe cfg.defaultApps.webBrowser}'";
        always = false;
      }
      # {
      # command = "swaymsg 'output * scale 1.5'";
      # always = true;
      # }
      {
        command = "swaymsg 'exec ${lib.getExe pkgs.swaywsr} -r'";
        always = true;
      }
      {command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";}
      {command = lib.getExe pkgs.autotiling;}
      {
        command = "fcitx5 -d";
        always = false;
      }
    ];

    window = {
      titlebar = false;

      commands = [
        {
          command = "border pixel 4"; # Workaround for libadwaita + CSD apps not having borders when floating.
          criteria = {all = true;};
        }
        {
          command = "floating enable; sticky toggle; resize 35ppt 10ppt";
          criteria = {
            title = "^Picture-in-Picture$";
            app_id = "firefox";
          };
        }
        {
          command = "focus; sticky toggle";
          criteria = {app_id = "gcr-prompter";};
        }
        {
          command = "focus; sticky toggle";
          criteria = {app_id = "polkit-gnome-authentication-agent-1";};
        }
        {
          command = "floating enable; resize set 40ppt 20ppt; move position center";
          criteria = {title = "File Operation Progress";};
        }
        {
          command = "resize set 40ppt 60ppt; move position center";
          criteria = {title = "Open Folder";};
        }
        {
          command = "resize set 40ppt 60ppt; move position center";
          criteria = {title = "Open File";};
        }
        {
          command = "resize set 60ppt 80ppt; move position center";
          criteria = {app_id = "solaar";};
        }
        {
          command = "resize set 40ppt 60ppt; move position center";
          criteria = {app_id = ".blueman-manager-wrapped";};
        }
        {
          command = "resize set 40ppt 60ppt; move position center";
          criteria = {app_id = "nm-connection-editor";};
        }
        {
          command = "resize set 40ppt 60ppt; move position center";
          criteria = {app_id = "pavucontrol";};
        }
      ];
    };

    workspaceAutoBackAndForth = true;
  };

  extraConfig =
    ''
      bindsym --locked XF86MonBrightnessUp exec ${helpers.brightness.up}
      bindsym --locked XF86MonBrightnessDown exec ${helpers.brightness.down}
      bindsym --locked XF86AudioRaiseVolume exec ${helpers.volume.up}
      bindsym --locked XF86AudioLowerVolume exec ${helpers.volume.down}
      bindsym --locked XF86AudioMute exec ${helpers.volume.mute}
      bindsym --locked XF86AudioMicMute exec ${helpers.volume.micMute}
      bindsym --locked XF86AudioPlay exec ${helpers.media.play}
      bindsym --locked XF86AudioPrev exec ${helpers.media.prev}
      bindsym --locked XF86AudioNext exec ${helpers.media.next}


      assign [app_id="org.wezfurlong.wezterm"] workspace number 1
      assign [class="chrome"] workspace number 2
      assign [app_id="firefox"] workspace number 2
      assign [app_id="google-chrome"] workspace number 2
      assign [class="clion"] workspace number 3
      assign [class="idea"] workspace number 3
      assign [app_id="org.kde.okular"] workspace number 4
      assign [class="okular"] workspace number 4
      assign [class="Slack"] workspace number 5
      assign [class="discord"] workspace number 5
      assign [app_id="org.telegram.desktop"] workspace number 5

      mode "move" {
        bindgesture pinch:inward+down move down
        bindgesture pinch:inward+left move left
        bindgesture pinch:inward+right move right
        bindgesture pinch:inward+up move up
        bindgesture swipe:down move container to workspace prev; workspace prev
        bindgesture swipe:left move container to workspace next; workspace next
        bindgesture swipe:right move container to workspace prev; workspace prev
        bindgesture swipe:up move container to workspace next; workspace next
      }

      bindgesture swipe:down workspace prev
      bindgesture swipe:left workspace next
      bindgesture swipe:right workspace prev
      bindgesture swipe:up workspace next

      bindswitch --reload --locked lid:on exec ${scripts.clamshell} on
      bindswitch --reload --locked lid:off exec ${scripts.clamshell} off

      default_border pixel 4
      default_floating_border pixel 4

      output * scale 1.5
    ''
    + lib.strings.optionalString (config.wayland.windowManager.sway.package
      == pkgs.swayfx) ''
      blur enable
      blur_passes 2
      blur_radius 8

      # corner_radius ${toString cfg.theme.borders.radius}
      shadow_blur_radius 8
      shadow_color ${config.lib.stylix.colors.withHashtag.base00}
      shadow_offset 4 4
      shadows enable
      shadows_on_csd disable

      default_dim_inactive 0.05

      layer_effects gtk-layer-shell blur enable
      layer_effects gtk-layer-shell blur_ignore_transparent enable
      layer_effects launcher blur enable
      layer_effects launcher blur_ignore_transparent enable
      layer_effects logout_dialog blur enable
      layer_effects notifications blur enable
      layer_effects notifications blur_ignore_transparent enable
      layer_effects rofi blur enable
      layer_effects rofi blur_ignore_transparent enable
      layer_effects swaybar blur enable
      layer_effects swaybar blur_ignore_transparent enable
      layer_effects swayosd blur enable
      layer_effects swayosd blur_ignore_transparent enable
      layer_effects waybar blur enable
      layer_effects waybar blur_ignore_transparent enable
    '';
}
