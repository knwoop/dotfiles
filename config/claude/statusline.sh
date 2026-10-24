#!/usr/bin/env bash
# Claude Code status line.
# Shows model, cwd, git branch, and the number of open PRs waiting for my review:
# in a GitHub repository only that repository's, elsewhere all of them.
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
repo="" # owner/name on GitHub
if [ -n "$cwd" ]; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null \
        || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    repo=$(git -C "$cwd" --no-optional-locks remote get-url origin 2>/dev/null |
        sed -nE 's#^(https://|ssh://git@|git@)github\.com[:/]([^/]+/[^/]+)$#\2#p')
    repo=${repo%.git}
fi

# Where I am, short: the full ghq path to a worktree, followed by a branch named
# like the worktree, runs off the end of the line. "owner/name", then the
# worktree without the repeated repo name (as tmux session names have it), then
# any subdirectory; the branch only when it differs from the worktree's name, as
# in a -work worktree on a child branch.
location() {
    local top main sub wt
    top=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
    if [ -z "$top" ] || [ -z "$repo" ]; then
        loc="${cwd/#$HOME/~}"
        [ -n "$branch" ] && loc="$loc ($branch)"
        return
    fi
    main=$(dirname "$(git -C "$cwd" --no-optional-locks rev-parse --path-format=absolute --git-common-dir)")
    loc="$repo"
    if [ "$top" != "$main" ]; then
        wt=$(basename "$top")
        loc="$loc › ${wt#"$(basename "$main")"-}"
    fi
    sub=${cwd#"$top"}
    loc="$loc$sub"
    [ -n "$branch" ] && [ "$branch" != "${wt:-$(git -C "$main" --no-optional-locks symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')}" ] &&
        loc="$loc (${branch#"$(basename "$main")"-})"
}

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
    count=$(jq -r --arg repo "$repo" \
        '[.[] | select($repo == "" or .repository.nameWithOwner == $repo)] | length' \
        "$CACHE_FILE" 2>/dev/null || echo 0)
    [ -n "$repo" ] &&
        REVIEW_URL="https://github.com/$repo/pulls?q=is%3Apr+is%3Aopen+draft%3Afalse+review-requested%3A%40me"
    if [ "${count:-0}" -gt 0 ]; then
        # The text itself links to the list (an OSC 8 hyperlink), rather than a
        # spelled-out URL taking up half the line.
        review=$(printf '\033]8;;%s\033\\\033[33m\xf0\x9f\x91\x80 %s PR%s to review\033[0m\033]8;;\033\\' \
            "$REVIEW_URL" "$count" "$([ "$count" -gt 1 ] && echo s)")
    else
        review=$(printf '\033[32m\xe2\x9c\x93 no reviews pending\033[0m')
    fi
fi

parts=()
[ -n "$model" ] && parts+=("$(printf '\033[36m%s\033[0m' "$model")")
if [ -n "$cwd" ]; then
    location
    parts+=("$loc")
fi
[ -n "$review" ] && parts+=("$review")

out=""
for p in "${parts[@]}"; do
    [ -n "$out" ] && out+=" | "
    out+="$p"
done
printf '%s\n' "$out"
