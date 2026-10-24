#!/usr/bin/env bash
set -x
# shellcheck source=./scripts/common.bash
source "$(dirname "$0")/common.bash"

# tmux plugins live under XDG_DATA_HOME so the dotfiles repo (symlinked at
# $XDG_CONFIG_HOME/tmux) stays clean. See config/tmux/tmux.conf.
export TMUX_PLUGIN_MANAGER_PATH="$XDG_DATA_HOME/tmux/plugins"
TPM_DIR="$TMUX_PLUGIN_MANAGER_PATH/tpm"

if [ -d "$TPM_DIR/.git" ]; then
    echo "Updating tpm..."
    git -C "$TPM_DIR" pull --ff-only
else
    echo "Installing tpm..."
    mkdir -p "$TMUX_PLUGIN_MANAGER_PATH"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# Install the plugins declared in tmux.conf without an interactive session.
if command -v tmux >/dev/null 2>&1; then
    tmux start-server
    tmux source-file "$XDG_CONFIG_HOME/tmux/tmux.conf" 2>/dev/null || true
    "$TPM_DIR/bin/install_plugins" || true
fi

true
