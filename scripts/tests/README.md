# scripts/tests

Tests for the manifest validator and verify logic. No Pester dependency - plain
assertions; exit 0 = all pass.

## Contents / rules
- `telegram-notify.test.mjs` - offline sender tests: BOM/quotes/duplicates/missing
  configuration, the exact HTTPS POST/body, request/body deadlines, sanitized errors
  and CLI argument rejection. Injected fetch implementations perform no network I/O.
  Run `node --test scripts/tests/telegram-notify.test.mjs`.
- `telegram-env-tests.ps1` - targeted real Full verification in a synthetic empty
  workspace: local Telegram fields are allowed but redacted, duplicates and other
  credentials still fail, and indexed Telegram values/force-added `.env` stay forbidden.
  It never reads the real `.env`, user environment credentials, registry or members.
  Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/telegram-env-tests.ps1`.
- `run-tests.ps1` - dot-sources zima.ps1 (ZIMA_DOT_SOURCED=1 guard) and runs:
  schema structure and defaults, malformed and unknown fields, canonical paths and
  junction escape, exact ignore rules, D19 pruning/depth, deterministic generation,
  portable workspace paths, CLI JSON/exit contracts, actual Git dirty/conflict/detached/
  upstream states, external command failures, atomic lock race/ownership, real rg
  visibility (including linked-worktree `.git` files) and Full `.env`/entire-index/
  preamble checks, duplicate environment keys, unchanged tracked secrets/protected
  paths, Unicode/space filenames and exact public-path exceptions: `projects/.gitkeep`,
  `.vscode/settings.json` and `.vscode/README.md`. VS Code cases cover ignored siblings
  and nested files, force-added neighbors, case variants and secrets in allowed blobs.
- Real Git success tests use a local bare remote. A wrapper redirects only the fetch
  transport from the declared GitHub URL to the fixture; origin checks, fetch and
  ff-only/diverged merges run actual Git. Dirty fetch fingerprints working files,
  index bytes, HEAD, stash, untracked and ignored bytes before and after.
- `fixtures/` - broken manifests that MUST be rejected with the expected error message
  (bad-dup-name, bad-path-traversal, bad-enum, bad-missing-field, bad-label-dup,
  bad-ci-no-runner, bad-thirdparty-inside, bad-path-name-mismatch).
- Assertions are counted. All synthetic repositories, mock CLIs and compiler temp
  files stay in `.agent-tmp/a1-hardening/tests-<guid>/`; only that canonical fixture
  is cleaned. `.agent-tmp/a1-hardening/test-summary.txt` retains the result.
- No network, real member repo, zima Git index, runner, broker or user config writes.
- The baseline uses an all-active synthetic manifest independently
  of production deferrals, preserving its original safety coverage.
- `deferred-tests.ps1` exercises optional active defaults, invalid deferral metadata,
  pure declared-path validation, early no-probe state, explicit refusal before native
  calls, bulk selection, active-only portable generation, metadata-only cards and
  runner queries scoped to active containers. All paths/CLIs are synthetic fixtures.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/run-tests.ps1`.
  A new safety rule needs a meaningful rejection regression in the same change.

## Related
- [../README.md](../README.md) - [../../repos.schema.json](../../repos.schema.json)
