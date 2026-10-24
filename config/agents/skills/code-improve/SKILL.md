---
name: code-improve
description: Analyze source code for improvements across security, correctness, performance, refactoring, code smells, and best practices. Supports Go, TypeScript, and Python with language-specific checks.
disable-model-invocation: true
---

This skill performs multi-pass source code analysis to find actionable improvements. It uses category-specific expert analysis via sub agents and produces a structured report with severity levels and concrete fix suggestions.

## Phase 1: Scope Clarification

Use `AskUserQuestion` to ask the user:

1. **Target**: Which files or directories to analyze? (Accept glob patterns like `src/**/*.go`)
2. **Categories**: Which improvement categories to check?
   - All (default)
   - Security
   - Correctness
   - Performance
   - Refactoring
   - Code Smells
   - Best Practices
   - Modernization

If `$ARGUMENTS` is provided, treat it as the target path and default to all categories. Still confirm with the user before proceeding.

## Phase 2: File Discovery

1. Normalize the user's target into a glob pattern:
   - **Single file** (`internal/auth/handler.go`) → use as-is
   - **Directory** (`internal/auth` or `internal/auth/`) → expand recursively to `{target}/**/*.{go,ts,tsx,py}` (include all supported extensions, not just one language — a directory may be polyglot)
   - **Glob pattern** (`src/**/*.go`, `internal/**/*.{ts,tsx}`) → use as-is
   - **Repo root** (`.`) → warn the user about cost (many files will trigger grouping → 6 × N parallel sub agents) and confirm before proceeding
2. Use `Glob` with the normalized pattern to collect the list of target file paths.
3. Exclude common noise paths unless the user explicitly included them: `node_modules/`, `vendor/`, `dist/`, `build/`, `.git/`.
4. Detect the primary language(s) from file extensions of the collected files:
   - `.go` → Go
   - `.ts`, `.tsx` → TypeScript
   - `.py` → Python
   - Other → apply general analysis only
5. Collect the final list of file paths. **Do not read file contents** — sub agents will read them independently.
6. If available, note the project's linter configuration path (`.golangci.yml`, `.eslintrc.*`, `pyproject.toml`, `ruff.toml`) to pass to sub agents.

### File Grouping

If the collected file count exceeds **20 files**, launch a **grouping agent** (`Agent`, `subagent_type: "general-purpose"`) to split files into focused groups. This is a sequential step — wait for the grouping agent to return before proceeding to Phase 3.

**Grouping agent prompt must include:**
- The full list of collected file paths
- The detected language(s)
- Instruction: "Group these files for parallel code review. Each group should contain 5–15 related files that a single reviewer can analyze together with sufficient context."

**What the grouping agent does:**
1. Reads the directory tree structure of the target files
2. Groups files by package/module directory — files in the same directory belong together
3. Merges related directories heuristically by name similarity and proximity (e.g., `internal/auth` + `internal/session`, `internal/api` + `internal/middleware`)
4. Optionally reads import statements of a few representative files to confirm relatedness
5. Splits directories that exceed 15 files into smaller groups
6. Merges directories smaller than 3 files with the nearest related group
7. Returns a JSON object mapping group labels to file lists:

```json
{
  "groups": [
    { "label": "auth-session", "files": ["internal/auth/handler.go", "internal/session/store.go", ...] },
    { "label": "api-middleware", "files": ["internal/api/server.go", "internal/middleware/logging.go", ...] },
    { "label": "cmd-config", "files": ["cmd/server/main.go", "pkg/config/config.go", ...] }
  ]
}
```

If file count is ≤ 20, skip the grouping agent — all files form a single group.

## Phase 3: Multi-Pass Analysis via Sub Agents

Launch sub agents as follows:
- **Single group** (≤ 20 files or grouping skipped): 1 sub agent per category → **7 sub agents**
- **Multiple groups**: 1 sub agent per (category × group) → **7 × N sub agents** (where N = number of groups)

**Launch all sub agents in a single message (multiple `Agent` tool calls in one response) so they run in parallel.** Sequential invocation defeats the purpose of this design.

**IMPORTANT**: Do not combine multiple categories into a single agent. The persona separation is load-bearing — combined agents systematically miss "what's missing" findings and cross-cutting security concerns. Always launch one agent per category (or per category × group).

### What the parent agent includes in each sub agent's prompt

The sub agent has no context beyond its prompt. The parent must include all of the following:

1. **Persona** — the category-specific role (e.g., "You are a Senior Security Engineer")
2. **Category description** — copy the relevant category section from this file (e.g., "### Category: Security") into the prompt verbatim
3. **Target file paths** — the full list of files to analyze
4. **Detected language(s)** — so the sub agent knows which `checks/{lang}.md` to read
5. **Linter configuration path** — if found in Phase 2
6. **Output format** — copy the "Sub Agent Output Format" section into the prompt
7. **Instruction to read reference files** — tell the sub agent to read `checks/{lang}.md` and `checks/patterns.md` at the paths relative to this skill directory (provide the absolute paths). Emphasize that items in these files are illustrative examples grouped by underlying principle — not exhaustive checklists. The sub agent must report equivalent issues even when they are not explicitly listed.
8. **File group scope** (if grouping applied) — the sub agent's **primary target** is its assigned group's files. It may read files outside the group to follow imports, references, or type definitions when needed for context. Findings should focus on the primary files, but cross-package issues discovered while following references should still be reported.

### What each sub agent does independently

**Step 1 — Load reference material:**
1. Reads `checks/{lang}.md` (e.g., `checks/go.md`) for each detected language. Items are grouped under **principles** — the sub agent applies each principle broadly, using the listed items only as representative examples. Equivalent issues not explicitly listed must still be reported if the underlying principle applies.
2. Reads `checks/patterns.md` and, when target code exhibits any pattern's **Trigger** (outbound HTTP client, DB query, cache, queue, background job, file I/O, logging, rate limiting, auth/session, config/feature flags), applies that pattern's **Checklist**. Each checklist item represents something that **should exist** — a checklist item absent from the code is itself a finding. Pattern findings are language-agnostic and get classified under the most relevant category.
3. If a linter configuration exists, reads it to avoid duplicate findings.

**Step 2 — Understand the code structure before analyzing:**
4. Reads all target files using `Read`.
5. **Map relationships between files** before looking for issues: identify import/dependency direction, caller → callee chains, interface implementations, middleware/interceptor ordering, and shared types. Build a mental model of how the files interact — not just what each file does in isolation.
6. **Trace execution paths**: For key entry points (HTTP handlers, gRPC methods, CLI commands, event handlers), follow the call chain through the target files. When a chain leads outside the group, read the external file to understand the interaction boundary. Issues often hide at the seams between components — interceptor ordering, decorator chains, middleware composition, error propagation across layers.

**Step 3 — Analyze with context:**
7. Performs analysis for its assigned category, informed by the structural understanding from Step 2. Findings should reference the execution context (e.g., "this nil check is missing on the path from handler.ServeHTTP → service.Process → repo.Get") rather than reporting file-local symptoms in isolation.
8. Returns findings as structured JSON.

**Two analysis modes** — sub agents must analyze from both directions:
- **What's wrong**: problems in existing code (bugs, inefficiencies, anti-patterns)
- **What's missing**: capabilities that should exist but don't (error handling, timeouts, retry logic, validation, observability)

The "what's missing" mode is structurally harder — it requires reasoning about what the code *should* do based on its purpose, not just what it *does* do. The `checks/patterns.md` checklists are primarily "should-exist" lists and are the main driver for this mode. Sub agents must actively look for absent capabilities, not only present defects. However, absence may be intentional — frame missing-capability findings as "consider whether X is needed" rather than asserting a defect, unless the omission is clearly dangerous (e.g., no timeout on an HTTP client, no error check after a fallible call).

### Cross-cutting: Deprecated / Legacy Usage

Across all categories, sub agents should flag any code using APIs, syntax, or patterns known to be deprecated or legacy in the target language ecosystem. Rely on LLM knowledge — do not enumerate specific APIs. Each language has a deprecation convention that serves as a signal:

- **Go**: `Deprecated:` marker in godoc (`staticcheck` SA1019 territory)
- **Python**: `DeprecationWarning` / `PendingDeprecationWarning`; APIs removed or scheduled for removal in recent CPython releases
- **TypeScript / JavaScript**: `@deprecated` JSDoc annotation; legacy language features

When uncertain about the deprecation status of a specific API, note the uncertainty rather than reporting it as definitive (see `Avoid false positives` principle). Deprecated usage findings are classified under **Refactoring** unless they constitute a security or performance issue.

### Sub Agent Output Format

Each sub agent must return a JSON array:

```json
[
  {
    "id": "S1",
    "category": "Security",
    "title": "Brief title",
    "file": "path/to/file.go",
    "line": 42,
    "severity": "Critical|High|Medium|Low",
    "current_code": "// problematic code snippet",
    "issue": "Clear explanation of the problem and its impact",
    "suggested_fix": "// improved code snippet"
  }
]
```

### Category: Security (Persona: Senior Security Engineer)

Analyze for:
- **Injection vulnerabilities**: SQL injection, command injection, XSS, path traversal
- **Secrets exposure**: hardcoded credentials, API keys, tokens, passwords
- **Cryptographic issues**: weak hashing (MD5/SHA1 for security), insecure random, broken crypto
- **Unsafe deserialization**: untrusted data unmarshaling without validation
- **Missing input validation**: system boundary inputs not validated
- **Concurrency safety**: race conditions, unprotected shared state, goroutine leaks (Go)
- **Auth/AuthZ gaps**: missing authentication checks, privilege escalation paths

For language-specific security checks, see `checks/{lang}.md` → `## Security` section.

### Category: Performance (Persona: Performance Engineer)

Analyze for:
- **Algorithmic inefficiency**: O(n^2) or worse where O(n log n) or O(n) is possible
- **N+1 queries**: database calls in loops
- **Unnecessary allocations**: allocations in hot loops, string concatenation in loops
- **Missing caching**: repeated expensive computations with same inputs
- **Unbounded growth**: maps/slices/channels that grow without limits
- **Blocking in hot paths**: I/O or locks in performance-critical code
- **Unnecessary copies**: large struct copies where pointers would suffice

For language-specific performance checks, see `checks/{lang}.md` → `## Performance` section.

### Category: Correctness (Persona: Senior Software Engineer — Runtime Correctness)

Analyze for:
- **Nil/null safety**: dereferencing potentially nil pointers, accessing nil maps/slices, unguarded optional access
- **Error handling correctness**: swallowed errors causing incorrect subsequent behavior, wrong error variable checked
- **Boundary conditions**: off-by-one, empty collection edge cases, integer overflow/underflow
- **Concurrency correctness**: race conditions, deadlocks, closure variable capture, incorrect synchronization
- **Type safety at runtime**: incorrect type assertions, unsafe casts producing silent wrong values
- **Logic errors**: inverted conditions, wrong boolean operators, incorrect comparison
- **Resource lifecycle**: use-after-close, double-close, leaked resources on error paths
- **API contract violations**: misusing library/framework APIs in ways that cause silent incorrect behavior

For language-specific correctness checks, see `checks/{lang}.md` → `## Correctness` section.

### Category: Refactoring (Persona: Software Architect)

Analyze for:
- **God functions/methods**: functions doing too many things (>40 lines, multiple responsibilities)
- **Deep nesting**: >3 levels of indentation (consider early returns, guard clauses)
- **Duplicated logic**: similar code blocks that should be abstracted
- **Inappropriate coupling**: tight coupling between modules that should be independent
- **Dead code**: unused functions, unreachable branches, commented-out code
- **Inconsistent error handling**: mixed patterns for error handling within the same module
- **Long parameter lists**: >4 parameters (consider parameter objects or builder pattern)
- **Primitive obsession**: using primitive types where domain types would be clearer

For language-specific refactoring checks, see `checks/{lang}.md` → `## Refactoring` section.

### Category: Code Smells (Persona: Code Quality Specialist)

Analyze for:
- **Feature envy**: methods that use another object's data more than their own
- **Shotgun surgery**: one conceptual change requires edits across many files
- **Magic numbers/strings**: unnamed constants scattered through code
- **Overly complex conditionals**: boolean expressions that need extraction or truth tables
- **Data clumps**: groups of variables that always appear together (should be a struct/class)
- **Middle man**: classes/functions that only delegate without adding value
- **Speculative generality**: abstractions for scenarios that don't exist yet
- **Temporal coupling**: operations that must happen in a specific order but nothing enforces it

For language-specific code smells, see `checks/{lang}.md` → `## Code Smells` section.

### Category: Best Practices (Persona: Language Expert)

Best practices are almost entirely language-idiomatic. Sub agents must read `checks/{lang}.md` → `## Best Practices` section for each detected language as the primary reference for this category, applying the same principle-based reasoning to unlisted but equivalent idioms.

### Category: Modernization (Persona: Language Version Specialist)

This agent analyzes whether the code takes full advantage of the target language's latest stable version.

**Step 0 — Determine the target version:**
Read the project's version specification file (`go.mod`, `package.json` `tsconfig.json`, `pyproject.toml`, `.python-version`, etc.) to identify the minimum supported language version. All suggestions must be valid for that version or newer.

Analyze for:
- **Modern stdlib replacements**: standard library packages or functions introduced in recent versions that replace older patterns or third-party dependencies (e.g., a newer stdlib package that makes an external library unnecessary)
- **Syntax and language feature upgrades**: newer syntax that is more readable, safer, or more performant than the equivalent old-style code
- **Deprecated API migration**: APIs marked deprecated in the language or its ecosystem, with concrete migration paths to the recommended replacement
- **Third-party to stdlib migration**: cases where functionality that previously required a third-party library is now available in the standard library
- **Compiler / runtime improvements**: patterns that can be simplified because newer compiler or runtime versions handle them automatically (e.g., loop variable capture semantics, automatic escape analysis improvements)

For language-specific modernization checks, see `checks/{lang}.md` → `## Modernization` section.

Note: The Cross-cutting "Deprecated / Legacy Usage" section still applies to all other agents. This category goes further — it covers non-deprecated patterns that have strictly better modern alternatives, and provides version-aware migration guidance.

## Phase 4: Consolidation

Collect the JSON results from all sub agents, then:

1. **Deduplicate**: Remove findings that overlap across categories or across groups (keep in the most relevant category). When grouping is applied, different groups' sub agents may report the same cross-package issue — deduplicate by file + line + category.
2. **Check for partial coverage gaps**: When multiple findings touch the same area (e.g., connection resilience), verify that each distinct concern is addressed independently. A finding about timeouts does not satisfy the need for retry logic, even though both relate to "resilience." Cross-reference `checks/patterns.md` checklists against reported findings — if a triggered pattern has checklist items not covered by any finding, flag the gap as an additional finding.
3. **Re-evaluate severity based on impact scope**: Sub agents report severity from a local perspective. The parent agent must adjust severity by considering the broader impact:
   - **Shared code amplifier**: A finding in a shared library, common middleware, or base package used across many callers is higher severity than the same finding in a leaf package. A Medium issue in `pkg/errors/` that all services import may warrant High.
   - **Execution path criticality**: Issues on hot paths (request handling, authentication, data persistence) are higher severity than issues in setup/teardown or CLI tooling.
   - **Blast radius**: Consider how many services, endpoints, or users are affected. An unrecovered panic in a per-request goroutine is more critical than one in a background cleanup job.
   - Apply these adjustments to the base severity:
     - **Critical**: Security vulnerabilities that could be exploited, data loss risks
     - **High**: Significant performance issues, major design flaws, potential bugs
     - **Medium**: Code smells that impact maintainability, minor performance issues
     - **Low**: Style issues, minor best practice deviations, documentation gaps
4. **Sort**: Order findings by severity (Critical → High → Medium → Low), then by file
5. **Count**: Tally findings per category and severity

## Phase 5: Report

Present findings in this format:

```markdown
# Code Improvement Report

## Summary
- **Files analyzed**: N
- **Language(s)**: Go / TypeScript / Python
- **Findings**: N total (N Critical, N High, N Medium, N Low)

## Critical Findings

### [C1] Category: Brief title
- **File**: `path/to/file.go:42`
- **Severity**: Critical
- **Current code**:
  ```go
  // problematic code snippet
  ```
- **Issue**: Clear explanation of the problem and its impact
- **Suggested fix**:
  ```go
  // improved code snippet
  ```

## High Findings
...

## Medium Findings
...

## Low Findings
...

## Next Steps
- Prioritized list of recommended actions
- Suggestion to run linter after applying fixes (if applicable)
```

## Principles

- **Judge from general principles** — This skill reasons from general principles, not from enumerated rule databases. The items in `checks/{lang}.md` and `checks/patterns.md` are **illustrative examples**, not exhaustive checklists. Sub agents must recognize equivalent issues through the underlying principle (e.g., "avoid unbounded resource consumption", "prefer modern idioms over legacy APIs", "validate at trust boundaries"), even when the specific API, library, or syntax is not explicitly listed. Use LLM knowledge of the language ecosystem to identify issues that rhyme with the listed examples. For exhaustive rule enforcement, defer to linters (`staticcheck`, `ruff`, `eslint`, etc.) — this skill's value is reasoning, not rule matching.
- **Never analyze from descriptions alone** — always read the actual code first.
- **Be specific** — every finding must include the exact file path and line reference.
- **Be actionable** — every finding must include a concrete code suggestion, not just a problem description.
- **Avoid false positives** — if unsure whether something is an issue, note the uncertainty rather than reporting it as definitive.
- **Respect existing patterns** — if the codebase consistently uses a pattern, don't flag it as an issue unless it's a genuine problem (security, correctness).
- **Consider context** — a pattern that's fine in a CLI tool may be problematic in a web server. Adjust severity based on the application context.
- **Stay domain-agnostic** — This skill analyzes from general engineering principles without knowledge of business requirements, domain logic, or intended product behavior. Do not infer what the code *should* do from domain context (e.g., "this looks like a payment flow, so it should have idempotency"). Judge only from what is observable in the code: types, control flow, API contracts, and language semantics. When a finding would only be valid under certain business assumptions, state the assumption explicitly (e.g., "if this operation is intended to be retryable, consider adding..."). This principle applies especially to "what's missing" findings and Correctness findings — both are prone to projecting requirements that may not exist.
- **Don't flag what linters catch** — if the project has a linter configured, focus on issues beyond what the linter already enforces.
- **Suggest, don't demand** — present findings as recommendations for human review, not automatic fixes.
