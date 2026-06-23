{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Denys Kondratiuk";
        email = "dkondratiuk@pm.me";
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
        condition = "gitdir:~/gitLair/check24/thv/thv-core";
        contents = {
          user.email = "denys.kondratiuk@check24.de";
        };
      }
      {
        condition = "gitdir:~/gitLair/check24/thv/thv-desktop";
        contents = {
          user.email = "denys.kondratiuk@check24.de";
        };
      }
      {
        condition = "gitdir:~/gitLair/check24/thv/thv-mobile";
        contents = {
          user.email = "denys.kondratiuk@check24.de";
        };
      }
    ];
  };
}
