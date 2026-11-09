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
- GitHub issues are managed under this fork only. All milestones are closed (M0/M1 completed 2026-10-28; later phases stay Backlog metadata). Implementation started 2026-10-25 by explicit user instruction; P01-P22 (issues #1-#22) closed with evidence — **first usable personal release shipped 2026-11-05**: v4301 "4.3-archive.1", debug-keystore-signed (user risk acceptance 2026-11-05), installed on the deployment phone CPH2095 with the upgrade path device-proven (PR #49, ADR-018; DoD checklist in release.md §14.3 ticked). Personal-use scope: no store, minSdk 31. PRODUCT PIVOT executed: #55 always-on SILENT capture merged, #56 Telegram forwarding pipeline merged (PR #60), debt issues closed (#50, #52, #53, #54); cloud arc #23-#25 closed/superseded. Backlog issue #63 tracked for future cloud DB integration (dual-trigger batching: size threshold or 5-min timeout); P23-P25 cloud on-demand only, nothing dispatched without explicit user ask.
- Upstream README, contribution policy, AI policy and licenses are preserved. AI-generated upstream issues/PRs/comments are not part of the own-fork workflow.
