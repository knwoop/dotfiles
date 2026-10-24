#!/usr/bin/env bash
# Remember when each tmux session was last opened, for the session picker.
# tmux forgets session_last_attached when the server restarts, and
# tmux-resurrect then recreates every session at the same instant, so
# neither is left to order the list by.
#
# Usage: session-opened.bash opened|created SESSION
# `created` only records a session not seen before: it keeps the original
# creation time when a restore recreates the session under the same name.
state="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/session-opened"
mkdir -p "${state%/*}"
touch "$state"

event="$1" name="$2"
if [ "$event" = created ] &&
    awk -F'\t' -v n="$name" '$2 == n { found = 1 } END { exit !found }' "$state"; then
    exit 0
fi

tmp="$(mktemp "$state.XXXXXX")"
awk -F'\t' -v n="$name" '$2 != n' "$state" >"$tmp"
printf '%s\t%s\n' "$(date +%s)" "$name" >>"$tmp"
mv "$tmp" "$state"
