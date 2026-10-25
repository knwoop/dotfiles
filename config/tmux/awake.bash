#!/usr/bin/env bash
# Keep the Mac awake on demand: caffeinate -i -s, toggled from tmux.
# Claude Code already holds idle sleep off while it works; this covers the
# rest, such as leaving the screen locked with sessions reachable from the
# phone after the work is done. -i stops idle sleep, -s system sleep while on
# AC power; the display still sleeps, and closing the lid still sleeps.
# caffeinate is tied to the tmux server (-w), so it ends with it.
#
# Usage: awake.bash toggle | status
state="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/awake.pid"

running() {
    local pid
    pid="$(cat "$state" 2>/dev/null)" || return 1
    [ -n "$pid" ] && [ "$(ps -o comm= -p "$pid" 2>/dev/null)" = caffeinate ]
}

case "$1" in
toggle)
    if running; then
        kill "$(cat "$state")"
        rm -f "$state"
        tmux display-message "awake: off"
    else
        mkdir -p "${state%/*}"
        nohup caffeinate -i -s -w "$(tmux display-message -p '#{pid}')" >/dev/null 2>&1 &
        echo $! >"$state"
        tmux display-message "awake: on (caffeinate -i -s)"
    fi
    ;;
status)
    running && printf '☕ awake '
    ;;
esac
exit 0
