{
  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza";
    };
    bashrcExtra = ''
      complete -cf doas
      export MANPAGER='nvim +Man!'
    '';
  };
}
