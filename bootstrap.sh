#!/bin/bash

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting machine setup..."
echo "→ Repo: $REPO_ROOT"

# ------------------------------
# Homebrew: Apple Silicon only (/opt/homebrew)
# ------------------------------
load_brew_shellenv() {
  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    return 0
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return 0
  fi
  return 1
}

if ! load_brew_shellenv; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! load_brew_shellenv; then
  echo "Homebrew is installed but not on PATH yet. Open a new terminal, then run this script again." >&2
  exit 1
fi

# Idempotent: do not duplicate shellenv line on re-runs
ZPROFILE="${HOME}/.zprofile"
if [[ -f "$ZPROFILE" ]] && grep -q 'brew shellenv' "$ZPROFILE"; then
  :
else
  echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >>"$ZPROFILE"
fi

# ------------------------------
# Update & install packages
# ------------------------------
echo "Updating Homebrew..."
brew update

echo "Installing Brew packages..."
brew bundle --file="${REPO_ROOT}/Brewfile"

# ------------------------------
# Oh My Zsh (not in Homebrew — official installer + theme/plugins for .zshrc)
# ------------------------------
OMZ_DIR="${HOME}/.oh-my-zsh"
if [[ ! -f "${OMZ_DIR}/oh-my-zsh.sh" ]]; then
  echo "Installing Oh My Zsh (official script; Homebrew does not ship it)..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${OMZ_DIR}/custom"
mkdir -p "${ZSH_CUSTOM}/themes" "${ZSH_CUSTOM}/plugins"

P10K_THEME="${ZSH_CUSTOM}/themes/powerlevel10k"
if [[ ! -d "${P10K_THEME}/.git" ]] && [[ ! -f "${P10K_THEME}/powerlevel10k.zsh-theme" ]]; then
  echo "Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${P10K_THEME}"
fi

ZAS="${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
if [[ ! -d "${ZAS}/.git" ]]; then
  echo "Installing zsh-autosuggestions..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZAS}"
fi

ZSH_SYNTAX="${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
if [[ ! -d "${ZSH_SYNTAX}/.git" ]]; then
  echo "Installing zsh-syntax-highlighting..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_SYNTAX}"
fi

# ------------------------------
# Dotfiles setup
# ------------------------------
echo "Linking dotfiles..."

mkdir -p "${HOME}/.ssh"

ln -sf "${REPO_ROOT}/dotfiles/.zshrc" "${HOME}/.zshrc"
ln -sf "${REPO_ROOT}/dotfiles/.gitconfig" "${HOME}/.gitconfig"
ln -sf "${REPO_ROOT}/dotfiles/.ssh/config" "${HOME}/.ssh/config"

chmod 600 "${HOME}/.ssh/config"

# ------------------------------
# macOS defaults (optional script in repo)
# ------------------------------
if [[ -x "${REPO_ROOT}/macos.sh" ]]; then
  echo "Applying macOS defaults..."
  "${REPO_ROOT}/macos.sh"
fi

# ------------------------------
# Done
# ------------------------------
echo "Setup complete."

# Interactive terminal: replace this shell with login zsh so ~/.zprofile + ~/.zshrc load (PATH, Oh My Zsh, etc.)
# Skip with SETUP_COMPUTER_SKIP_ZSH_REEXEC=1 (e.g. CI) or when stdout is not a TTY.
if [[ -t 1 ]] && [[ -z "${SETUP_COMPUTER_SKIP_ZSH_REEXEC:-}" ]] && command -v zsh >/dev/null 2>&1; then
  echo "→ Starting login zsh with your updated configuration (type exit to return to the previous shell)."
  exec zsh -l
fi

echo "→ Open a new terminal or run: zsh -l"
