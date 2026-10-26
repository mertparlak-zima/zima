# docs

Workspace-level documentation: policy documents that member repos reference instead of
duplicating. Link-only for repo content (cards under `repos/` carry those links).

## Contents / rules
- `runners.md` - runner policy; its registry table is GENERATED from repos.json.
- `issues.md` - task & issue standard (form marker, comment types, workflow, milestones).
- [cloudflare.md](cloudflare.md) - official MCP/OAuth setup, live tool checks and account/deployment workflow across sessions.
- `local-state.md` - irreplaceable local data inventory + backup/restore policy.
- `decisions.md` - dated workspace decision log (append-only).
- [workspace.md](workspace.md) - current six-project layout, setup and retained recovery evidence.
- `telegram/NOTIFICATIONS.md` - one-way notification contract.
- `templates/` - issue/comment/PR/folder-README templates.
- Every doc cross-links; no content duplication; nearer (repo) rules win except the
  never-loosened set in AGENTS.md.

## Related
- [../AGENTS.md](../AGENTS.md) - [../repos/README.md](../repos/README.md)
