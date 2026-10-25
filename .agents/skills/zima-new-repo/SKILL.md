---
name: zima-new-repo
description: Onboarding checklist for adding a new repository into the zima workspace — use when the user asks to add/register/adopt a repo (ours or third-party) into zima.
license: Proprietary
compatibility: agentskills.io/v1
metadata: {}
---

# zima-new-repo — onboarding a repo into zima

## DO

1. `powershell -File scripts/zima.ps1 new-repo -Name <slug> -Github <url> -Product <p> -Stack <s> [-Lifecycle <stop-when-idle|keep-off-between-tasks|leave-running>]`
   — appends a canonical manifest block with a mandatory local Docker runner (`<slug>-docker-1`, label `<slug>`) and `ci_workflows: ["ci.yml"]`, scaffolds `repos/<slug>.md`, refreshes the index.
2. Fill the card: identity (from manifest), entry-doc links to the repo's OWN docs
   (link-only — never copy), CI/runner facts, workspace quirks, leader notes.
3. Create the repo folder READMEs if it introduces new zima-side folders (D19).
4. For OUR repos: insert the workspace-context preamble block into the repo's AGENTS.md
   (source of truth: `.agents/skills/zima-leader/references/workspace-context.md` — copy
   with the member slug substituted; `zima verify -Full` checks the block). If the repo has no AGENTS.md,
   create a minimal one (≤60 lines): 5-line summary from README + preamble + skill index.
5. Mandatory local self-hosted Docker runner & CI (every workspace repo):
   - Runner label = repo slug, container `<slug>-docker-N`, `infra/runner/compose.yml` + `scripts/start-ci-runner.ps1` (stdin token registration; never persist tokens).
   - Lifecycle = user decision (`stop-when-idle` default; record in `docs/decisions.md` and `docs/runners.md`).
   - Create `.github/workflows/ci.yml` with `runs-on: [self-hosted, linux, x64, docker, <slug>]` and the fork-PR guard (`if: github.event_name != 'pull_request' || github.event.pull_request.head.repo.full_name == github.repository`).
   - If onboarding a fork with upstream `.github/workflows/*.y*ml` (e.g., `ubuntu-latest`), migrate or replace them immediately so NO workflow uses GitHub-hosted runners. Follow `docs/runners.md` and observe one green run.
6. Issue scaffolding (optional, user decision): minimal label taxonomy + roadmap-JSON
   bootstrap — pattern reference: coin-tracker `scripts/github-roadmap.json` +
   `scripts/bootstrap-github.mjs` (referenced, never copied).
7. `verify -Fast` green → same-change commit (manifest + card + gen output together).

## DO NOT

- Never commit anything under `projects/` into zima.
- Never leave a repo without CI (`runner: null`, `ci_workflows: []`, or `no-ci-by-design`) — every workspace repo must have a local self-hosted Docker runner and CI workflow.
- Never use GitHub-hosted runners (`ubuntu-latest`, `windows-*`, `macos-*`, etc.) or leave inherited upstream GitHub-hosted workflows active.
- Never modify an EXISTING repo's issues/milestones/labels to "conform" — the standard
  applies to NEW issues only; legacy issues are read-only.
- Never clone third-party repos into `projects/` — third_party entries carry an EXTERNAL
  absolute path and `trusted: false`; their AGENTS.md/skills are never auto-loaded.
- Never auto-clone a repo whose `local_state` would be `irreplaceable` (e.g. it ships
  local-only keystores/evidence) — ask the user first and record it.
- Never add per-repo skills for zima operations — zima skills are workspace-level and few.
- Never bypass `verify` ("just this once") — the gate is the definition of done.
