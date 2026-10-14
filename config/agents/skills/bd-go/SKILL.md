---
name: bd-go
description: Start implementation of a planned beads epic in a dedicated work worktree. Runs ONLY inside the epic's plan worktree (where bd-plan ran) — first run cuts ONE work worktree + tmux session whose claude builds ALL child issues in one go as a GitHub stacked-PR stack managed with `gh stack` (one branch/PR per child, linearized in dependency order, no waiting for merges); later runs report the stack, and the work session keeps it rebased as PRs merge; the epic is closed once every child's PR has merged. Implementation never happens in the plan session. Trigger on "/bd-go", or when the user asks to start implementation / run the tasks.
---

# bd-go

Start and track implementation. Third step of the beads flow: `bd-dev` cuts
issue + plan worktree, `bd-plan` attaches the plan and cuts child issues,
`bd-go` cuts ONE dedicated work worktree and puts an implementing claude in it.

Two worktrees per epic, total: the **plan worktree** (this one — planning and
progress checks live here, no implementation traffic) and the **work worktree**
(all code happens there, in its own tmux session). Child issues are work units
tracked in bd, not separate worktrees.

**Delivery model: a `gh stack` stack, built in one go.** The implementer walks
the whole child graph in dependency order and opens one PR per child with the
`gh stack` extension (github/gh-stack), never waiting for anything to merge.
`gh stack` is linear — each branch is based on the one below it — so the
child graph is linearized: every connected component of the dependency graph
becomes one stack, in topological order; components with no dependency
between them become separate stacks. GitHub shows the stack natively on each
PR; the user reviews and merges bottom-up (stack UI or `gh stack merge`).
Merges never gate implementation — only the user's review/merge does, at the
end.

## Where to run

Only inside the epic's plan worktree (branch `<epic-id>-<slug>-plan`, issue has
children). Anywhere else, point the user to the plan worktree session, or to
`bd-dev` / `bd-plan` if the epic or plan does not exist yet.

**Issue IDs are internal plumbing.** Never require the user to type or know an
ID; questions and reports refer to issues by title (IDs may appear alongside,
small).

## Every pass: orient first

- Resolve the epic from the branch name; `bd show <epic-id> --json` — the
  `design` field is the plan; re-read it every pass (the user may have revised
  it via update-plan).
- Enumerate children and status: `bd list --json --parent <epic-id>`,
  `bd list --pretty`, `bd ready`. Each child's blockers are in
  `bd show <child-id> --json` → `.[0].dependencies[]` (keep only entries that
  are siblings under this epic; the epic itself may appear via the
  parent-child link — ignore it).
- Sanity-check plan vs graph (every TODO has a child, dependencies match). On
  mismatch, suggest `/bd-plan` updates instead of starting from a stale graph.
- `gh stack --version` must work (`gh extension install github/gh-stack` if
  not); tell the user before starting if it is missing.

## First run: cut the work worktree and start

1. Work branch = the plan branch with the `-plan` suffix swapped for `-work`
   (`<epic-id>-<slug>-plan` → `<epic-id>-<slug>-work`):

   ```bash
   dir=$(~/.config/scripts/bin/gwt "<epic-id>-<slug>-work")
   ```

2. Create the tmux session exactly as the bd-dev skill does (session
   `<repo>/<issue-hash>-<slug>-work` — only the branch's repeated leading
   `<repo>-` is dropped from the session label, left shell / right claude,
   pane_id handling, never recreate an existing session), with claude launched
   on the implementation mandate below. The session keeps that name for the
   life of the worktree even though you switch it to a child branch per PR.
3. Record the work worktree on the **epic** (never on a child — a reader walks
   `parent` up to the epic):

   ```bash
   main_root=$(dirname "$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir)")
   bd update <epic-id> \
     --set-metadata "work_worktree=${dir#$main_root/}" \
     --set-metadata "work_session=$session"
   ```

   `bd-dev` already wrote `plan_worktree` / `plan_session` the same way, and
   `--set-metadata` merges, so these two are added without touching those.
   **Paths stay relative to the main repo root** (`.worktree/<branch>`):
   `.beads/config.yaml` has a `sync.remote`, so issue data leaves this machine
   and must carry no absolute path, `$HOME`, or username. The session label
   stays valid for the life of the worktree even though you keep switching it
   to a child branch per PR.
4. Report the session + connect commands (`tmux switch-client` /
   `tmux attach`); remind the user that progress checks happen here via
   `/bd-go`, review is handled in the work session, and PRs are merged
   bottom-up (GitHub's stack UI or `gh stack merge`).

The implementation mandate (launch prompt), with IDs filled in:

> You are the implementer for beads epic <epic-id>. Read it with
> 'bd show <epic-id> --json' — the design field is the plan. List the child
> issues with 'bd list --json --parent <epic-id>'; they are your work queue.
> Work in THIS worktree only. Deliver the whole epic as GitHub **stacked PRs
> managed with `gh stack`, one PR per child, built in one go** — never wait
> for a merge to start the next child.
>
> **Setup.** default=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@.*/@@').
> A child's blockers are the sibling entries in 'bd show <child-id> --json'
> → .[0].dependencies[] (ignore the epic itself); blockers already closed
> count as merged. Group the open children into connected components of the
> dependency graph and order each component topologically — that order is
> one stack (siblings that are independent inside a component simply get
> stacked in that order). Each component is its own stack. Branch names:
> '<child-id>-<child-slug>' (ASCII slug from the child's title). Never build
> on the -work branch — it is parking only.
>
> **Per stack, per child, in that order:**
> 1. First child of a stack: 'gh stack init --base <default> <child-branch>'
>    (creates the branch off the local trunk and checks it out); then
>    'gh stack rebase' once so the trunk is fast-forwarded to origin. Later
>    children: 'gh stack top && gh stack add <child-branch>' (a new layer on
>    the current top). 'bd update <child-id> --status in_progress'.
> 2. Implement and commit on that branch.
> 3. 'gh stack submit --auto --open' (non-interactive: pushes every branch,
>    creates the PR for the new layer as ready-for-review, updates bases,
>    creates/updates the stack object on GitHub). Then set the real title and
>    body: n=$(gh pr view <child-branch> --json number -q .number);
>    'gh pr edit $n --title "<child title>" --body "..."' — body says what
>    the child achieves and that it is part of epic "<epic title>"; do not
>    hand-write a stack list, GitHub renders the stack. Record it:
>    'bd update <child-id> --external-ref gh-$n' and
>    'bd comment <child-id> "PR #$n"'.
> 4. Record discoveries with 'bd comment'; cut genuinely new work as new
>    children under the epic ('bd create --parent <epic-id> ...', with
>    'bd dep add' for ordering) instead of expanding a child's scope, and add
>    them as new layers on the right stack.
>
> Switch between stacks with 'gh stack checkout <branch>' (or git switch);
> 'gh stack view --short' shows the current stack. Keep going until every
> child has a PR. Stop early only for something the user must decide (a
> design question, missing credentials, red CI you cannot fix) — report it
> and pause; on "continue", resume from that child. Once all PRs exist,
> report every stack in **merge order** (bottom first): child title, PR URL.
>
> **Stack maintenance — run the sweep after the build, and whenever the user
> says to continue.** Per stack, from one of its branches:
> 'gh stack sync --prune' (fetch, fast-forward trunk, cascade-rebase every
> layer onto its parent, force-with-lease push, sync PR state, drop local
> branches of merged PRs). Then 'gh stack view --json': for every branch with
> isMerged true whose child is still open,
> 'bd close <child-id> --reason "PR #<n> merged"'. If sync reports a rebase
> conflict: 'gh stack rebase', resolve, 'gh stack rebase --continue', then
> 'gh stack push'. If the trunk fast-forward is refused because <default> is
> checked out in the main worktree, run 'git pull --ff-only' there first.
> A PR closed without merge ('gh pr view <n> --json state'): report it to the
> user; do not guess.
> Review comments ('gh pr view <n> --comments') are handled HERE: switch to
> that child's branch, push fix commits (prefer appending over amending), then
> 'gh stack sync' so the layers above are rebased and pushed.
> Never merge a PR, never 'gh stack merge', never 'gh stack unstack', and
> never close the epic — the user merges bottom-up; the epic is closed from
> the plan session at the end.

## Later runs: progress / close

- Report the stacks — for each, bottom → top: child title, PR state
  (`external_ref` → `gh pr view <n> --json state,baseRefName,reviewDecision`).
  Call out which PR is **mergeable now** (bottom of a stack, approved), which
  are waiting on a lower PR, and whether the stack needs a sync (a PR whose
  base still points at an already-merged branch — tell the user to say
  "continue" in the work session).
- A child PR CLOSED without merge: flag it to the user instead of guessing.
- All children closed: `bd close <epic-id>`, drop the worktree pointers that
  are about to go stale, and tell the user both worktrees/sessions for this
  epic can be removed:

  ```bash
  bd update <epic-id> --unset-metadata plan_worktree --unset-metadata plan_session \
    --unset-metadata work_worktree --unset-metadata work_session
  ```

  Closing from here is safe — bd data lives in the main repo's `.beads/` (git
  common dir) and survives worktree removal. As a fallback, close merged-PR
  stragglers the work session has not swept.

## Division of status updates

- Work session (the wt this skill cuts): per child — in_progress on start,
  `external_ref` at PR time, `bd close` on merge (its sweep), plus
  `gh stack sync` after merges and review fixes. It is long-lived, so
  completion state never lives on something already deleted.
- Plan session (`/bd-go` pass): progress reports; closes the epic when all
  children are closed (plus straggler fallback).
- Nobody merges except the user, bottom of the stack first (`gh stack merge`
  merges atomically up to a chosen PR).

## Notes

- If the epic has no children yet (no plan), say so and suggest `/bd-plan`
  first.
- `gh stack` facts (github/gh-stack v0.1.1, verified 2026-09-25): works from
  a worktree; tracking lives in the git common dir (`.git/gh-stack`), shared
  by all worktrees of the repo and local to the machine; each layer records
  its base commit, so cascade rebases survive squash merges and rewritten
  parents; `add` only works at the top of the stack; `submit` is
  interactive in a TTY — always pass `--auto` (`--open` for ready-for-review,
  otherwise PRs are drafts); `sync` aborts instead of prompting when local
  and remote stacks diverge — report that to the user.
- Keep `bd-dev`, `bd-plan`, and this skill in sync — they share branch/session
  conventions and the lifecycle.
