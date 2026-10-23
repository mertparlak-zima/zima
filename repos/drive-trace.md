# drive-trace — DriveTrace

**DEFERRED — user exclusion 2026-10-23.** Another agent is active in the old-root
project. This card is reference metadata; do not inspect, clone, sync, update, patch
or operate its source, worktrees, evidence, CI jobs or runner in this adoption.
The generated workspace omits it. A separate authorized transition is required.

## Identity

| Field | Value |
|---|---|
| Planned future dir | `projects/drive-trace` (not adopted) |
| GitHub | https://github.com/mertparlak-zima/drive-trace |
| Product | DriveTrace |
| Stack | Android/Kotlin offline dashcam, GPS, telemetry (Compose, Navigation 3, Hilt, Room, CameraX, Media3, MapLibre; minSdk 29/target 36, JDK 25) |
| Default branch | `main` |
| Local state | **irreplaceable** — `artifacts/device-evidence/` (permanent acceptance evidence, never uploaded) |

## Reference paths (planned future location; no source probes)

- `README.md` (README) — project overview
- `AGENTS.md` (AGENTS.md) — mandatory agent rules (issue-driven, evidence policy)
- `docs/agent-skills.md` (Skills catalog) — skills live in `.opencode/skills/` (+ vendored `vendor/`)
- Key docs: `docs/ROADMAP.md` (ROADMAP) (normative) · `docs/architecture.md` (architecture) · `docs/data-model.md` (data-model) · `docs/data-integrity.md` (data-integrity) · `docs/device-test-runbook.md` (device-test-runbook)
- Active work source of truth: [GitHub Issues](https://github.com/mertparlak-zima/drive-trace/issues) + milestones

## CI and runner

Workflows: `ci.yml`, `issue-governance.yml` (issue metadata sync + close-evidence gate —
its own issue form satisfies the zima issue standard), `release-candidate.yml`.
Runner: `dt-docker-1`, lifecycle **keep-off-between-tasks**, compose at
`D:\development\drive-trace\docker-runner` (EXTERNAL root — see `.env`).
**Label `drive-trace` pending migration** (workflows currently run on the shared
`[self-hosted, docker]` pool — add-label sequence in `docs/runners.md`).
Repo-owned scripts to use (never duplicate): `scripts/finalize-issue.ps1`,
`scripts/watch-ci.ps1`, `scripts/local-gate.ps1`, `scripts/run-device-lane.ps1`,
`scripts/run-gps-acceptance.ps1`, evidence scripts.

## Branches and protection

Default `main`. **Known external worktree:**
`D:\development\drive-trace\worktrees\issue13-tests` — outside this partial adoption; leave untouched.

## Workspace quirks

- Android SDK at `D:\development\drive-trace\android-sdk` (`local.properties`, unaffected by cutover).
- Physical device lane: OPPO CPH2095TR (ColorOS), wireless ADB preferred — acquire the
  `oppo-device` lock before lanes.
- Gradle build env quirks documented in workspace memory (AS JBR JDK 25, daemon restarts).
- The ~209 KB startup-set / 77 KB runbook figures are historical plan estimates.
  Current AGENTS/README already route phase-specific reads; measure again before any
  Faz B restructuring. Policy fixes (review tiering and one-way Telegram) are A2 gates.

## Leader notes

- Evidence policy: device evidence never uploaded; SHA + run-summary tables suffice.
- Issue governance automation must pass before issues are workable — keep `ct`/`dm`
  runners' shared engine healthy (never quit Docker Desktop while dt CI runs).
- Soak/lane runs hold device locks; 3-hour runs contend with CI on the same host.

Workspace router: [AGENTS.md](../AGENTS.md).
