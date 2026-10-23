<!-- zima:workspace-context v1 -->

# Workspace context (maintained by zima — do not edit per-repo)

This repository is a member of the **zima** workspace. All links below are relative
to this repository's root at `zima/projects/<this-repo>/`.
Workspace router: `../../AGENTS.md`.
Card: `../../repos/<this-repo>.md`.

Rules that apply regardless of repo-local rules (never-loosened set):

- **Chain of command** (2026-10-16): subagents never contact the user directly — Telegram
  included. Report to the leader; the leader asks the user.
- **Telegram is one-way** (2026-10-19): only the leader sends notifications, only via
  `telegram_send_notification`. Schema: `../../docs/telegram/NOTIFICATIONS.md`.
- **Temp files**: `.agent-tmp/<task>/` inside this repo; never AppData; never committed;
  cleaned task-scoped. PARKED decision files live in zima's `.local-state/parked/` (durable).
- **Issues**: this repo's issues follow `../../docs/issues.md` — legacy (marker-less) issues
  are READ-ONLY; commit messages use `Refs #N` (never auto-close keywords); `Closes #N`
  lives in the PR body only; gh writes are leader-only.
- **Runners**: labels are routing; never stop another repo's runner or quit Docker
  Desktop; see `../../docs/runners.md`.
- **Workspace credentials**: automation/JARVIS secret values remain in HKCU user
  environment; never copy them into files, logs, messages or commits. Existing product
  signing material and explicitly approved private product artifacts follow repo-local
  protection rules; this block never authorizes reading, publishing or committing them.
- **Git boundaries**: this repo is an independent git root; never treat the workspace as
  one repo.
- **Review**: workspace risk-based T0–T3 minimums apply; keep stricter local acceptance
  gates. Mandatory policy conflicts are patched at their actual source before cutover.
