{
  # config,
  pkgs,
  username,
  system,
  # tree-sitter-cli,
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
        igbinary
        pspell
      ])
    );
    extraConfig = ''
      xdebug.mode=debug
    '';
  };

  homeDirectory = if system == "aarch64-darwin" then "/Users/${username}" else "/home/${username}";

  isMacbook = system == "aarch64-darwin";
  isLinux = system == "x86_64-linux";

  iosevkaTermNerdFont = nerd-fonts.iosevka-term;

  fontsDir = if isMacbook then "Library/Fonts" else ".local/share/fonts";
in
{
  home.username = username;
  home.homeDirectory = homeDirectory;

  nixpkgs.config.allowUnfree = true;
  home.stateVersion = "26.11";

  home.packages = [
    # GUI
    dbeaver-bin
    yaak
    bruno
    # prismlauncher

    gnumake

    neovim

    imagemagick
    redis
    nodejs_24

    # Treesitter/LSP
    # tree-sitter-cli
    tree-sitter
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

    iosevkaTermNerdFont
  ]
  ++ (
    if isMacbook then
      [
        maccy
        claude-code
        spotify
        vagrant

        jetbrains.phpstorm
        code-cursor
        orbstack
        php
        (php82Packages.composer.override { inherit php; })
        anki-bin

        # spotify-player
      ]
    else
      [ ]
  )
  ++ (
    if isLinux then
      [
        glibc
        clang
        wl-clipboard
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
