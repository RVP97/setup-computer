#!/bin/bash

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting machine setup..."
echo "→ Repo: $REPO_ROOT"

# ------------------------------
# Homebrew: PATH before/after install (Apple Silicon + Intel)
# ------------------------------
load_brew_shellenv() {
  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    return 0
  fi
  local prefix
  for prefix in /opt/homebrew /usr/local; do
    if [[ -x "${prefix}/bin/brew" ]]; then
      eval "$("${prefix}/bin/brew" shellenv)"
      return 0
    fi
  done
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
# Dotfiles setup
# ------------------------------
echo "Linking dotfiles..."

mkdir -p "${HOME}/.ssh"

ln -sf "${REPO_ROOT}/dotfiles/.zshrc" "${HOME}/.zshrc"
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
echo "→ Restart terminal OR run: source ~/.zshrc"
