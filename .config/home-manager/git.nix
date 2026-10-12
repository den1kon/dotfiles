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
        # No trailing slash: a bare repository's gitdir is the directory itself,
        # while "dir/" only matches paths below it (such as dir/.git).
        condition = "gitdir:~/.dotfiles";
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
      {
        condition = "gitdir:~/gitLair/klarbeleg/";
        contents = {
          user.email = "dkondratiuk@pm.me";
        };
      }
    ];
  };
}
