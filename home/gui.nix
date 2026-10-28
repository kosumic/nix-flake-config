{
  config,
  pkgs,
  ...
}: {
  gui_packages = with pkgs; [
    # i3status
    brightnessctl
    feh
    # zoom-us
    discord
    slack
    chatgpt
    telegram-desktop

    wireshark
    # HDR image viewer
    # tev

    maim
    gdbgui
    blender
    # heroic
    # lutris
    mpv
    # mdcat
    xdotool
    # networkmanager_dmenu
    networkmanagerapplet
    # Inlyne - a GPU powered, browserless, markdown + html viewer
    # inlyne
    graphviz

    # File manager
    # spacedrive
    nautilus

    steam-run

    kdePackages.okular

    oculante

    # wayland stuff
    mako
    wl-clipboard
    shotman

    swayidle #idle locker
    swaylock #screen locker
    swaywsr
    grim
    wdisplays

    pavucontrol
    pamixer
    # pulseaudioFull
    brightnessctl
    wlprop

    # screenshot
    wayshot
    slurp
    # nur.repos.k3a.ib-tws
  ];
}
