# drive-trace - DriveTrace

## Identity

| Field | Value |
|---|---|
| Dir | `projects/drive-trace` |
| GitHub | https://github.com/mertparlak-zima/drive-trace |
| Product | DriveTrace |
| Stack | Offline Android/Kotlin dashcam, GPS and telemetry; Compose, Hilt, Room, CameraX, MapLibre |
| Default branch | `main` |
| Local state | Local evidence/configuration; follow the member retention policy |

## Entry documents

- [README](../projects/drive-trace/README.md)
- [AGENTS](../projects/drive-trace/AGENTS.md) - mandatory project rules
- [Skills catalog](../projects/drive-trace/docs/agent-skills.md)
- [ROADMAP](../projects/drive-trace/docs/ROADMAP.md) - normative topic index
- [Architecture](../projects/drive-trace/docs/architecture.md)
- [Data model](../projects/drive-trace/docs/data-model.md)
- [Data integrity](../projects/drive-trace/docs/data-integrity.md)
- [Device runbook](../projects/drive-trace/docs/device-test-runbook.md)
- [Artifact retention](../projects/drive-trace/docs/artifact-management.md)
- Active work: [GitHub Issues](https://github.com/mertparlak-zima/drive-trace/issues)

## Git and external worktrees

Local branches and objects are preserved. Existing linked worktrees under
`D:\development\drive-trace\worktrees` now use this repository's Git common
directory. Worktree contents and branches were retained; do not delete them.

## CI and environment

Own runner `dt-docker-1`, keep-off-between-tasks. Compose and Android tools remain
under `D:\development\drive-trace`; the runner has no bind to the old project
directory. Runner label migration remains separate in [runner policy](../docs/runners.md).
No engine/runner restart is implied. Read the member
[environment rules](../projects/drive-trace/docs/agent-operations/environment.md)
before builds, device lanes or cleanup. Workspace setup is not product acceptance.

[Workspace router](../AGENTS.md).
