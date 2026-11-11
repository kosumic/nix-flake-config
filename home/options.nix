{
  config,
  lib,
  pkgs,
  ...
}: {
  options.ar.home = {
    apps = {
      backblaze = {
        enable = lib.mkEnableOption "Backblaze-b2 client with declarative authentication.";

        keyIdFile = lib.mkOption {
          description = "Backblaze key ID.";
          default = null;
          type = lib.types.nullOr lib.types.str;
        };

        keyFile = lib.mkOption {
          description = "Backblaze application key.";
          default = null;
          type = lib.types.nullOr lib.types.str;
        };
      };

      firefox.enable = lib.mkEnableOption "Firefox web browser.";
      fuzzel.enable = lib.mkEnableOption "Fuzzel app launcher.";
      helix.enable = lib.mkEnableOption "Helix text editor.";

      keepassxc = {
        enable = lib.mkEnableOption "KeePassXC password manager.";
        package = lib.mkPackageOption pkgs "keepassxc" {};

        settings = lib.mkOption {
          description = "KeePassXC settings.";
          default = {};
          type = lib.types.attrs;
        };
      };

      librewolf.enable = lib.mkEnableOption "Librewolf web browser.";

      rofi.enable = lib.mkEnableOption "Rofi launcher.";
      shell.enable = lib.mkEnableOption "Shell with defaults.";
      swaylock.enable = lib.mkEnableOption "Swaylock screen locker.";

      tmux.enable = lib.mkEnableOption "Tmux shell session manager.";
      wlogout.enable = lib.mkEnableOption "Wlogout session prompt.";
      yazi.enable = lib.mkEnableOption "Yazi terminal file manager.";

      zed = {
        enable = lib.mkEnableOption "Zed text editor.";
        package = lib.mkPackageOption pkgs "zed-editor" {};

        keymaps = lib.mkOption {
          description = "Zed keymaps.";
          default = [];
          type = lib.types.listOf lib.types.attrs;
        };

        settings = lib.mkOption {
          description = "Zed settings.";
          default = {};
          type = lib.types.attrs;
        };
      };
    };

    defaultApps = {
      enable = lib.mkEnableOption "Declaratively set default apps and file associations.";
      audioPlayer = lib.mkPackageOption pkgs "audio player" {default = ["celluloid"];};
      editor = lib.mkPackageOption pkgs "text editor" {default = ["neovim"];};
      fileManager = lib.mkPackageOption pkgs "file manager" {default = ["nautilus"];};
      imageViewer = lib.mkPackageOption pkgs "image viewer" {default = ["oculante"];};
      pdfViewer = lib.mkPackageOption pkgs "pdf viewer" {default = ["kdePackages" "okular"];};
      terminal = lib.mkPackageOption pkgs "terminal emulator" {default = ["wezterm"];};
      terminalEditor = lib.mkPackageOption pkgs "terminal text editor" {default = ["neovim"];};
      videoPlayer = lib.mkPackageOption pkgs "video player" {default = ["mpv"];};
      webBrowser = lib.mkPackageOption pkgs "web browser" {default = ["google-chrome"];};
    };

    desktop = {
      autoSuspend = lib.mkOption {
        description = "Whether to autosuspend on idle.";
        default = false;
        type = lib.types.bool;
      };

      hyprland = {
        enable = lib.mkOption {
          description = "Hyprland with full desktop session components.";
          default = false;
          type = lib.types.bool;
        };
      };

      sway = {
        enable = lib.mkOption {
          description = "Sway with full desktop session components.";
          default = true;
          type = lib.types.bool;
        };
      };

      windowManagerBinds = lib.mkOption {
        description = "Default binds for window management.";

        default = {
          Down = "down";
          Left = "left";
          Right = "right";
          Up = "up";
          H = "left";
          J = "down";
          K = "up";
          L = "right";
        };

        type = lib.types.attrs;
      };
    };

    services = {
      easyeffects = {
        enable = lib.mkEnableOption "EasyEffects user service.";

        preset = lib.mkOption {
          description = "Name of preset to start with.";
          default = "";
          type = lib.types.str;
        };
      };

      gammastep.enable = lib.mkEnableOption "Gammastep redshift daemon.";
      mako.enable = lib.mkEnableOption "Mako notification daemon.";

      mpd = {
        enable = lib.mkEnableOption "MPD user service.";

        musicDirectory = lib.mkOption {
          description = "Name of music directory";
          default = config.xdg.userDirs.music;
          type = lib.types.str;
        };
      };

      pipewire-inhibit.enable = lib.mkEnableOption "Inhibit idle when audio is playing with Pipewire.";
      randomWallpaper.enable = lib.mkEnableOption "Lightweight swaybg-based random wallpaper daemon.";
      swayidle.enable = lib.mkEnableOption "Swayidle idle daemon.";
      swayosd.enable = lib.mkEnableOption "OSD for brightness and volume keys.";
      waybar.enable = lib.mkEnableOption "Waybar wayland panel.";
    };

    theme = {
      enable = lib.mkEnableOption "Gtk, Qt, and application colors.";

      borders = {
        radius = lib.mkOption {
          description = "Global border radius.";
          default = 10;
          type = lib.types.int;
        };
      };

      gtk.hideTitleBar = lib.mkOption {
        description = "Whether to hide GTK3/4 titlebars (useful for some window managers).";
        default = false;
        type = lib.types.bool;
      };
    };
  };
}
