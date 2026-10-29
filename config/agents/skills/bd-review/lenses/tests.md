---
model: sonnet
---

# Lens: tests

Label: `tests`. Scope: each open PR, its tests against its child's
acceptance criteria.

Look for:

- An acceptance criterion that no test exercises.
- Tests that cannot fail: asserting on a mock's own return, no assertion,
  comparing a value with itself, a condition that is always true.
- Missing failure paths: only the happy path is tested where the code has
  error branches that matter.
- Tests that break the repo's own test conventions (helpers, table-driven
  style, fixtures, how fields are compared), with an example `path:line`
  of the convention.
- Tests or test data edited so that they pass instead of the code being
  fixed.

Not this lens: running the suite — CI does that — or correctness of the
production code.
