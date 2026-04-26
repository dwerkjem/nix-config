# nix-config

Reusable Home Manager flake for Derek's machines.

It provides:

- A Home Manager profile with common CLI and desktop tools
- A packaged LazyVim-based `nvim`
- Git and Zsh configuration
- `sops-nix` scaffolding for encrypted per-user secrets

## Layout

- [flake.nix](/home/derekrn/nix-config/flake.nix): top-level inputs, user settings, shared package helpers
- [flake-outputs.nix](/home/derekrn/nix-config/flake-outputs.nix): Home Manager outputs, shell configuration, dev shell, package outputs

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
- `age`
- `sops`

## sops-nix

The flake now imports `sops-nix` through Home Manager and expects an existing
age private key at `~/.config/sops/age/keys.txt`.

Before storing real secrets, put your private key in that file and set the
matching public recipient in [.sops.yaml](/home/derekrn/nix-config/.sops.yaml).
If you want to derive a recipient from an SSH key, you can use:

```bash
nix shell nixpkgs#ssh-to-age -c sh -c 'ssh-to-age < ~/.ssh/id_ed25519.pub'
```

Then encrypt a secrets file, for example:

```bash
mkdir -p secrets
cp secrets/example.yaml secrets/secrets.yaml
sops secrets/secrets.yaml
```

When you are ready to consume a secret from Home Manager, add a `sops.secrets`
entry in [flake-outputs.nix](/home/derekrn/nix-config/flake-outputs.nix) that
points at your encrypted `secrets/secrets.yaml`.

## User configuration

The flake currently hardcodes these values near the top of [flake.nix](/home/derekrn/nix-config/flake.nix):

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
