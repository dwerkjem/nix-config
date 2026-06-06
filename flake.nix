{
  description = "Reusable home-manager flake built for servers. Includes a set of common tools and packages I use across all my machines, and is designed to unify and simplify configuration management.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      home-manager,
      nixgl,
      nixpkgs,
      sops-nix,
      ...
    }:
    let
      defaultOptions = import ./options.defaults.nix;
      configDirectory =
        let
          configured = builtins.getEnv "NIX_CONFIG_DIR";
          pwd = builtins.getEnv "PWD";
          home = builtins.getEnv "HOME";
        in
        if configured != "" then
          configured
        else if builtins.pathExists "${pwd}/options.nix" then
          pwd
        else
          "${home}/nix-config";
      localOptionsPath = "${configDirectory}/options.nix";
      secretsFilePath = "${configDirectory}/secrets/secrets.yaml";
      secretsFile =
        if builtins.pathExists secretsFilePath then
          builtins.path {
            path = secretsFilePath;
            name = "nix-config-secrets.yaml";
          }
        else
          null;
      localOptions =
        if builtins.pathExists localOptionsPath then import localOptionsPath else { };
      options = defaultOptions // localOptions;
      fullName = options.fullName;
      gitName = options.gitName;
      email = options.email;
      username = options.username;
      stateVersion = options.stateVersion;
      enableDesktop = options.enableDesktop;
      useNvidiaNixGL = options.useNvidiaNixGL;
      homeDirectory = "/home/${username}";
      basePackageSetName = "${username}-base-tools";
      desktopPackageSetName = "${username}-desktop-tools";
      packageSetName =
        if enableDesktop then desktopPackageSetName else basePackageSetName;
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
      mkQtPackages =
        pkgs:
        with pkgs;
        [
          # Build tools
          cmake
          ninja
          gcc

          # Qt libraries and tooling
          qt6.qtbase
          qt6.qttools
          qt6.qtmultimedia
          qt6.qtsvg
          qt6.qtdeclarative
        ];
      mkBasePackages =
        system:
        let
          pkgs = mkPkgs system;
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
          # Shell and environment
          zsh
          direnv
          ghostty

          # Editors and IDEs
          lazyvim
          vscode

          # Version control and Nix
          git
          nixfmt

          # Search and file navigation
          fd
          ripgrep

          # Networking and file transfer
          magic-wormhole-rs
          rclone
          wget

          # Language runtimes and package tools
          nodejs
          nodenv
          rustc
          python313Env
          poetry
          uv
          gcc.cc.lib
    
          # Task and time tracking
          taskwarrior3
          timewarrior
          taskwarrior-tui

          # Secrets and encryption
          gnupg
          age
          sops

          # Disk and system tools
          htop
          parted
        ]
        ++ (mkQtPackages pkgs);
      mkDesktopPackages =
        system:
        let
          pkgs = mkPkgs system;
          vivaldiWithCodecs = pkgs.vivaldi.override {
            proprietaryCodecs = true;
            enableWidevine = true;
          };
        in
        with pkgs;
        [
          # Browsers
          vivaldiWithCodecs

          # Communication
          discord

          # Gaming and media
          steam
          spotify

          # Notes and knowledge
          obsidian

          # Disk and system tools
          gnome-disk-utility
        ];
      mkPackages =
        system: desktopEnabled:
        (mkBasePackages system)
        ++ nixpkgs.lib.optionals desktopEnabled (mkDesktopPackages system);
    in
    (import ./flake-outputs.nix {
      inherit
        home-manager
        nixgl
        nixpkgs
        sops-nix
        configDirectory
        secretsFile
        username
        homeDirectory
        stateVersion
        enableDesktop
        useNvidiaNixGL
        gitName
        email
        mkPkgs
        mkQtPackages
        mkBasePackages
        mkDesktopPackages
        mkPackages
        basePackageSetName
        desktopPackageSetName
        packageSetName
        forAllSystems
        ;
    });
}
