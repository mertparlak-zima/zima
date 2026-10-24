# zima

Workspace meta-repo for `C:\Users\mertp\Desktop\projects` — manages five independent git
repositories in its catalog. Four are eligible for the current partial adoption;
DriveTrace is deferred while another agent works in its old-root location.
zima holds the rules, the manifest (`repos.json`),
workspace docs, agent skills and orchestration scripts. Member repos live under `projects/`
(gitignored) and keep their own history, CI and rules.

**Start at [AGENTS.md](AGENTS.md).** It is the router: startup protocol, chain of command,
Telegram/runners/issues policies, and the skill index.

Current stage: four projects are available under `projects/`; see the
[workspace setup](docs/partial-migration-2026-10-23.md). Originals are retained;
DriveTrace and shared old-root infrastructure stay in their original locations.
[Readiness and audit](docs/a1-readiness.md) records verified results and remaining gates.
Each agent reads AGENTS.md, the target repo card and that repo's rules/skills before work.
Deferred members are metadata only; operational commands and source/runner probes skip them.

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
