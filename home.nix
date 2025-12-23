{ config, pkgs, ... }:
let variables = import ./vars.nix; 
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = variables.username;
  home.homeDirectory = variables.homeDirectory;
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.ripgrep
    pkgs.fd
    pkgs.fzf
    pkgs.gcc
    pkgs.nixd
    pkgs.lua-language-server
    pkgs.rustup
    pkgs.zlib
    pkgs.openssh_gssapi
    pkgs.kitty
    pkgs.git
    pkgs.yazi
    pkgs.yaziPlugins.git
    pkgs.helix
    pkgs.glibc
    pkgs.htop
    pkgs.bat
    pkgs.fira-code

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      rrhm = "nix run home-manager/master -- init --switch --impure";
    };
    initExtra = ''
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      	  builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
    '';
  };
  

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    settings = {
      enter_accept = false;
    };
  };
  programs.helix = {
    enable = true;
    settings = {
      keys.normal = {
        "#" = "toggle_line_comments";
      };
    };
  };

  # xdg.configFile."nvim".source = /home/Z42437/code/nvim;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/Z42437/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # helix makes sense as the default editor for anyone who doesn't 
    # have a preference, since it's usable with minimal configuration and
    # has lsp support out of the box.
    EDITOR = "hx";
    SHELL = "bash";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
