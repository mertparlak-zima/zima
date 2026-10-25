# lg-tv-channel-sort — LG Channel List Editor

## Identity

| Field | Value |
|---|---|
| Dir | `projects/lg-tv-channel-sort` |
| GitHub | https://github.com/mertparlak-zima/lg-channel-import (**GitHub repo name ≠ dir name**) |
| Product | LG Channel List Editor |
| Stack | Python tooling for LG 42LB652V-ZA (webOS 1.4) GlobalClone TLL satellite channel lists (Türksat 42°E); USB export/import |
| Default branch | `main` |
| Local state | clean |

## Entry documents

- [README](../projects/lg-tv-channel-sort/README.md) — the device-verified rule set
- [AGENTS.md](../projects/lg-tv-channel-sort/AGENTS.md) — reviewed workspace routing; applied during partial adoption
- Main skill (read fully before ANY TLL edit): [lg-tll-channel-editing](../projects/lg-tv-channel-sort/.claude/skills/lg-tll-channel-editing/SKILL.md)
- References: [file-format](../projects/lg-tv-channel-sort/.claude/skills/lg-tll-channel-editing/references/file-format.md) · [verification](../projects/lg-tv-channel-sort/.claude/skills/lg-tll-channel-editing/references/verification.md)
- Device profile: [lg-42lb652v-tv](../projects/lg-tv-channel-sort/.claude/skills/lg-42lb652v-tv/SKILL.md)
- Verification script: [verify_channel_list.py](../projects/lg-tv-channel-sort/scripts/verify_channel_list.py)

## CI and runner

Workflow: `ci.yml` (`build_channel_list.py` + `verify_channel_list.py`). Runner:
`lg-tv-channel-sort-docker-1`, label `lg-tv-channel-sort` (`[self-hosted, linux, x64, docker, lg-tv-channel-sort]`),
lifecycle **stop-when-idle**, compose `infra/runner/compose.yml` (start via `scripts/start-ci-runner.ps1`).
GitHub-hosted runners are forbidden.

## Workspace quirks

- Skills live in `.claude/skills/` (repo's own convention — indexed, not changed).
- TV-verified rule: the freshest TV export is ALWAYS the editing base; an import test not
  performed on the TV is never reported PASS.
- USB stick handling is physical — that is a legitimate ask-the-user case.

## Leader notes

- Verify this directory is a real git root before any git operation (dir/repo name
  mismatch makes wrong-target mistakes easy).

Workspace router: [AGENTS.md](../AGENTS.md).
