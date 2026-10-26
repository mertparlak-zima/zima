# coin-tracker — Coin Tracker

## Identity

| Field | Value |
|---|---|
| Dir | `projects/coin-tracker` |
| GitHub | https://github.com/mertparlak-zima/coin-tracker |
| Product | Coin Tracker — new Binance Futures paper-bot plan dated 2026-10-26; application remains a Gea scaffold until roadmap implementation |
| Stack | Current: TypeScript, Gea + Vite, Vitest, Node 24. Planned: Cloudflare Workers/D1, deterministic browser paper engine, single-password admin panel |
| Default branch | `main` |
| Local state | clean |

## Entry documents

- [README](../projects/coin-tracker/README.md)
- [AGENTS.md](../projects/coin-tracker/AGENTS.md) — product-plan routing + TDD, runner rules, independent-subagent acceptance
- [Product plan](../projects/coin-tracker/docs/product-plan.md) — new bounded Futures paper-bot specification and dependency roadmap
- [Plan review](../projects/coin-tracker/docs/plan-review-2026-10-26.md) — two independent review lenses, corrections and evidence
- [GitHub roadmap resources](../projects/coin-tracker/docs/github/README.md) — generated milestone/issue map
- [Repo skills](../projects/coin-tracker/.agents/skills/README.md) — development, engine and data/access rules; every functional change updates affected skills and docs
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
  zima-new-repo scaffolding. The owner-authorized 2026-10-26 replacement roadmap contains
  M9 (foundation) and M10 (paper MVP/acceptance); old closed resources remain historical.

## Leader notes

- Fork-PR guard required on CI (self-hosted runner).
- Runner stays running; do not "helpfully" stop it when idle.
- 2026-10-26 reset: owner cancelled the product; all 15 open issues closed `not_planned`
  and milestones M2/M3/M5/M6/M7/M8 closed (owner override of legacy read-only rule —
  decision: `.local-state/decisions/coin-tracker-reset-2026-10-26.md`). Replacement plan was finalized with two independent reviews; milestones M9/M10 and issues #115–#130 are published. No real Binance orders,
  application implementation or production deployment are authorized by this planning task.

Workspace router: [AGENTS.md](../AGENTS.md).
