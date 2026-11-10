# Runners - policy and behavior

This document holds POLICY ONLY. The runner registry table below is GENERATED from
`repos.json` by `zima.ps1 gen` - never edit the table by hand; change `repos.json` and
re-run gen. Machine paths live in `.env`.

## Standard

- Every workspace repository (existing and newly onboarded; no `no-ci` exceptions) MUST
  have CI workflows and a dedicated local self-hosted Docker runner container registered
  exclusively to that repository. GitHub-hosted runners (`ubuntu-latest`, `windows-*`,
  `macos-*`, etc.) are strictly forbidden. Inherited upstream workflows in forks must be
  migrated to the repository's local self-hosted Docker runner during onboarding.
- Label set (all lowercase): `[self-hosted, linux, x64, docker, <repo-slug>]`. The repo
  slug label is mandatory and unique per repo.
- Labels are ROUTING/SELECTION, not isolation. Isolation comes from per-repo runner
  registration (a runner registered to exactly one repo physically cannot pick another
  repo's jobs) plus least-privilege hardening below.
- New container name: `<repo-slug>-docker-N` (`infra/runner/compose.yml` +
  `scripts/start-ci-runner.ps1`). Existing `dt/ct/dm` names in the registry
  are recorded legacy names; renaming them is not implied by workspace cutover.
- Runner groups are org-only (not available for personal accounts) - per-repo
  registration is the isolation mechanism here.
- One runner serves one job at a time; queued jobs 24h timeout; a runner older than ~30
  days without auto-update silently stops receiving jobs - keep auto-update ON.
- Validation CI workflows trigger on `pull_request` (targeting the default branch, with the
  fork-PR guard) plus `workflow_dispatch` for on-demand manual runs. Do NOT add
  `push: branches: [<default-branch>]` to validation workflows: `pull_request` already
  validates the merge ref before merge, and rerunning the full suite after merge wastes
  single-concurrency local runner capacity (owner decision 2026-11-04).

## Least-privilege rules

- Private repos only; NEVER run fork-PR workflows on these runners (fork guard required in
  workflows that trigger on pull_request).
- No Docker socket host-mounts, no privileged containers, no host path mounts beyond the
  runner work dir. This is target policy; current effective mounts, repo registration,
  event guards and secret permissions require measured production evidence before claiming compliance.
- Registration tokens via stdin/ephemeral files only; never in compose files or logs.

## RAM-backed runtime temporary storage

All active and newly onboarded member Docker CI runners use a bounded tmpfs for
eligible disposable test/runtime temporary data. Keep the OS/runtime temp mount
outside checkout-cleaned directories (normally `/tmp`, mode1777); point TMPDIR at
that mount. Agent-authored temp files and acceptance evidence still follow the
workspace's repo-local `.agent-tmp/` rules.

Choose an explicit per-repo size from measured workload and available shared-engine
memory; the reference's2GiB is not a universal allocation. Before first adoption,
compare identical selected tests on disk/RAM/disk, then run the complete unchanged
suite and actual repo PR CI. Preserve assertions, timeouts, in-test concurrency,
isolation and SQL semantics. Record observed memory/capacity limits honestly.

Keep workspaces, tool caches, retained evidence/logs, credentials, production data
and fixtures requiring physical-disk or container-restart durability on persistent
storage. A RAM-backed local SQLite file remains a real database, but is not proof
of survival across host/container loss. Never move such durability requirements
to RAM merely to improve test speed.

Existing members adopt this standard in their own runner maintenance change.
Only the assigned repo's idle runner may be recreated, after checking queued jobs
and preserving its workspace volume; re-register through the supported secret-safe
script when needed. This rule authorizes no bulk restart, other-repo runner action
or shared-engine restart. Existing lifecycle/lock rules still apply.

Reference: [coin-tracker runner](../projects/coin-tracker/infra/runner/README.md),
with measured temporary-storage comparison and full-suite evidence.

## Shared engine rules (one Docker Desktop/WSL2 engine hosts all runner containers)

- NEVER stop/restart another repo's runner container.
- NEVER quit/restart Docker Desktop while any runner container is up - one engine kill
  drops every repo's job queue. Engine restart requires: `zima.ps1 locks list` shows no
  live locks AND explicit user approval.
- Before any device lane, AVD boot, or heavy build: acquire the matching advisory lock in
  `projects/.shared/locks/` (`zima.ps1 locks acquire <resource> -Owner <task-token>`);
  release with the same token. Acquisition is atomic. These are advisory files, not a
  security boundary. Owner/mtime are recorded; breaking a stale lock is a HUMAN decision.

## Lifecycle matrix (owner decisions - do not "harmonize" without a user decision)

| Repo | Policy | Note |
|---|---|---|
| drive-trace | keep-off-between-tasks | started per task, stopped after; Docker Desktop quit only when nothing else runs |
| coin-tracker | leave-running | owner decision 2026-10-07 |
| call-tracker | stop-when-idle | stopped between CI bursts |
| lg-tv-channel-sort | stop-when-idle | owner decision 2026-10-26; stopped between CI bursts |
| str-fixer | stop-when-idle | owner decision 2026-10-26; stopped between CI bursts |
| tahmin-ligi | stop-when-idle | owner decision 2026-10-26; stopped between CI bursts |
| heliboard-archive | stop-when-idle | owner decision 2026-10-26; stopped between CI bursts |

## Label add sequence (when a runner lacks its repo label)

1. Add the new label to the runner (REST API or web UI - `config.sh` cannot add labels to
   an existing runner).
2. Update the repo workflows' `runs-on:` to include the label.
3. Observe one green run per workflow.
4. Only then remove the runner from any shared pool.

## Label rename sequence (call-tracker: `daily-moods` to `call-tracker`)

1. Register BOTH labels on the same runner (alias) via REST/web.
2. Switch workflows to the new label; observe one green run per workflow.
3. Remove the old `daily-moods` label.

## Planned runner changes (tracked as zima-filed issues, executed in their repos)

These are separate planned changes; workspace housekeeping does not authorize
them. Any manifest member explicitly marked DEFERRED is metadata only: do not
inspect or operate that member's runner/jobs until its authorized reactivation.

- drive-trace: add `drive-trace` label to dt-docker-1 + matching `runs-on:` lines (label add
  sequence above). Until then dt workflows run on the shared `[self-hosted, docker]` pool.
- call-tracker: label rename sequence above (coordinate with `scripts/ci-policy.mjs`
  contract test in one change).
- Normalize label casing to lowercase in policy scripts (ci-policy.mjs / ci-policy-core.cjs).
- coin-tracker ci.yml concurrency + PR-branch filter: DONE 2026-10-26 (with the repo reset).
- Remove redundant post-merge `push` triggers from validation CI workflows (keep
  `pull_request` + `workflow_dispatch`): `coin-tracker` DONE 2026-11-04;
  `call-tracker`, `lg-tv-channel-sort`, `str-fixer`, `tahmin-ligi`, `heliboard-archive`
  DONE 2026-11-05 (T3-reviewed sweep). `drive-trace` is a deliberate EXEMPTION: its
  layered `ci-policy` model already suppresses duplicate post-merge full runs (verified
  same-tree merge push) and keeps fail-closed full verify for direct/unknown main pushes,
  node:test-protected — removing its `push` trigger would break that contract.
  Discipline note (T3 finding): direct pushes to main now get NO CI anywhere — use
  PRs or a manual `workflow_dispatch` run after unavoidable direct pushes.

## Registry (GENERATED)

<!-- BEGIN GENERATED RUNNER REGISTRY -->
| Repo | State | Container | Label today | Label target | Lifecycle | Compose |
|---|---|---|---|---|---|---|
| drive-trace | active | dt-docker-1 | (shared pool - no repo label yet) | drive-trace | keep-off-between-tasks | D:\development\drive-trace\docker-runner |
| coin-tracker | active | ct-docker-1 | coin-tracker | coin-tracker | leave-running | infra/runner/compose.yml |
| call-tracker | active | dm-docker-1 | daily-moods | call-tracker | stop-when-idle | infra/runner/compose.yml |
| lg-tv-channel-sort | active | lg-tv-channel-sort-docker-1 | lg-tv-channel-sort | lg-tv-channel-sort | stop-when-idle | infra/runner/compose.yml |
| str-fixer | active | str-fixer-docker-1 | str-fixer | str-fixer | stop-when-idle | infra/runner/compose.yml |
| tahmin-ligi | active | tahmin-ligi-docker-1 | tahmin-ligi | tahmin-ligi | stop-when-idle | infra/runner/compose.yml |
| heliboard-archive | active | heliboard-archive-docker-1 | heliboard-archive | heliboard-archive | stop-when-idle | infra/runner/compose.yml |
<!-- END GENERATED RUNNER REGISTRY -->
