# Python-specific Checks

Items below are **illustrative examples grouped by principle**, not an exhaustive checklist. Sub agents must apply each principle broadly — if the code exhibits an issue that rhymes with a listed example but is not explicitly mentioned, report it. For exhaustive rule enforcement, defer to linters (`ruff`, `flake8`, `mypy`).

## Security

**Never execute or deserialize untrusted input** — e.g.:
- `pickle.loads()` / `pickle.load()` on untrusted data
- `eval()` / `exec()` on user input
- `subprocess(..., shell=True)` with user input
- YAML `load()` without `safe_load()`
- `xml.etree` / `lxml` without `defusedxml`

**Validate at trust boundaries** — e.g.:
- SQL string concatenation / `.format()` in queries (use parameterized queries)
- `Jinja2` autoescape disabled for HTML
- `requests` with `verify=False`

**Protect secrets and credentials** — e.g.:
- Hardcoded secrets / credentials in source
- Flask / Django debug mode in production
- Weak hashing (`hashlib.md5` / `sha1`) for security purposes

## Performance

**Choose the right abstraction for scale** — e.g.:
- List comprehension vs generator for large datasets (memory)
- Missing `__slots__` on frequently-instantiated data classes
- GIL-bound CPU work that should use `multiprocessing`
- String concatenation in loops (use `"".join(...)`)

**Avoid blocking in async contexts** — e.g.:
- Sync I/O in async handlers
- Missing `asyncio.gather` for parallel async
- Sequential awaits where parallelism is possible

**Watch for ORM pitfalls** — e.g.:
- N+1 queries (missing `select_related` / `prefetch_related`)
- Pandas `iterrows` where vectorized ops work

## Correctness

**Guard against common runtime traps** — e.g.:
- `is` vs `==` for value comparison (identity vs equality)
- Mutable default arguments causing shared state across calls
- Modifying a collection while iterating over it
- Missing `await` on coroutine (coroutine never executes)

**Check boundary and logic conditions** — e.g.:
- Off-by-one in range/slice operations
- Integer division truncation (`/` vs `//` in Python 3)
- Incorrect exception variable scope (`except ... as e` rebound)
- Catching too-broad exceptions masking unrelated bugs

**Validate resource lifecycle** — e.g.:
- File/connection not closed on error paths (missing `with` statement)
- `asyncio` task created but never awaited (fire-and-forget without error handling)

**Verify concurrency correctness** — e.g.:
- Late binding closures in loops passed to threads/processes
- Shared mutable state across threads without locking
- `asyncio.gather` without `return_exceptions=True` losing errors

## Refactoring

- Missing `dataclass` / `NamedTuple` for data containers
- Bare `except:` clauses (catch specific exceptions)
- Mutable default arguments (`def f(x=[])`)
- Long function signatures without keyword-only arguments
- Classes used where a function / module would suffice
- `__init__.py` with heavy logic / side effects
- Circular imports

## Code Smells

- Magic numbers / strings without constants
- `global` keyword usage
- Overly complex list / dict comprehensions
- Deep nesting where early return / guard clauses work
- `print` debugging left in source
- Commented-out code blocks
- `lambda` assigned to variables (use `def`)

## Best Practices

**Type safety** — type hints for public function signatures and complex variables.

**Resource management** — context managers (`with` statements) for files, connections, locks.

**Error handling** — specific exception types, never bare `except:`.

**Modern idioms** — `pathlib.Path` over `os.path`; f-strings over `.format()`; `enum.Enum` / `StrEnum` over string constants; `dataclass(frozen=True)` / `NamedTuple` for immutable data.

**Module hygiene** — `logging` module over `print`; `__all__` for explicit exports; clean `__init__.py`.

## Modernization

**Read `pyproject.toml` / `.python-version` / `setup.cfg`** to determine the minimum supported Python version. All suggestions must be valid for that version.

**Syntax and language features** — e.g.:
- `match` / `case` (3.10+) for complex dispatch over `if`/`elif` chains
- `type` statement for type aliases (3.12+) over `TypeAlias`
- Exception groups and `except*` (3.11+) for concurrent error handling
- `Self` type (3.11+) over manual `TypeVar` for return-self patterns
- Walrus operator `:=` (3.8+) for assignment in conditions

**Stdlib replacements** — e.g.:
- `tomllib` (3.11+) over `toml` third-party package
- `pathlib` over `os.path` for file operations
- `dataclasses.field(kw_only=True)` (3.10+) for keyword-only dataclass fields
- `StrEnum` (3.11+) over `str, Enum` mix-in

**Type system evolution** — e.g.:
- Built-in generics `list[int]`, `dict[str, Any]` (3.9+) over `typing.List`, `typing.Dict`
- `X | Y` union syntax (3.10+) over `Union[X, Y]`
- `ParamSpec` / `Concatenate` (3.10+) for decorator typing
