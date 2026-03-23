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
          gdrive = pkgs.stdenvNoCC.mkDerivation rec {
            pname = "gdrive";
            version = "2.1.1";

            src = pkgs.fetchurl {
              url = "https://github.com/prasmussen/gdrive/releases/download/${version}/gdrive_${version}_linux_amd64.tar.gz";
              sha256 = "sha256-BI10g1c4+X8rH4ZBt0a9DqhrZ+8vt6Ff3eN3S1nU3I4=";
            };

            nativeBuildInputs = [ pkgs.autoPatchelfHook ];
            buildInputs = [ pkgs.musl ];

            sourceRoot = ".";

            installPhase = ''
              runHook preInstall
              install -Dm755 gdrive $out/bin/gdrive
              runHook postInstall
            '';
          };
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
          lazyvim
          nodejs
          nodenv
          python313Env
          poetry
          vscode
          docker-compose
          docker
          musl
          gdrive
          gnupg
          wget
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
