# nix-config

Reusable Home Manager flake for Derek's machines.

It provides:

- A Home Manager profile with common CLI and desktop tools
- A packaged LazyVim-based `nvim`
- Git and Zsh configuration
- A user-managed PostgreSQL 18 service
- A reusable NixOS PostgreSQL auth module

## Layout

- [flake.nix](/home/derek/nix-config/flake.nix): top-level inputs, user settings, shared package helpers
- [flake-outputs.nix](/home/derek/nix-config/flake-outputs.nix): Home Manager outputs, PostgreSQL service, dev shell, package outputs

## Included tools

The default package set currently includes:

- `fd`
- `git`
- `nixfmt`
- `ripgrep`
- `zsh`
- `magic-wormhole-rs`
- `direnv`
- `postgresql_18`
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

## PostgreSQL

This repo runs PostgreSQL as a `systemd --user` service, not as a system-wide Debian service.

Important details:

- PostgreSQL data directory: `~/.local/share/postgresql/18`
- PostgreSQL socket directory: `$XDG_RUNTIME_DIR/postgresql`
- Default database created by activation: `mental-math-db`
- Local auth method: `scram-sha-256`
- Password encryption: `scram-sha-256`

Because it is a user service, manage it with:

```bash
systemctl --user status postgresql
systemctl --user restart postgresql
journalctl --user -u postgresql --no-pager -n 100
```

## PostgreSQL password

The PostgreSQL role password is managed declaratively from:

```bash
~/.config/postgresql/role-password
```

Create it like this:

```bash
mkdir -p ~/.config/postgresql
chmod 700 ~/.config/postgresql
printf '%s\n' 'your-strong-password-here' > ~/.config/postgresql/role-password
chmod 600 ~/.config/postgresql/role-password
```

Then apply the config:

```bash
update-system
systemctl --user restart postgresql
```

## Connect to PostgreSQL

The shell config exports `PGHOST` to the user socket path. If needed, set it manually:

```bash
export PGHOST="$XDG_RUNTIME_DIR/postgresql"
```

Connect with:

```bash
psql -h "$PGHOST" -U derek -d mental-math-db
```

Useful checks:

```bash
psql -h "$PGHOST" -l
psql -h "$PGHOST" -d postgres -c '\du'
psql -h "$PGHOST" -d postgres -c '\conninfo'
```

## NixOS module

This flake also exports a reusable NixOS module:

- `nixosModules.postgresql-secure-auth`

It configures PostgreSQL with:

- local `scram-sha-256`
- localhost TCP `scram-sha-256`
- `password_encryption = "scram-sha-256"`

That module is intended for NixOS consumers of this flake. It is separate from the Home Manager PostgreSQL user service used on this Debian host.

## Validation

Check the flake without building everything:

```bash
nix flake check --no-build
```

## Notes

- Flakes only see files tracked by Git, so new imported files must be added to the repo.
- The repo may show `warning: Git tree ... is dirty` during local work; that is expected while editing.
