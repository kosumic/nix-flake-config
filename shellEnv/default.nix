{
  pkgs,
  full,
  gui,
  homeProfile,
  lib,
  config,
  ...
}: let
  inherit (lib) optionals;
  homeDirectory = config.home.homeDirectory;
in {
  imports =
    optionals full [
      ./helix
      ./nushell
      ./tickrs
      ./sops
    ]
    ++ [
      # ./nvim
      ./starship
      ./herdr
      ./git
      ./fish
      ./neofetch
      ./terminfo.nix
      # ./nix-index.nix
      ./bat
      ./gitui
      # ./jj
      # ./k9s
    ];
  home = {
    file = {
      ".ssh/config".text = ''
        Host *.cloudlab.us
          ForwardAgent yes
          forwardX11Trusted yes
      '';
      ".gdbinit".text = ''
        set auto-load safe-path /
        tui enable
      '';
    };
    packages = pkgs.callPackage ../shellEnv/shellList.nix {inherit full;};
    sessionVariables = {
      KUBECONFIG = "${homeDirectory}/.kube/config";
    };
    sessionPath =
      [
        "${homeDirectory}/.cargo/bin"
        "${homeDirectory}/.npm-global/bin"
      ]
      ++ optionals (homeProfile == "mini") [
        "/Applications/ChatGPT.app/Contents/Resources"
      ];
  };
  xdg.configFile."nvf/after/plugin/clipboard.lua".text = ''
    vim.opt.clipboard:append("unnamedplus")
  '';
  programs = {
    kubecolor = {
      enable = true;
      enableAlias = true;
    };
    taskwarrior = {
      package = pkgs.taskwarrior3;
      enable = true;
      dataLocation = "${config.home.homeDirectory}/.task";
      config = {
        confirmation = false;
        report.minimal.filter = "status:pending";
        report.next.filter = "(status:pending or status:waiting)";
      };
    };
    readline = {
      enable = true;
      extraConfig = "set editing-mode vi
          ";
    };
    direnv = {
      enable = true;
      #enableFishIntegration = true;
      nix-direnv.enable = true;
    };
    broot = {
      enable = full;
      enableFishIntegration = true;
    };

    fzf = {
      enable = true;
      enableFishIntegration = true;
      defaultCommand = "fd --type file --follow"; # FZF_DEFAULT_COMMAND
      defaultOptions = ["--height 20%"]; # FZF_DEFAULT_OPTS
      fileWidget.command = "fd --type file --follow"; # FZF_CTRL_T_COMMAND
      historyWidget.command = "";
    };

    gpg.enable = true;
    ssh = {
      enable = true;
      enableDefaultConfig = false;
    };
    zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = [];
    };
    starship = {
      enable = true;
      enableFishIntegration = true;
      # enableZshIntegration = true;
    };
    navi = {
      enable = full;
      # enableZshIntegration = true;
      enableFishIntegration = true;
    };
    skim = {
      enable = full;
      enableFishIntegration = true;
      # enableZshIntegration = true;
      changeDirWidgetCommand = "fd --type d";
      fileWidgetOptions = [
        "--preview 'head {}'"
      ];
    };
    atuin = {
      enable = true;
      enableFishIntegration = true;
      # enableZshIntegration = true;
    };
    tealdeer = {
      enable = true;
      enableAutoUpdates = gui;
      settings = {
        updates = {
          auto_update = gui;
        };
      };
    };
    yazi = {
      enable = true;
      enableFishIntegration = true;
      shellWrapperName = "yy";
    };
    eza = {
      enable = true;
      enableFishIntegration = true;
    };
    opencode = {
      enable = true;
      web.enable = false;
      context = ''
        If you want to run Python, use uv instead

        I am on NixOS with Sway/Wayland/Waybar. Usually my project has a Nix flake for dev env.

        This machine has Podman but no Docker.

        This machine has aws-cli, gh, rg and fd installed.

        For k8s related problems you can use kubectl and flux. Do not use helm. All my k8s configs are managed by FluxCD.

        After making changes in a Git repo, give me the command to git add those files, give me a commit command like `git cm "feat: ..."`, `fix: ...`, `ci: ...`, `chore: ...`, `doc: ...`. I may copy-paste to run them.

        When I talk about a Github project, check if it is already cloned in ~/repos. If not, shallow clone it and answer based on the source.

        If you need to use browser cookies, use the one from Brave by default.

        If you need to run a command but it is not found, you can try to run it with nix shell
      '';
      settings = {
        agent.title.model = "openai/gpt-5.4-mini";
        small_model = "openai/gpt-5.4-mini";
        plugin = [
          "opencode-scheduler"
        ];
        mcp = {
          context7 = {
            type = "local";
            command = [
              "npx"
              "-y"
              "@upstash/context7-mcp"
              "--api-key"
              "{env:CONTEXT7_API_KEY}"
            ];
          };
          chrome-devtools = {
            type = "local";
            command = [
              "npx"
              "chrome-devtools-mcp@latest"
              "--autoConnect"
            ];
          };
        };
        permission = {
          webfetch = "allow";
          websearch = "allow";
        };
      };
    };
  };
}
