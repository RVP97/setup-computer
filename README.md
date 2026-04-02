# setup-computer

Personal macOS bootstrap: [Homebrew](https://brew.sh/) packages, symlinked dotfiles, and optional system defaults. Safe to re-run; paths are resolved from the script’s location, so the repo can live anywhere on disk.

## Requirements

- macOS
- Network access for Homebrew and `brew bundle`
- Apple Silicon or Intel (Homebrew is detected under `/opt/homebrew` or `/usr/local`)

## Quick start

```bash
git clone <your-repo-url> ~/path/you/prefer/setup-computer
cd ~/path/you/prefer/setup-computer
chmod +x bootstrap.sh macos.sh   # macos.sh must be executable to run from bootstrap
./bootstrap.sh
```

Then restart the terminal or run `source ~/.zshrc`.

If Homebrew was **just** installed and the script exits asking for a new terminal, open a fresh window and run `./bootstrap.sh` again.

## What `bootstrap.sh` does

1. Installs Homebrew if it is missing, then loads it into the current shell.
2. Adds a **single** `brew shellenv` line to `~/.zprofile` if one is not already there (re-runs do not duplicate it).
3. Runs `brew update` and `brew bundle` using this repo’s `Brewfile`.
4. Symlinks `dotfiles/.zshrc` → `~/.zshrc` and `dotfiles/.ssh/config` → `~/.ssh/config`, creates `~/.ssh` if needed, and sets `600` on the SSH config.
5. Runs `macos.sh` when it exists **and** is executable (`chmod +x macos.sh`).

## `macos.sh`

Applies `defaults` for Dock, keyboard repeat, trackpad, Finder, screenshots, and a few global UI tweaks, then restarts Dock, Finder, and SystemUIServer where needed. Run it alone anytime:

```bash
./macos.sh
```

Some changes may require logging out and back in.

## Customizing

- **Packages and apps:** edit `Brewfile`, then run `brew bundle` (or re-run `./bootstrap.sh`).
- **Shell and SSH client config:** edit files under `dotfiles/`; symlinks pick up changes immediately.
- **SSH keys:** this repo only manages `~/.ssh/config`. Generate or copy keys separately; do not commit private keys.

## Repository layout

| Path | Role |
|------|------|
| `bootstrap.sh` | One-shot machine setup |
| `Brewfile` | `brew bundle` formula and cask list |
| `macos.sh` | macOS `defaults` |
| `dotfiles/` | Source files symlinked into `$HOME` |
