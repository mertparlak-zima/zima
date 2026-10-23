# Leader references

Templates used by [zima-leader](../SKILL.md). These files define the subagent contract
and the workspace context added to member repositories during onboarding or cutover.

- [preamble.md](preamble.md): copy the contract and substitute the target path and task.
- [workspace-context.md](workspace-context.md): substitute the member slug before use.

Read the target repository's own rules first. A workspace-context block supplements
them; contradictory A2 policies require reviewed patches to their actual source files.
It does not authorize modifying an active repository during A1.

Router: [AGENTS.md](../../../../AGENTS.md). Migration:
[runbook](../../../../docs/migration-2026-10.md).
