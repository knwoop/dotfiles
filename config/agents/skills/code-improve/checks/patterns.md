# Operational Patterns (language-agnostic)

Cross-cutting checklist for common operational patterns that apply regardless of language. Sub agents should scan target files for each pattern's **Trigger**, and when a pattern is detected, verify every item in its **Checklist**.

These checks are language-agnostic: Go `net/http`, Python `requests`/`httpx`, TypeScript `axios`/`fetch` all exhibit the same pattern and warrant the same checklist.

The patterns below are common but not exhaustive — sub agents should apply the same discipline to analogous patterns (e.g., GraphQL resolver, blob storage access) even if not explicitly listed.

Pattern-derived findings should be classified into the most relevant category (Security / Performance / Refactoring / Code Smells / Best Practices) during consolidation.

---

## 1. Outbound HTTP Client

**Trigger**: code makes HTTP calls to external services
(Go `http.Client` / `http.NewRequest`, Python `requests.get` / `httpx.AsyncClient`, TypeScript `fetch` / `axios`, etc.)

**Checklist**:
- [ ] **Timeout** — connect, read, and total request timeouts explicitly set (not default / infinite)
- [ ] **Retry with backoff** — transient failures (5xx, network errors) retried with exponential backoff + jitter
- [ ] **Retry cap** — max retry count bounded (avoid retry storms amplifying downstream outages)
- [ ] **Idempotency** — retries applied only to idempotent operations (GET/PUT/DELETE) or with an idempotency key for POST
- [ ] **Circuit breaker** — consecutive failure threshold to short-circuit when downstream is unhealthy
- [ ] **Context / cancellation propagation** — deadline and cancel signal passed through the call
- [ ] **Error classification** — distinguish transient (retry) vs permanent (fail fast, e.g., 4xx)
- [ ] **Rate limit respect** — honor `429` / `Retry-After` header, client-side throttling
- [ ] **Auth refresh** — `401` triggers token refresh before retry
- [ ] **Response size limit** — bound body read (guard against OOM on large / unexpected payloads)
- [ ] **Connection pooling** — client reused across requests, not instantiated per request
- [ ] **TLS verification** — certificate verification enabled (no `InsecureSkipVerify` / `verify=False`)
- [ ] **Observability** — metrics (latency, error rate, retry count), structured logs with correlation / trace ID

---

## 2. Database Query

**Trigger**: code issues SQL or ORM queries
(Go `database/sql` / `sqlx` / `ent` / `gorm`, Python `psycopg` / `SQLAlchemy` / Django ORM, TypeScript `pg` / `prisma` / `typeorm`, etc.)

**Checklist**:
- [ ] **Parameterized queries** — user input never concatenated into SQL strings
- [ ] **Query timeout** — per-query context / statement timeout bounded
- [ ] **Transaction boundaries** — multi-statement writes wrapped in a transaction with proper rollback
- [ ] **Connection pool config** — `max_open_conns`, `max_idle_conns`, `conn_max_lifetime` explicitly tuned (not library defaults)
- [ ] **Pagination** — unbounded list queries use `LIMIT` / cursor pagination
- [ ] **N+1 query prevention** — related data fetched in batch (JOIN / `IN` / ORM preload)
- [ ] **Index coverage** — queries on large tables use indexed columns (flag suspicious full scans)
- [ ] **Read / write separation** — read-only queries routed to replica when infrastructure supports it
- [ ] **"No rows" vs "error" distinction** — empty result handled separately from actual errors
- [ ] **Retry on transient errors** — connection loss / deadlock retried idempotently
- [ ] **Schema migration safety** — DDL run under lock timeout, avoid full rewrites on large tables
- [ ] **Observability** — query duration / error rate metrics, slow query log correlation

---

## 3. Cache Access

**Trigger**: code reads or writes a cache layer
(Redis, Memcached, in-process LRU, HTTP cache, React Query, SWR, etc.)

**Checklist**:
- [ ] **Explicit TTL** — every write has a bounded expiration, never "forever by default"
- [ ] **Cache stampede protection** — singleflight / distributed lock / request coalescing for hot keys
- [ ] **Stale-while-revalidate** — serve stale value on refresh failure instead of propagating the error
- [ ] **Negative caching** — miss results cached briefly to avoid repeatedly hammering the origin
- [ ] **Key naming & versioning** — namespaced / versioned prefix so invalidation is safe across deploys
- [ ] **Serialization consistency** — single format (JSON / msgpack / protobuf), documented
- [ ] **Size limit** — bounded value size to avoid evicting everything else
- [ ] **Graceful degradation** — cache failure falls back to origin, not a hard error
- [ ] **Invalidation strategy** — write-through / write-behind / TTL-only is explicit and consistent
- [ ] **Hit rate observability** — metrics for hit / miss / error counts

---

## 4. Queue / Pub-Sub

**Trigger**: code produces or consumes messages
(SQS, Kafka, RabbitMQ, Google Pub/Sub, NATS, Redis Streams, BullMQ, Celery, etc.)

**Checklist**:

*Producer side*:
- [ ] **Idempotency key** — messages carry a dedupe key for consumer deduplication
- [ ] **Retry on publish failure** — bounded retries with backoff
- [ ] **Ordering guarantee** — partition / routing key set when order matters
- [ ] **Batching** — high-throughput producers batch sends
- [ ] **Transactional outbox** — if DB state must stay consistent with publishes

*Consumer side*:
- [ ] **Idempotent consumer** — duplicate delivery handled (dedupe store or idempotent operation)
- [ ] **Dead-letter queue (DLQ)** — failed messages routed to DLQ after max retries
- [ ] **Ack after success only** — messages acknowledged only after durable processing completes
- [ ] **Visibility / lease timeout** — long processing extends visibility, not lost to redelivery
- [ ] **Backoff on retry** — exponential with jitter
- [ ] **Poison message handling** — infinite retry loops avoided
- [ ] **Graceful shutdown** — in-flight messages drained / returned on `SIGTERM`
- [ ] **Observability** — lag, DLQ depth, processing duration, retry count metrics

---

## 5. Background Job / Long-Running Work

**Trigger**: code spawns goroutines / threads / async tasks / cron jobs / worker pools for work that outlives a single request

**Checklist**:
- [ ] **Cancellation propagation** — `context.Context` / cancel token / `AbortController` threaded through
- [ ] **Timeout / deadline** — hard upper bound on run duration
- [ ] **Graceful shutdown** — in-flight work completes (or checkpoints) on `SIGTERM` / `SIGINT`
- [ ] **Bounded concurrency** — worker pool size capped (no unbounded goroutine / thread spawn)
- [ ] **Progress / heartbeat** — long-running jobs emit progress or liveness signal
- [ ] **Resumability** — crash-safe via checkpointing to durable storage
- [ ] **Error classification** — retryable vs fatal, with max retry
- [ ] **Panic / exception recovery** — uncaught errors don't kill the whole worker
- [ ] **Resource cleanup** — temp files / DB connections / locks released on exit
- [ ] **Observability** — start / complete / error counts, duration histogram, stuck job detection

---

## 6. File I/O

**Trigger**: code reads, writes, or manipulates files on disk

**Checklist**:
- [ ] **Close / cleanup on all paths** — defer / `with` / `try-finally` ensures release even on error
- [ ] **Size limit on reads** — bounded `ReadAll` / iteration to avoid OOM
- [ ] **Streaming for large files** — chunked / line-by-line, not load-entire-file
- [ ] **Atomic write** — write to temp + rename (fsync where durability matters)
- [ ] **Path validation** — reject `..` / absolute paths / symlink escapes on user-controlled input
- [ ] **Permissions** — file mode explicit, not world-writable (`0666`, `0777`)
- [ ] **TOCTOU safety** — no `stat` followed by `open` on the same name
- [ ] **Concurrent access** — file locks / advisory locks if multiple writers possible
- [ ] **Temp file handling** — unique unpredictable names, cleaned up even on crash
- [ ] **Disk space** — free-space check or quota before large writes

---

## 7. Logging

**Trigger**: code emits log records (any logger — stdlib, `zap` / `slog`, `logging`, `winston`, `pino`, etc.)

**Checklist**:
- [ ] **Structured logging** — key-value fields, not string concatenation
- [ ] **Appropriate level** — `debug` for development detail, `info` for flow, `warn` for recoverable, `error` for failures; avoid log-and-throw (duplicate)
- [ ] **Correlation / trace ID** — request or trace ID propagated and included in every log within a request scope
- [ ] **PII / secret scrubbing** — no emails, tokens, passwords, API keys, credit cards in log fields
- [ ] **Sampling for high-volume events** — hot-path logs sampled to avoid log storms
- [ ] **Context enrichment** — user ID, tenant ID, feature flag state attached
- [ ] **Error wrapping** — stack trace / root cause preserved, not lost to string format
- [ ] **No logging in hot loops** — avoid per-iteration logs unless gated
- [ ] **Consistent logger instance** — not `console.log` / `fmt.Println` / `print` scattered through production code
- [ ] **Log level configurable** — level controlled via config / env, not hardcoded

---

## 8. Rate Limiting (incoming)

**Trigger**: code exposes an HTTP / gRPC / API endpoint that could be abused

**Checklist**:
- [ ] **Rate limit applied** — per-IP, per-user, per-API-key, or per-tenant as appropriate
- [ ] **Algorithm choice explicit** — token bucket / leaky bucket / sliding window, documented
- [ ] **Distributed state** — shared across instances (Redis / shared store), not per-process
- [ ] **Response headers** — `X-RateLimit-*` / `Retry-After` returned on throttle
- [ ] **Fail-open vs fail-closed** — explicit policy when rate limiter itself is unavailable
- [ ] **Expensive endpoints** — lower limit on costly operations (search, export, bulk mutate)
- [ ] **Burst tolerance** — short bursts handled without immediate rejection
- [ ] **Whitelist / bypass** — internal / trusted sources exempt where justified
- [ ] **Observability** — throttle count, top offenders, per-endpoint hit rate

---

## 9. Authentication / Session

**Trigger**: code issues, validates, or refreshes credentials / sessions / tokens

**Checklist**:
- [ ] **Token expiry** — access tokens short-lived, refresh tokens longer but bounded
- [ ] **Refresh flow** — refresh token rotation to prevent replay
- [ ] **Revocation** — server-side revocation list / session store for compromised tokens
- [ ] **Signature verification** — JWT `alg` verified (reject `none`), key rotation supported
- [ ] **Timing-safe comparison** — secret / HMAC comparison uses constant-time function
- [ ] **Secure cookie flags** — `HttpOnly`, `Secure`, `SameSite` set appropriately
- [ ] **CSRF protection** — state-changing endpoints require CSRF token / `SameSite`
- [ ] **Session fixation protection** — session ID rotated on login / privilege change
- [ ] **Password storage** — bcrypt / scrypt / argon2 with tuned cost, never MD5 / SHA1
- [ ] **Rate limit on auth endpoints** — throttle login / password reset to prevent brute force
- [ ] **Lockout / backoff** — repeated failures trigger exponential delay (but no permanent lock without recovery flow)
- [ ] **Audit log** — login, logout, privilege change events recorded
- [ ] **PII in token** — no sensitive claims in unencrypted JWT payload

---

## 10. Feature Flags / Config

**Trigger**: code reads configuration, environment variables, feature flags, or secrets

**Checklist**:
- [ ] **Default values** — every flag / config has a safe default (fail-closed for risky features)
- [ ] **Type safety** — parsed to strong types with validation, not raw strings
- [ ] **Schema validation** — config validated at startup, fail fast on missing / invalid
- [ ] **Environment scoping** — dev / staging / prod values clearly separated
- [ ] **Secret handling** — secrets loaded from secret manager / env, not committed
- [ ] **Hot reload awareness** — if runtime reload is expected, code reads current value, not cached at startup
- [ ] **Rollout strategy** — feature flags support gradual rollout (percentage / user segment)
- [ ] **Kill switch** — risky features have an emergency-off flag separate from rollout percentage
- [ ] **Stale flag cleanup** — flags removed from code after full rollout (flag debt)
- [ ] **Observability** — flag evaluations logged / metered for audit and rollback decisions
- [ ] **Consistent within request** — flag value snapshotted per request, not re-evaluated mid-flow

---

## 11. gRPC Server Setup

**Trigger**: code assembles a gRPC server with interceptor chains
(Go `grpc.NewServer`, Python `grpc.server`, etc.)

**Checklist**:
- [ ] **Panic recovery interceptor is outermost** — index 0 in the chain, so it catches panics from all downstream interceptors and handlers
- [ ] **Default auth interceptor is fail-closed** — unauthenticated by default; services opt in to public access explicitly, not implicitly
- [ ] **Debug / introspection endpoints gated by environment** — reflection, admin services, verbose error details enabled only in dev/staging, disabled in production
- [ ] **Graceful shutdown with timeout fallback** — graceful drain with a deadline, falling back to forced stop if draining exceeds the timeout
- [ ] **Health check registered** — gRPC health service registered for load balancer probes
- [ ] **Observability interceptors** — logging, metrics, and tracing interceptors present in the chain

---

## 12. gRPC Client Connection

**Trigger**: code establishes gRPC client connections
(Go `grpc.DialContext` / `grpc.NewClient`, Python `grpc.insecure_channel` / `grpc.secure_channel`, etc.)

**Checklist**:
- [ ] **Keepalive parameters** — configured for long-lived connections to prevent silent drops behind load balancers / proxies
- [ ] **Retry policy** — available and opt-in for idempotent RPCs; non-idempotent RPCs fail fast
- [ ] **Default call timeout / deadline propagation** — every RPC has a deadline, either via default call options or per-call context
- [ ] **Connection reuse** — client connection shared across callers, not instantiated per request
- [ ] **TLS verification** — certificate verification enabled for production connections
- [ ] **Backoff configuration** — connection backoff parameters tuned (not relying on defaults for reconnect storms)
