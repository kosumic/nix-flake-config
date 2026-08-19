{inputs}: {
  mini = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";

    modules = [
      inputs.home-manager.darwinModules.home-manager
      ({pkgs, ...}: {
        nixpkgs.overlays = [
          (final: prev: {fish-bobthefish-theme = inputs.fish-bobthefish-theme;})
          inputs.nurpkgs.overlays.default
          (final: prev: {
            tex2nix = inputs.tex2nix.defaultPackage.aarch64-darwin;
          })
          ((import ../home/overlays/md-toc) {inherit (inputs) gh-md-toc;})
          (import ../home/overlays/ranger)
        ];

        system.primaryUser = "kosumi";
        system.stateVersion = 4;
        ids.gids.nixbld = 350;
        programs.fish.enable = true;
        users.users.kosumi = {
          home = "/Users/kosumi";
          shell = pkgs.fish;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrWwGk9L6aGeJUflLOY25e7Aaa/AfDU51irnmchw1Zw thinker@example.com"
          ];
        };

        nix.settings = {
          experimental-features = ["nix-command" "flakes"];
          trusted-users = ["root" "kosumi"];
          require-sigs = false;
          sandbox = false;
        };

        services.tailscale.enable = true;
        environment.systemPackages = [pkgs.tailscale];

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {
            full = false;
            gui = false;
            homeProfile = "mini";
            herdr = inputs.herdr.packages.aarch64-darwin.default;
          };

          users.kosumi = {
            imports = [
              ../home/home.nix
              ../home/programs/wezterm/default.nix
            ];
            home.username = "kosumi";
            home.homeDirectory = "/Users/kosumi";
          };
        };
      })
    ];
  };
}
