{
  programs.zsh = {
    enable = true;
    initContent =
      let
        # Restore nix after macOS updates break home-manager
        nixDaemonFix = ''
          [[ ! $(command -v nix) && -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]] && source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        '';
        aliases = ''
          alias cat="bat"
          alias cd="z"
          alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
          alias lazydots='lazygit --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
        '';
        env = ''
          export MANPAGER='nvim +Man!'
          # Apple didn't adopt XDG
          export XDG_CONFIG_HOME="$HOME/.config"
          export XDG_DATA_HOME="$HOME/.local/share"
          export XDG_STATE_HOME="$HOME/.local/state"
          export XDG_CACHE_HOME="$HOME/.cache"
        '';
        completion = ''
          compdef dotfiles=git
        '';
      in
      nixDaemonFix + aliases + env + completion;
  };
}
