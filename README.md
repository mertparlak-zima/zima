# zima

Workspace meta-repo for six independent Git repositories, all active under
`projects/`. Shared machine infrastructure stays in its existing locations.
zima holds the rules, the manifest (`repos.json`),
workspace docs, agent skills and orchestration scripts. Member repos live under `projects/`
(gitignored) and keep their own history, CI and rules.

**Start at [AGENTS.md](AGENTS.md).** It is the router: startup protocol, chain of command,
Telegram/runners/issues policies, and the skill index.

Current stage: all six catalogued projects are active under `projects/`;
see the [workspace setup record](docs/partial-migration-2026-10-23.md).
[Readiness and audit](docs/a1-readiness.md) records verified results and remaining gates.
Each agent reads AGENTS.md, the target repo card and that repo's rules/skills before work.
Any future deferred member remains metadata only until explicitly reactivated.

Quick reference:

```powershell
powershell -File scripts/zima.ps1 status            # active repo states; deferred members uninspected
powershell -File scripts/zima.ps1 issues            # open issues across repos + zima
powershell -File scripts/zima.ps1 verify -Full      # normal active-member consistency gate
powershell -File scripts/zima.ps1 help              # all commands
```

During A1 preparation, add `-Pending` while active target directories are absent.
Pending is forbidden during/after partial adoption and never certifies a cutover.

Docs: [docs/runners.md](docs/runners.md) · [docs/issues.md](docs/issues.md) ·
[docs/telegram/NOTIFICATIONS.md](docs/telegram/NOTIFICATIONS.md) ·
[docs/decisions.md](docs/decisions.md) · [docs/local-state.md](docs/local-state.md)
