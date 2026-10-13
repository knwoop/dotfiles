---
name: issue-dev
description: Spin up a parallel dev environment from a Linear issue. Fetches the issue, creates a worktree via gwt, starts a tmux session with claude in the same style as wt-new, and moves the issue to In Progress. Trigger on "start KWN-12", "/issue-dev KWN-12", etc. Pass multiple issues to launch them in parallel.
---

# issue-dev

Launch worktree + tmux session + claude in one shot, starting from a Linear issue.
Non-interactive counterpart of the user's `wt-new` (zsh function, `~/.config/zsh/.zshrc`).
Worktree creation uses the same `gwt` (`~/.config/scripts/bin/gwt`), and the tmux
session name / pane layout match `wt-new` / `_wt_new_claude_session`. If gwt or
wt-new changes, update this skill to match.

## Arguments

- Issue identifier (e.g. `KWN-12`) or a Linear issue URL. Multiple, space-separated, allowed.
- No arguments: fetch the user's open assigned issues via Linear `list_issues` and
  ask which one(s) to start with AskUserQuestion.

## Steps

Repeat per issue (for multiple issues, run steps 2–4 for each).

1. Load Linear tools via ToolSearch:
   `select:mcp__linear__get_issue,mcp__linear__save_issue,mcp__linear__list_issue_statuses`
   (also `mcp__linear__list_issues` when called with no arguments)

2. Fetch the issue with `get_issue`. Use the `branchName` suggested by Linear as-is
   (do not invent a branch name).

3. Create the worktree. Run from the main repo root (the parent of `.worktree/`):

   ```bash
   dir=$(~/.config/scripts/bin/gwt "<branchName>")
   ```

   - stdout is the worktree path. If it already exists, gwt just returns the path — idempotent.
   - The base is origin's default branch (gwt fetches and resolves it).

4. Create the tmux session. Naming and layout are identical to wt-new
   (session name = `<repo dir name>/<branchName>`, left pane shell / right pane claude):

   ```bash
   session="$(basename "$repo_root")/<branchName>"
   # tmux session name constraint: replace '.' and ':' with '_'
   if ! tmux has-session -t "=$session" 2>/dev/null; then
     tmux new-session -d -s "$session" -c "$dir"
     tmux split-window -h -t "=$session" -c "$dir" \
       claude "Read Linear issue <identifier> with get_issue and start implementing it. When done, create a PR and comment the PR link on the issue."
   fi
   ```

   If the session already exists, do not recreate it (never destroy a session in use).

5. Move the issue to In Progress:
   - Find the status with `type: started` via `list_issue_statuses` (scoped to the team)
   - Update the state with `save_issue`. Skip if the issue is already in a started state.

6. Report to the user. List per issue: title / worktree path / connect commands:
   - From inside tmux: `tmux switch-client -t '=<session>'`
   - From outside tmux: `tmux attach -t '=<session>'`

   Claude's Bash cannot switch the user's tmux client, so only present the commands.

## Notes

- The Linear MCP server is authenticated at user scope, so newly launched claude
  sessions can use it as-is. On auth errors, tell the user to re-authenticate via `/mcp`.
- `branchName` usually has the form `<username>/<identifier>-<slug>` and contains `/`.
  The worktree nests under `.worktree/<username>/<identifier>-<slug>/`, which is fine.
- If the issue cannot be found or the identifier is ambiguous, ask instead of guessing.
