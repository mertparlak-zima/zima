# Workspace project setup

All six catalogued projects are active under `projects/`.

| Project | Directory |
|---|---|
| DriveTrace | `projects/drive-trace/` |
| Coin Tracker | `projects/coin-tracker/` |
| Daily Moods | `projects/call-tracker/` |
| LG Channel List Editor | `projects/lg-tv-channel-sort/` |
| str-fixer | `projects/str-fixer/` |
| Tahmin Ligi | `projects/tahmin-ligi/` |

## Completed adoption - 2026-10-25

The four initial projects retained their history, branches and local ignored
files. Their old directories were removed after clean-Git/same-HEAD and local
file presence/size/time checks. Member policy/local-path edits remain local;
member repositories are independent and are excluded from Zima's index.

The user then authorized DriveTrace adoption and publication of its existing
local commits. Nine commits were pushed normally to `chore/devloop-device-lane`
and `test/issue47-a11y-i18n-gate`. No force push or merge occurred. Its independent
clone was fetched afterward; no unpublished commits remained at adoption.
Initial main HEAD `6fea671708d513c41b425138b6ba80c7e3f0aceb` was preserved.
Five clean external worktrees were reconnected to the new Git common directory,
with their contents and branches retained. All 7,310 non-cache local files
matched presence/size/time checks, including local configuration and evidence.
Only regenerable `.gradle`, `.kotlin`, root `build` and `app/build` were omitted.
The old DriveTrace directory was removed. Development now continues in its new
location independently of this completed workspace task.

The superseded root plan/review documents and, by explicit user request, the
last root `AGENTS.md` and `telegram-agent-instructions.md` were removed.
Start project sessions at [Zima AGENTS](../AGENTS.md). Notification rules are in
[the Zima notification contract](telegram/NOTIFICATIONS.md). Existing machine
infrastructure was initially retained; the Telegram simplification below supersedes
that temporary arrangement.

## Scope and verification

The user rejected the bespoke migration engine and its resource cost. It and
its dedicated tests were excluded from publication. Do not resume its old
attestation/COMMITTED workflow or add more migration tests. Use ordinary Git
checks and cloning, preserving required ignored local files. Historical protected
recovery records under C/D run `partial-20261023-b279d9711e44` remain retained.

Live AI startup tests and Call AVD boot were explicitly waived. No product,
device, AVD or CI acceptance PASS is claimed by workspace adoption.
The Daily Moods runner's readonly bind uses its new directory; its registration
files were verified. Runner/engine lifecycle and label changes remain separate.
Zima status disables optional Git index writes; the existing CLI validation
passed 151 baseline and 45 deferred/status assertions. Credentials/local data
remain excluded from the Zima Git index.

[Router](../AGENTS.md) - [Readiness](a1-readiness.md) - [Runner policy](runners.md)

## Tahmin Ligi and remaining root folders - 2026-10-25

Tahmin Ligi was moved into `projects/tahmin-ligi` with Git history, dependencies,
product env files, Vercel linkage and both local database backups retained.
Its old directory is gone. Application source and deployment were unchanged;
only the standard local workspace-context prefix was added to AGENTS.
Database backups and Vercel linkage are excluded from root ripgrep searches;
source remains visible. The local-data flag prevents blind future auto-cloning.

Remaining root-folder decisions and completed actions:

| Folder | Outcome |
|---|---|
| `.claude/` | Moved to ignored `zima/.claude/`; both local files retained. Its `CLAUDE.md` imports `../AGENTS.md` as the canonical workspace instructions. |
| `.idea/` | Five obsolete old-root IDE metadata files removed; no run/debug/database configurations were present. |
| `.jarvis-telegram-mcp/` | Retired and removed at the user's request. Owned MCP entries, the OpenCode loader and Startup launcher were removed; the old broker/MCP processes were stopped. Zima now uses one outbound CLI command. |
| `.local-archives/` | Empty directory removed. |
| `artifacts/` | Eleven unique evidence files (1,204,536 bytes) moved unchanged to ignored `zima/artifacts/`, outside the active DriveTrace project. |

## Outbound Telegram - 2026-10-25

The user requested a small sender instead of carrying forward JARVIS. The new
`scripts/telegram-notify.mjs` reads only the two Telegram credentials in ignored
root `.env`, accepts message text on stdin, sends one HTTPS `sendMessage` request
and exits. It has no incoming-message or server path. Existing unrelated user
environment settings remain intact. Credential values are never published.

The standard local workspace prefix was updated to v2 in all six member AGENTS
files, preserving their native instruction bodies. Member changes remain local;
concurrent DriveTrace development is independent of this workspace cleanup.
See [notification usage](telegram/NOTIFICATIONS.md).

Verification passed: 151 baseline assertions, eight offline sender tests and
15 synthetic env/index assertions. Normal `verify -Full` passed with the real
ignored `.env` and the entire staged index scanned. Two independent Tier 3
reviews approved the change. The parent workspace now contains only `zima/`.
