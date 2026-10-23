# coin-tracker — Coin Tracker

## Identity

| Field | Value |
|---|---|
| Dir | `projects/coin-tracker` |
| GitHub | https://github.com/mertparlak-zima/coin-tracker |
| Product | Coin Tracker |
| Stack | TypeScript, Gea + Vite, Tailwind, Lightweight Charts v5, Vitest; Node 24. Manual TA helper for Binance USDt-M Futures — no trading, no AI, no backend |
| Default branch | `main`; query live branch/worktree state before work and preserve existing changes |
| Local state | clean |

## Entry documents

- [README](../projects/coin-tracker/README.md)
- [AGENTS.md](../projects/coin-tracker/AGENTS.md) — RED→GREEN→REFACTOR TDD, no-future-leakage, raw indicators separate from strategy, independent-subagent acceptance
- CLAUDE.md in-repo is a deliberate pointer stub to AGENTS.md (single-source pattern; Faz B unification candidate)
- Key docs: [docs/README.md](../projects/coin-tracker/docs/README.md) (normative) · [product/roadmap.md](../projects/coin-tracker/docs/product/roadmap.md)
- Skills live in `.agents/skills/` (8: project-context, tdd-workflow, market-data, indicator-engine, strategy-engine, ui-chart, github-workflow, release-validation)

## CI and runner

Workflow: `ci.yml` (typecheck/lint/test/build). Runner: `ct-docker-1`, label
`coin-tracker` (compliant), lifecycle **leave-running** (owner decision 2026-10-07 —
never quit Docker Desktop because of another repo's task). Compose in-repo:
`infra/runner/compose.yml`; start via `scripts/start-ci-runner.ps1` (verifies labels).
Pending fix (zima-filed issue): add concurrency group + `pull_request: branches: [main]`;
normalize label casing.

## Workspace quirks

- Roadmap bootstrap pattern lives here: `scripts/github-roadmap.json` +
  `scripts/bootstrap-github.mjs` (labels/milestones/issues from JSON) — the reference for
  zima-new-repo scaffolding.
- Doc-link checker: `scripts/verify-docs.mjs`.

## Leader notes

- Fork-PR guard required on CI (self-hosted runner).
- Runner stays running; do not "helpfully" stop it when idle.

Workspace router: [AGENTS.md](../AGENTS.md).
