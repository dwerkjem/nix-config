{
  home-manager,
  nixgl,
  nixpkgs,
  sops-nix,
  configDirectory,
  secretsFile,
  username,
  homeDirectory,
  stateVersion,
  enableDesktop,
  useNvidiaNixGL,
  gitName,
  email,
  mkPkgs,
  mkQtPackages,
  mkBasePackages,
  mkDesktopPackages,
  mkPackages,
  basePackageSetName,
  desktopPackageSetName,
  packageSetName,
  forAllSystems,
}:
{
  formatter = forAllSystems (system: (mkPkgs system).nixfmt);

  homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
    pkgs = mkPkgs "x86_64-linux";
    modules = [
      sops-nix.homeManagerModules.sops
      (
        { config, lib, pkgs, ... }:
        let
          qtPackages = mkQtPackages pkgs;
          qtCmakePrefixPath = pkgs.lib.makeSearchPath "" [
            pkgs.qt6.qtbase
            pkgs.qt6.qtdeclarative
            pkgs.qt6.qtmultimedia
            pkgs.qt6.qtsvg
          ];
          qtPluginPath = pkgs.lib.makeSearchPath "lib/qt-6/plugins" qtPackages;
          qtQmlImportPath = pkgs.lib.makeSearchPath "lib/qt-6/qml" qtPackages;
          isIntelX86Platform = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
          nixglPackages = import nixgl {
            inherit pkgs;
            enable32bits = isIntelX86Platform;
            enableIntelX86Extensions = isIntelX86Platform;
          };
          desktopPackages = mkDesktopPackages "x86_64-linux";
          desktopPackagesWithoutSteam =
            builtins.filter
              (package: lib.getName package != lib.getName pkgs.steam)
              desktopPackages;
        in
        {
          home.username = username;
          home.homeDirectory = homeDirectory;
          home.stateVersion = stateVersion;

          targets.genericLinux.nixGL = {
            packages = nixglPackages;
            defaultWrapper = if useNvidiaNixGL then "nvidia" else "mesa";
            vulkan.enable = true;
          };

          home.packages =
            (mkBasePackages "x86_64-linux")
            ++ lib.optionals enableDesktop (
              desktopPackagesWithoutSteam
              ++ [ (config.lib.nixGL.wrap pkgs.steam) ]
            );

          home.sessionVariables = {
            SHELL = "${pkgs.zsh}/bin/zsh";
            CMAKE_PREFIX_PATH = qtCmakePrefixPath;
            QT_PLUGIN_PATH = qtPluginPath;
            QML2_IMPORT_PATH = qtQmlImportPath;

            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
              pkgs.stdenv.cc.cc.lib
              pkgs.zlib
            ];
          } // lib.optionalAttrs enableDesktop {
            TERMINAL = "${pkgs.alacritty}/bin/alacritty";
          };

          systemd.user.startServices = "sd-switch";
              programs.direnv = {
              enable = true;
              nix-direnv.enable = true;
            };

          programs.zsh = {
            enable = true;

            oh-my-zsh = {
              enable = true;
              theme = "agnoster";
              plugins = [ "git" ];
            };

            shellAliases = {
              update-system = "NIX_CONFIG_DIR=$HOME/nix-config nix run github:nix-community/home-manager -- switch --impure --flake $HOME/nix-config#$USER";
              wormhole = "wormhole-rs";
              nv = "nvim";
            };

            initContent = ''
              # Managed by Home Manager.

              if [ -d "$HOME/.nix-profile/bin" ]; then
                export PATH="$HOME/.nix-profile/bin:$PATH"
              fi

              if [ -d "$HOME/.nix-profile/share" ]; then
                export XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"
              fi

              export EDITOR="$HOME/.nix-profile/bin/nvim"
              export VISUAL="$HOME/.nix-profile/bin/nvim"
              export SUDO_EDITOR="$HOME/.nix-profile/bin/nvim"

              if [ -f "$HOME/.local/bin/env" ]; then
                source "$HOME/.local/bin/env"
              fi

              export PATH="$HOME/bin:$PATH"

              # Load settings that are intentionally not managed by Home Manager.
              if [ -f "$HOME/.zshrc.local" ]; then
                source "$HOME/.zshrc.local"
              fi
            '';
          };

          programs.alacritty = lib.mkIf enableDesktop {
            enable = true;
            settings = {
              shell.program = "${pkgs.zsh}/bin/zsh";
            };
          };

          programs.git = {
            enable = true;
            settings.user = {
              name = gitName;
              email = email;
            };
          };

          xdg.configFile."git/ignore" = {
            text = ''
              .codex
            '';
            force = true;
          };

          programs.taskwarrior = {
            enable = true;
            package = pkgs.taskwarrior3;
            extraConfig = ''
              uda.reviewed.type=date
              urgency.user.tag.next.coefficient=15
            '';
          };

          home.file.".task/hooks/on-modify.timewarrior" = {
            source = "${pkgs.timewarrior}/share/doc/timew/ext/on-modify.timewarrior";
            executable = true;
          };

          programs.home-manager.enable = true;
        }
      )
    ];
  };

  packages = forAllSystems (
    system:
    let
      pkgs = mkPkgs system;
    in
    {
      default = pkgs.buildEnv {
        name = packageSetName;
        paths = mkPackages system enableDesktop;
      };

      Desktop = pkgs.buildEnv {
        name = desktopPackageSetName;
        paths = (mkBasePackages system) ++ (mkDesktopPackages system);
      };

      base = pkgs.buildEnv {
        name = basePackageSetName;
        paths = mkBasePackages system;
      };
    }
  );

    devShells = forAllSystems (
    system:
    let
      pkgs = mkPkgs system;
      qtCmakePrefixPath = pkgs.lib.makeSearchPath "" [
        pkgs.qt6.qtbase
        pkgs.qt6.qtdeclarative
        pkgs.qt6.qtmultimedia
        pkgs.qt6.qtsvg
      ];

      nativeLibraryPath = pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
      ];
    in
    {
      default = pkgs.mkShell {
        packages = mkPackages system enableDesktop;

        shellHook = ''
          export CMAKE_PREFIX_PATH="${qtCmakePrefixPath}:$CMAKE_PREFIX_PATH"
          export LD_LIBRARY_PATH="${nativeLibraryPath}:$LD_LIBRARY_PATH"
        '';
      };

      python = pkgs.mkShell {
        packages = with pkgs; [
          python313
          uv
          gcc
          zlib
        ];

        shellHook = ''
          export LD_LIBRARY_PATH="${nativeLibraryPath}:$LD_LIBRARY_PATH"

          if [ -d .venv ]; then
            source .venv/bin/activate
          fi
        '';
      };
    }
  );
}
