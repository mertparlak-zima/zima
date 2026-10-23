# hooks

Versioned git hooks (installed via `git config core.hooksPath hooks` - standard .git/hooks
would not travel with clones).

## Contents / rules
- `pre-commit` - runs `zima.ps1 verify -Fast`; while `.local-state/migration/PHASE` says
  A1 it passes -Pending (repo directories do not exist yet); after cutover the full gate
  applies. Only the exact A1 marker enables Pending. Run time depends on the checks;
  bypassing the hook never waives the verification gate.

## Related
- [../scripts/README.md](../scripts/README.md) - [../docs/migration-2026-10.md](../docs/migration-2026-10.md)
