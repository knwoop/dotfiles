# TypeScript-specific Checks

Items below are **illustrative examples grouped by principle**, not an exhaustive checklist. Sub agents must apply each principle broadly — if the code exhibits an issue that rhymes with a listed example but is not explicitly mentioned, report it. For exhaustive rule enforcement, defer to linters (`eslint`, `tsc --strict`).

## Security

**Never execute or inject untrusted input** — e.g.:
- `eval()` / `Function()` constructor on user input
- Passing strings to `setTimeout` / `setInterval` (acts like `eval`)
- `innerHTML` / `dangerouslySetInnerHTML` with unsanitized data
- `document.write` with user-controlled content

**Validate at trust boundaries** — e.g.:
- Unvalidated URL construction → open redirect, SSRF
- Prototype pollution (unsafe object merging on user input)
- `JSON.parse` without schema validation on untrusted input
- Missing CSRF protection on state-changing endpoints

**Protect secrets** — e.g.:
- Hardcoded secrets / API keys in frontend bundles

## Performance

**Don't block the event loop** — e.g.:
- Synchronous operations blocking the main thread
- Large JSON payloads parsed synchronously
- CPU-intensive work that should use Web Workers

**Parallelize independent async work** — e.g.:
- Sequential `await` where `Promise.all` / `Promise.allSettled` would work
- Missing debounce / throttle on frequent event handlers

**Optimize bundle and render cost** — e.g.:
- Large bundle imports where tree-shaking would work
- Unnecessary re-renders (missing `memo`, unstable deps in `useEffect`)
- Missing virtualization for long lists
- Missing code splitting / lazy loading at route boundaries

## Correctness

**Guard against silent undefined/null traps** — e.g.:
- Array index access returning `undefined` without check
- Optional chaining (`?.`) silently producing `undefined` in arithmetic/logic
- `in` operator on arrays (checks index, not value)

**Check async correctness** — e.g.:
- Missing `await` (function returns Promise instead of resolved value)
- `forEach` with async callback (doesn't await iterations)
- Unhandled promise rejection (missing `.catch` or try/catch)

**Check boundary and logic conditions** — e.g.:
- Floating point comparison (`0.1 + 0.2 === 0.3` is false)
- Object spread order silently overwriting intended values
- Incorrect truthiness check (empty string, `0`, `NaN` are falsy)

**Validate resource lifecycle** — e.g.:
- Event listeners not removed (memory leak in SPA)
- `setInterval` / `setTimeout` not cleared on component unmount
- `AbortController` signal not checked after long async operation

## Refactoring

**Leverage the type system** — e.g.:
- `any` type usage without justification
- Type assertions (`as X`) instead of proper type guards
- Missing discriminated unions where type narrowing would help
- `enum` where string literal union would work

**Use modern syntax** — e.g.:
- `var` usage (use `const` / `let`)
- `==` / `!=` instead of `===` / `!==`
- String concatenation with `+` instead of template literals
- Callback chains over `async` / `await`

**Keep components and modules focused** — e.g.:
- God components (>200 lines)
- Barrel file bloat (`index.ts` re-exporting too much)
- Long parameter lists (use options objects)

## Code Smells

- Magic strings / numbers in conditionals
- Mutating props / state directly
- `useEffect` dependencies with unstable object references
- Conditional hooks (violates rules of hooks)
- Commented-out JSX / code left in source
- `console.log` left in production code
- Boolean variables without `is` / `has` / `should` / `can` prefix
- Functions with hidden side effects
- `switch` without `default` or `never` exhaustiveness check

## Best Practices

**Strict type safety** — `strict: true` in tsconfig; no `any` without justification; `readonly` / `as const` for immutability; discriminated unions over type assertions; `satisfies` operator; type-only imports.

**Equality and syntax** — `===` / `!==`; `const` / `let` (never `var`); curly braces on all blocks; template literals; literal initializers.

**Error handling** — `throw new Error(...)` (never plain objects/strings); `new Error('msg', { cause: err })` for chaining; try/catch around fallible `await`.

**Async** — `async` / `await` over raw Promise chains; `Promise.all` for parallel work; `AbortController` for cancellation.

**Functions** — pure where feasible; centralize side effects; >3 params → options object; return early to avoid nesting.

**Naming** — `is` / `has` / `should` / `can` prefix for booleans; meaningful names; English identifiers.

**Module organization** — imports ordered (external → internal → relative); no global variables; export only what's needed.

## Modernization

**Read `tsconfig.json` / `package.json`** to determine the target ES version and TypeScript version. All suggestions must be valid for those versions.

**TypeScript version features** — e.g.:
- `satisfies` operator (TS 4.9+) over `as const` + manual type checks
- `const` type parameters (TS 5.0+) for inferred literal types
- `using` / `await using` for resource management (TS 5.2+ with ES2022+ target)
- `NoInfer<T>` utility type (TS 5.4+) to prevent unwanted inference

**ES version features** — e.g.:
- `Object.groupBy` / `Map.groupBy` (ES2024) over manual reduce-based grouping
- `Array.prototype.at()` (ES2022) for negative indexing
- `structuredClone` (ES2022) over `JSON.parse(JSON.stringify(...))` for deep copy
- `Error.cause` (ES2022) for error chaining
- Top-level `await` (ES2022) where applicable
- `Promise.withResolvers` (ES2024) over manual Promise constructor pattern

**Ecosystem modernization** — e.g.:
- Native `fetch` (Node 18+) over `node-fetch` / `axios` for simple HTTP
- `node:test` (Node 18+) as potential alternative to third-party test runners
- ES modules over CommonJS `require` where the project supports it
