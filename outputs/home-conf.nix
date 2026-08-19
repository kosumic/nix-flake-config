{
  inputs,
  system,
  ...
}:
with inputs; let
  mkPkgs = system: let
    fishOverlay = final: prev: {
      inherit fish-bobthefish-theme;
    };
    tex2nixOverlay = final: prev: {
      tex2nix = tex2nix.defaultPackage.${system};
    };
  in
    import nixpkgs {
      inherit system;

      config.allowUnfree = true;
      config = {
        packageOverrides = pkgs: {
          espanso = pkgs.espanso.override {
            x11Support = false;
            waylandSupport = true;
          };
        };
      };

      overlays = [
        fishOverlay
        nurpkgs.overlays.default
        # (import ../overlay.nix)
        #neovim-flake.overlays.${system}.default
        tex2nixOverlay
        ((import ../home/overlays/md-toc) {inherit (inputs) gh-md-toc;})
        (import ../home/overlays/ranger)
      ];
    };
  commonImports = [
    inputs.sops-nix.homeManagerModules.sops
    # neovim-flake.homeManagerModules.default
  ];

  mkHome = {
    hostSystem ? system,
    hidpi ? false,
    username,
    profileName ? username,
    extraModules ? [],
    gui ? false,
    full ? true,
    homed,
  }: let
    pkgs = mkPkgs hostSystem;
    nur = import nurpkgs {
      inherit pkgs;
      nurpkgs = pkgs;
    };
  in
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = {
        inherit hidpi;
        inherit full;
        inherit gui;
        homeProfile = profileName;
        herdr = inputs.herdr.packages.${hostSystem}.default;
        addons = nur.repos.rycee.firefox-addons;
      };

      modules = let
        homeDirectory = homed;
      in [
        {
          imports =
            (pkgs.lib.optionals full commonImports)
            ++ [../home/home.nix]
            ++ pkgs.lib.optional gui inputs.stylix.homeModules.stylix;
        }
        {
          home = {
            inherit username;
            inherit homeDirectory;
          };
          programs.git.signing.signByDefault = gui;
          xdg = {
            configHome = "${homeDirectory}/.config";
            enable = true;
          };
        }
      ] ++ extraModules;
    };
  mkCloud = hostSystem: let
    username = "kosumi";
  in
    mkHome {
      inherit hostSystem;
      hidpi = false;
      inherit username;
      gui = false;
      full = false;
      homed = "/home/${username}";
    };
  cloudAarch64 = mkCloud "aarch64-linux";
  cloudX86_64 = mkCloud "x86_64-linux";
in {
  kosumi = let
    username = "kosumi";
  in
    mkHome {
      hidpi = false;
      gui = true;
      full = true;
      inherit username;
      homed = "/home/${username}";
    };

  mini = let
    username = "kosumi";
  in
    mkHome {
      hostSystem = "aarch64-darwin";
      hidpi = false;
      inherit username;
      profileName = "mini";
      gui = false;
      full = false;
      extraModules = [../home/programs/wezterm/default.nix];
      homed = "/Users/${username}";
    };

  shellhome = let
    username = "kosumic";
  in
    mkHome {
      hidpi = false;
      inherit username;
      gui = false;
      full = false;
      homed = "/users/${username}";
    };
  shellhomeForWork = let
    username = "kchen";
  in
    mkHome {
      hidpi = false;
      inherit username;
      gui = false;
      full = false;
      homed = "/home/${username}";
    };
  cloud = cloudAarch64;
  "cloud-aarch64-linux" = cloudAarch64;
  "cloud-x86_64-linux" = cloudX86_64;
  # Continuous Integration automation
  #  ci = {
  #    metals = pkgs.callPackage ../home/programs/neovim-ide/metals.nix { };
  #    metals-updater = pkgs.callPackage ../home/programs/neovim-ide/update-metals.nix { };
  #  };
}
