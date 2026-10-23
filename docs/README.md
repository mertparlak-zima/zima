# docs

Workspace-level documentation: policy documents that member repos reference instead of
duplicating. Link-only for repo content (cards under `repos/` carry those links).

## Contents / rules
- `runners.md` - runner policy; its registry table is GENERATED from repos.json.
- `issues.md` - task & issue standard (form marker, comment types, workflow, milestones).
- `local-state.md` - irreplaceable local data inventory + backup/restore policy.
- `decisions.md` - dated workspace decision log (append-only).
- `migration-2026-10.md` - cutover runbook, rollback plan, journal schema, GO gate.
- [a1-readiness.md](a1-readiness.md) - current audit evidence and remaining gates.
- [a2-go-checklist.md](a2-go-checklist.md) - preparation status and old-root disposition.
- [partial-migration-2026-10-23.md](partial-migration-2026-10-23.md) - authorized four-project adoption; DriveTrace excluded.
- [policy-patch-pack.md](policy-patch-pack.md) - mandatory A2 rule-source coverage.
- `telegram/NOTIFICATIONS.md` - one-way notification contract.
- `templates/` - issue/comment/PR/folder-README templates.
- Every doc cross-links; no content duplication; nearer (repo) rules win except the
  never-loosened set in AGENTS.md.

## Related
- [../AGENTS.md](../AGENTS.md) - [../repos/README.md](../repos/README.md)
