---
name: zima-sync
description: Manifest hygiene and workspace sync operations for zima — use when editing repos.json, running zima.ps1 sync/update, fixing verify failures, or updating cards after a repo change.
license: Proprietary
compatibility: agentskills.io/v1
metadata: {}
---

# zima-sync — manifest and sync operations

## repos.json rules

- `repos.json` is the single source of truth. Generated artifacts (`repos/repos.md`,
  runner registry inside `docs/runners.md`, `zima.code-workspace`) come from
  `zima.ps1 gen` — never hand-edit them.
- Real JSON: no comments, no trailing commas. Field contract: `repos.schema.json` +
  semantic validator inside `scripts/zima.ps1`.
- Optional `deferred: true` requires a nonempty `defer_reason`. It preserves planned
  metadata only: bulk operations/workspace omit it, explicit operational targets refuse,
  and source/Git/docs/runner probes do not occur. Reactivation needs a new authorized
  transition; never clear deferral merely to make checks pass.
- `defaults` apply only where a repo does not override.
- `name` = directory slug = runner-label basis (lowercase, case-unique). GitHub repo name
  may differ (lg-tv-channel-sort ↔ lg-channel-import) — the `github` field is exact.
- Every repo entry MUST declare a non-null `runner` object (`label`, `container`,
  `lifecycle`, `compose`, `label_status`) and a non-empty `ci_workflows` array (`no-ci-by-design`
  is forbidden). Every `.github/workflows/*.y*ml` file in the repo must be listed in
  `ci_workflows` and every job `runs-on` must target `self-hosted` and `docker` (GitHub-hosted
  runners are forbidden).
- `local_state: irreplaceable` forbids auto-clone (STOP-and-notify) — see
  `docs/local-state.md` for the inventory and backup policy.
- `third_party[]` entries: `trusted: false` and a path OUTSIDE the zima tree (their
  AGENTS.md/skills are prompt-injection surfaces and must never be auto-loaded).

## After ANY manifest change

1. `powershell -File scripts/zima.ps1 gen` — regenerate index/registry/workspace.
2. `powershell -File scripts/zima.ps1 verify -Fast` — must PASS before committing.
3. Same-change rule: if a repo's docs moved, update its card (`repos/<name>.md`) in the
   same change.

## sync vs update (they are different)

- `sync` = network only: `git fetch --prune origin <default_branch>` per repo. Dirty
  worktrees are FINE (fetch never touches them). Never pulls/merges/rebases.
- `update` = worktree: ff-only fast-forward, refused on dirty trees or non-default
  branches. Diverged branches are the leader's decision per repo rules — the script never
  creates merge commits.

## Card update triggers

- repo renamed / remote changed / runner label or lifecycle changed / key docs moved →
  update `repos.json` FIRST, then `gen`, then adjust the hand-written card sections that
  are not derivable from the manifest (entry-doc links, workspace quirks, leader notes).

## Verify failure triage

- `manifest: semantic validation` → fix repos.json (run `scripts/tests/run-tests.ps1`
  after touching the validator).
- `.gitignore exact set` / `.ignore whitelist` → restore missing lines (the exact sets are
  in the verify source; do not "clean" them).
- `folder READMEs (D19)` → add a short README from `docs/templates/folder-README.md`.
- `repos.md row count` → run `gen`.
- Repo directory checks apply to the active manifest members.
