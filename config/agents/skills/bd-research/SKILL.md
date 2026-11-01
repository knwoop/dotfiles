---
name: bd-research
description: Research a beads (bd) epic before planning it — the "research" step of research → plan → implement. Runs inside a bd-dev plan worktree, agrees on the purpose with the user first, then sends read-only sub-agents over the code, data, docs, and history, and writes one sourced research document for the planning agent; facts only, every decision left to the plan. Once the user accepts it, it is stored on the epic so create-plan / bd-plan build on it. Trigger on "/bd-research", "research this first", or when the user asks to investigate a bd issue before planning it.
---

# bd-research

The research step of the beads flow: `bd-dev` cuts issue + plan worktree,
**`bd-research` finds out what is true**, create-plan → `bd-plan` turns it into
a plan and child issues, `bd-go` implements.

The research document is for agents: the one that plans, and any later
session that picks the work up. Searching and reading happen in sub-agents
so this context keeps only what was found. Research without an agreed goal
searches everything and settles nothing, so agreeing on the purpose is the
step that matters most.

For a small, well-understood change, the user can skip this and go straight
to create-plan.

## Where to run

In the epic's plan worktree (branch `<issue-id>-<slug>-plan`), before
`/bd-plan`. Derive the issue from the branch as bd-plan does; an issue ID
given as argument overrides it. With no issue, research anyway, keep the
document in the scratchpad, and say that nothing was stored.

## Rules

- **Facts, not opinions.** State what is true, with a source for each claim.
  Options that exist and the questions the plan must decide belong in it; a
  recommendation, a ranking, or a fix plan does not. Pass this on to every
  sub-agent.
- **Read-only.** Change nothing outside the scratchpad.
- **Nothing private.** No absolute paths, usernames, credentials, or personal
  data: the issue data syncs off this machine.

## Steps

1. **Agree on the purpose.** Read the issue (`bd show <id> --json`, including
   `notes`, which may hold an earlier research) and anything the user points
   to. Look around briefly first (today's date, the current versions and
   state of what is involved), so neither the purpose nor the sub-agents'
   briefs rest on stale assumptions. Then draft the purpose (what this
   research feeds), the scenario (what is already fixed), the questions
   that must be answered before planning, and what is out of scope, and
   confirm it with the user before sending any sub-agent.

2. **Research in sub-agents**, in parallel, one per area. Each writes
   everything it found to its own file, `<scratchpad>/research/<area>.md`,
   with sources and what it searched without finding, and replies with a
   short summary and the file path. Stop when the agreed questions are
   answered or known to be unanswerable; go back for more at most a couple
   of times. A question still open at that point stays open in the
   document, with what was searched, not settled as unanswerable.

3. **Write the document**, `<scratchpad>/research.md`, from those files,
   in whatever form you like. Start it with what was agreed in step 1, so a
   later reader knows what the facts were gathered for, together with the
   date and the commit and versions it looked at; give every number the
   environment, time range, and query it came from. Keep what was searched
   without finding, and where, so nobody searches for it again: not found
   there is not the same as does not exist. Bring over everything from the
   findings files that serves the purpose: they are gone after the
   session. Check the facts a decision rests on yourself.
   End with what is uncertain and what could block the goal: known
   blockers, and unknowns that might turn out to be blockers, as facts,
   without judging whether to go ahead.

4. **Review with the user.** Give the path and what is left for the plan to
   decide.
   Accept → store it. Steer → research again with the correction. Discard
   → stop. Never store research the user has not accepted.

5. **Store and hand over.** Put it in the issue's `notes` (`design` is for
   the plan), or where the user names, recording that path with
   `bd update <id> --set-metadata "research_doc=<path>"`:

   ```bash
   bd update <id> --notes "$(cat <scratchpad>/research.md)"
   bd comment <id> "Research stored in notes (commit <short-sha>)"
   ```

   Then point to the next step: create-plan (clear-plan-skills:create-plan)
   reads it from the issue; then
   `/bd-plan`.

## Notes

- Every run reads the live code and data. An earlier research shows where to
  look and what was already not found; it is not something to trust as is.
- Research does not change the issue's type or status and cuts no children.
- Keep `bd-dev`, `bd-research`, `bd-plan`, `bd-go`, and `bd-review` in sync.
