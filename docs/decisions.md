# Workspace decision log

Chronological, dated, append-only. Decisions here are workspace-level and bind all repos
via AGENTS.md; repo-specific decisions live in the repo's own docs.

| Date | Decision | Context |
|---|---|---|
| 2026-10-07 | coin-tracker runner `ct-docker-1` stays RUNNING between tasks | owner decision; shared engine — others must not quit Docker Desktop because of it |
| 2026-10-16 | Chain of command: subagent → leader → user. Subagents never contact the user directly (Telegram included); only the leader notifies/asks | a device agent messaged the user directly on Telegram; single point of contact enforced since |
| 2026-10-18 | Automation-first: the agent performs device/OS/app settings itself (adb etc.) and verifies by measurement; walking the user through menus is forbidden except for physically-required actions | repeated manual-UI requests slowed device work |
| 2026-10-19 | zima meta-repo architecture: plain clones + gitignore + JSON manifest; no submodules; harness-agnostic repo root (AGENTS.md + .agents/skills, no CLAUDE.md/.claude at zima root) | multi-research plan v1-v5; architecture audit accepted |
| 2026-10-19 | Telegram becomes ONE-WAY: only `telegram_send_notification`; ask_user + session-mailbox tools denied at settings level; broker code untouched (stays sole getUpdates consumer for the Daily Moods product bot) | reply mechanism unreliable; park-file protocol replaces blocking asks |
| 2026-10-19 | Review tiering replaces fixed "2 independent reviewers": leader decides T0-T3 via risk/scope self-check; "merge-bound" alone never triggers T3 | fixed dual review slowed small changes (user decision) |
| 2026-10-19 | Sessions always start at the zima root; repo rules are read on demand through cards (rules-read record) | single workspace context; path-keyed surfaces repaired in cutover |
| 2026-10-19 | Task & Issue standard centralized in zima (`docs/issues.md`); issues live in the repo they belong to (zima included); legacy issues read-only; commit auto-close keywords forbidden (`Refs` in commits, `Closes` in PR body only) | prior auto-close-before-evidence incidents |
| 2026-10-19 | Folder README convention (D19): every committed folder carries a short technical README; exceptions whitelisted in verify | workspace navigability for agents and humans |
| 2026-10-19 | Deferred cutover: zima built in `projects/zima` while old workspace keeps running; single maintenance window moves repos with their uncommitted changes; old root ends containing only `zima/` | user decision — zero-interruption build, atomic switch |
| 2026-10-21 | A1.4 live agent startup/context tests WAIVED; no custom launcher or model/profile answer required. Agents read documents and record the relevant rules read | explicit user decision; see [scope and preserved gates](#agent-startup-decision--2026-10-21) |

## Factual correction — 2026-10-20

The 2026-10-19 Telegram row's product-bot dependency was an unverified premise, not
evidence of shared bot identity or polling ownership. Preserve the workspace broker's
single-consumer invariant, discover its actual polling owner during A2, and keep the
Daily Moods personal product bot separate. Environment-variable names establish no
credential/identity relationship; never inspect their values to compare them.
See [notification contract](telegram/NOTIFICATIONS.md) and
[migration runbook](migration-2026-10.md). The historical row is retained unchanged.

## Agent startup decision — 2026-10-21

User instruction: “boşver canlı testleri zaten her agent dökümanları okuyarak kendisi
anlayacaktır özel bir şey vs yapmaya gerek yok”

A1.4 is WAIVED, never PASS. Cancel live Claude/OpenCode startup/context tests,
model/profile requests and the custom startup helper. Normal AGENTS/card/member
rules/skill reads and task-log records remain required. G08 records document reads;
G19 verifies selected-memory source/destination paths and content hashes while
retaining originals, without a model/session spot-check. Earlier test attempts and
their authorization remain historical observations, not proof of automatic loading.

This waiver changes only agent startup/model callbacks. CI and permission enforcement,
backup/restore, AVD/device and Telegram functional checks remain required. Commit/push
hold and A2 NO-GO remain in force. Durable local resolution:
`.local-state/decisions/a1-harness-profile.md`; the pending profile question is closed.

## Publication and partial adoption — 2026-10-23

The user released the commit/push hold for zima and authorized gradual transfer of
current projects except active DriveTrace. [The scoped record](partial-migration-2026-10-23.md)
lists the four eligible projects. DriveTrace, its worktrees/runner/evidence and
shared old-root infrastructure remain outside this operation. The prior hold and
full-workspace-only cleanup assumption are superseded for this authorized scope;
data integrity and independent Git boundaries remain required.

## DriveTrace adoption and old-root retirement - 2026-10-25

The user explicitly released the DriveTrace exclusion, requested publication of
existing local commits, and authorized deleting its old directory and the last
two root instruction Markdown files. All five catalogued projects now use
`zima/projects/`; [the setup record](partial-migration-2026-10-23.md) documents the
completed operations. Existing machine/broker infrastructure stays in place.
The earlier DriveTrace exclusion applies only to its historical partial stage.

## Local workspace settings and outbound Telegram - 2026-10-25

The user requested moving the two local Claude files into ignored `zima/.claude/`
and replacing the old JARVIS infrastructure with a single outbound command.
Its local `CLAUDE.md` imports the canonical Zima AGENTS. This supersedes the
historical no-local-Claude arrangement; harness-specific settings stay untracked.

`scripts/telegram-notify.mjs` reads the bot token and chat ID only from ignored
root `.env`, sends one message, then exits. No MCP, broker, listener, startup
service, session routing, question or reply handling remains. Ask in the active
agent conversation. The user's explicit env-storage instruction supersedes the
earlier HKCU-only/broker-preservation rules for workspace Telegram; unrelated
credentials and product Telegram features remain outside this change.
