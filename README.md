# nix-config

Reusable Home Manager flake for Derek's machines.

It provides:

- A Home Manager profile with a server-safe base plus an optional desktop layer
- A packaged LazyVim-based `nvim`
- Git and Zsh configuration
- `sops-nix` scaffolding for encrypted per-user secrets

## Layout

- [flake.nix](/home/derekrn/nix-config/flake.nix): top-level inputs, options loading, shared package helpers
- [flake-outputs.nix](/home/derekrn/nix-config/flake-outputs.nix): Home Manager outputs, shell configuration, dev shell, package outputs
- [options.defaults.nix](/home/derekrn/nix-config/options.defaults.nix): tracked fallback values used when no local options file exists
- [options.nix.example](/home/derekrn/nix-config/options.nix.example): example local overrides file to copy to `options.nix`

## Included tools

The shared base package set includes:

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
- `age`
- `sops`

The optional desktop layer adds:

- `vivaldi` with proprietary codecs and Widevine
- `vscode`
- Alacritty Home Manager configuration

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

User-editable values now live in an ignored local file named `options.nix`.
Start by copying [options.nix.example](/home/derekrn/nix-config/options.nix.example)
to `options.nix`, then update the values there.

The tracked defaults/example include:

- `fullName`
- `gitName`
- `email`
- `username`
- `stateVersion`
- `enableDesktop`

The flake falls back to [options.defaults.nix](/home/derekrn/nix-config/options.defaults.nix)
when `options.nix` is missing, so the repo still evaluates cleanly without
committing personal settings. Set `enableDesktop = false;` in `options.nix` on
servers to keep only the base package set and skip desktop-specific config.

## Apply the configuration

Use the Home Manager alias:

```bash
update-system
```

That expands to:

```bash
nix run github:nix-community/home-manager -- switch --impure --flake $HOME/nix-config#$USER
```

## Package outputs

The flake exposes these package bundles:

- `.#default`: base plus desktop when `enableDesktop = true`, otherwise base only
- `.#Desktop`: the full desktop bundle regardless of local toggle
- `.#base`: the server-safe base bundle

## Validation

Check the flake without building everything:

```bash
nix flake check --impure --no-build
```

## Notes

- The ignored `options.nix` file is loaded impurely from `$NIX_CONFIG_DIR/options.nix`
  or `$HOME/nix-config/options.nix`, so commands that evaluate the flake should use `--impure`.
- The repo may show `warning: Git tree ... is dirty` during local work; that is expected while editing.
