---
model: sonnet
---

# Lens: tests

Label: `tests`. Scope: each open PR, its tests against its child's
acceptance criteria.

Look for:

- No test at all: the PR changes behaviour and adds or changes no test,
  or an acceptance criterion that no test exercises.
- Tests that cannot fail, or barely can: no assertion, comparing a value
  with itself, asserting on a mock's own return, a condition that is always
  true, assertions too weak to catch the bug (only `err == nil`, only a
  length), an assertion in a loop body, callback or goroutine that never
  runs.
- Missing failure paths: only the happy path is tested where the code has
  error branches that matter.
- Tests weakened to pass: test or test data edited instead of the code,
  assertions deleted or loosened, a test or test file removed, a skip
  (`t.Skip`, `xfail`, `.skip`) or focus (`.only`) added, golden or snapshot
  files regenerated in the same PR without saying why.
- Flaky constructs: sleeps for timing, real network or clock, map or
  goroutine ordering, shared global state, dependence on test order.
- Tests that break the repo's own test conventions (helpers, table-driven
  style, fixtures, how fields are compared), with an example `path:line`
  of the convention.

Not this lens: running the suite — CI does that — or correctness of the
production code.
