# Leader references

Templates used by [zima-leader](../SKILL.md). These files define the subagent contract
and the workspace context added to member repositories during onboarding.

- [preamble.md](preamble.md): copy the contract and substitute the target path and task.
- [workspace-context.md](workspace-context.md): substitute the member slug before use.

Read the target repository's own rules first. A workspace-context block supplements
them; policy conflicts require reviewed changes at their actual source. Member changes
must stay within the authorized task and preserve the router's never-loosened rules.

Router: [AGENTS.md](../../../../AGENTS.md). Current setup and recovery record:
[workspace](../../../../docs/workspace.md).
