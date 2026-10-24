#!/usr/bin/env bash
# Remember when each tmux session was created and last opened, for the
# session picker. tmux forgets session_last_attached when the server
# restarts, and tmux-resurrect then recreates every session at the same
# instant, so neither is left to show or to order the list by.
#
# Usage: session-opened.bash opened|created SESSION
# The state file holds one "opened<TAB>created<TAB>name" line per session.
# `created` only records a session not seen before: it keeps the original
# times when a restore recreates the session under the same name.
state="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/session-opened"
mkdir -p "${state%/*}"
touch "$state"

event="$1" name="$2"
created="$(awk -F'\t' -v n="$name" '$3 == n { print $2 }' "$state")"
if [ "$event" = created ] && [ -n "$created" ]; then
    exit 0
fi

now="$(date +%s)"
if [ -z "$created" ]; then
    # Opened before it was ever recorded: tmux's own creation time is the
    # best left, right unless the session came back from a restore.
    created="$(tmux display-message -p -t "=$name" '#{session_created}' 2>/dev/null)"
    created="${created:-$now}"
fi

tmp="$(mktemp "$state.XXXXXX")"
awk -F'\t' -v n="$name" '$3 != n' "$state" >"$tmp"
printf '%s\t%s\t%s\n' "$now" "$created" "$name" >>"$tmp"
mv "$tmp" "$state"
