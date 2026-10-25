---
name: bd-dev
description: Cut a beads (bd) issue and its dev environment — nothing more. Interviews the user just enough to name the issue and branch (or takes a task description / existing bd issue ID), creates the bd issue, creates a worktree via gwt with a readable branch name, and starts a tmux session with a plain claude as its only pane. Planning and implementation happen INSIDE the worktree session (the user runs /bd-plan there to cut child issues). Trigger on "bd-dev <task>", "/bd-dev", or when the user asks to start a task with beads. Pass multiple tasks/IDs to launch them in parallel.
---

# bd-dev

Cut issue + worktree + tmux session — then hand over. This skill does NOT plan or
implement: the user enters the worktree session and drives from there (typically
`/bd-research` when the code or data needs investigating first, then
create-plan → `/bd-plan` to attach the plan and cut child issues).

Beads counterpart of the `issue-dev` skill (Linear) and non-interactive counterpart
of the user's `bd-dev` zsh function (`~/.config/zsh/.zshrc`). Worktree creation uses
the same `gwt` (`~/.config/scripts/bin/gwt`), the tmux session name matches `wt-new`,
and the claude-only session matches `_bd_new_claude_session`. If gwt, wt-new, or the bd-dev zsh function
changes, update this skill to match.

Requires a repo where `bd init` has been run (a `.beads/` directory at the main repo
root). If there is none, ask the user before running `bd init`.

## Arguments

- A task description in natural language → create a new bd issue from it (step 2a).
  If it is too vague, interview the user (AskUserQuestion) — but the interview's
  only purpose is naming: enough to write a title that yields a good branch /
  worktree / session name, plus a one-paragraph description. Do NOT dig into
  requirements or design — that happens inside the worktree (create-plan →
  /bd-plan), and the description will be superseded by the plan in the issue's
  design field anyway.
- A reference to an existing issue — by title words, or an ID if the user happens
  to paste one → resolve it via `bd list --json -n 0` (step 2b).
- Multiple tasks/references allowed; repeat steps 2–5 per issue.
- No arguments: run `bd list --json --status open` and ask which one(s) to start
  with AskUserQuestion, presenting **titles** as the options.

**Issue IDs are internal plumbing.** Never require the user to type or know an ID;
refer to issues by title in questions and reports (IDs may appear alongside, small).

## Steps

1. Confirm we are in a git repo with beads initialized. Run everything from the main
   repo root (the parent of `.worktree/`). `bd` works from inside worktrees too — it
   resolves the main repo's `.beads/` via the git common dir.

2. Get the issue:

   a. **New task**: create the issue. Derive a concise title from the task description;
      put what was heard in the description. Priority 2 unless the user indicates
      urgency.

      ```bash
      bd create "<title>" -d "<description>" -p 2 --json
      ```

      The JSON output object has the `id` field (form `<project>-<hash>`).

   b. **Existing issue**: resolve the user's reference (title words or pasted ID)
      against `bd list --json -n 0` (the default stops at 50); confirm with `bd show <id> --json` (output is an
      array; title is `.[0].title`). If ambiguous or not found, ask by title
      instead of guessing.

3. Create the worktree with a readable branch name so humans can pick the session
   from `tmux ls` / choose-tree:

   - Branch name: `<id>-<slug>-plan` — the `-plan` suffix marks this as the plan
     worktree; `/bd-go` later cuts the matching `<id>-<slug>-work`. **The slug
     must be ASCII** — lowercase letters, digits and `-` only, trimmed of
     leading/trailing `-`, truncated to ~40 chars. Japanese titles get a short
     English rendering of the meaning, not a transliteration (a title meaning
     "create/delete users" → `create-delete-user`).
   - Never put non-ASCII in a branch name. GitHub flags such a PR with "The head ref
     may contain hidden characters" and shows the head ref as escape sequences, and
     the worktree directory inherits the same name.

   ```bash
   dir=$(~/.config/scripts/bin/gwt "<branch>")
   ```

   - stdout is the worktree path. If it already exists, gwt just returns the path — idempotent.
   - The base is origin's default branch (gwt fetches and resolves it).

4. Create the tmux session: one pane, claude only. Naming identical to wt-new,
   but not its layout (wt-new adds a shell pane on the left). The session name is
   `<repo dir name>/<branch with the leading "<repo>-" removed>` — the repeated
   repo name goes, the issue hash stays, so the session list reads
   `kauche-app/5ld7-farm-storybook-stories-plan` instead of
   `kauche-app/kauche-app-5ld7-farm-storybook-stories-plan`. This mirrors the
   `_wt_short_branch` / `_wt_session_name_for` pair in `~/.config/zsh/.zshrc`;
   keep them identical or `wt-cd` will not find the session:

   ```bash
   session="$(basename "$repo_root")/<issue-hash>-<slug>-plan"
   # tmux session name constraint: replace '.' and ':' with '_'
   if ! tmux has-session -t "=$session" 2>/dev/null; then
     tmux new-session -d -s "$session" -c "$dir" -- \
       sh -c 'claude "$1"; exec "$SHELL" -l' sh \
       "Read beads issue <id> with 'bd show <id> --json' for context, then wait for the user. Do NOT start planning or implementing on your own — the user drives from here (typically /bd-research when investigation is needed, then create-plan, then /bd-plan to cut child issues under this one, then /bd-go to dispatch them). Start every status report, and any reply after a context compaction, with '[<issue title> / plan session]' (add ' / work: <work_session>' once the issue's metadata has one); if you lose track of which issue this is, recover it from the branch and 'bd show <id> --json', never guess."
   fi
   ```

   A shell takes over when claude quits: as the only pane, claude alone would
   close the session with it. The prompt goes to claude as an argument, never
   through a shell, so any quoting in it is safe.

   The claude prompt is context-only on purpose: this skill stops at environment
   setup. If the session already exists, do not recreate it (never destroy a
   session in use).

5. Move the issue to in_progress and record where its plan worktree lives, in
   one call:

   ```bash
   main_root=$(dirname "$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir)")
   bd update <id> --status in_progress \
     --set-metadata "plan_worktree=${dir#$main_root/}" \
     --set-metadata "plan_session=$session"
   ```

   The metadata lets anything outside this flow (Emacs, another agent) go
   issue → worktree without re-deriving the branch naming convention. Rules:

   - **Paths are relative to the main repo root** (`.worktree/<branch>`).
     `.beads/config.yaml` has a `sync.remote`, so issue data leaves this
     machine — never write an absolute path, `$HOME`, or a username.
   - Only the epic carries this. Child issues get nothing; a reader walks
     `parent` up to the epic.
   - `--set-metadata` merges into the existing map, so `/bd-go` can add
     `work_worktree` / `work_session` later without clobbering these.
   - Read it back with `bd show <id> --json` → `.[0].metadata`.
   - Stale metadata after a worktree is removed is accepted; readers are
     expected to check that the path still exists.

6. Report to the user. List per issue: id / title / worktree path / connect commands:
   - From inside tmux: `tmux switch-client -t '=<session>'`
   - From outside tmux: `tmux attach -t '=<session>'`

   Claude's Bash cannot switch the user's tmux client, so only present the commands.
   Remind the user: plan inside the session (`/bd-plan` uses this issue as the
   parent), `/bd-go` later starts implementation from it, and issues close as
   PRs merge: children and then the epic by the work session, with a `/bd-go`
   pass in the plan session as the fallback (see "Issue lifecycle").

## Issue lifecycle

The worktree this skill cuts is the epic's **plan worktree**: planning and
progress checks live here; implementation happens in the single work worktree
that `/bd-go` cuts (branch `<epic-id>-<slug>-work`). The PR is the source of truth;
bd follows it. Who does what:

| Stage | Where | What |
|---|---|---|
| Research (optional) | plan worktree (this one) | `/bd-research`: sourced facts + questions for the plan, stored in this issue's notes |
| Plan | plan worktree (this one) | create-plan → `/bd-plan`: plan onto this issue's design, child issues cut under it |
| Start | plan worktree, `/bd-go` | cuts the work worktree + session, launches the implementer |
| Implement | work worktree session | ALL children built in one go as a `gh stack` stack (dependency graph linearized; one branch `<child-id>-<slug>` + one PR per child, each layer based on the one below); in_progress + external-ref per child |
| Review | **same work session** | address PR comments on the child's branch, push fixes, `gh stack sync` to rebase the layers above |
| Merge | the user | bottom of the stack first (GitHub stack UI or `gh stack merge`); never merge from a session |
| Close children | work session sweep, every turn | `gh stack sync --prune`, conflict check, then `bd close <child-id> --reason "PR #<n> merged"` for merged layers, bottom-up |
| Close epic | work session (fallback: plan worktree, `/bd-go` pass) | `bd close <epic-id>` + unset worktree metadata when the last child closes |

- Issues stay `in_progress` through review. There is no built-in "in review"
  status (open / in_progress / blocked / deferred / closed), and a custom one is
  not worth it — `external_ref` already says a PR is out.
- Never close an issue on PR creation: a PR that gets sent back leaves the
  tracker lying. Children close when their PR merges.
- Closing from a worktree is safe: bd data lives in the main repo's `.beads/`
  (via the git common dir), so it survives worktree removal.

## Notes

- `bd` is installed via Homebrew (`brew "beads"` in the Brewfile).
- Division of labor with `bd-plan`: bd-dev cuts the issue and the environment;
  bd-plan (run inside the worktree) attaches the plan to this issue's `design`
  field and cuts child issues under it with dependencies. The branch name starts
  with the issue ID, so bd-plan can derive the parent issue from
  `git rev-parse --abbrev-ref HEAD`.
- The issues live in the main repo's `.beads/`, and worktrees resolve it via the git
  common dir, so the spawned claude session sees the same issues with no extra auth
  — unlike the Linear variant. Note `.beads/` is git-ignored: the ledger is local to
  the machine unless `bd dolt push` is set up, so CI cannot write to it.
