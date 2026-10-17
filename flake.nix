{
  description = "Home Manager configuration of Kosumi";

  nixConfig = {
    extra-substituters = ["https://fcitx5-vinput.cachix.org"];
    extra-trusted-public-keys = ["fcitx5-vinput.cachix.org-1:XpX3AA6+dDIX4qJhb1QM7sbTwX6/qSlGvW8Z5NK6XdU="];
  };

  inputs = {
    # colmena.url = "github:zhaofengli/colmena";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    fcitx5-vinput = {
      url = "github:xifan2333/fcitx5-vinput";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nurpkgs.url = "github:nix-community/NUR";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS profiles to optimize settings for different hardware.
    # nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-cli-nix.url = "github:sadjow/codex-cli-nix";
    opencode.url = "github:anomalyco/opencode/v2.0.26";
    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # agenix = {
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   url = "github:yaxitech/ragenix";
    # };

    #Declarative disk partitioning and formatting using nix
    # disko = {
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   url = "github:nix-community/disko";
    # };

    # add git hooks to format nix code before commit
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # haumea = {
    #   url = "github:nix-community/haumea/v0.2.2";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # rycee-nurpkgs = {
    #   url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # neovim-flake = {
    #   # url = "github:notashelf/neovim-flake";
    #   url = "github:KaminariOS/neovim-flake/master";
    #   # neovim-flake pushes its binaries to the cache using its own nixpkgs version
    #   # if we instead use ours, we'd be rebuilding all plugins from scratch
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Fish shell

    fish-bobthefish-theme = {
      url = "github:gvolpe/theme-bobthefish";
      flake = false;
    };

    # Github Markdown ToC generator

    gh-md-toc = {
      url = "github:ekalinin/github-markdown-toc";
      flake = false;
    };

    # LaTeX stuff

    tex2nix = {
      #url = github:Mic92/tex2nix;
      url = "github:gvolpe/tex2nix"; # fork with nixFlakes fix
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:danth/stylix";
    };
  };

  outputs = {
    self,
    nixpkgs,
    pre-commit-hooks,
    sops-nix,
    nix-index-database,
    ...
  } @ inputs: let
    forDefaultSystems = inputs.nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
    ];
  in {
    formatter = forDefaultSystems (system: inputs.nixpkgs.legacyPackages.${system}.alejandra);

    homeConfigurations = import ./outputs/home-conf.nix {
      inherit inputs;
      system = "x86_64-linux";
    };

    nixosConfigurations = import ./outputs/nixos-conf.nix {
      inherit inputs;
      system = "x86_64-linux";
    };

    darwinConfigurations = import ./outputs/darwin-conf.nix {inherit inputs;};

    checks = forDefaultSystems (
      system: {
        # eval-tests per system
        # eval-tests = allSystems.${system}.evalTests == {};

        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            actionlint.enable = true;
            alejandra.enable = true; # formatter
            deadnix = {
              enable = true;
              settings = {
                noLambdaArg = true;
                noLambdaPatternNames = true;
              };
            };
            statix.enable = true;
            # Source code spell checker
            typos = {
              enable = true;
              settings = {
                write = false;
                configPath = "./.typos.toml"; # relative to the flake root
              };
            };
            prettier = {
              enable = false;
              settings = {
                write = true; # Automatically format files
                configPath = "./.prettierrc.yaml"; # relative to the flake root
              };
            };
          };
        };
      }
    );

    # Development Shells
    devShells = forDefaultSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # fix https://discourse.nixos.org/t/non-interactive-bash-errors-from-flake-nix-mkshell/33310
            bashInteractive
            # fix `cc` replaced by clang, which causes nvim-treesitter compilation error
            gcc
            # Nix-related
            alejandra
            actionlint
            deadnix
            gitleaks
            shellcheck
            statix
            zizmor
            # spell checker
            typos
            # code formatter
            # nodePackages.prettier
          ];
          name = "dots";
          shellHook = ''
            ${self.checks.${system}.pre-commit-check.shellHook}
          '';
        };
      }
    );
  };
}
