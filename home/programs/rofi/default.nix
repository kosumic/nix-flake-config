{
  config,
  pkgs,
  lib,
  ...
}: {
  # Keep the custom theme and font while Stylix still uses programs.rofi.font.
  stylix.targets.rofi.enable = false;

  programs.rofi = {
    enable = true;
    settings = {
      terminal = "${pkgs.wezterm}/bin/wezterm";
      font = "${config.stylix.fonts.monospace.name} ${toString config.stylix.fonts.sizes.popups}";
    };
    theme = lib.mkForce ./launcher/type2-style-10.rasi;
  };
}
