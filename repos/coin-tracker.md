# coin-tracker — Coin Tracker

## Identity

| Field | Value |
|---|---|
| Dir | `projects/coin-tracker` |
| GitHub | https://github.com/mertparlak-zima/coin-tracker |
| Product | Coin Tracker — **product cancelled 2026-10-26**; repo holds an empty Gea base site pending re-planning |
| Stack | TypeScript, Gea + Vite only (runtime deps: `@geajs/core`, `@geajs/ui`); Vitest smoke test; Node 24. No backend, no other runtime libs |
| Default branch | `main` |
| Local state | clean |

## Entry documents

- [README](../projects/coin-tracker/README.md)
- [AGENTS.md](../projects/coin-tracker/AGENTS.md) — base-state guide: zima context block + TDD, runner rules, independent-subagent acceptance
- [Reset record](../projects/coin-tracker/docs/reset-2026-10-26.md) — 2026-10-26 cancellation audit (issues/milestones closed, delete/keep inventory, verification)
- CLAUDE.md in-repo is a pointer stub to AGENTS.md (single-source pattern)

## CI and runner

Workflow: `ci.yml` (typecheck/lint/test/build). Runner: `ct-docker-1`, label
`coin-tracker` (compliant), lifecycle **leave-running** (owner decision 2026-10-07 —
never quit Docker Desktop because of another repo's task). Compose in-repo:
`infra/runner/compose.yml`; start via `scripts/start-ci-runner.ps1` (verifies labels).
2026-10-26: concurrency group + `pull_request: branches: [main]` added (the previously
zima-filed ci.yml fix is DONE); fork guard and exact label set unchanged.

## Workspace quirks

- Roadmap bootstrap pattern lives here: `scripts/github-roadmap.json` +
  `scripts/bootstrap-github.mjs` (labels/milestones/issues from JSON) — the reference for
  zima-new-repo scaffolding. `github-roadmap.json` still contains the CANCELLED roadmap
  (stale until the owner's re-planning rewrites it; dry-run still validates).

## Leader notes

- Fork-PR guard required on CI (self-hosted runner).
- Runner stays running; do not "helpfully" stop it when idle.
- 2026-10-26 reset: owner cancelled the product; all 15 open issues closed `not_planned`
  and milestones M2/M3/M5/M6/M7/M8 closed (owner override of legacy read-only rule —
  decision: `.local-state/decisions/coin-tracker-reset-2026-10-26.md`). New roadmap will
  be planned with the owner and published via the bootstrap tooling.

Workspace router: [AGENTS.md](../AGENTS.md).
