#!/bin/bash
set -e
echo "👋 Starting dotfiles bootstrap..."

# Check and install Nix if needed
if ! command -v nix &> /dev/null; then
    echo "📦 Installing Nix..."
    sh <(curl -L https://nixos.org/nix/install) --darwin-use-unencrypted-nix-store-volume --daemon
    echo "⏳ Waiting for Nix to initialize..."
    sleep 5
    # Source Nix environment
    if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    else
        echo "❌ Error: Nix environment file not found. Please check Nix installation."
        exit 1
    fi
fi

# Ensure Nix environment is loaded (even if already installed)
if ! command -v nix &> /dev/null; then
    echo "🔁 Sourcing Nix environment..."
    if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    else
        echo "❌ Error: Nix environment file not found. Please check Nix installation."
        exit 1
    fi
fi

# Enable experimental features
echo "⚙️ Configuring Nix experimental features..."
mkdir -p "$HOME/.config/nix"
if ! echo "experimental-features = nix-command flakes" | sudo tee "$HOME/.config/nix/nix.conf" > /dev/null; then
    echo "❌ Error: Failed to write to $HOME/.config/nix/nix.conf. Check permissions."
    exit 1
fi

# Move to dotfiles directory if not already there
if [ ! -d ".git" ]; then
    echo "🔄 Cloning dotfiles..."
    git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
    cd ~/dotfiles || { echo "❌ Error: Failed to change to ~/dotfiles directory."; exit 1; }
else
    cd ~/dotfiles || { echo "❌ Error: Failed to change to ~/dotfiles directory."; exit 1; }
fi

# Backup existing .zshenv
if [ -f "$HOME/.zshenv" ]; then
    echo "🛡 Backing up existing .zshenv..."
    mv "$HOME/.zshenv" "$HOME/.zshenv.backup.$(date +%s)"
fi

# Build and apply Home Manager config from flake
echo "🏗 Applying Home Manager configuration for user $USER..."
if ! nix run --extra-experimental-features nix-command --extra-experimental-features flakes \
  github:nix-community/home-manager -- switch -b backup --flake .#"$USER"; then
    echo "❌ Error: Failed to apply Home Manager configuration."
    exit 1
fi

echo "✅ Setup complete! You can restart your shell or run 'source ~/.zshrc'"