# nix-config

Reusable Home Manager flake for Derek's machines.

It provides:

- A Home Manager profile with a server-safe base plus an optional desktop layer
- A packaged LazyVim-based `nvim`
- Git and Zsh configuration
- `sops-nix` scaffolding for encrypted per-user secrets

## Usage
Clone the repo in your home directory:

```bash
git clone https://github.com/dwerkjem/nix-config.git
```

Then set the `NIX_CONFIG_DIR` environment variable to point at the repo:

```bash
export NIX_CONFIG_DIR=$HOME/nix-config
```

then make sure that nix has experimental features enabled in `/etc/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

then set the options in `options.nix` by copying `options.nix.example` to `options.nix` and editing the values there.

then you can run the Home Manager alias to apply the configuration:

```bash
NIX_CONFIG_DIR=$HOME/nix-config nix run github:nix-community/home-manager -- switch --impure --flake $HOME/nix-config#$USER
```

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
NIX_CONFIG_DIR=$HOME/nix-config nix run github:nix-community/home-manager -- switch --impure --flake $HOME/nix-config#$USER
```