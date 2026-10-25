# zima

Workspace meta-repo for six independent Git repositories, all active under
`projects/`. Local Claude settings live in ignored `.claude/`.
zima holds the rules, the manifest (`repos.json`),
workspace docs, agent skills and orchestration scripts. Member repos live under `projects/`
(gitignored) and keep their own history, CI and rules.

**Start at [AGENTS.md](AGENTS.md).** It is the router: startup protocol, chain of command,
Telegram/runners/issues policies, and the skill index.

Open the `zima` folder directly in VS Code for one Explorer root and all seven
Source Control repositories: Zima plus the six members under `projects/`.
The shared [VS Code settings](.vscode/README.md) enable discovery to depth two;
they contain no machine paths or credentials.

Current stage: all six catalogued projects are active under `projects/`;
see the [current workspace record](docs/workspace.md).
Each agent reads AGENTS.md, the target repo card and that repo's rules/skills before work.
Any future deferred member remains metadata only until explicitly reactivated.

Quick reference:

```powershell
powershell -File scripts/zima.ps1 status            # active repo states; deferred members uninspected
powershell -File scripts/zima.ps1 issues            # open issues across repos + zima
powershell -File scripts/zima.ps1 verify -Full      # normal active-member consistency gate
powershell -File scripts/zima.ps1 help              # all commands
'Zima: work completed.' | node scripts/telegram-notify.mjs --silent
```

Telegram is outbound only: the command reads its bot token and chat ID from the
ignored root `.env`, sends one message and exits. No background service is needed.

Docs: [docs/runners.md](docs/runners.md) · [docs/issues.md](docs/issues.md) ·
[docs/telegram/NOTIFICATIONS.md](docs/telegram/NOTIFICATIONS.md) ·
[docs/decisions.md](docs/decisions.md) · [docs/local-state.md](docs/local-state.md)
