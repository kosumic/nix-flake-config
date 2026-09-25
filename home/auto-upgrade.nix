{
  config,
  homeProfile,
  lib,
  pkgs,
  ...
}: let
  flake = "github:KaminariOS/nix-flake-config/dev#${homeProfile}";
  homeManager = "${config.programs.home-manager.package}/bin/home-manager";
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
        domain = "user";
        config = {
          ProgramArguments = [homeManager] ++ arguments;
          ProcessType = "Background";
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
