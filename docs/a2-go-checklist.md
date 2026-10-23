# A2 readiness checklist — preparation record

Execution contract: [migration runbook](migration-2026-10.md).
Evidence: [A1 audit](a1-readiness.md), [policy packet](policy-patch-pack.md),
[local state](local-state.md). This is a status record, not permission to cut over.

This matrix describes the full workspace transition. The authorized four-project
[partial scope](partial-migration-2026-10-23.md) keeps DriveTrace and shared global
infrastructure deferred. Their future checks are not claimed PASS or waived;
active-project copy/activation still requires its scoped integrity evidence.

## Ready to start

| Requirement | Current evidence / remaining work |
|---|---|
| A1 CLI/schema/search/index integrity | 151 assertions; Fast/Full Pending PASS; two independent T3 reviews. |
| Recovery rehearsal | 28 fixture checks PASS; full production equivalence remains untested. |
| Mandatory policy patches | Six candidate patches / 21 files checked on copies; originals unchanged. Rehash against frozen sources. |
| Agent document reads | A1.4 live startup/context tests WAIVED by user on 2026-10-21. Agents read AGENTS, target cards and linked rules/skills and record reads in the task log; no launcher or model/profile requirement. |
| External recovery copy | VERIFIED on D: (2026-10-21): 2,577 files, one named stream, seven restore checks, source stability and protected ACLs. Revalidate against frozen sources before A2. |
| Signing material | No production key configured at this stage (public toolchain/build rules); restore N/A. QA SDK debug-signature continuity remains a smoke check. No external key backup claimed. |
| Old-root inventory | Top-level entries mapped below; freeze-time recursive inventory and content hashes still required. |
| Commit/push hold | Released by user on 2026-10-23; publication authorized. |
| Maintenance window | Partial adoption of four projects authorized; DriveTrace and shared infrastructure excluded. See the [scoped record](partial-migration-2026-10-23.md). Full cutover remains deferred. |

## Old-root entry disposition

Read-only top-level inventory on 2026-10-21 found the entries below. Targets are
planned destinations relative to zima. No source has been moved or deleted.
Each row needs a frozen recursive inventory, content/metadata verification and
journal records. Unknown/new entries stop cleanup; a top-level list never
proves that nested content is replaceable.

| Old-root entry | Planned disposition |
|---|---|
| `call-tracker/`, `coin-tracker/`, `drive-trace/`, `lg-tv-channel-sort/`, `str-fixer/` | Copy to matching `projects/<repo>/`; preserve Git/dirty/stash/worktree/local data. |
| `.jarvis-telegram-mcp/` | Copy to matching root path; preserve runtime dependencies; consumer/config switch follows runbook. |
| `artifacts/` | Copy to `artifacts/`; permanent evidence retained. |
| `drive-trace-prd/` | Preserve under `.local-archives/drive-trace-prd/`. |
| `.local-archives/` | Preserve contents under `.local-archives/`; detect destination conflicts before copying. |
| `zima-plan.md`, `zima-architecture-review-2026-10-19.md` | Preserve under `.local-archives/`; current English execution docs remain canonical. |
| `AGENTS.md`, `telegram-agent-instructions.md` | Retain recovery originals outside cleanup targets before retiring old rules. |
| `.claude/` | Discover active instructions/settings/memory first; copy selected memory and retain recovery originals. Never activate copied permissions blindly. |
| `.idea/` | Inspect recursive inventory and classify user state versus disposable caches before selecting a destination. Unclassified state blocks cleanup. |
| `zima/` | Existing destination; remains in place. Never recursively copy it into itself. |

The old catalog's absent `ai-trading-lab` entry was removed during A1.6 factual
maintenance. It is not a managed manifest member; no repository was deleted.

## During the window and before cleanup

All G01–G20 rows retain their timing and requirements from the runbook. Recheck
freeze/jobs/writers immediately before COMMITTED. Real worktree and AVD boot,
effective harness permissions, runner access, single Telegram consumer, selected-memory
path/content hashes and all non-Pending checks need production evidence. G08 requires
document-read records, not a live model session. G18 is checked
only after controlled cleanup; COMMITTED must already exist in both journals.

No fixture, static review or user GO waives these integrity requirements.
