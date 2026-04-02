#!/bin/bash

set -e

echo "Installing Homebrew..."

if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "Updating Homebrew..."
brew update

echo "Installing Brew packages..."
brew bundle --file=~/setup/Brewfile

echo "Linking dotfiles..."
ln -sf ~/setup/dotfiles/.zshrc ~/.zshrc


echo "Done. Restart terminal or run: source ~/.zshrc"