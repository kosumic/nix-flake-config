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
    multiplexer = lib.mkDefault "herdr";
    workspaceName = lib.mkDefault "{repository}#{issue_number} {agent_name}";
    tabName = lib.mkDefault "{agent_name}";
    enable = lib.mkDefault (pkgs.stdenv.hostPlatform.isLinux && homeProfile == "kosumi");
    herdrPackage = herdr;
    botName = lib.mkDefault "invo";
    useHostnameAsBotName = lib.mkDefault false;
    agent = lib.mkDefault "codex";
    acknowledgementMessage = lib.mkDefault "🪄 Invocateur started {agent} for this task.\n\nTriggered by {comment_url}.";
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
