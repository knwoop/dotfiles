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

# Skills live under config/agents/ because nothing in them is Claude-specific:
# the same SKILL.md is linked into the vendor-neutral ~/.agents/skills and into
# ~/.claude/skills. Both directories stay real — they also hold skills installed
# from elsewhere (and Claude's synced/ bucket), so they cannot be linked wholesale.
# A skill installed by some other tool lands as a real directory. `ln -sfn` onto
# one does not replace it — it silently creates the link INSIDE it
# (skills/ship/ship -> ...), which loads nothing and hides the repo version. So
# move anything that is not already a symlink out of the way first.
link_skill() {
    src="$1"
    dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        # Park it outside the skills directory. A copy left alongside would be
        # picked up as a second skill, under the backup directory's name.
        backup_dir="$XDG_STATE_HOME/dotfiles/skills-replaced"
        mkdir -p "$backup_dir"
        backup="$backup_dir/$(basename "$dst")-$(date +%Y%m%d%H%M%S)"
        echo "warning: $dst was installed outside dotfiles; moved to $backup" >&2
        mv "$dst" "$backup"
    fi
    ln -sfnv "$src" "$dst"
}

mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills"
for skill in "$REPO_DIR"/config/agents/skills/*/; do
    [ -d "$skill" ] || continue
    name=$(basename "$skill")
    link_skill "${skill%/}" "$HOME/.agents/skills/$name"
    link_skill "${skill%/}" "$HOME/.claude/skills/$name"
done
