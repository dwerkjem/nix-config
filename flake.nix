{
  description = "Reusable home-manager flake built for servers. Includes a set of common tools and packages I use across all my machines, and is designed to unify and simplify configuration management.";

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
      #-- USER CONFIGURATION --#
      # CHANGE THESE TO YOUR OWN VALUES BEFORE USING THIS FLAKE
      fullName = "Derek R. Neilson";
      gitName = "dwerkjem";
      email = "derekrneilson@gmail.com";
      username = "derek";
      #-- END OF USER CONFIGURATION--#
      homeDirectory = "/home/${username}";
      packageSetName = "${username}-global-tools";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      mkPackages =
        system:
        let
          pkgs = mkPkgs system;
          postgresPackage = pkgs.postgresql_18;
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
          direnv
          postgresPackage
          lazyvim
          nodejs
          nodenv
          python313Env
          poetry
          vscode
          docker-compose
          docker
        ];
    in
    import ./flake-outputs.nix {
      inherit
        home-manager
        nixpkgs
        username
        homeDirectory
        gitName
        email
        mkPkgs
        mkPackages
        packageSetName
        forAllSystems
        ;
    };
}
