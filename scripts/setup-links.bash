#!/usr/bin/env bash
set -x
# shellcheck source=./scripts/common.bash
source "$(dirname "$0")/common.bash"

if [[ ! -d "$HOME/.ssh" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
fi

if [[ ! -d "$HOME/.gnupg" ]]; then
    mkdir -p "$HOME/.gnupg"
    chmod 700 "$HOME/.gnupg"
fi

mkdir -p \
    "$XDG_CONFIG_HOME" \
    "$XDG_STATE_HOME" \
    "$XDG_DATA_HOME/vim"

ln -sfnv "$REPO_DIR/config/"* "$XDG_CONFIG_HOME"
ln -sfv "$XDG_CONFIG_HOME/zsh/.zshenv" "$HOME/.zshenv"
ln -sfv "$XDG_CONFIG_HOME/editorconfig/.editorconfig" "$HOME/.editorconfig"
ln -sfv "$XDG_CONFIG_HOME/starship/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
ln -sfnv "$XDG_CONFIG_HOME/vim" "$HOME/.vim"
ln -sfnv "$XDG_CONFIG_HOME/emacs" "$HOME/.emacs.d"

# Claude Code: link individual files so runtime data under ~/.claude is preserved.
mkdir -p "$HOME/.claude"
ln -sfv "$REPO_DIR/config/claude/settings.json" "$HOME/.claude/settings.json"
ln -sfv "$REPO_DIR/config/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
if [ -d "$HOME/.claude/commands" ] && [ ! -L "$HOME/.claude/commands" ]; then
    rm -rf "$HOME/.claude/commands"
fi
ln -sfnv "$REPO_DIR/config/claude/commands" "$HOME/.claude/commands"
