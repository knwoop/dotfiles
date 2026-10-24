#!/usr/bin/env bash
# Claude Code status line.
# Shows model, cwd, git branch, and the number of open PRs waiting for my review.
# The PR count comes from `gh search prs --review-requested=@me`, cached for
# 5 minutes and refreshed in the background so the status line never blocks.
set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude"
CACHE_FILE="$CACHE_DIR/review-requested.json"
LOCK_DIR="$CACHE_DIR/review-requested.lock"
TTL=300
REVIEW_URL="https://github.com/pulls/review-requested"

mkdir -p "$CACHE_DIR"

input=$(cat)
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')

branch=""
if [ -n "$cwd" ]; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null \
        || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi

# --- background refresh -------------------------------------------------------
mtime() {
    stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

refresh() {
    tmp=$(mktemp "$CACHE_DIR/review-requested.XXXXXX")
    if gh search prs --review-requested=@me --state=open --draft=false \
        --limit 100 --json url,title,repository,updatedAt >"$tmp" 2>/dev/null; then
        mv -f "$tmp" "$CACHE_FILE"
    else
        rm -f "$tmp"
    fi
    rmdir "$LOCK_DIR" 2>/dev/null
}

now=$(date +%s)
if [ ! -f "$CACHE_FILE" ] || [ $((now - $(mtime "$CACHE_FILE"))) -ge "$TTL" ]; then
    # mkdir is atomic: only one refresh runs at a time.
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        (refresh) >/dev/null 2>&1 </dev/null &
        disown 2>/dev/null || true
    elif [ $((now - $(mtime "$LOCK_DIR"))) -ge $((TTL * 2)) ]; then
        rmdir "$LOCK_DIR" 2>/dev/null # stale lock from a killed refresh
    fi
fi

# --- render -------------------------------------------------------------------
review=""
if [ -f "$CACHE_FILE" ]; then
    count=$(jq -r 'length' "$CACHE_FILE" 2>/dev/null || echo 0)
    if [ "${count:-0}" -gt 0 ]; then
        review=$(printf '\033[33m\xf0\x9f\x91\x80 %s PR%s to review\033[0m %s' \
            "$count" "$([ "$count" -gt 1 ] && echo s)" "$REVIEW_URL")
    else
        review=$(printf '\033[32m\xe2\x9c\x93 no reviews pending\033[0m')
    fi
fi

parts=()
[ -n "$model" ] && parts+=("$(printf '\033[36m%s\033[0m' "$model")")
if [ -n "$cwd" ]; then
    loc="${cwd/#$HOME/~}"
    [ -n "$branch" ] && loc="$loc ($branch)"
    parts+=("$loc")
fi
[ -n "$review" ] && parts+=("$review")

out=""
for p in "${parts[@]}"; do
    [ -n "$out" ] && out+=" | "
    out+="$p"
done
printf '%s\n' "$out"
