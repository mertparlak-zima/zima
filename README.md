# zima

Workspace meta-repo for `C:\Users\mertp\Desktop\projects` — manages five independent git
repositories as a virtual monorepo. zima holds the rules, the manifest (`repos.json`),
workspace docs, agent skills and orchestration scripts. Member repos live under `projects/`
(gitignored) and keep their own history, CI and rules.

**Start at [AGENTS.md](AGENTS.md).** It is the router: startup protocol, chain of command,
Telegram/runners/issues policies, and the skill index.

Current stage: A1 publication authorized; [partial adoption](docs/partial-migration-2026-10-23.md)
preparing four projects while DriveTrace stays in its active old-root workspace.
[Readiness and audit](docs/a1-readiness.md) records verified results and remaining gates.
Each agent reads AGENTS.md, the target repo card and that repo's rules/skills before work.

Quick reference:

```powershell
powershell -File scripts/zima.ps1 status -Pending   # repo states (A1: repos not yet moved)
powershell -File scripts/zima.ps1 issues            # open issues across repos + zima
powershell -File scripts/zima.ps1 verify -Pending   # consistency gate
powershell -File scripts/zima.ps1 help              # all commands
```

Docs: [docs/runners.md](docs/runners.md) · [docs/issues.md](docs/issues.md) ·
[docs/telegram/NOTIFICATIONS.md](docs/telegram/NOTIFICATIONS.md) ·
[docs/decisions.md](docs/decisions.md) · [docs/local-state.md](docs/local-state.md)
