# repos

Workspace repo index and per-repo cards. `repos.json` is the single source of truth;
this folder is its human/agent-facing view.

## Contents / rules
- `repos.md` - GENERATED index table (produced by `zima.ps1 gen`; never hand-edited).
- `<name>.md` - hand-written per-repo cards: identity, entry-doc LINKS to the repo's own
  docs (link-only, never copies), CI/runner facts, workspace quirks, leader notes.
- New repo => `zima.ps1 new-repo` scaffolds the card; fill it in the same change.
- When a repo doc moves, its card is updated in the same change.

## Related
- [../AGENTS.md](../AGENTS.md) startup protocol step 3-5 - [../docs/issues.md](../docs/issues.md)
