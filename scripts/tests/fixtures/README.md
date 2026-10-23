# scripts/tests/fixtures

Broken manifest fixtures for the negative-validation tests. Every file here is
DELIBERATELY invalid and must be REJECTED by `Invoke-ZimaManifestValidation` with the
error message `run-tests.ps1` expects.

## Contents / rules
- `bad-*.json` - one specific defect each (duplicate name, path traversal, bad enum,
  missing field, duplicate label, CI-without-runner, third-party inside the tree,
  path/name mismatch).
- New validator rule => add a matching negative fixture + assertion in the same change.
- Never use these as templates - the valid example is the real `../../../repos.json`.

## Related
- [../README.md](../README.md) - [../../../repos.schema.json](../../../repos.schema.json)
