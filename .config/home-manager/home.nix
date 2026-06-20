{
  # config,
  pkgs,
  username,
  system,
  tree-sitter-cli,
  ...
}:

with pkgs;

let
  php = php82.buildEnv {
    extensions = (
      { enabled, all }:
      enabled
      ++ (with all; [
        xdebug
        imagick
        redis
        xsl
      ])
    );
    extraConfig = ''
      xdebug.mode=debug
    '';
  };

  homeDirectory = if system == "aarch64-darwin" then "/Users/${username}" else "/home/${username}";

  isMacbook = system == "aarch64-darwin";
  isThinkpad = system == "x86_64-linux";
  isLinux = isThinkpad;

  iosevkaTermNerdFont = nerd-fonts.iosevka-term;

  fontsDir = if isMacbook then "Library/Fonts" else ".local/share/fonts";
in
{
  home.username = username;
  home.homeDirectory = homeDirectory;

  nixpkgs.config.allowUnfree = true;
  home.stateVersion = "25.11";

  home.packages = [
    # php85
    # php85Packages.composer
    # symfony-cli
    # telegram-desktop
    vaultwarden-postgresql
    tree-sitter-cli
    neovim
    imagemagick
    redis
    nodejs_24
    adminer

    markdown-oxide
    lua-language-server
    typescript-language-server
    stylua
    nil
    nixfmt
    prettierd
    jq
    php82Packages.php-cs-fixer
    phpactor
    tinymist
    typstyle
    astyle
    rumdl

    fzf

    rustc
    rustfmt
    cargo

    ripgrep
    fd

    # clang-tools

    iosevkaTermNerdFont
  ]
  ++ (
    if isMacbook then
      [
        # usbutils
        fritzing
        signal-desktop
        obsidian
        # osu-lazer-bin
        # spotify-player
        spotify
        vagrant

        jetbrains.phpstorm
        code-cursor
        orbstack
        php
        (php82Packages.composer.override { inherit php; })
        anki-bin

        spotify-player
      ]
    else
      [ ]
  )
  ++ (
    if isThinkpad then
      [
        spotify-player
      ]
    else
      [ ]
  );

  home.file."${fontsDir}/NerdFonts".source = iosevkaTermNerdFont;

  fonts.fontconfig.enable = isLinux;

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.home-manager.enable = true;
}
