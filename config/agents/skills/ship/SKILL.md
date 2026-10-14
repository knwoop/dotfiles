---
name: ship
description: Commit, push, and create a PR with ## What / ## Why description. Title, branch name, and description follow the host repository's conventions.
---

# Ship Skill

Commit changes, push, and create a Pull Request with a clean `## What` / `## Why` description. Match whatever conventions the host repository already uses (language, scope prefixes, commit style) — this skill never imposes its own.

## Steps

### Step 1: Understand the change and the repo's conventions

1. Determine base branch: use the user-provided base branch, or default to `main` (fall back to `master` if `main` does not exist). Store as `BASE_BRANCH`.
2. Run in parallel:
   - `git diff $BASE_BRANCH...HEAD --name-only` — list changed files
   - `git diff $BASE_BRANCH...HEAD` — inspect the actual changes
   - `git log $BASE_BRANCH..HEAD --oneline` — all commits on this branch
   - `git log --oneline -20` on `$BASE_BRANCH` — learn the repo's commit/PR title style
3. Infer a **scope label** from the changed file paths *only if* the repo uses scope prefixes in its commit/PR titles (e.g. `auth:`, `feat(api):`, `web/ui:`). Pick the dominant top-level directory or package when changes span multiple areas. If the repo does not use scopes, skip this.
4. Note the title language (English, Japanese, etc.). Default to English unless the repo clearly uses another language.

### Step 2: Create commit

1. Follow the repository's commit conventions — match the style you observed in Step 1.
2. If the user requested staged-only mode (`-s`), only commit already-staged files.
3. Otherwise, stage the relevant files by name (never `git add -A` or `git add .`) and commit with a message matching the project's style.
4. **Do NOT append `Co-Authored-By` lines** unless the project's existing history uses them.

### Step 3: Push

1. Check if the remote branch exists:
   ```bash
   git ls-remote --heads origin $(git branch --show-current)
   ```
2. If no remote branch: `git push -u origin $(git branch --show-current)`
3. Otherwise: `git push`
4. Stop and notify the user on failure.

### Step 4: Draft PR title

**Never switch branches. All operations happen on the current branch.**

Re-read `git log $BASE_BRANCH..HEAD --oneline` and the full diff to understand what the PR achieves as a whole — the title describes the PR, not just the latest commit.

#### PR title rules

- Match the repo's language and style (see Step 1).
- Under 70 characters.
- If the repo uses conventional-commit style, apply it: `{type}({scope}): summary` or `{scope}: summary` (e.g. `feat(auth):`, `fix(api):`, `refactor(web):`, `docs:`, `chore:`). Otherwise write a plain imperative summary.
- Describe what this PR **achieves**, not the structural change. "add retry with exponential backoff to webhook delivery" beats "refactor webhook client".

### Step 5: Draft PR description

Write `## What` and `## Why` sections. `## What` is a **decision tool**, not a description or summary — a reviewer or future engineer should be able to decide whether this PR matters to them without reading the diff.

```markdown
## What

<One sentence: what problem disappears when this PR is merged?>

## Why

<What prompted this? What risk, pain, or requirement makes this necessary?>
```

**## What rules:**
- Lead with the **problem being solved** or the **outcome**, not the solution or technology.
- Do NOT describe implementation details — the diff shows "how".
- Do NOT write a summary or overview.
- The reader should understand the value/outcome without reading code.
- Write in plain sentences. Use bullet points only when listing truly independent items.

**## Why rules:**
- Explain the **motivation and necessity** for the change.
- Why now? What prompted this? (bug report, requirement, tech debt, performance issue, incident, etc.)
- Write in plain sentences. Use bullet points only when listing truly independent items.

### Step 6: Self-check PR description (MANDATORY — do not skip)

Before proceeding to Step 7, review EVERY sentence in `## What` against all 4 filters below.
If ANY filter matches ANY sentence, rewrite that sentence and re-run the check.
Do NOT proceed to Step 7 until all sentences pass all filters.

**Filter 1 — Function/method/API name:**
Does the sentence mention a specific function, method, callback, API, class, or variable name
(e.g. `set_after_send`, `useEffect`, `handleClick`, `SecretStore::open`)?
→ Remove it. Describe the outcome instead.

**Filter 2 — "How" verb:**
Does the sentence use verbs like "migrate to", "refactor into", "move X into Y",
"replace X with Y", "consolidate into", "extract into", "split into"?
→ These describe structural changes (how), not goals (what). Rewrite to describe what the user/system gains.

**Filter 3 — Technical mechanism:**
Does the sentence describe WHERE or HOW the code runs
(e.g. "in the callback", "at the middleware layer", "via a cron job", "using a goroutine")?
→ Remove the mechanism. Describe the behavior change.

**Filter 4 — Diff-readable:**
Could the reader learn this information just by reading the diff?
→ If yes, it's "how" and should not be in What.

**Examples:**
- BAD: "Move cache TTL control into the `set_after_send` callback" — function name (filter 1) + "move into" (filter 2) + "callback" (filter 3)
- GOOD: "Ensure CDN caches only successful responses, with a default 7-day TTL as fallback for missing origin Cache-Control"
- BAD: "Replace `fmt.Errorf` with `liberrors.Wrap` across the repository layer" — function names (filter 1) + "replace with" (filter 2) + "repository layer" (filter 3)
- GOOD: "Standardize error wrapping so production errors always carry stack traces and structured context"

### Step 7: Create PR

Create the PR as **draft** by default. Use `--assignee @me`.

If the user specified:
- reviewers: add `--reviewer` flags
- open mode: omit `--draft`
- base branch: use it instead of `main`

After PR creation, print the PR URL.

## Usage examples

```
/ship                          # commit all, push, draft PR to main
/ship -s                       # staged files only
/ship -b release/v1.0          # target a release branch
/ship -r reviewer1,reviewer2   # assign reviewers
/ship -o                       # create as open (not draft)
/ship -s -o                    # combine options
```
