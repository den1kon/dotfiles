{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    textfox.url = "github:adriankarlen/textfox";
    tree-sitter = {
      url = "github:tree-sitter/tree-sitter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      textfox,
      tree-sitter,
      ...
    }:
    let
      # Define configurations for different machines
      configs = {
        macbook = {
          system = "aarch64-darwin";
          username = "denyskondratiuk";
          modules = [
            textfox.homeManagerModules.default
            ./home.nix
            ./git.nix
            ./firefox.nix
            ./alacritty.nix
            ./tmux.nix
            ./delta.nix
            ./lazygit.nix
            ./zsh.nix
            ./eza.nix
            ./bat.nix
            ./zoxide.nix
            ./starship.nix
            ./man.nix
            ./tealdeer.nix
          ];
        };
        thinkpad = {
          system = "x86_64-linux";
          username = "dk";
          modules = [
            textfox.homeManagerModules.default
            ./home.nix
            ./bash.nix
            ./firefox.nix
            ./gtk.nix
            ./delta.nix
            ./lazygit.nix
          ];
        };
      };

      mkHomeConfig =
        name: config:
        let
          pkgs = nixpkgs.legacyPackages.${config.system};
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = config.modules;
          extraSpecialArgs = {
            inherit (config) system username;
            tree-sitter-cli = tree-sitter.packages.${config.system}.cli;
          };
        };
    in
    {
      homeConfigurations = builtins.mapAttrs mkHomeConfig configs;
    };
}
