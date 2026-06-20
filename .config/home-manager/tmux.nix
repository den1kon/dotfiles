{ pkgs, ... }:
{
  # pkgs.tmux
  programs.tmux = {
    enable = true;
    clock24 = false;
    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.cpu
    ];
    extraConfig = ''
      # set -ga terminal-overrides ",*-256color:Tc"
      set -g default-terminal "alacritty"
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # colored underscores
      set -as terminal-overrides ',alacritty:RGB' # true-color support
    '';
  };
}
