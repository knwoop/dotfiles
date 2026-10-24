#!/usr/bin/env bash
# fzf session picker: each session with how long ago it was opened and
# created, and one icon per Claude Code running in it:
# 🟡 busy, 🔴 waiting on me, 🟢 idle. Claude reports each session's pid and
# status through `claude agents --json`; a pid is placed in the tmux session
# whose pane shell it descends from.
#
# Most recently opened first. session_last_attached, not session_activity:
# activity is bumped by any pane output, so a session with something chattering
# away in it floats to the top although it was never opened. Sessions created
# detached report an empty last_attached and fall back to their creation time.
# Both are lost when the server restarts, so session-opened.bash keeps them in
# a file from tmux hooks, and that wins over tmux's own: after a restore,
# session_created is the restore time for every session.
# sort keeps to field 1 and is stable, so sessions sharing a timestamp stay in
# tmux's own alphabetical order instead of the reverse-alphabetical one a
# whole-line `sort -rn` falls back to.

opened="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/session-opened"
[ -f "$opened" ] || opened=/dev/null

tmux list-sessions -F $'#{?session_last_attached,#{session_last_attached},#{session_created}}\t#{session_created}\t#{session_name}' |
    awk -F'\t' '
        FILENAME != "-" { saved[$3] = $1 "\t" $2; next }
        { print ($3 in saved ? saved[$3] : $1 "\t" $2) "\t" $3 }
    ' "$opened" - |
    sort -t$'\t' -k1,1rn -s |
    awk -F'\t' -v now="$(date +%s)" '
        BEGIN { icon["busy"] = "🟡"; icon["waiting"] = "🔴"; icon["idle"] = "🟢" }
        FNR == 1 { input++ }
        input == 1 { session_of[$1] = $2; next }                  # pane shell pid, session
        input == 2 { split($0, f, " "); parent[f[1]] = f[2]; next } # pid ppid
        input == 3 {                                              # claude pid, status
            for (pid = $1; pid > 1 && !(pid in session_of); pid = parent[pid]) {}
            if (pid in session_of && $2 in icon)
                icons[session_of[pid]] = icons[session_of[pid]] " " icon[$2]
            next
        }
        {                                                         # opened, created, session
            n++; name[n] = $3; opened[n] = ago(now - $1); created[n] = ago(now - $2)
            if (length($3) > width) width = length($3)
        }
        # Pad inside the second field, so the first stays the bare session name
        # to search on and to switch to. The first line is the header.
        END {
            printf "\t%*s%8s%9s\n", width, "", "opened", "created"
            for (i = 1; i <= n; i++)
                printf "%s\t%*s%8s%9s\t%s\n", name[i], width - length(name[i]), "",
                    opened[i], created[i], icons[name[i]]
        }
        function ago(s) {
            if (s < 60) return "now"
            if (s < 3600) return int(s / 60) "m"
            if (s < 86400) return int(s / 3600) "h"
            return int(s / 86400) "d"
        }
    ' <(tmux list-panes -a -F $'#{pane_pid}\t#{session_name}') \
      <(ps -A -o pid= -o ppid= | awk '{ print $1, $2 }') \
      <(claude agents --json 2>/dev/null | jq -r '.[] | [.pid, .status] | @tsv') \
      - |
    fzf --reverse --no-sort --header-lines=1 --delimiter='\t' --nth=1 --tabstop=1 |
    cut -f1 | xargs -r tmux switch-client -t
