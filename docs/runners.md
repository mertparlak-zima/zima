# Runners - policy and behavior

This document holds POLICY ONLY. The runner registry table below is GENERATED from
`repos.json` by `zima.ps1 gen` - never edit the table by hand; change `repos.json` and
re-run gen. Machine paths live in `.env`.

## Standard

- Label set (all lowercase): `[self-hosted, linux, x64, docker, <repo-slug>]`. The repo
  slug label is mandatory and unique per repo.
- Labels are ROUTING/SELECTION, not isolation. Isolation comes from per-repo runner
  registration (a runner registered to exactly one repo physically cannot pick another
  repo's jobs) plus least-privilege hardening below.
- New container name: `<repo-slug>-docker-N`. Existing `dt/ct/dm` names in the registry
  are recorded legacy names; renaming them is not implied by workspace cutover.
- Runner groups are org-only (not available for personal accounts) - per-repo
  registration is the isolation mechanism here.
- One runner serves one job at a time; queued jobs 24h timeout; a runner older than ~30
  days without auto-update silently stops receiving jobs - keep auto-update ON.

## Least-privilege rules

- Private repos only; NEVER run fork-PR workflows on these runners (fork guard required in
  workflows that trigger on pull_request).
- No Docker socket host-mounts, no privileged containers, no host path mounts beyond the
  runner work dir. This is target policy; current effective mounts, repo registration,
  event guards and secret permissions require measured production evidence before claiming compliance.
- Registration tokens via stdin/ephemeral files only; never in compose files or logs.

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
- coin-tracker: add `concurrency: group: ci-${{ github.ref }}, cancel-in-progress: true`
  and `pull_request: branches: [main]` to ci.yml.
- Normalize label casing to lowercase in policy scripts (ci-policy.mjs / ci-policy-core.cjs).

## Registry (GENERATED)

<!-- BEGIN GENERATED RUNNER REGISTRY -->
| Repo | State | Container | Label today | Label target | Lifecycle | Compose |
|---|---|---|---|---|---|---|
| drive-trace | active | dt-docker-1 | (shared pool - no repo label yet) | drive-trace | keep-off-between-tasks | D:\development\drive-trace\docker-runner |
| coin-tracker | active | ct-docker-1 | coin-tracker | coin-tracker | leave-running | infra/runner/compose.yml |
| call-tracker | active | dm-docker-1 | daily-moods | call-tracker | stop-when-idle | infra/runner/compose.yml |
<!-- END GENERATED RUNNER REGISTRY -->
