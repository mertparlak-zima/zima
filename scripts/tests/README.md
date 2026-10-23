# scripts/tests

Tests for the manifest validator and verify logic. No Pester dependency - plain
assertions; exit 0 = all pass.

## Contents / rules
- `run-tests.ps1` - dot-sources zima.ps1 (ZIMA_DOT_SOURCED=1 guard) and runs:
  schema structure and defaults, malformed and unknown fields, canonical paths and
  junction escape, exact ignore rules, D19 pruning/depth, deterministic generation,
  portable workspace paths, CLI JSON/exit contracts, actual Git dirty/conflict/detached/
  upstream states, external command failures, atomic lock race/ownership, real rg
  visibility (including linked-worktree `.git` files) and Full `.env`/entire-index/
  preamble checks, duplicate environment keys, unchanged tracked secrets/protected
  paths, Unicode/space filenames and the allowed `projects/.gitkeep` exception.
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
- `backup-tests.ps1` uses only `.agent-tmp/a1-backup/fixture-<guid>/` and loads the
  backup script without executing its production entry point. Tiny binary files,
  file/directory ADS, empty/absent categories, largest-image/signing sample restore,
  restrictive ACLs, redacted matching receipts and protected inventory hashes are
  exercised. Rejections cover low capacity, actual robocopy >=8, source changes,
  backup/restore corruption, weak ACLs, running-emulator injection, existing targets,
  a competing destination claim, arbitrary fixture roots, production fault injection,
  junction escapes, sparse files and hard-linked metadata. Source fingerprints include
  data, streams, timestamps, attributes and original DACL; failures preserve sources
  (the explicit source-change fixture intentionally simulates a separate writer).
  Fixtures are retained for review; `implementation-tests.json` is the redacted result.
  Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/backup-tests.ps1`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/run-tests.ps1`.
  A new safety rule needs a meaningful rejection regression in the same change.

## Related
- [../README.md](../README.md) - [../../repos.schema.json](../../repos.schema.json)
