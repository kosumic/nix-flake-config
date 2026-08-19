{
  config,
  pkgs,
  lib,
  homeProfile,
  ...
}: let
  nixDaemonInit = lib.optionalString pkgs.stdenv.isDarwin ''
    if not set -q __ETC_PROFILE_NIX_SOURCED; and test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    end
  '';
  fzfConfig = ''
    set -x FZF_DEFAULT_OPTS "--preview='bat {} --color=always'" \n
    set -x SKIM_DEFAULT_COMMAND "rg --files || fd || find ."
  '';

  themeConfig = ''
    set -g theme_display_date no
    set -g theme_display_git_master_branch no
    set -g theme_nerd_fonts yes
    set -g theme_newline_cursor yes
    set -g theme_color_scheme solarized
  '';

  custom = pkgs.callPackage ./plugins.nix {};

  fenv = {
    name = "foreign-env";
    inherit (pkgs.fishPlugins.foreign-env) src;
  };
  bass = {
    name = "bass";
    inherit (pkgs.fishPlugins.bass) src;
  };
  puffer = {
    name = "puffer";
    inherit (pkgs.fishPlugins.puffer) src;
  };
  done = {
    name = "done";
    inherit (pkgs.fishPlugins.done) src;
  };
  loadenv = builtins.readFile ./loadenv.fish;
  #aliases = ''
  #alias z  "zoxide"
  #alias nuco  "nvim ~/.config/nushell/config.nu"
  #alias hxco  "hx ~/.config/helix/config.toml"
  #alias alco  "nvim ~/.config/alacritty/alacritty.yml"
  #alias nico  "nvim ~/.config/nixpkgs/home.nix"
  #alias ll  "eza -l"
  #alias his  "history"
  #alias c  "bat"
  #alias lt  "eza --icons --tree --no-user --no-permissions"
  #alias e "eza --icons -l --no-user --no-permissions"
  #alias ls  "eza --icons -l --no-user --no-permissions"
  #alias du  "dust"
  #alias ps  "procs"
  #alias rfr  "rofi -show run"
  #alias diff "delta"
  #alias ca "cargo"
  #alias idea "idea-ultimate"
  #alias clo "clion"
  #alias dnix "echo 'use nix' >> .envrc; direnv allow"
  #'';
  fishConfig =
    "

    fish_add_path -g $HOME/.npm-global/bin

    set -g fish_color_autosuggestion 555 yellow
    set -g fish_color_command 5f87d7
    set -g fish_color_comment 808080
    set -g fish_color_cwd 87af5f
    set -g fish_color_cwd_root 5f0000
    set -g fish_color_error 870000 --bold
    set -g fish_color_escape af5f5f
    set -g fish_color_history_current 87afd7
    set -g fish_color_host 5f87af
    set -g fish_color_match d7d7d7 --background=303030
    set -g fish_color_normal normal
    set -g fish_color_operator d7d7d7
    set -g fish_color_param 5f87af
    set -g fish_color_quote d7af5f
    set -g fish_color_redirection normal
    set -g fish_color_search_match --background=purple
    set -g fish_color_status 5f0000
    set -g fish_color_user 5f875f
    set -g fish_color_valid_path --underline

    set -g fish_color_dimmed 555
    set -g fish_color_separator 999

    # Git prompt status
    set -g __fish_git_prompt_showdirtystate 'yes'
    set -g __fish_git_prompt_showupstream auto
    set -g pure_git_untracked_dirty false

    # pure
    set pure_threshold_command_duration 1
    set pure_separate_prompt_on_error true
    set pure_begin_prompt_with_current_directory false
    set -U pure_color_success (set_color green)
    set -U pure_color_git_dirty (set_color cyan)

    # Status Chars
    #set __fish_git_prompt_char_dirtystate '*'
    set __fish_git_prompt_char_upstream_equal ''
    set __fish_git_prompt_char_upstream_ahead '↑'
    set __fish_git_prompt_char_upstream_behind '↓'
    set __fish_git_prompt_color_branch yellow
    set __fish_git_prompt_color_dirtystate 'red'

    set __fish_git_prompt_color_upstream_ahead ffb90f
    set __fish_git_prompt_color_upstream_behind blue

    # Local prompt customization
    # set -e fish_greeting


    set -g fish_pager_color_completion normal
    set -g fish_pager_color_description 555 yellow
    set -g fish_pager_color_prefix cyan
    set -g fish_pager_color_progress cyan


    # highlighting inside manpages and elsewhere
    #set -gx LESS_TERMCAP_mb \e'[01;31m'       # begin blinking
    #set -gx LESS_TERMCAP_md \e'[01;38;5;74m'  # begin bold
    #set -gx LESS_TERMCAP_me \e'[0m'           # end mode
    #set -gx LESS_TERMCAP_se \e'[0m'           # end standout-mode
    #set -gx LESS_TERMCAP_so \e'[38;5;246m'    # begin standout-mode - info box
    #set -gx LESS_TERMCAP_us \e'[04;38;5;146m' # begin underline
    "
    + "
    fish_vi_key_bindings
    # Emulates vim's cursor shape behavior
    # Set the normal and visual mode cursors to a block
    set fish_cursor_default block blink
    # Set the insert mode cursor to a line
    set fish_cursor_insert line blink
    # Set the replace mode cursor to an underscore
    set fish_cursor_replace_one underscore blink
    # The following variable can be used to configure cursor shape in
    # visual mode, but due to fish_cursor_default, is redundant here
    set fish_cursor_visual block blink

    # function fish_greeting
    #   fortune -a
    # end

    function oku 
      okular $argv &>/dev/null &; disown
    end 

    function clo 
      clion $argv &>/dev/null &; disown 
    end

    function idea 
      idea-ultimate $argv &>/dev/null &; disown 
    end

    function ride 
      rider $argv &>/dev/null &; disown 
    end

    function wssh 
      wezterm ssh $argv &>/dev/null &; disown 
    end

    set -gx ATUIN_NOBIND true
    # bind to ctrl-r in normal and insert mode, add any other bindings you want here too
#    atuin init fish | source
    bind \\e\\[A _atuin_search
    bind -M insert \\e\\[A _atuin_search
    # set_color normal

    # Make vi mode work in wezterm
    set fish_vi_force_cursor 1
  "
    + fzfConfig
    + themeConfig;
  #+ aliases;
in {
  programs.fish = {
    enable = true;

    functions = {
      #fish_greeting = {
      #description = "Hi!";
      #body = ''
      ##echo -e "\e[3m "(${pkgs.fortune}/bin/fortune literature riddles)"\e[0m\n"
      #'';
      #};
      prepend_path = {
        description = "Prepends a path to PATH if it exists";
        body = ''
          if test -e $argv[1]
            set PATH $argv[1] $PATH
          end
        '';
      };
      source_if_exists = {
        description = "Sources a script if it exists";
        body = ''
          if test -e $argv[1]
            source $argv[1]
          end
        '';
      };
    };
    shellAliases = {
      # v = "${config.home.homeDirectory}/nix/neovim-flake/result/bin/nvim";
      v = "nvim";
      vc = "nvim --clean";
      c = "bat";
      e = "eza --icons -l --no-user --no-permissions --git";
      r = "rip";
      yz = "yazi";
      mk = "make";
      wt = "wthrr";
      py = "python";

      nfu = "nix flake update";
      ngc = "nix-collect-garbage -d";
      nsh = "nix-shell -p";

      gad = "git add";
      glg = "git log";
      grs = "git restore";
      dg = "ddgr --unsafe -n 6";
      bang = "ddgr --gb --np --unsafe";
      dj = "ddgr -j --unsafe";
      # ai = "aichat";
      ts = "tickrs";
    };
    shellAbbrs = {
      drr = "direnv reload";
      dra = "direnv allow";
      drb = "direnv block";
      dfl = "echo 'use flake' >> .envrc; direnv allow";

      #v = "nvim";
      tt = "taskwarrior-tui";
      # nuco = "nvim ~/.config/nushell/config.nu";
      # hxco = "hx ~/.config/helix/config.toml";
      # alco = "nvim ~/.config/alacritty/alacritty.yml";
      swim = "home-manager switch --flake '${config.home.homeDirectory}/nixpkgs#${homeProfile}'";
      shr = "home-manager switch --flake github:KaminariOS/nixpkgs/dev#shellhome --extra-experimental-features nix-command --extra-experimental-features flakes";
      # nico = "nvim ~/.config/nixpkgs/home.nix";
      ll = "eza -l --git";
      his = "history";
      lt = "eza --icons --tree --no-user --no-permissions --git";
      # ls = "eza --icons -l --no-user --no-permissions --git";
      du = "dust";
      psr = "procs";
      rfr = "rofi -show run";
      dif = "delta";
      ca = "cargo";
      man = "batman";
      scs = "systemctl suspend";
      gp = "git pso";
      ga = "git ca";
      gs = "git st";
      gd = "git diff";
      gl = "git plo --ff-only";
      gsh = "git show";
      gcl = "git clone";
      gdb = "gdb";
      logout = "pkill -u $USER";
      uvr = "uv run";
      dk = "docker";
      pm = "podman";
      pr = "podman -r";

      kb = "kubectl";
      kba = "kubectl apply -f";
      kbg = "kubectl get --all-namespaces";
      kbgs = "kubectl get svc --all-namespaces";
      kbgp = "kubectl get pods --all-namespaces";
      kbd = "kubectl describe --all-namespaces";
      kbds = "kubectl describe svc --all-namespaces";
      kbdp = "kubectl describe pods --all-namespaces";
      kbr = "kubectl rollout --all-namespaces";
      kbl = "kubectl logs --all-namespaces";
      kbdb = "kubectl debug -it -n --image=busybox --all-namespaces";
      kbe = "kubectl edit --all-namespaces";

      fr = "flux reconcile";
      frk = "flux reconcile ks flux-system --with-source";
      fga = "flux get -A";
      fls = "flux logs --since=1h -f";

      kt = "kubetui";
      kta = "kubetui -A";

      uvn = "uvx napy";

      helmi = "helm upgrade --install";
      helmu = "helm uninstall";
    };
    plugins = [custom.theme fenv bass puffer done];
    interactiveShellInit = ''
      eval (direnv hook fish)
      any-nix-shell fish --info-right | source
    '';
    shellInit = nixDaemonInit + fishConfig + loadenv;
  };

  xdg.configFile."fish/functions/fish_prompt.fish".text = custom.prompt;
}
