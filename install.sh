#!/bin/sh

# If running from inside the cloned repo, use that location
if [ -f "$(dirname "$0")/scripts/setup.bash" ]; then
    INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
else
    INSTALL_DIR="${INSTALL_DIR:-$HOME/.dotfiles}"
    if [ -d "$INSTALL_DIR" ]; then
        echo "Updating dotfiles..."
        git -C "$INSTALL_DIR" pull
    else
        echo "Installing dotfiles..."
        git clone https://github.com/knwoop/dotfiles "$INSTALL_DIR"
    fi
fi

/bin/bash "$INSTALL_DIR/scripts/setup.bash"