# Go-specific Checks

Items below are **illustrative examples grouped by principle**, not an exhaustive checklist. Sub agents must apply each principle broadly — if the code exhibits an issue that rhymes with a listed example but is not explicitly mentioned, report it. For exhaustive rule enforcement, defer to linters (`staticcheck`, `golangci-lint`).

## Security

**Validate and sanitize at trust boundaries** — e.g.:
- SQL string concatenation (use `database/sql` placeholders)
- `os/exec.Command` with `sh -c` or unsanitized user input
- `filepath.Join` without `filepath.Clean` → path traversal
- `html/template` vs `text/template` misuse → XSS
- Unvalidated outbound URLs → SSRF

**Use cryptographically secure primitives** — e.g.:
- `math/rand` instead of `crypto/rand` for tokens, nonces, session IDs
- `crypto/tls` with `InsecureSkipVerify: true`
- MD5 / SHA1 for security-sensitive purposes (passwords, integrity)
- Hardcoded keys, API tokens, credentials

**Bound resource consumption** — e.g.:
- Unbounded `io.ReadAll` on request body → memory exhaustion
- `http.Server` / `http.Client` without timeouts
- Unbounded goroutine creation per request
- Goroutine leaks from missing `context.Context` propagation

**Treat deserialized data as untrusted** — e.g.:
- `encoding/xml` XXE / billion laughs
- `encoding/json` unbounded nesting depth
- YAML deserialization without type restrictions

**Don't leak internal details** — e.g.:
- Error messages exposing internal paths, SQL statements, stack traces
- Unrecovered panic at HTTP boundary → stack trace leak
- `net/http/pprof` exposed in production

**Avoid unsafe escape hatches** — e.g.:
- `unsafe` package usage without justification
- Type assertion without comma-ok idiom → panic on unexpected types
- `os.OpenFile` with world-writable modes (`0666`, `0777`)

## Performance

**Minimize allocations in hot paths** — e.g.:
- `append` without pre-allocated capacity (`make([]T, 0, n)`)
- String concatenation in loops (use `strings.Builder`)
- Map without size hint (`make(map[K]V, n)`)
- `json.Marshal` / `json.Unmarshal` in hot paths (consider code-gen)

**Choose the right concurrency primitive** — e.g.:
- Goroutine-per-request without a worker pool
- `sync.Mutex` where `sync.RWMutex` or `sync/atomic` would suffice
- `sync.Pool` opportunities for frequently allocated objects

**Hoist invariant work out of loops** — e.g.:
- `defer` inside tight loops (overhead accumulates)
- Regex compilation inside loops (hoist to package-level `regexp.MustCompile`)
- `reflect` calls in hot paths

**Pick the right algorithm / data structure** — e.g.:
- Linear scan of large slice where sorted + `sort.Search` would work
- Missing `context.Context` cancellation → doing work that will be discarded

## Correctness

**Guard against nil/zero-value traps** — e.g.:
- Write to nil map (panic)
- Method call on nil pointer where receiver is dereferenced
- Unguarded type assertion without comma-ok

**Verify concurrency correctness** — e.g.:
- Loop variable captured by goroutine closure (pre-Go 1.22)
- `sync.WaitGroup.Add` called after goroutine launch
- Missing mutex unlock on all code paths (especially error returns)
- Channel operations on nil channel (blocks forever)
- `time.After` in select loop (leaks timers each iteration)

**Check boundary and logic conditions** — e.g.:
- Off-by-one in slice operations
- Wrong error variable checked after multi-return call
- Inverted boolean condition or wrong comparison operator
- Integer overflow in length/capacity calculations

**Validate resource lifecycle** — e.g.:
- Use-after-close on `*os.File`, `*sql.DB`, network connections
- Missing `defer close` on error paths (resource created, early return skips cleanup)
- `context.CancelFunc` not called (leaked context)

## Refactoring

**Handle errors consistently and informatively** — e.g.:
- `fmt.Errorf` with `%v` instead of `%w` for wrapping
- Sentinel error compared with `==` instead of `errors.Is`
- Type assertion instead of `errors.As`
- Silently ignored errors (`_, _ =`, blank receivers)
- Inconsistent sentinel vs typed errors within the same package

**Design narrow, composable interfaces** — e.g.:
- Large interfaces (>5 methods) — violate interface segregation
- `interface{}` / `any` where generics fit
- Missing domain types (`type UserID string` over bare `string`)

**Keep function signatures simple and idiomatic** — e.g.:
- Functions with >4 parameters (use options struct / functional options)
- Missing `context.Context` as first parameter
- `context.Context` stored in struct fields
- `init()` with hidden side effects or global state

**Write tests that are easy to extend** — e.g.:
- Non-table-driven tests where parametrization fits
- Missing `t.Helper()` in test helpers
- `defer` cleanup instead of `t.Cleanup`

**Organize packages by responsibility** — e.g.:
- Package-level mutable state
- Utility packages (`utils`, `common`, `helpers`)

## Code Smells

- Magic numbers / strings in switch / if chains
- `panic` where `error` return is appropriate
- Commented-out code blocks left in source
- Stringly-typed APIs (string constants without a named type)
- Premature goroutines (concurrency without clear need)
- `defer` after error-prone operation (never runs on early error return)
- Boolean flag parameters (use typed enums or separate functions)
- `init()` abuse creating hidden ordering dependencies
- `fmt.Println` / `println` debug prints in production code
- `TODO` / `FIXME` without issue reference

## Best Practices

**Error handling** — wrap with `%w`, inspect with `errors.Is` / `errors.As`, return errors rather than panicking.

**Context propagation** — `context.Context` as first parameter of I/O functions, propagated through call chains, checked in long-running loops.

**Concurrency** — every goroutine has a clear cancellation path; `sync/errgroup` for parallel operations; channels for signaling, mutexes for state.

**Interfaces** — accept interfaces, return concrete types; keep interfaces small (1-3 methods); define at point of use.

**Naming** — avoid stutter (`http.HTTPServer` → `http.Server`); short names in small scopes, descriptive in large scopes.

**Testing** — table-driven tests with `t.Run`; `t.Helper()` in helpers; `cmp.Diff` over `reflect.DeepEqual`.

**Project structure** — `internal/` for non-exported packages; `cmd/` for binaries; zero-value useful structs; single-word lowercase package names.

## Modernization

**Read `go.mod`** to determine the module's Go version. All suggestions must be valid for that version.

**Stdlib replacements in recent versions** — e.g.:
- `log/slog` (Go 1.21+) over third-party structured loggers (`zap`, `logrus`) for new code
- `slices`, `maps` packages (Go 1.21+) over hand-rolled sort/search/clone
- `errors.Join` (Go 1.20+) over manual multi-error aggregation
- `context.WithCancelCause` / `context.AfterFunc` (Go 1.21+/1.23+) for richer cancellation

**Language feature upgrades** — e.g.:
- Range-over-func (Go 1.23+) for iterator patterns
- Loop variable per-iteration scoping (Go 1.22+) — old `v := v` capture workaround is unnecessary
- Generic types / functions (Go 1.18+) replacing `interface{}` + type assertions

**Third-party to stdlib migration** — e.g.:
- `golang.org/x/exp/slices` → `slices` (Go 1.21+)
- `golang.org/x/exp/maps` → `maps` (Go 1.21+)
- `io/ioutil` (deprecated Go 1.16) → `io` / `os` equivalents
