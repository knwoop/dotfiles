---
model: sonnet
---

# Lens: plan conformance

Label: `plan`. Scope: the whole epic — every open PR plus the children
already merged — because gaps and overlaps only show across children.

Look for:

- A child's acceptance criteria (its bd description) that its PR does not
  meet, or meets only partly.
- A PR that does what the epic plan (`design`) did not ask for: scope
  outside its child, a decision the plan left open taken silently, or a
  plan decision reversed.
- Gaps between children: a TODO of the plan no child's PR covers.
  Overlaps: the same change made in two layers.
- Work the plan puts after merge (apply, migration, backfill, manual check)
  that a PR assumes is already done, or that no child owns.

Not this lens: whether the code is correct, tested or secure — the other
lenses cover those.
