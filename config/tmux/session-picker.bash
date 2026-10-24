#!/usr/bin/env bash
# fzf session picker: each session with how long ago it was opened and
# created, and one icon per Claude Code running in it:
# 🟡 busy, 🔴 waiting on me, 🟢 idle. Claude reports each session's pid and
# status through `claude agents --json`; a pid is placed in the tmux session
# whose pane shell it descends from.
#
# ctrl-r flips to the repository roots: one row per ghq repository, standing
# for its main checkout's session, with the icons of all its sessions. A root
# without a session yet gets one, named the way the ghq widget in .zshrc names
# it, so either way leads to the same session.
#
# Most recently opened first. session_last_attached, not session_activity:
# activity is bumped by any pane output, so a session with something chattering
# away in it floats to the top although it was never opened. Sessions created
# detached report an empty last_attached and fall back to their creation time.
# Both are lost when the server restarts, so session-opened.bash keeps them in
# a file from tmux hooks, and that wins over tmux's own: after a restore,
# session_created is the restore time for every session.
#
# Sessions of the repository the current session is in come first, the main
# checkout and its worktrees alike: a session's repository is its start
# directory with any .worktree/ part dropped. A root counts as opened when any
# of its sessions was. Roots never opened follow in ghq's order.
# sort keeps to its key fields and is stable, so sessions sharing a timestamp
# stay in tmux's own alphabetical order instead of the reverse-alphabetical one
# a whole-line `sort -rn` falls back to.
#
# Each row is "name<TAB>columns<TAB>icons<TAB>start directory"; fzf shows the
# first three and searches the name only.

opened="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/session-opened"
[ -f "$opened" ] || opened=/dev/null

# $1: sessions or roots
list() {
    tmux list-sessions -F $'#{?session_last_attached,#{session_last_attached},#{session_created}}\t#{session_created}\t#{session_path}\t#{session_name}' |
        awk -F'\t' -v mode="$1" -v here="$(tmux display-message -p '#{session_path}')" -v ghq_root="$(ghq root)" '
            function repo(path) { sub(/\/(\.git\/)?\.worktree\/.*/, "", path); return path }
            # The session name the ghq widget gives a repository root.
            function root_name(r,  name) {
                name = index(r, ghq_root "/") == 1 ? substr(r, length(ghq_root) + 2) : r
                gsub(/[:. ]/, "-", name)
                return name
            }
            BEGIN { icon["busy"] = "🟡"; icon["waiting"] = "🔴"; icon["idle"] = "🟢"; here = repo(here) }
            FNR == 1 { input++ }
            input == 1 { saved[$3] = $1 "\t" $2; next }               # opened, created, session
            input == 2 { session_of[$1] = $2; next }                  # pane shell pid, session
            input == 3 { split($0, f, " "); parent[f[1]] = f[2]; next } # pid ppid
            input == 4 {                                              # claude pid, status
                for (pid = $1; pid > 1 && !(pid in session_of); pid = parent[pid]) {}
                if (pid in session_of && $2 in icon) {
                    icons[session_of[pid]] = icons[session_of[pid]] " " icon[$2]
                    states[session_of[pid]] = states[session_of[pid]] " " $2
                }
                next
            }
            input == 5 { roots[++nroots] = $0; next }                 # ghq repository
            {                                                         # last attached, created, path, session
                if ($4 in saved) { split(saved[$4], t, "\t"); $1 = t[1]; $2 = t[2] }
                r = repo($3)
                if (mode == "sessions") {
                    print (r == here) "\t" $1 "\t" $2 "\t" $4 "\t" icons[$4] "\t" $3
                    next
                }
                if (r != $3 && !(r in seen)) { seen[r]; roots[++nroots] = r } # worktrees of a repo outside ghq
                if ($1 > root_opened[r]) root_opened[r] = $1
                k = split(states[$4], st, " ")
                for (j = 1; j <= k; j++) count[r, st[j]]++
                # Several sessions can start in the root: prefer the one named
                # the ghq way, else the one opened last.
                if (r == $3 && root_session[r] != root_name(r) &&
                    ($4 == root_name(r) || !(r in root_session) || $1 > root_session_opened[r])) {
                    root_session[r] = $4; root_session_opened[r] = $1; root_created[r] = $2
                }
            }
            END {
                if (mode == "sessions") exit
                for (i = 1; i <= nroots; i++) {
                    r = roots[i]
                    if (r in done) continue
                    done[r]
                    name = r in root_session ? root_session[r] : root_name(r)
                    # One icon per state with how many: a repository can run dozens.
                    summary = ""
                    split("busy waiting idle", order, " ")
                    for (j = 1; j <= 3; j++)
                        if (count[r, order[j]]) summary = summary " " icon[order[j]] count[r, order[j]]
                    print (r == here) "\t" root_opened[r] "\t" root_created[r] "\t" name "\t" summary "\t" r
                }
            }
        ' "$opened" \
          <(tmux list-panes -a -F $'#{pane_pid}\t#{session_name}') \
          <(ps -A -o pid= -o ppid= | awk '{ print $1, $2 }') \
          <(claude agents --json 2>/dev/null | jq -r '.[] | [.pid, .status] | @tsv') \
          <(ghq list -p) \
          - |
        sort -t$'\t' -k1,1rn -k2,2rn -s |
        awk -F'\t' -v now="$(date +%s)" '
            {                                                     # here, opened, created, name, icons, path
                n++; name[n] = $4; opened[n] = ago($2); created[n] = ago($3); icons[n] = $5; path[n] = $6
                if (length($4) > width) width = length($4)
            }
            # Pad inside the second field, so the first stays the bare name to
            # search on and to switch to. The first line is the header.
            END {
                printf "\t%*s%8s%9s\n", width, "", "opened", "created"
                for (i = 1; i <= n; i++)
                    printf "%s\t%*s%8s%9s\t%s\t%s\n", name[i], width - length(name[i]), "",
                        opened[i], created[i], icons[i], path[i]
            }
            function ago(t,  s) {
                if (t == "") return ""
                s = now - t
                if (s < 60) return "now"
                if (s < 3600) return int(s / 60) "m"
                if (s < 86400) return int(s / 3600) "h"
                return int(s / 86400) "d"
            }
        '
}

if [ "$1" = --list ]; then
    list "$2"
    exit
fi

self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
selected="$(
    list sessions |
        fzf --reverse --border=none --no-sort --header-lines=1 --delimiter='\t' --with-nth=1..3 --nth=1 --tabstop=1 \
            --prompt='session> ' --header='ctrl-r: sessions / repository roots' \
            --bind "ctrl-r:transform:[ \"\$FZF_PROMPT\" = 'session> ' ] &&
                echo 'reload($self --list roots)+change-prompt(root> )+first' ||
                echo 'reload($self --list sessions)+change-prompt(session> )+first'"
)" || exit 0

name="$(cut -f1 <<<"$selected")"
dir="$(cut -f4 <<<"$selected")"
tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$dir"
tmux switch-client -t "=$name"
