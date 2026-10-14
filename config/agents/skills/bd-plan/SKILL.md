---
name: bd-plan
description: Turn an implementation plan (create-plan format) into a beads issue graph. Run inside a bd-dev worktree: attaches the full plan to the current issue's design field, promotes it to epic, and expands the TODO section into child issues with blocking dependencies via bd create --graph. Trigger on "/bd-plan", when the user asks to hand a plan to beads, or right after a plan is approved in Plan Mode / created with create-plan.
---

# bd-plan

Turn a plan into a beads issue graph under the current issue: the issue carries the
full plan in its `design` field and becomes an epic; child task issues are cut per
TODO item with blocking dependencies so `bd ready` surfaces only what can be started.

Normal operation (set up by the `bd-dev` skill): bd-dev cuts the issue + worktree +
session, the user plans inside that session (create-plan), then runs this skill to
hand the plan to bd.

## Input

- A plan in the user's create-plan format (five sections: What / Requirements /
  TODO / References / Verification) — pasted, on the clipboard (`pbpaste`), or just
  produced in this conversation (Plan Mode / clear-plan-skills:create-plan).
- If no plan exists yet, plan first (clear-plan-skills:create-plan), get the user's
  OK, then continue here.
- Parent issue:
  - **Inside a bd-dev plan worktree** (the usual case): derive it from the
    branch — the branch is `<issue-id>-<slug>-plan`, so the parent is the
    `bd list --json | jq -r '.[].id'` entry that is a prefix of
    `git rev-parse --abbrev-ref HEAD`. Confirm with
    `bd show <id>`.
  - An explicit issue ID as argument overrides this.
  - Neither (e.g. run from the main repo): fall back to creating a standalone epic
    node in the graph (add an `epic` node and use `parent_key` instead of
    `parent_id` below).

## Steps

1. Save the full plan markdown to a scratchpad file (`plan.md`).

2. Attach the plan to the parent issue and promote it to epic:

   ```bash
   bd update <id> --design-file <scratchpad>/plan.md
   bd update <id> --acceptance "<Verification section summary>"
   bd update <id> -t epic
   ```

3. Build the graph JSON in the scratchpad and create the child issues:

   ```json
   {
     "nodes": [
       {"key": "t1", "parent_id": "<id>", "title": "<TODO item 1>",
        "description": "<the TODO item's details/subitems from the plan>"},
       {"key": "t2", "parent_id": "<id>", "title": "<TODO item 2>", "description": "..."}
     ],
     "edges": [
       {"from_key": "t2", "to_key": "t1", "type": "blocks"}
     ]
   }
   ```

   ```bash
   bd create --graph <scratchpad>/plan-graph.json
   ```

   Schema notes (verified against bd 1.1.2 — unknown fields are silently dropped
   with a warning):
   - Node fields: `key`, `title`, `description`, `type`, `priority`, `parent_id`
     (existing issue ID) or `parent_key` (another node's key). `design`/`acceptance`
     are NOT supported on nodes — that is why step 2 uses `bd update`.
   - Edge direction: `from_key` is the issue that DEPENDS ON `to_key`
     (t2 waits for t1; only t1 shows in `bd ready` until t1 closes).
   - One node per TODO group/item at the granularity of "one sitting of work".
     Add edges only for real ordering constraints from the plan — independent
     TODOs get no edges so they can be picked up in any order.
   - Output maps each key to a created issue ID (`t1 -> myrepo-oct`).

4. Report to the user:
   - The tree (`bd list --pretty`) and which children are ready now (`bd ready`).
   - Refer to issues by title — issue IDs are internal plumbing the user should
     not need to read or type.
   - Next step: `/bd-go` in THIS session. It cuts the single work worktree
     where an implementing claude builds every child in dependency order as a
     `gh stack` stack of PRs, without waiting for merges; this plan worktree stays
     the place for progress checks. The
     lifecycle (PR / review / close) follows the bd-dev skill's
     "Issue lifecycle" section.

## Notes

- If the plan changes mid-implementation (clear-plan-skills:update-plan), update
  the epic's design with `--design-file` again and add/close child issues rather
  than recreating the graph.
- `bd dep add <issue> <blocker>` adds a dependency after the fact if an ordering
  constraint was missed.
- Close each child as its TODO lands (`bd close <child-id>`); the epic itself is
  closed from the main repo after the PR merges (see bd-dev lifecycle).
