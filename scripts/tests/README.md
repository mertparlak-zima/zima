# scripts/tests

Lightweight, in-memory unit tests for the manifest validator, runner rules, and
generated artifacts. No Pester dependency, no network I/O, and no slow disk fixtures.

## Contents
- `run-tests.ps1` - dot-sources `scripts/zima.ps1` (`ZIMA_DOT_SOURCED=1`) and verifies
  manifest schema validation, mandatory local Docker runner and `ci_workflows` rules,
  rejection of `fixtures/bad-*.json`, path traversal guards, deferred-member filtering,
  generated artifact consistency, and `zima.ps1` UTF-8 BOM + CRLF encoding.
  Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/run-tests.ps1`.
- `telegram-notify.test.mjs` - offline unit tests for `scripts/telegram-notify.mjs`.
  Run `node --test scripts/tests/telegram-notify.test.mjs`.
- `fixtures/` - broken manifests that MUST be rejected by `Invoke-ZimaManifestValidation`.

## Related
- [../README.md](../README.md) - [../../repos.schema.json](../../repos.schema.json)
