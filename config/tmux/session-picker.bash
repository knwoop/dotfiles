#!/usr/bin/env bash
# fzf session picker, with one icon per Claude Code running in the session:
# 🟡 busy, 🔴 waiting on me, 🟢 idle. Claude reports each session's pid and
# status through `claude agents --json`; a pid is placed in the tmux session
# whose pane shell it descends from.
#
# Most recently opened first. session_last_attached, not session_activity:
# activity is bumped by any pane output, so a session with something chattering
# away in it floats to the top although it was never opened. Sessions created
# detached report an empty last_attached and fall back to their creation time.
# sort keeps to field 1 and is stable, so sessions sharing a timestamp stay in
# tmux's own alphabetical order instead of the reverse-alphabetical one a
# whole-line `sort -rn` falls back to.

tmux list-sessions -F '#{?session_last_attached,#{session_last_attached},#{session_created}} #{session_name}' |
    sort -k1,1rn -s | cut -d' ' -f2- |
    awk -F'\t' '
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
        { print $0 "\t" icons[$0] }
    ' <(tmux list-panes -a -F $'#{pane_pid}\t#{session_name}') \
      <(ps -A -o pid= -o ppid= | awk '{ print $1, $2 }') \
      <(claude agents --json 2>/dev/null | jq -r '.[] | [.pid, .status] | @tsv') \
      - |
    fzf --reverse --no-sort --delimiter='\t' --nth=1 --tabstop=1 \
        --preview 'tmux capture-pane -ep -t {1} 2>/dev/null | tail -n 80' --preview-window=right:45% |
    cut -f1 | xargs -r tmux switch-client -t
