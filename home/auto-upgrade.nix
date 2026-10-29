{
  config,
  homeProfile,
  lib,
  pkgs,
  ...
}: let
  flake = "github:KaminariOS/nix-flake-config/dev#${homeProfile}";
  homeManager = "${config.programs.home-manager.package}/bin/home-manager";
  logFile = "${config.home.homeDirectory}/Library/Logs/home-manager-auto-upgrade.log";
  arguments = [
    "switch"
    "--flake"
    flake
    "--refresh"
    "--extra-experimental-features"
    "nix-command"
    "--extra-experimental-features"
    "flakes"
  ];
in
  lib.mkMerge [
    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      systemd.user.services.home-manager-auto-upgrade = {
        Unit = {
          Description = "Update Home Manager configuration from GitHub";
          X-SwitchMethod = "keep-old";
        };

        Service = {
          Type = "oneshot";
          ExecStart = lib.escapeShellArgs ([homeManager] ++ arguments);
        };
      };

      systemd.user.timers.home-manager-auto-upgrade = {
        Unit.Description = "Daily Home Manager update from GitHub";

        Timer = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };

        Install.WantedBy = ["timers.target"];
      };
    })

    (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      launchd.agents.home-manager-auto-upgrade = {
        enable = true;
        domain = "gui";
        config = {
          # A store path here changes on upgrade and makes activation stop its own job.
          ProgramArguments = ["${config.home.profileDirectory}/bin/home-manager"] ++ arguments;
          EnvironmentVariables.PATH = "/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          ProcessType = "Background";
          StandardOutPath = logFile;
          StandardErrorPath = logFile;
          StartCalendarInterval = [
            {
              Hour = 0;
              Minute = 0;
            }
          ];
        };
      };
    })
  ]
