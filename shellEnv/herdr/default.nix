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
    useHostnameAsBotName = lib.mkDefault true;
    agent = lib.mkDefault "codex";
    agentArgs = lib.mkDefault [
      "--model"
      "gpt-6.1-sol"
      "-c"
      "model_reasoning_effort=\"high\""
    ];
    acknowledgementMessage = lib.mkDefault "🪄 [Invocateur](https://github.com/kosumic/invocateur) started {agent} for this task.\n\nTriggered by {comment_url}.";
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
