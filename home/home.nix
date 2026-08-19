{
  config,
  pkgs,
  lib,
  gui,
  ...
}: let
  inherit (lib) mkIf optionals;
  cfg = config.ar.home.defaultApps;
  mimeTypes = import ./mimeTypes.nix;
  defaultPkgs = with pkgs; [
    arandr # simple GUI for xrandr
    asciinema # record the terminal

    # gimp # gnu image manipulation program

    betterlockscreen # fast lockscreen based on i3lock

    # nodePackages_latest.bash-language-server
    #    nodePackages.dockerfile-language-server-nodejs

    # simplescreenrecorder # screen recorder gui
  ];

  gui_apps = (pkgs.callPackage ./gui.nix {}).gui_packages;
  nixos_app = with pkgs; [
    # jetbrains.clion
    # jetbrains.idea-ultimate
    # jetbrains.rider
    google-chrome
    brave
    rclone
    # seahorse
    pulseaudio
    # android-studio
    # windsurf
    pkgs."proton-vpn"
    feishu
    # unityhub
  ];
in {
  imports =
    (lib.concatMap import (optionals gui [
      #      ./age
      ./programs
      ./scripts
      ./services
      #      ./themes
    ]))
    ++ (optionals gui [
      ./stylix.nix
    ])
    ++ [
      ./options.nix
      ../shellEnv
    ];

  ar.home.defaultApps.enable = lib.mkDefault gui;

  home = {
    stateVersion = "22.05";
    #    packages = defaultPkgs ++ gnomePkgs;
    packages = optionals gui (defaultPkgs ++ gui_apps ++ nixos_app);
    sessionVariables =
      {
        DISPLAY = ":0";
        EDITOR = "nvim";
        TERM_PROGRAM = "WezTerm";
        TMUX_TMPDIR = "/tmp";
        QT_SCALE_FACTOR = 2;
        GDK_SCALE = 2;
      }
      // lib.optionalAttrs gui {
        BROWSER = lib.getExe cfg.webBrowser;
      };
  };

  wayland.windowManager.hyprland.configType = mkIf gui "hyprlang";

  # fonts.fontconfig = mkIf gui {
  #   enable = true;
  #   defaultFonts = {
  #     emoji = ["Noto Color Emoji"];
  #   };
  # };

  # i18n.inputMethod = {
  #   enabled = "fcitx5";
  #   fcitx5.addons = with pkgs; [fcitx5-rime fcitx5-chinese-addons fcitx5-mozc];
  # };
  # restart services on change
  systemd.user = mkIf gui {
    targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = ["graphical-session-pre.target"];
      };
    };
    startServices = "sd-switch";
    # timers.wallpaper = {
    #   Install.WantedBy = ["timers.target"];
    #   Timer = {
    #     OnBootSec = "40m";
    #     OnUnitActiveSec = "1d";
    #   };
    # };
    services = let
      mkRcloneService = node: let
        mountPoint = "%h/${node}";
        prepareMountpoint = pkgs.writeShellScript "prepare-rclone-mount-${node}" ''
          set -eu

          mount_point="$1"
          home_dir="$2"

          # Clean up stale FUSE mounts left behind by crashes or abrupt restarts.
          if ${pkgs.util-linux}/bin/mountpoint -q "$mount_point"; then
            ${pkgs.fuse3}/bin/fusermount3 -uz "$mount_point" || true
            ${pkgs.coreutils}/bin/sleep 1
          fi

          ${pkgs.coreutils}/bin/mkdir -p "$mount_point"

          # rclone refuses to mount on non-empty dirs; stash any local leftovers.
          if [ -n "$(${pkgs.findutils}/bin/find "$mount_point" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
            stash_dir="$home_dir/.local/share/rclone-mount-stash/${node}/$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)"
            ${pkgs.coreutils}/bin/mkdir -p "$stash_dir"
            ${pkgs.findutils}/bin/find "$mount_point" -mindepth 1 -maxdepth 1 -exec ${pkgs.coreutils}/bin/mv -t "$stash_dir" -- {} +
            ${pkgs.coreutils}/bin/echo "Moved pre-existing files from $mount_point to $stash_dir"
          fi
        '';
      in {
        Service = {
          Type = "simple";
          ExecStartPre = "${prepareMountpoint} ${mountPoint} %h";
          ExecStart = "${pkgs.rclone}/bin/rclone mount --umask 022 --allow-other ${node}: ${mountPoint} --vfs-cache-mode full --vfs-fast-fingerprint --vfs-cache-max-size 10G";
          ExecStop = "-${pkgs.fuse3}/bin/fusermount3 -u ${mountPoint}";
          ExecStopPost = "-${pkgs.fuse3}/bin/fusermount3 -uz ${mountPoint}";
          Environment = ["PATH=/run/wrappers/bin/:$PATH"];
        };
        Install.WantedBy = ["default.target"];
      };
    in {
      gdrive_main = mkRcloneService "gdrive_main";
      edu = mkRcloneService "unc";
      savior = mkRcloneService "savior";

      #   wallpaper = {
      #     Service = {
      #       Type = "oneshot";
      #       ExecStart = "${homeDirectory}/nixpkgs/wallpaper/wallpaper.sh";
      #       #''${pkgs.wget}/bin/wget -O wallpaper.jpg "http://www.bing.com/$(wget -q -O- https://binged.it/2ZButYc | sed -e 's/<[^>]*>//g' | cut -d / -f2 | cut -d \& -f1)" -O ${homeDirectory}/Pictures/wallpaper.jpg &&
      #       #${pkgs.feh}/bin/feh --bg-scale /Pictures/wallpaper.jpg'';
      #       Environment = ["PATH=/run/current-system/sw/bin:${homeDirectory}/.nix-profile/bin:$PATH"];
      #     };
      #     #Install.WantedBy = ["default.target"];
      #     Install.WantedBy = ["default.target"];
      #   };
    };
  };

  xdg.mimeApps = mkIf cfg.enable {
    enable = true;
    defaultApplications = let
      mkDefaults = files: desktopFile: lib.genAttrs files (_: [desktopFile]);
      audioTypes =
        mkDefaults mimeTypes.audioFiles
        "defaultAudioPlayer.desktop";

      browserTypes =
        mkDefaults mimeTypes.browserFiles
        "defaultWebBrowser.desktop";

      documentTypes =
        mkDefaults mimeTypes.documentFiles
        "defaultPdfViewer.desktop";

      editorTypes =
        mkDefaults mimeTypes.editorFiles
        "defaultEditor.desktop";

      folderTypes = {"inode/directory" = "defaultFileManager.desktop";};

      imageTypes =
        mkDefaults mimeTypes.imageFiles
        "defaultImageViewer.desktop";

      videoTypes =
        mkDefaults mimeTypes.videoFiles
        "defaultVideoPlayer.desktop";
    in
      audioTypes
      // browserTypes
      // documentTypes
      // editorTypes
      // folderTypes
      // imageTypes
      // videoTypes;
  };
  xdg.desktopEntries = mkIf cfg.enable (let
    mkDefaultEntry = name: package: {
      name = "Default ${name}";
      exec = "${lib.getExe package} %U";
      terminal = false;
      settings = {
        NoDisplay = "true";
      };
    };
  in {
    defaultAudioPlayer = mkDefaultEntry "Audio Player" cfg.audioPlayer;
    defaultEditor =
      (mkDefaultEntry "Editor" cfg.editor)
      // {
        terminal = true;
      };
    defaultFileManager = mkDefaultEntry "File Manager" cfg.fileManager;
    defaultImageViewer = mkDefaultEntry "Image Viewer" cfg.imageViewer;
    defaultPdfViewer = mkDefaultEntry "PDF Viewer" cfg.pdfViewer;
    defaultVideoPlayer = mkDefaultEntry "Video Player" cfg.videoPlayer;
    defaultWebBrowser =
      (mkDefaultEntry "Web Browser" cfg.webBrowser)
      // {
        exec = "${lib.getExe cfg.webBrowser} %U";
        mimeType = mimeTypes.browserFiles;
      };
  });

  # notifications about home-manager news
  news.display = "silent";
  programs = {
    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.

    # Let Home Manager install and manage itself.
    home-manager.enable = true;
  };

  home.pointerCursor = mkIf gui {
    enable = true;
    # x11.enable = true;
    # name = "Adwaita";
    # package = pkgs.gnome.adwaita-icon-theme;
    # name = "WhiteSure-cursors";
    # package = pkgs.whitesur-cursors;
    # name = "Bibata-Modern-Ice";
    # package = pkgs.bibata-cursors;
    # size = 60;
  };
  gtk = mkIf gui {
    enable = true;
    gtk4.theme = lib.mkDefault config.gtk.theme;
    iconTheme = {
      name = "WhiteSure";
      package = pkgs.whitesur-icon-theme;
    };
    # theme = {
    #   name = "WhiteSure-Dark-hdpi";
    #   package = pkgs.whitesur-gtk-theme;
    # };
    # font = {
    #   name = "Noto fonts";
    #   package = pkgs.noto-fonts;
    #   size = 24;
    # };
  };
}
