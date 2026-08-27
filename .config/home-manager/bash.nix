{
  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza";
    };
    bashrcExtra = ''
      alias cat="bat"
      alias cd="z"
      alias dotfiles='/usr/bin/env git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
      alias lazydots='lazygit --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
      complete -cf doas
      export MANPAGER='nvim +Man!'
    '';
  };
}
