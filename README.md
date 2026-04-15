# setup-computer

Personal macOS bootstrap: [Homebrew](https://brew.sh/) packages, symlinked dotfiles, and optional system defaults. Safe to re-run; paths are resolved from the script’s location, so the repo can live anywhere on disk.

**GitHub:** [`RVP97/setup-computer`](https://github.com/RVP97/setup-computer) — URLs and defaults in [`install.sh`](install.sh) use this `owner/repo` unless you override `SETUP_COMPUTER_GITHUB`.

**Target hardware:** Apple Silicon Macs (M1 / M2 / M3 / M4 / M5 and later). Homebrew and `dotfiles/.zshrc` assume the standard prefix [`/opt/homebrew`](https://docs.brew.sh/Installation). Intel Macs are not supported here.

## Requirements

- macOS on **Apple Silicon**
- Network access for Homebrew and `brew bundle`

## Quick start

This repo is **public** — no GitHub token needed for the paths below (unless you use a **private fork**).

### Recommended: `git clone` + [`bootstrap.sh`](bootstrap.sh)

This is the path most dotfiles-style repos use: you get a real `.git` directory, can **`git pull`** to update scripts, and you run **`bootstrap.sh`** from a checkout you can read first.

```bash
git clone https://github.com/RVP97/setup-computer.git ~/setup-computer
cd ~/setup-computer
chmod +x bootstrap.sh macos.sh
./bootstrap.sh
```

If `git clone` on macOS prompts for Xcode/Developer Tools, install **Command Line Tools** first, then retry:

```bash
xcode-select --install
```

SSH (if your GitHub account uses it): `git clone git@github.com:RVP97/setup-computer.git ~/setup-computer`

### Quick alternative: one-liner ([`install.sh`](install.sh))

Same end state with fewer commands; handy on a brand-new Mac:

```bash
curl -fsSL https://raw.githubusercontent.com/RVP97/setup-computer/main/install.sh | bash
```

Caveat: if `git` is missing and the script falls back to a **tarball**, that tree has **no `.git`** — run `git clone` into `~/setup-computer` later if you want normal pulls. Treat `curl | bash` like any remote script (you trust `main` on this repo).

### Private fork or blocked `raw.githubusercontent.com`

Use a [PAT](https://github.com/settings/tokens) (**never commit it**):

```bash
export GITHUB_TOKEN=ghp_your_token_here
curl -fsSL \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.raw" \
  "https://api.github.com/repos/RVP97/setup-computer/contents/install.sh?ref=main" | bash
```

Or copy `install.sh` to the machine and run `GITHUB_TOKEN=… bash install.sh`.

### Environment variables (`install.sh`)

| Variable | Default | Purpose |
|----------|---------|---------|
| `GITHUB_TOKEN` | (unset) | Only for **private** repos or authenticated API fetch |
| `SETUP_COMPUTER_DIR` | `$HOME/setup-computer` | Where the repo is placed |
| `SETUP_COMPUTER_BRANCH` | `main` | Branch to clone / archive |
| `SETUP_COMPUTER_GITHUB` | `RVP97/setup-computer` | `owner/repo` for GitHub URLs |
| `SETUP_COMPUTER_CLONE_URL` | (derived) | Override clone URL (e.g. SSH or fork) |

**Security:** Treat `curl … | bash` like running any remote script; this one is yours on `main`. PATs can appear briefly in process listings—revoke one-off tokens after use.

### After bootstrap

On an **interactive** terminal, [`bootstrap.sh`](bootstrap.sh) finishes by running **`exec zsh -l`**, so a **login zsh** starts with your new `PATH` and `~/.zshrc` without opening another window. Type **`exit`** if you want the shell you launched bootstrap from.

Set **`SETUP_COMPUTER_SKIP_ZSH_REEXEC=1`** (e.g. in CI) to skip that and only print the reminder.

If Homebrew was **just** installed and the script exits asking for a **new terminal** before Homebrew is on `PATH`, open a new window and run `./bootstrap.sh` again — that case happens before the final `exec zsh -l`.

## What `bootstrap.sh` does

1. Installs Homebrew if it is missing, then loads it into the current shell.
2. Adds a **single** `brew shellenv` line to `~/.zprofile` if one is not already there (re-runs do not duplicate it).
3. Runs `brew update` and `brew bundle` using this repo’s `Brewfile`.
4. Installs [Oh My Zsh](https://ohmyz.sh/) with the upstream installer if `~/.oh-my-zsh` is missing (Homebrew does not provide a supported formula). Uses `KEEP_ZSHRC=yes` so your symlinked `~/.zshrc` is preserved. Also clones Powerlevel10k, zsh-autosuggestions, and zsh-syntax-highlighting into `~/.oh-my-zsh/custom/` when needed so the bundled `.zshrc` works on a new machine.
5. Symlinks `dotfiles/.zshrc` → `~/.zshrc`, `dotfiles/.gitconfig` → `~/.gitconfig`, and `dotfiles/.ssh/config` → `~/.ssh/config`, creates `~/.ssh` if needed, and sets `600` on the SSH config.
6. If [`dev-repos`](dev-repos) has entries, prompts you to **unlock 1Password** (for SSH), then clones or updates repos under **`~/dev`** (see file for path layout).
7. Runs `macos.sh` when it exists **and** is executable (`chmod +x macos.sh`).
8. In an interactive terminal, runs **`exec zsh -l`** so a login zsh loads with the updated `PATH` and `~/.zshrc` (skippable with `SETUP_COMPUTER_SKIP_ZSH_REEXEC=1`).

## `macos.sh`

Applies `defaults` for Dock, keyboard repeat, trackpad, Finder, screenshots, and a few global UI tweaks, then restarts Dock, Finder, and SystemUIServer where needed. Run it alone anytime:

```bash
./macos.sh
```

Some changes may require logging out and back in.

## Customizing

- **Packages and apps:** edit `Brewfile`, then run `brew bundle` (or re-run `./bootstrap.sh`).
- **Shell, Git, and SSH client config:** edit files under `dotfiles/`; symlinks pick up changes immediately. For Git identity, see `dotfiles/.gitconfig` (or override locally with `git config --global` if you do not want it in the repo).
- **SSH keys:** this repo only manages `~/.ssh/config`. Generate or copy keys separately; do not commit private keys.
- **Dev projects:** edit [`dev-repos`](dev-repos) — **`owner/repo`** per line (SSH). If the file has entries, **`bootstrap.sh` pauses** before cloning so you can **unlock 1Password** (your [`dotfiles/.ssh/config`](dotfiles/.ssh/config) uses the 1Password agent). Set **`SETUP_COMPUTER_SKIP_DEV_PAUSE=1`** to skip the pause. Optional **path first** (`webdev`, `webdev/paginas`, …) under **`~/dev`**. Env: **`SETUP_COMPUTER_DEV_ROOT`**, **`SETUP_COMPUTER_GITHUB_HOST`** (Enterprise).

### Clone dev repos separately

If you only want to clone/update projects from [`dev-repos`](dev-repos) (without running full bootstrap):

```bash
./clone-dev-repos.sh
```

You can also pass a different list file:

```bash
./clone-dev-repos.sh /path/to/dev-repos
```

After `git clone` succeeds for your repos, copy macOS Quick Actions from `mac-automator`:

```bash
mkdir -p ~/Library/Services && cp -R "/Users/rodrigo/dev/automation/mac-automator/"*.workflow ~/Library/Services/
```

## Repository layout

| Path | Role |
|------|------|
| `install.sh` | Remote one-liner: fetch repo + run `bootstrap.sh` |
| `bootstrap.sh` | One-shot machine setup |
| `Brewfile` | `brew bundle` formula and cask list |
| `macos.sh` | macOS `defaults` |
| `dev-repos` | Optional: one `owner/repo` per line → cloned into `~/dev` |
| `clone-dev-repos.sh` | Standalone clone/update for entries in `dev-repos` |
| `dotfiles/` | Source files symlinked into `$HOME` |
