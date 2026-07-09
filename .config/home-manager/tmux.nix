{ pkgs, ... }:
{
  # pkgs.tmux
  programs.tmux = {
    enable = true;
    clock24 = false;
    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.cpu
      tmuxPlugins.nord
      tmuxPlugins.resurrect
      tmuxPlugins.continuum
    ];
    extraConfig = ''
      set -g prefix C-a
      unbind C-b
      bind C-a send-prefix
      set -g status-position top
      # set -ga terminal-overrides ",*-256color:Tc"
      set -g default-terminal "alacritty"
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # colored underscores
      set -as terminal-overrides ',alacritty:RGB' # true-color support
      # Start windows and panes at 1, not 0
      set -g base-index 1
      setw -g pane-base-index 1
      # Plugins
      set -g @continuum-restore 'on' # Last saved environment is automatically restored when tmux is started.
      set -g @continuum-boot-options 'alacritty,fullscreen'
    '';
  };
}
