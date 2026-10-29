---
name: bd-review
description: Review a beads epic's stacked PRs from the plan session, with a context independent of the implementer. Runs inside the epic's plan worktree after bd-go has opened PRs: fans out read-only sub-agents over every open child PR on four lenses — plan conformance, correctness, tests, security — verifies each finding against the code, shows the list to the user, and files each accepted finding as a bd issue under its child, so the work session — or any other agent — picks it up from bd. Nothing is posted on GitHub. Trigger on "/bd-review", "review the stack", or when the user asks to review a bd epic's PRs before merging.
---

# bd-review

The review step of the beads flow: `bd-dev` cuts issue + plan worktree,
`bd-research` finds out what is true, `bd-plan` cuts child issues, `bd-go`
builds them as a `gh stack` stack in the work session, **`bd-review` reviews
that stack from the plan session**, and the user merges.

The reviewer is not the implementer. The work session wrote the code and
holds its own reasoning about it; reviewing from there tends to confirm that
reasoning. The plan session never saw the implementation traffic, and the
sub-agents below start from nothing but the plan and the diff.

**bd is the channel.** Every accepted finding is a bd issue: its status says
whether it is open, fixed or declined, and its description carries the PR,
the head sha and the code location. Any agent that can run `bd` — the work
session's claude, Codex, a later session after the worktrees are gone — can
follow a review from bd alone, without this conversation, a tmux screen, or
parsing comment text. tmux only wakes the work session up.

The review is private to the user: nothing goes onto GitHub — no PR
comments, no review approvals or rejections, no labels.

## Where to run

Only inside the epic's plan worktree (branch `<epic-id>-<slug>-plan`), once
`bd-go` has opened PRs. Resolve the epic from the branch with bd-plan's
"Parent issue" snippet (`bd list --all -n 0`). Anywhere else, point the user
to the plan session. No child has a PR yet → say so and suggest `/bd-go`.

An issue on the small-task path (metadata `delivery=direct`, see bd-dev
"Small tasks") has one PR from the plan branch and no work session: review
that PR the same way, then fix the accepted findings in this session
instead of relaying them.

**Issue IDs are internal plumbing.** Questions and reports refer to issues by
title (IDs may appear alongside, small).

## Steps

1. **Collect the targets.**
   - `bd show <epic-id> --json` → `design` is the plan; re-read it.
   - Children: `bd list --json --parent <epic-id> --all -n 0`. Each child's
     PR is its `external_ref` (`gh-<n>`); each child's own description holds
     its acceptance criteria.
   - Per PR: `gh pr view <n> --json
     number,title,state,headRefName,headRefOid,baseRefName,additions,deletions`.
     Review only OPEN PRs. Order them by stack, bottom first
     (`gh stack view --short` from the work worktree, or follow
     `baseRefName` down to the default branch).
   - Earlier reviews: each child's metadata `review_sha` (the head sha it
     was last reviewed at) and its findings,
     `bd list --json --parent <child-id> --label review --all -n 0`. A PR
     whose `headRefOid` equals `review_sha` and that has no open finding is
     skipped; say so in the report.
   - If the user names PRs or children, review only those (plan conformance
     still looks at the whole epic).
   - `git fetch origin` so every head sha is readable here.

2. **Fan out read-only sub-agents in parallel** (one message, several agent
   calls). Use a read-only agent type where the harness has one that can
   review code, not just search. Each agent starts from a fresh context:
   never a fork or any agent that inherits this conversation, or the
   review is no longer independent (and a fork ignores the model choice
   below). One agent per lens; each lens has its own file in `lenses/` next
   to this one, with its scope and what to look for:

   | Lens (label) | File | Model | Scope |
   |---|---|---|---|
   | Plan conformance (`plan`) | `lenses/plan.md` | sonnet | the whole epic: every open PR plus the already merged children |
   | Correctness (`correctness`) | `lenses/correctness.md` | sonnet | each open PR |
   | Tests (`tests`) | `lenses/tests.md` | sonnet | each open PR |
   | Security (`security`) | `lenses/security.md` | opus | each open PR |

   Run each agent on the model in its lens file's frontmatter (`model:`).
   On a harness with other model names, use its equivalent tier (sonnet =
   mid tier, opus = top tier); if it cannot choose a model, use its
   default. The verification in step 3 stays in this session.

   To change what a lens checks or which model runs it, edit its file (and
   the row here); a new lens is a new file plus a row here. When the open PRs together change more than ~2000
   lines, split the correctness, tests and security lenses per PR instead
   of one agent per lens. Each brief gives:
   - the lens file's content, verbatim;
   - the epic plan (its `design`) and, per PR, the child's title,
     description, PR number, `headRefOid` and base;
   - how to read the code: `gh pr diff <n>` for the layer's own change
     (each PR's base is the layer below, so the diff is that layer only),
     and `git show <headRefOid>:<path>` for full files at the PR head —
     never the plan worktree's checkout, which is on the plan branch;
   - read-only: no checkout, commit, push, `gh pr comment`, `gh pr review`
     or any other write;
   - for a re-review, that child's open and declined findings (their bd
     descriptions), to check whether each still holds at the new head;
   - the return shape: at most ~15 findings per PR, each with severity
     (`blocker` = wrong behaviour, data loss or a hole if merged;
     `should` = a real problem that does not break the feature; `nit`),
     `path:line` at the head sha, one sentence stating the defect, and a
     concrete failure scenario (input or state → wrong result). No style
     preferences the repo does not enforce. An explicit "checked, nothing
     found" when that is the result.

3. **Verify.** Wait for every agent. For each finding, open the cited lines
   at the head sha (`git show <sha>:<path>`) and confirm the failure
   scenario holds against the actual code, including what lower layers
   already handle. Drop what does not hold; merge duplicates found by
   several lenses into one. A false finding costs the work session a
   detour and the user's trust in the review, so when in doubt, drop it or
   mark it `unsure`.

4. **Show the user.** Per PR, in merge order (bottom first): child title, PR
   URL, then its findings by severity, each one line with `path:line`.
   For a re-review, also each earlier finding as fixed / declined (with the
   work session's close reason) / still open. Then ask what to file
   (AskUserQuestion): blockers and shoulds (default), everything, a
   selection, or nothing. The user may also edit or drop findings, and
   reopen a declined one (`bd reopen <id>`). Never file a finding the user
   has not accepted.

5. **File each accepted finding as a bd issue** under its child (a grandchild
   of the epic, so bd-go's child listing, which is one level deep, never
   mistakes it for a stack layer). Tag the round
   `tag=RV-$(date +%Y%m%d-%H%M)`:

   ```bash
   bd create "<defect, short>" -t bug -p <1 blocker | 2 should | 3 nit> \
     --parent <child-id> -l review,"$tag",<lens> \
     -d "PR #<n> at <head-sha>, <path>:<line>. <defect>. Failure: <input or state> → <wrong result>."
   ```

   `<lens>` is one of `plan`, `correctness`, `tests`, `security`. Then mark
   every reviewed child, including those with no findings, so the next round
   can skip unchanged PRs:

   ```bash
   bd update <child-id> --set-metadata review_sha=<head-sha> --set-metadata review_round="$tag"
   bd comment <epic-id> "Review $tag: <n> findings filed on <children>; <children> clean"
   ```

   The epic comment is the human trail only; state lives in the finding
   issues. Paths stay relative to the repo root. Never write absolute
   paths, `$HOME`, a username, credentials, or personal data from the code
   or production: the issue data syncs off this machine
   (`.beads/config.yaml` has a `sync.remote`). Write the findings in the
   user's language.

6. **Wake the work session** with bd-go "Relay a change to the work
   session" steps 2–5 (find the session from the epic's `work_session`
   metadata, look before typing, never touch a draft in its input box,
   confirm the nudge was submitted), with this nudge:

   ```bash
   tmux send-keys -t "=<session>:" -l "[from plan session] Review $tag for epic <epic title>: open findings are bd issues labelled $tag; follow 'Apply a review' in ~/.agents/skills/bd-review/SKILL.md."
   tmux send-keys -t "=<session>:" Enter
   ```

   The nudge points at this file so that work sessions launched before
   bd-review existed still know what to do. If the work session is gone,
   say so: the findings stay in bd for whichever agent works the epic next.

7. **Report** the round's state from bd, never from memory:
   `bd list --json --label "$tag" --all -n 0` → open (not yet fixed),
   closed (fixed), closed with label `declined` (the work session's reason
   is the close reason; the user decides). Later `/bd-review` and `/bd-go`
   passes report open rounds the same way; a round is done when none of
   its findings is open.

## Apply a review (work session)

This section is for whichever agent implements the epic — normally the work
session, which receives `[from plan session] Review RV-<...>` nudges. It
works without a nudge too: open findings are always
`bd list --json --label review --status open -n 0` (narrow to the epic by
their parent, a child of the epic).

1. Read the findings: `bd show <finding-id> --json` → description (PR,
   head sha, `path:line`, defect, failure scenario). The parent is the
   child whose branch takes the fix.
2. Run the bd-go sweep's read-only check first. A PR that merged since the
   review cannot take fix commits: move its open findings under the epic
   (`bd update <finding-id> --parent <epic-id>`), which makes them new
   children; build them as new layers on top of the stack like any other
   new child.
3. Per finding, bottom of the stack first: `bd update <finding-id> --status
   in_progress`, switch to the parent child's branch, fix, and push a fix
   commit (append, do not amend), then
   `bd close <finding-id> --reason "fixed in <sha>"`. If you disagree with
   a finding, do not fix it:
   `bd label add <finding-id> declined` and
   `bd close <finding-id> --reason "declined: <why>"`; the user decides,
   and may reopen it. A finding that needs a design change is a question
   for the user: leave it open and say so.
4. Once a child's fixes are pushed, `gh stack sync` so the layers above are
   rebased and pushed.
5. Report in this session: fixed, declined (with reasons), and left open
   (with why). Always name the issue in `bd close`; without an ID it closes
   the last issue bd touched.

## Notes

- Review never merges, approves, requests changes, or comments on GitHub,
  and never changes a child's or the epic's status. The user merges,
  bottom-up.
- Review reads the live PRs every run. An earlier round's findings are a
  checklist for the re-review, not a result to trust.
- bd allows closing a child whose findings are still open, so the bd-go
  sweep moves them first (step 2 above) — an open finding never ends up
  under a closed child.
- Keep `bd-dev`, `bd-research`, `bd-plan`, `bd-go`, and this skill in sync.
  They share branch/session conventions and the lifecycle.
