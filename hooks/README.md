# hooks

Versioned git hooks (installed via `git config core.hooksPath hooks` - standard .git/hooks
would not travel with clones).

## Contents / rules
- `pre-commit` - runs `zima.ps1 verify -Fast` against the active workspace. Run time
  depends on the checks; bypassing the hook never waives the verification gate.

## Related
- [../scripts/README.md](../scripts/README.md) - [../docs/workspace.md](../docs/workspace.md)
