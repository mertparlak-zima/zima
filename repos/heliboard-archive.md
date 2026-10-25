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

Inherited source workflows use GitHub-hosted runners: `build-debug-apk.yml`, `build-test-auto.yml`.
They are upstream workflows, not evidence that the archive is implemented or verified.
P03 audits the project CI. Workspace-managed `ci_workflows` remains empty until that setup;
the manifest requires an associated runner label before registering managed CI.
No local runner, container or signing key is provisioned by this bootstrap.
Follow [onboarding](../.agents/skills/zima-new-repo/SKILL.md) before future runner setup.

## Workspace quirks and leader notes

- Personal fork of [HeliBorg/HeliBoard](https://github.com/HeliBorg/HeliBoard).
- The first archive release must include both visible IME sessions and the owned note editor.
- Bootstrap source main is `c768bf5ebd6059bcbf56b4c5f8e94224890e1bf4` (4.3-beta1); stable v4.2 is a candidate to validate in P01/P02. Do not reset the fork history implicitly.
- GitHub issues are managed under this fork only. At most two open milestones (M0/M1); later phases remain backlog metadata. Implementation started 2026-10-25 by explicit user instruction; P01 baseline evidence complete (issue #1 closed, PR #27).
- Upstream README, contribution policy, AI policy and licenses are preserved. AI-generated upstream issues/PRs/comments are not part of the own-fork workflow.
