{
  config,
  lib,
  pkgs,
  ...
}: let
  routeManager = pkgs.writeShellScriptBin "tailscale-exit-routes" ''
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.jq]}:/usr/bin:/bin:/usr/sbin:/sbin
    ${builtins.readFile ./tailscale-exit-routes.sh}
  '';
in {
  # The open-source macOS daemon supports the tailnet but needs scoped physical
  # defaults alongside split tunnel defaults when consuming an exit node.
  launchd.daemons.tailscale-exit-routes = lib.mkIf config.services.tailscale.enable {
    serviceConfig = {
      ProgramArguments = ["${routeManager}/bin/tailscale-exit-routes"];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 5;
      StandardOutPath = "/var/log/tailscale-exit-routes.log";
      StandardErrorPath = "/var/log/tailscale-exit-routes.log";
    };
  };
}
