# dotfiles — repo conventions

Nix flakes + home-manager, multi-host, cross-platform (nix-darwin on macOS, NixOS on Linux + WSL).
Secrets via sops-nix. Entry point: `flake.nix`.

## Critical

- **`git add` before applying.** Flakes ignore untracked files — a new `.nix` file is invisible to
  the build until staged. Stage first, then apply.
- **Format with `nix fmt`.** The flake formatter is treefmt (alejandra, deadnix, statix, typos,
  oxfmt, renovate-validator); config in `treefmt.nix`. The pre-commit hook (on dev hosts) auto-runs
  gitleaks + treefmt on staged files.

## Commands

| Command                              | Effect                                                       |
| ------------------------------------ | ------------------------------------------------------------ |
| `nix run .#apply`                    | `darwin-rebuild`/`nixos-rebuild switch` for the current host |
| `nix run .#update`                   | `nix flake update` + run every package's `update.nu`         |
| `nix run .#clean`                    | GC generations older than 1 day                              |
| `nix build .#checks.<system>.<host>` | dry build a host (CI builds all)                             |

## Layout

- `flake.nix` — hosts wired via `mkDarwinHost`/`mkNixosHost` (`lib/default.nix`); `globals.nix` = name/email/keys.
- `hosts/<name>/{default,home}.nix` + `hosts/base*.nix` — per-machine config. Darwin host: `pelico`.
- `home-manager/applications/<app>/` — user program config; `home-manager/shell/` — zsh, git, tmux, ssh.
- `pkgs/<name>/` — custom derivations, exported in `flake.packages`. Each bumps itself via a
  `passthru.updateScript` → `update.nu` (nushell), driven by `nix run .#update`.
- `modules/` — NixOS/darwin system modules; `dev/` — dev-shell flake (treefmt + git hooks).

## Patterns

- Feature toggles use the `local.home-manager.<name>.enable` option pattern — follow it for new opt-in modules.
- Prefer nixpkgs packages over Homebrew casks when both exist.
- Renovate owns GitHub Actions + pinned Docker digests; the weekly `flake-update.yml` workflow owns Nix inputs.
