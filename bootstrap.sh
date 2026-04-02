#!/bin/bash

set -e

echo "Starting machine setup..."

# ------------------------------
# Install Homebrew if not installed
# ------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is available in PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# ------------------------------
# Update & install packages
# ------------------------------
echo "Updating Homebrew..."
brew update

echo "Installing Brew packages..."
brew bundle --file="$HOME/setup/Brewfile"

# ------------------------------
# Dotfiles setup
# ------------------------------
echo "Linking dotfiles..."

mkdir -p "$HOME/.ssh"

ln -sf "$HOME/setup/dotfiles/.zshrc" "$HOME/.zshrc"
ln -sf "$HOME/setup/dotfiles/.ssh/config" "$HOME/.ssh/config"

# Secure SSH config permissions
chmod 600 "$HOME/.ssh/config"

# ------------------------------
# Done
# ------------------------------
echo "Setup complete."
echo "→ Restart terminal OR run: source ~/.zshrc"