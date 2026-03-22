# nix-config

Reusable Home Manager flake for Derek's machines.

It provides:

- A Home Manager profile with common CLI and desktop tools
- A packaged LazyVim-based `nvim`
- Git and Zsh configuration

## Layout

- [flake.nix](/home/derek/nix-config/flake.nix): top-level inputs, user settings, shared package helpers
- [flake-outputs.nix](/home/derek/nix-config/flake-outputs.nix): Home Manager outputs, shell configuration, dev shell, package outputs

## Included tools

The default package set currently includes:

- `fd`
- `git`
- `nixfmt`
- `ripgrep`
- `zsh`
- `magic-wormhole-rs`
- `direnv`
- `nvim` via LazyVim packaging
- `nodejs`
- `nodenv`
- Python 3.13 with `pip`, `virtualenv`, `wheel`, `setuptools`, `black`, and `isort`
- `poetry`
- `vscode`

## User configuration

The flake currently hardcodes these values near the top of [flake.nix](/home/derek/nix-config/flake.nix):

- `fullName`
- `gitName`
- `email`
- `username`

If this repo is reused for another machine or user, update those values first.

## Apply the configuration

Use the Home Manager alias:

```bash
update-system
```

That expands to:

```bash
nix run github:nix-community/home-manager -- switch --flake $HOME/nix-config#$USER
```

## Validation

Check the flake without building everything:

```bash
nix flake check --no-build
```

## Notes

- Flakes only see files tracked by Git, so new imported files must be added to the repo.
- The repo may show `warning: Git tree ... is dirty` during local work; that is expected while editing.
