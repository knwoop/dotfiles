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

- Resolve the epic from the branch name with bd-plan's "Parent issue"
  snippet (`bd list --all -n 0`; the default list stops at 50 open issues);
  `bd show <epic-id> --json` — the
  `design` field is the plan; re-read it every pass (the user may have revised
  it via update-plan).
- Enumerate children and status: `bd list --json --parent <epic-id> --all -n 0`
  (without `--all`, closed children are hidden, so a fully merged epic looks
  childless),
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
   `<repo>-` is dropped from the session label, claude as the only pane with
   the prompt passed as an argument, never recreate an existing session), with claude launched
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
> issues with 'bd list --json --parent <epic-id> -n 0'; they are your work queue.
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
> '<epic-id>-<child-hash>-<child-slug>', where <child-hash> is the child's
> id without the '<project>-' prefix and <child-slug> is an ASCII slug of
> its title (epic kauche-app-xtjxw, child kauche-app-evgms →
> 'kauche-app-xtjxw-evgms-<slug>'). Every branch of the epic then starts
> with the epic id, so from a PR's branch alone the user can tell which
> epic, and so which work session ('<repo>/<epic-hash>-<slug>-work'), owns
> it; bd-plan's parent lookup also resolves any of them to the epic. Never
> build on the -work branch — it is parking only.
>
> **Per stack, per child, in that order:**
> 1. First child of a stack: 'gh stack init --base <default> <child-branch>'
>    (creates the branch off the local trunk and checks it out); then
>    'gh stack rebase' once so the trunk is fast-forwarded to origin. Later
>    children: 'gh stack top && gh stack add <child-branch>' (a new layer on
>    the current top). 'bd update <child-id> --status in_progress'.
>    If the child has a 'Carry over: <sha> <sha> ...' comment
>    ('bd comments <child-id> --json'), cherry-pick exactly those commits,
>    in the listed order ('git cherry-pick <sha> <sha> ...'), onto the new
>    branch first (the commits come from a small task that grew into this
>    epic) and resolve any conflict before building the rest of the child.
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
> **Stack maintenance: the sweep.** A read-only check of the PRs, plus a
> sync only when the check finds a reason. Run it when you judge the PRs'
> state matters to what you are about to do or say — not on every turn, so
> unrelated work stays fast. Typical moments: the user says "merged",
> "continue", pastes a PR URL, asks for status, or asks for a review fix;
> a message from the plan session arrives (read the change first, below);
> right after the build; before the final report; or a while has passed
> and a merge may have landed unmentioned. When in doubt about state you
> are about to act on, check. Conflicts need no hunting: the user will
> point them out, and the check fixes any it happens to see.
>
> Never fetch, rebase or push just because the sweep ran: main moves constantly in a busy repo, and rebasing every layer each
> time would re-run CI on every PR and churn diffs under review.
>
> *Check (read-only).* For each open child that has a PR (its
> external_ref 'gh-<n>'): 'gh pr view <n> --json
> state,mergeable,mergeStateStatus'. Look up each PR by number; do not list
> recent PRs and filter, since in a busy repo the latest 100 cover only a
> day or two. Then, per PR:
> - MERGED, child still open → close it (below), then sync that stack.
> - CONFLICTING, or mergeStateStatus DIRTY → sync that stack and resolve.
> - CLOSED without merge → report it to the user; do not guess.
> - UNKNOWN (GitHub still computing, e.g. right after a push) → nothing now;
>   the next check picks it up.
> - BEHIND alone (main moved, no conflict) is NOT a reason to sync; mention
>   it only if the user asks or the repo requires up-to-date branches.
>
> *Close merged children*, bottom of the stack first. Always name the issue
> in 'bd close': without an ID it closes the last issue bd touched, which
> after a 'bd show' of a blocker is the wrong one. For each merged PR whose
> child is still open: 'bd close <child-id> --reason "PR #<n> merged"'.
> Going bottom-up closes each blocker before the child that depends on it.
> Before closing a merged child, move its open /bd-review findings
> ('bd list --json --parent <child-id> --label review --status open -n 0')
> under the epic ('bd update <finding-id> --parent <epic-id>'); they become
> new children, built as new layers.
> If bd still refuses with "blocked by open issues": when the blocking
> sibling's PR has merged too, close that one first; otherwise the merged PR
> is the source of truth, so 'bd close <child-id> --force --reason "PR #<n>
> merged"' and leave 'bd comment <child-id> "closed with open blocker
> <blocker title>"'.
>
> *Sync (only when the check found a merge or a conflict, a plan change was
> applied, or the user asks).* Per affected stack, from one of its branches:
> 'gh stack sync --prune' (fetch, fast-forward trunk, cascade-rebase every
> layer onto its parent, force-with-lease push, sync PR state, drop local
> branches of merged PRs). If it reports a rebase conflict: 'gh stack
> rebase', resolve, 'gh stack rebase --continue', then 'gh stack push'. If
> the trunk fast-forward is refused because <default> is checked out in the
> main worktree, run 'git pull --ff-only' there first. A conflict GitHub
> still reports after the sync: switch to that branch, rebase it onto its
> base, resolve, push, then 'gh stack sync' for the layers above.
>
> When a sweep ran, open the reply with a one-line result (what merged and
> was closed, whether a sync ran and why, what is mergeable now); then
> answer the user's message.
>
> Review comments ('gh pr view <n> --comments') are handled HERE: switch to
> that child's branch, push fix commits (prefer appending over amending), then
> 'gh stack sync' so the layers above are rebased and pushed. /bd-review
> findings are bd issues under a child, labelled 'review' (a
> '[from plan session] Review RV-<...>' message announces a round): follow
> 'Apply a review' in ~/.agents/skills/bd-review/SKILL.md.
>
> **Finish: close the epic here — post-merge work first.** When the sweep
> leaves no open child (the 'bd list --json --parent <epic-id> --all -n 0'
> listing is non-empty and every entry is closed):
> 1. Check what merging does not finish: for each merged PR, whether its
>    post-merge workflows ran and passed ('gh run list --commit <merge sha>'
>    — merging a whole stack at once can skip per-PR deploy/apply runs), and
>    every step the plan says happens after merge (apply, migration, manual
>    check).
> 2. Anything still to do → do NOT close the epic and keep its metadata.
>    Record it ('bd comment <epic-id> "post-merge pending: ..."'), report it
>    to the user, and repeat this check on later sweeps until the user
>    confirms it is done.
> 3. Nothing left → 'bd close <epic-id> --reason "all child PRs merged"',
>    then drop the worktree pointers that are about to go stale:
>    'bd update <epic-id> --unset-metadata plan_worktree --unset-metadata
>    plan_session --unset-metadata work_worktree --unset-metadata work_session'.
>    Final report: every child with its merged PR, then tell the user both
>    worktrees/sessions for this epic can be removed.
>
> Never merge a PR, never 'gh stack merge', never 'gh stack unstack' — the
> user merges, bottom-up.
>
> **Say where you are.** Start every status report, and any reply after a
> context compaction, with one line: '[<epic title> / work session /
> plan: <plan_session>]' (plan_session from the epic's metadata). If you
> lose track of which epic or session this is, recover it from the
> worktree's branch and 'bd show <epic-id> --json' → .[0].metadata — never
> guess.
>
> **Messages from the plan session** start with '[from plan session]' and
> name a change tag 'PC-<...>'. They mean the plan or the child graph
> changed, so do NOT sync or close anything first: that would rebase, push
> and close issues under the old plan. In this order:
> 1. Read the change: the epic comment that starts with 'Plan change
>    PC-<tag>' ('bd comments <epic-id> --json' → .text; 'bd show --json'
>    leaves comment bodies out), then the epic's design and
>    'bd list --json --parent <epic-id> --all -n 0'.
> 2. Work out the impact before touching anything: which open layers it
>    changes, drops or reorders, which new children it adds and where they
>    go in the stacks, and whether anything already merged conflicts with
>    it. If the change is unclear or contradicts merged work, ask the user
>    and stop here.
> 3. Run the sweep's check, then close and sync only where the new plan
>    still holds (do not rebase or push a layer that is about to be dropped
>    or rewritten).
> 4. Apply it: new children become new layers on the right stack (or a new
>    stack), a changed child gets fix commits on its branch, a dropped
>    child's PR is reported to the user rather than closed on your own.
> 5. Acknowledge on the epic, so the plan session can tell "sent" from
>    "applied". The plan session reads the comment's opening words, so
>    pick them by state:
>    - every part of the change is done →
>      'bd comment <epic-id> "Applied plan change PC-<tag>: <what you did>"';
>    - anything is left (waiting on the user, blocked, still building) →
>      'bd comment <epic-id> "Plan change PC-<tag> in progress: done <...>;
>      left <...> because <...>"', and write the 'Applied' comment only
>      once the rest is done.
>    Then report it here too.

## Later runs: progress / close

- Start the report with '[<epic title> / plan session / work:
  <work_session>]' so the user can tell the two sessions apart.
- Relayed plan changes not yet fully applied: list each as partially
  applied (with what is left) or not yet picked up (see "Relay a change to
  the work session"). Only an `Applied plan change <tag>` comment clears one.
  Also list open `/bd-review` findings (bd issues labelled `review` under
  this epic's children that are still open), by child.
- Report the stacks — for each, bottom → top: child title, PR state
  (`external_ref` → `gh pr view <n> --json state,baseRefName,reviewDecision`).
  Call out which PR is **mergeable now** (bottom of a stack, approved), which
  are waiting on a lower PR, and whether the stack needs a sync (a PR whose
  base still points at an already-merged branch). The work session syncs once
  its check sees the merge; a "continue" or "merged" to it triggers that.
- A child PR CLOSED without merge: flag it to the user instead of guessing.
- All children closed but the epic still open (the work session normally
  closes it; this is the fallback when that session is gone), where the
  `--all` listing is non-empty and every entry has status `closed`: run the
  work mandate's post-merge check first and keep the epic open if anything
  is pending; otherwise `bd close <epic-id>`, drop the worktree pointers that
  are about to go stale, and tell the user both worktrees/sessions for this
  epic can be removed:

  ```bash
  bd update <epic-id> --unset-metadata plan_worktree --unset-metadata plan_session \
    --unset-metadata work_worktree --unset-metadata work_session
  ```

  Closing from either worktree is safe — bd data lives in the main repo's
  `.beads/` (git common dir) and survives worktree removal. Also close
  merged-PR stragglers the work session has not swept, bottom-up as in the
  sweep.

## Relay a change to the work session

When the plan or the child graph changes after the first run (update-plan →
`/bd-plan` updates, new or dropped children, or the user says to tell the
work session something), the work session has to hear about it. Never retype
the change into its input box; the details go through bd, and tmux only
carries a fixed one-line nudge:

1. Write the change down on the epic, from here, under a fresh tag
   (`tag=PC-$(date +%Y%m%d-%H%M)`):
   `bd comment <epic-id> "Plan change $tag: <what changed, which children>"`.
2. Find the session: `bd show <epic-id> --json` → `.[0].metadata.work_session`.
   If it is missing or `tmux has-session -t "=<session>"` fails, tell the user
   the work session is gone and stop.
3. Look before typing: `tmux capture-pane -p -t "=<session>:" | tail -n 15`.
   If the claude input box already holds text (the user's unsent draft),
   do not clear or overwrite it. Tell the user and stop. A claude that is
   busy is fine: it queues the message for its next turn.
4. Send the nudge as literal text, then Enter as a separate key:

   ```bash
   tmux send-keys -t "=<session>:" -l "[from plan session] $tag for epic <epic title>: read the epic comment 'Plan change $tag', check its impact, then sync and apply it."
   tmux send-keys -t "=<session>:" Enter
   ```

5. Confirm with `capture-pane` again that the message was submitted (it
   appears in the transcript, not left in the input box). If it did not go
   through, say so; do not retry with Escape / C-c / clearing keys. Reading
   the screen is best-effort, so report only what you saw.
6. Report two states, never one: **sent** (the nudge was submitted, from
   step 5) and **applied** (an epic comment whose text starts with
   `Applied plan change <tag>`). Right after sending, applied is normally
   still pending. Every later `/bd-go` pass reads `bd comments <epic-id>
   --json` and, for each `Plan change <tag>:` comment, classifies the tag by
   the comment texts' opening words: `Applied plan change <tag>` → applied;
   otherwise the latest `Plan change <tag> in progress` → partially applied,
   with what is left; nothing → not yet picked up. Only "applied" drops off
   the list, so a lost or half-done relay shows up instead of passing
   silently.

## Division of status updates

- Work session (the wt this skill cuts): per child — in_progress on start,
  `external_ref` at PR time, `bd close` on merge (its read-only check, run
  when it judges PR state matters), plus `gh stack sync` only after a merge, a conflict, or a plan
  change; closes the epic when the last
  child closes. It is long-lived, so completion state never lives on
  something already deleted.
- Plan session (`/bd-go` pass): progress reports; fallback for stragglers
  and for closing the epic if the work session is gone.
- Nobody merges except the user, bottom of the stack first (`gh stack merge`
  merges atomically up to a chosen PR).

## Notes

- If the epic has no children yet (no plan), say so and suggest `/bd-plan`
  first. An issue with metadata `delivery=direct` is on the small-task path
  (bd-dev "Small tasks"): it has one PR from the plan branch and no work
  worktree, so do not cut one — report that PR's state instead, and close
  the issue the way that section says once it has merged.
- `gh stack` facts (github/gh-stack v0.1.1, verified 2026-09-25): works from
  a worktree; tracking lives in the git common dir (`.git/gh-stack`), shared
  by all worktrees of the repo and local to the machine; each layer records
  its base commit, so cascade rebases survive squash merges and rewritten
  parents; `add` only works at the top of the stack; `submit` is
  interactive in a TTY — always pass `--auto` (`--open` for ready-for-review,
  otherwise PRs are drafts); `sync` aborts instead of prompting when local
  and remote stacks diverge — report that to the user.
- Keep `bd-dev`, `bd-research`, `bd-plan`, `bd-review`, and this skill in sync — they share branch/session
  conventions and the lifecycle.
