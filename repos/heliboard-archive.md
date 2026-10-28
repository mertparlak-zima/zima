# heliboard-archive - HeliBoard Archive

[Workspace rules](../AGENTS.md) | [Index](repos.md)

## Identity

- Path: `projects/heliboard-archive`
- GitHub: https://github.com/mertparlak-zima/heliboard-archive.git
- Stack: Android Kotlin Java HeliBoard fork with offline personal text archive
- Default branch: `main`
- Local state: clean

## Entry documents

- [README](../projects/heliboard-archive/README.md) — fork mission and preserved upstream credits.
- [AGENTS.md](../projects/heliboard-archive/AGENTS.md) — own-fork workflow and workspace context.
- [Docs index](../projects/heliboard-archive/docs/README.md) — product and technical contracts.
- [Roadmap](../projects/heliboard-archive/docs/roadmap.md) — 25 tasks, dependencies and release gates.

## CI and runner

Target runner: `heliboard-archive-docker-1`, label `heliboard-archive`
(`[self-hosted, linux, x64, docker, heliboard-archive]`), lifecycle **stop-when-idle**
(owner decision 2026-10-26, workspace-wide default), compose `infra/runner/compose.yml`,
workflow `ci.yml`. P03 merged (PR #29): inherited upstream workflows
(`build-debug-apk.yml`, `build-test-auto.yml`) removed; local-only CI green with fork
identity `helium314.keyboard.archive` (ADR-002). Follow [runner policy](../docs/runners.md).

## Workspace quirks and leader notes

- Personal fork of [HeliBorg/HeliBoard](https://github.com/HeliBorg/HeliBoard).
- The first archive release must include both visible IME sessions and the owned note editor.
- Bootstrap source main is `c768bf5ebd6059bcbf56b4c5f8e94224890e1bf4` (4.3-beta1); stable v4.2 is a candidate to validate in P01/P02. Do not reset the fork history implicitly.
- GitHub issues are managed under this fork only. All milestones are closed (M0/M1 completed 2026-10-28; later phases stay Backlog metadata). Implementation started 2026-10-25 by explicit user instruction; P01-P18 (issues #1-#18) closed with evidence — latest: P17 variant audit + a11y (PR #44, ADR-013), P18 versioned JSON export streaming to SAF with no temp file (PR #45, ADR-014; local lint/CI robustness follow-up incl. kotlin.daemon 2g pin). Parked: upstream debug screen strip at P22 (decision banked 2026-10-28); P20 emulator lane ready (avd-24-min + avd-37-target smoke-tested). Next: P19 (#19) JSON import + clean-install restore.
- Upstream README, contribution policy, AI policy and licenses are preserved. AI-generated upstream issues/PRs/comments are not part of the own-fork workflow.
