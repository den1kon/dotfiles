{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Denys Kondratiuk";
        email = "denys.kondratiuk@check24.de";
      };
      init.defaultBranch = "main";
      core = {
        editor = "nvim";
        pager = "delta";
      };
      # Defined in delta.nix via git integration option
      # interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        dark = true;
      };
      merge.conflictStyle = "zdiff3";
    };

    includes = [
      {
        condition = "gitdir:~/.dotfiles/";
        contents = {
          user.email = "dkondratiuk@pm.me";
        };
      }
      {
        condition = "gitdir:~/gitLair/digital-notes/";
        contents = {
          user.email = "dkondratiuk@pm.me";
        };
      }
    ];
  };
}
