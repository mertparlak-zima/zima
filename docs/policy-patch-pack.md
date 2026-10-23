# A2 policy patch inventory

Source: [A1 audit](a1-readiness.md). Apply only under the
[migration runbook](migration-2026-10.md), after source freeze. Six candidate patches
(five members plus zima manifest/card transition), 21 files, are prepared in
`.local-state/migration/policy-pack-c5d4e26515cf4a36b8ecf3f39cd09391/`.
All six apply checks and apply-on-copy validations passed with source/candidate hashes
and command receipts; two independent T3 reviews passed. Production files remain intact.
Revalidate current frozen source/identity and actual repo governance before applying in A2.

## Mandatory source-file coverage

| Repo | Files | Required policy transformation |
|---|---|---|
| drive-trace | `AGENTS.md`; `docs/agent-operations/execution.md`, `issue-lifecycle.md`, `review-ci.md` | Replace fixed dual-review requirement with explicit risk-based T0–T3 minimums; preserve evidence/device/CI acceptance gates. |
| drive-trace | `.opencode/skills/drive-trace-workflow/SKILL.md`; `.opencode/skills/drive-trace-review/SKILL.md` | Align reviewer counts and review triggers; shell-less reviewers assess supplied evidence and do not claim independent test execution. |
| drive-trace | `.opencode/skills/drive-trace-test-first/SKILL.md`, its `references/implementation-checklist.md`; review `references/reviewer-quickref.md`; `docs/contracts/architecture-order.md` | Update remaining fixed-reviewer gates, checklist and normative contract together. Preserve T3 dual review; remove reviewer test execution and command-running instructions. |
| drive-trace | `docs/contracts/v2-product.md` | Align the unconditional dual-review clause with the same risk-tier contract; retain JVM/tool/UI/device acceptance requirements. |
| call-tracker | `AGENTS.md`; `skills/daily-moods-workflow/references/agent-execution.md` | Non-destructive dirty-tree patch; explicit minimum T3 for permission/PII/data risk; retain product, consent and device acceptance rules. |
| coin-tracker | `AGENTS.md` and any conflicting rule sources discovered by scan | Add workspace context; preserve independent UI/functionality acceptance because it is deliberately stricter local policy. |
| lg-tv-channel-sort | New minimal AGENTS pointing to README and `.claude/skills` | Add explicit workspace context without changing device/import/verification requirements. |
| str-fixer | New minimal AGENTS pointing to README and `.claude/skills` | Workspace context plus irreplaceable media handling; preserve encoding/resync/OCR and no-media-commit rules. |
| all | Active rules referencing Telegram replies, old paths, review counts, chain of command or evidence | Resolve every mandatory contradiction in the actual governing file; a root preamble cannot hide contrary local instructions. |

## Candidate patch acceptance

1. Record verified repo root, branch/HEAD and hashes of the EXACT working-tree input,
   including dirty files. Copy only non-secret rule sources into the preparation area.
2. Produce one candidate diff per repo. Substitute the repo slug in the
   [context template](../.agents/skills/zima-leader/references/workspace-context.md).
   Preserve user edits and project-specific stricter gates; never reset or stash them.
3. Run `git apply --check` on a fresh copy matching the frozen source; apply to that copy,
   inspect the complete diff, and run repo-specific governance checks where applicable.
4. Independent T3 review covers every replaced requirement and the policy-conflict scan.
   Record `evidence_review` separately from worker/leader `test_execution`.
5. Recheck source hashes immediately before applying in A2. Any changed source, rejected
   hunk, missing policy coverage or unresolved stricter-rule question means NO-GO.

User-level harness and Startup patches are a separate redacted packet discovered from
the real installed paths. Never copy credentials or entire user configuration into the
repo. Broker implementation and repo application code are out of scope for these patches.
