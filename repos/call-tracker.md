# call-tracker — Daily Moods

## Identity

| Field | Value |
|---|---|
| Dir | `projects/call-tracker` |
| GitHub | https://github.com/mertparlak-zima/call-tracker |
| Product | **Daily Moods** (product name ≠ repo/dir name; package `dev.dailymoods.app`) |
| Stack | Android/Kotlin single full-screen WebView app + local cellular-call METADATA collection (no audio); TS/Vitest tooling; Gradle unit tests |
| Default branch | `main`; preserve live dirty/staged/worktree state; workspace housekeeping never authorizes resetting it |
| Local state | **irreplaceable** — `private/` (AVD `avd-8`, keystores, personal build scripts) + `.planning/` acceptance evidence |

## Entry documents

- [README](../projects/call-tracker/README.md)
- [AGENTS.md](../projects/call-tracker/AGENTS.md) — strict: issue-driven, skill-per-task, no PII/APK/DB in git
- Skills live in top-level `skills/` (7 × `daily-moods-*`); product decisions:
  [daily-moods-product](../projects/call-tracker/skills/daily-moods-product/SKILL.md); workflow:
  [daily-moods-workflow](../projects/call-tracker/skills/daily-moods-workflow/SKILL.md)
- Active work: [GitHub Issues](https://github.com/mertparlak-zima/call-tracker/issues)

## CI and runner

Workflow: `ci.yml` (Vitest + Gradle unit/lint/assemble + `verify:apks`). Contract tests:
`scripts/ci-policy.mjs` asserts the exact label array — update together with any label
rename. Runner: `dm-docker-1`, label `daily-moods` (**rename to `call-tracker` pending** —
alias sequence in `docs/runners.md`), lifecycle **stop-when-idle**. Compose in-repo:
`infra/runner/`; bootstrap unit-tested (`tests/runner-bootstrap.test.mjs`).

## Workspace quirks

- Private scripts, AVD configuration and acceptance evidence remain protected by the
  member's own rules. Workspace adoption is complete; it does not certify AVD startup
  or replace the product's acceptance checks.
- Product Telegram configuration is separate from workspace notifications.
  Workspace sender rules: [NOTIFICATIONS.md](../docs/telegram/NOTIFICATIONS.md).

## Leader notes

- Signing preflight (2026-10-21): [toolchain signing boundary](../projects/call-tracker/skills/daily-moods-verification/references/toolchain.md)
  confirms default SDK debug signing for QA and no configured production release key.
  This is a dated observation; current signing and QA checks follow that source.

- CI label rename must be coordinated: runner alias + ci-policy.mjs expectation + workflow
  `runs-on` in one change (the contract test fails otherwise).
- `DAILY_MOODS_PERSONAL_TELEGRAM` builds are local-only, CI-forbidden.

Workspace router: [AGENTS.md](../AGENTS.md).
