---
model: sonnet
---

# Lens: correctness

Label: `correctness`. Scope: each open PR, its own layer's diff, read
against the full files at the PR head.

Look for:

- Logic errors: wrong condition, wrong operator, inverted branch, off by
  one, wrong unit or time zone.
- Edge and boundary cases: empty, nil / null, zero, maximum, duplicates,
  unicode, very large input.
- Error handling: errors dropped or swallowed, wrong error returned, partial
  writes left behind on failure, retries that are not idempotent.
- Concurrency: races, shared state without locking, ordering assumptions,
  transactions that do not cover the whole change.
- The stack: behaviour a lower layer changed that this layer still relies
  on in its old form; callers outside the diff that the change breaks.

Not this lens: missing tests, security, style the repo does not enforce.
