{
  description = "Derek's flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { home-manager, nixpkgs, ... }:
    let
      username = "derek";
      homeDirectory = "/home/derek";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      mkPackages =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lazyvimInit = pkgs.writeText "lazyvim-init.lua" ''
            vim.g.mapleader = " "
            vim.g.maplocalleader = "\\"

            vim.opt.rtp:prepend("${pkgs.vimPlugins.lazy-nvim}")

            require("lazy").setup({
              spec = {
                {
                  dir = "${pkgs.vimPlugins.LazyVim}",
                  name = "LazyVim",
                  import = "lazyvim.plugins",
                },
              },
              defaults = {
                lazy = false,
                version = false,
              },
              checker = {
                enabled = false,
              },
              change_detection = {
                notify = false,
              },
            })
          '';
          lazyvim = pkgs.wrapNeovim pkgs.neovim-unwrapped {
            viAlias = true;
            vimAlias = true;
            configure = {
              customRC = ''
                luafile ${lazyvimInit}
              '';
            };
          };
        in
        [
          pkgs.fd
          pkgs.git
          pkgs.nixfmt
          pkgs.ripgrep
          pkgs.zsh
          pkgs.magic-wormhole-rs
          pkgs.lemonade
          pkgs.direnv
          pkgs.postgresql_18
          lazyvim
        ];
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          {
            home.username = username;
            home.homeDirectory = homeDirectory;
            home.stateVersion = "25.05";

            home.packages = mkPackages "x86_64-linux";

            programs.git = {
              enable = true;
              settings.user = {
                name = "dwerkjem";
                email = "derekrneilson@gmail.com";
              };
            };

            programs.home-manager.enable = true;
          }
        ];
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.buildEnv {
            name = "derek-global-tools";
            paths = mkPackages system;
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = mkPackages system;
          };
        }
      );
    };
}
