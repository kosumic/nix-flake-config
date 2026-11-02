{
  config,
  herdr,
  invocateur,
  homeProfile,
  lib,
  pkgs,
  ...
}: {
  imports = [invocateur.homeManagerModules.default];

  home.packages = [herdr];

  services.invocateur = {
    enable = lib.mkDefault (pkgs.stdenv.hostPlatform.isLinux && homeProfile == "kosumi");
    herdrPackage = herdr;
    spells = lib.mkDefault ["summon"];
    agent = lib.mkDefault "codex";
    reposDirectory = lib.mkDefault "${config.home.homeDirectory}/repos";
    pollInterval = lib.mkDefault 60;
  };

  xdg.configFile."herdr/config.toml".text = ''
    [keys]
    prefix = "ctrl+a"

    [theme]
    name = "tokyo-night"

    [ui]
    agent_panel_sort = "priority"

    [ui.toast]
    delivery = "system"

    [experimental]
    kitty_graphics = true
  '';
}
