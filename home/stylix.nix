{
  lib,
  pkgs,
  ...
}: {
  # OpenCode v2 uses cli.json. Keep it writable for preferences and integrations;
  # apply the declarative theme with v2's supported inline configuration instead.
  programs.opencode.tui = lib.mkForce {};
  home.sessionVariables.OPENCODE_CLI_CONFIG_CONTENT = lib.escape ["\""] (builtins.toJSON {
    theme.name = "stylix";
  });

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";

    image = let
      wallpapers = builtins.fetchGit {
        url = "https://github.com/alyraffauf/wallpapers.git";
        rev = "ff956327520f2ecdd0f8b1cdab4420bef4095d38";
        ref = "master";
      };
    in "${wallpapers}/wallhaven-mp886k.jpg";

    imageScalingMode = "fill";
    polarity = "light";

    cursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 34;
    };

    targets.mako.enable = false;
    targets.firefox.profileNames = ["firefox"];

    fonts = {
      monospace = {
        name = "Iosevka Nerd Font Mono";
        package = pkgs.nerd-fonts.iosevka;
      };

      sansSerif = {
        name = "Ubuntu Sans";
        package = pkgs.nerd-fonts.ubuntu-sans;
      };

      serif = {
        name = "Vegur";
        package = pkgs.vegur;
      };

      emoji = {
        name = "Noto Color Emoji";
        package = pkgs.noto-fonts-color-emoji;
      };

      sizes = {
        applications = 14;
        desktop = 13;
        popups = 15;
        terminal = 16;
      };
    };

    opacity = {
      applications = 1.0;
      desktop = 0.4;
      terminal = 0.8;
      popups = 0.8;
    };
  };
}
