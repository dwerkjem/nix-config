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
          # Keep Python CLI tooling bundled under one interpreter to avoid
          # Home Manager path collisions between multiple Python versions.
          python313Env = pkgs.python313.withPackages (
            ps: with ps; [
              pip
              virtualenv
              wheel
              setuptools
              black
              isort
            ]
          );
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
          # Package the LazyVim config as a normal Neovim binary so it can live
          # in home.packages like the rest of the toolchain.
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
        with pkgs;
        [
          # General packages and tools
          fd
          git
          nixfmt
          ripgrep
          zsh
          magic-wormhole-rs
          lemonade
          direnv
          postgresql_18
          lazyvim
          nodejs
          nodenv
          python313Env
          poetry
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
