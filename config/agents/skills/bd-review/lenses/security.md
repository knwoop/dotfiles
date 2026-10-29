# Lens: security

Label: `security`. Scope: each open PR, its own layer's diff, read against
the full files at the PR head.

Look for:

- Authorization: an endpoint, query or job reachable by someone who should
  not reach it; a missing ownership or tenant check.
- Input validation and injection: SQL, shell, path, template or header
  injection; unbounded input sizes.
- Secrets: credentials, tokens or keys in code, config, logs or error
  messages.
- Personal data: logged, returned, exported or stored beyond what the
  feature needs; missing masking.
- Unsafe defaults: permissive CORS, disabled verification, debug left on,
  wide IAM or file permissions.

Not this lens: general correctness or tests. When the diff touches none of
the above, say "checked, nothing found" and stop.
