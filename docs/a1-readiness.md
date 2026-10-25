# A1 readiness and audit — 2026-10-20/21

Historical audit. Current project locations, cleanup and Telegram behavior are
recorded in [workspace setup](partial-migration-2026-10-23.md); its later user
decisions supersede this audit's old pending/exclusion statements.

Router: [AGENTS.md](../AGENTS.md). Execution contract:
[migration runbook](migration-2026-10.md). Policy preparation:
[patch pack](policy-patch-pack.md). This record supersedes optimistic completion claims
in the initial task handoff; supplied Turkish plan/review remain historical inputs.

## Objective and boundaries

zima centrally routes five independent repositories through one manifest, cards, rules
and orchestration CLI. Member histories, CI, project architecture and product decisions
remain independent. A1 hardens zima while the old workspace remains usable. A2 requires
an explicit maintenance-window GO after tested recovery; no production migration is
performed by this audit. The user released the commit/push hold on 2026-10-23 and
authorized [partial adoption](partial-migration-2026-10-23.md), excluding active DriveTrace.

## Audit findings addressed

| Finding | Required correction |
|---|---|
| Validator parses JSON but ignores schema | Execute the schema and semantic/path checks; malformed input fails cleanly. |
| Verification can report false success | Validate generated content even in Pending; run actual probes; propagate command errors. |
| Workspace generation omits absent members | Always generate root plus five portable member paths, with deterministic output. |
| Search whitelist overrides member ignores | Exclude private state, planning evidence, signing keys, databases, media and caches; test visibility. |
| str-fixer called replaceable despite local media | Mark irreplaceable; forbid auto-cloning a missing directory. |
| Coin Tracker described as React | Correct to Gea, matching the project README. |
| Policy text treated as trivial automatically | Risk/behavior changes require the appropriate review tier even in Markdown. |
| Rule/reference links and README exemptions | Repair links; document reference folder; exempt only actual skill roots. |
| Enforcement and runner hardening claimed before tests | Separate target policy from measured A2 evidence. |
| Source deletion before COMMITTED | Copy-only, verify all content, commit migration boundary, then controlled cleanup. |
| Mandatory call-tracker policy deferred | No exception: failure to safely patch is NO-GO. |
| GO requires already-cleaned root | Separate start/commit/cleanup gates; check G18 after cleanup. |
| Journal OK blindly skipped on resume | Revalidate recorded content/config hashes before skipping. |
| Policy pack omitted lower-level normative references | Include DriveTrace architecture-order contract, test-first checklist and reviewer quickref, as well as router/workflow docs. |

## Runtime and document-reading contract

- Windows PowerShell 5.1 is the available/tested implementation lane. PowerShell 7 is
  not installed; compatibility is unverified and is never reported as a second PASS.
- On 2026-10-21 the user waived live agent startup/context tests and special setup.
  Agents read AGENTS, the target card and its linked rules/skills and record those reads
  in the task log. No launcher, model/profile answer or session callback is required.
  This is a user waiver, not evidence that automatic loading or a live test passed.
  See [decision log](decisions.md#agent-startup-decision--2026-10-21).

## Current status

| Step | Evidence status |
|---|---|
| A1.0 | Git root and configured remote checked; unborn main; issue list read returned no issues. Remote emptiness must be rechecked online before any push. |
| A1.1–A1.3 | PASS for A1 structure: 151 assertions, Fast/Full Pending, source/search/index/locks checks and two independent T3 reviews. |
| A1.4 | WAIVED by user on 2026-10-21: live agent startup/context tests and special setup cancelled. Normal document reads remain required; no startup-test PASS or automatic-loading claim. |
| A1.5 | DONE on 2026-10-23: bootstrap `cce0781591a9bedffca5e6a742cdd5cc17136570` pushed to origin/main and remote ref verified. |
| A1.6 | Runbook corrected; dated 2026-10-21 transition note added to old-root AGENTS. Catalog includes the existing zima directory and removes absent ai-trading-lab; active member/old-root policies remain in force. |
| A1.7 | PASS for preparation: six reviewed patches / 21 files; 28-check migration rehearsal; 79-check backup suite; actual protected external backup/full inventory/7 restore checks verified. This does not certify A2 production acceptance. |
| A2 | Four-project partial scope authorized on 2026-10-23; preparation in progress. DriveTrace and shared old-root infrastructure excluded; full cutover deferred. |

## Verification and review

Review: Tier 3 because path/schema/security and migration integrity contracts change.
Rules-read record: zima AGENTS/README, all three workspace skills and leader references,
issues/notifications/runners/local-state/decisions/migration docs, plus the supplied plan
and architectural review. Bootstrap task log is local until the final audit is retained.

### Executed verification

| Command / evidence | Result |
|---|---|
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/run-tests.ps1` | 151 assertions, 0 failures, exit 0; leader reran frozen candidate. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/zima.ps1 verify -Fast -Pending` | PASS, exit 0. |
| Same CLI `verify -Full -Pending` | PASS, exit 0; real rg and `.env`/complete-index checks. Root index is empty under commit hold; synthetic tests cover indexed violations. |
| Candidate source index, `verify -Full -Pending` | PASS over all 60 current candidate blobs after removal of the startup helper, using a task-scoped alternate Git index. Secrets/member/local-state boundaries checked; real index remains empty, no commit. Evidence: `.agent-tmp/a1-harness-waiver/candidate-index.json`. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/migration-rehearsal.ps1` | 28 assertions, 0 failures, exit 0; actual robocopy, dirty/stash preservation, worktree repair/reversal, dual-journal/hash/corruption and rollback fixtures. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/backup-tests.ps1` | 79 assertions, 0 failures, exit 0 in independent worker and leader runs; frozen artifacts below. |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/backup-local-state.ps1 -Execute` | Actual approved D: backup VERIFIED, exit 0; full source/copy/after hashes and seven isolated restore checks. |
| Six candidate `git apply --check` + apply-on-copy | All 12 commands exit 0; applied bytes hashed; 19 existing source hashes unchanged and two new files remain absent at source. |
| Markdown link QA | 102 local file links checked, 0 broken, including the generated repo index. Templates, external URLs and fragment-only links are excluded; future member links resolve against current source locations. |
| PowerShell encoding QA | Reviewed orchestration, test, rehearsal and backup scripts use UTF-8 BOM with CRLF. |
| Git Bash pre-commit syntax + execution | PASS, exit 0 in A1; exact phase marker selects Pending. |

Historical live-test attempts (closed by the 2026-10-21 user waiver; no retry or
working model/profile is requested): the former startup helper's version check
reported Claude 2.1.238, exit 0. An explicit Claude call returned the router title
and three skills in one turn; its wrapper then hit a stdout encoding error, which
was fixed. Follow-ups reached 50/180-second time limits, including a minimal
`--bare --effort low` attempt. Only task-owned children were stopped. Isolated
OpenCode v2.0.32 used task-scoped XDG directories with MCP/tools denied and no
external plugins; the selected free model returned provider.auth / HTTP 403,
exit 1. No user configuration was changed. These observations never established
full startup acceptance or automatic rule loading. The custom helper was removed
under the waiver.

The successful local policy packet is
`.local-state/migration/policy-pack-c5d4e26515cf4a36b8ecf3f39cd09391/`.
Its `receipt.json` retains source root/branch/HEAD, absent baselines, original/candidate
hashes, patch hashes, UTC verification time and exact command results. Source Git reads
use a command-scoped trust entry for each verified user-owned root because the sandbox
child account differs; global Git configuration is unchanged. Rehash sources at A2 freeze.

Retained fixture result:
`.agent-tmp/a1-hardening/rehearsal-17565a9022e14dacb3ab9c3b72924c5c/result.json`.
The versioned summary here remains after disposable fixture cleanup.

### Independent review dispositions

Both reviewers worked shell-less, using direct read-only file access; neither executed
tests. `test_execution` belongs to worker/leader; their `evidence_review` checked source,
test assertions, receipts and candidate hashes separately.

- Correctness/security: APPROVE after fixing complete-index scanning (including unchanged
  violations and exact skeleton exception), duplicate environment keys and `.git` files
  used by linked worktrees. Final packet delta approval carried forward 18 unchanged
  member candidates and rechecked three zima transition files.
- Contract/evidence: REVIEW PASS after credential-scope correction, explicit destructive
  Git denies, dual-journal failure tests, product-bot ownership erratum, actual successful
  fetch/fast-forward/divergence tests and phase-aware startup instructions. No product
  CI/device/privacy/evidence gates were removed from candidate policies.

### Frozen artifact SHA-256

```text
scripts/zima.ps1 7f9b41f118b8fc5039746789c93a9425faf81415910bdce7fb33ab6eec2bedd7
scripts/tests/run-tests.ps1 7b44c0417fa584bb03264335b9fbc8c37d65771e001179483cdb406b3de57555
scripts/migration-rehearsal.ps1 18b3caac11ed84ed4bc911375b93f6d08da131f98b4321e1ff81cc88247b4e51
historical A1 policy packet receipt.json 0488b5f3e1ccf15c0b85b98580927d81e858c2ddae9cd1f38c335b44fd87b620
scripts/backup-local-state.ps1 92ec081342da95a45049d46111ddcc68ac4206be19fe087f3b95963294c13f32
scripts/tests/backup-tests.ps1 ab65f2109be38fce6afd5e2e133aa1833ade5a97262241c53e8761ce9b9ab252
```

### External backup and follow-up review — 2026-10-21

Approved storage root: `D:\projects`. Backup:
`D:\projects\zima\backups\pre-cutover-2026-10-20` (the date names the preparation
run; actual verification finished `2026-10-21T08:19:31.0648989Z`). Source data
stays in place. Run ID: `6e66d8d5f9ff4d9789a565c0316f88fd`.

- 2,577 files / 136 directories; 3,559,533,103 file bytes plus one 143-byte named
  NTFS stream. All source/backup/after inventories match; `source_stability=MATCH`.
- Five present categories restored; seven checks include the 2,684,420,096-byte
  largest AVD image and the actual named-stream file. All MATCH; restore scratch
  removed. `str-samples=ABSENT`, root SRT selection EMPTY; no fictitious restore.
- Restricted NTFS protection VERIFIED: owner, SYSTEM, Administrators only.
  Original owner/group/DACL recorded privately; copy DACL intentionally hardened.
  Access times/SACL/object IDs/USN are excluded; unsupported reparse, sparse,
  compression, encryption, hard links or EA cause preflight failure. No such
  unsupported metadata was accepted in this run. AVD boot is a separate A2 gate.
- Durable redacted receipt:
  `.local-state/migration/backup-2ece30b732914ea0b77439aeb7deef7c/receipt.json`.
  Its bytes match the external receipt; SHA-256
  `15982b946e872d78aa0b947224d2591dcbaf1e409d93e2cb6489fa3ee2987ec1`.
  Protected inventory hash independently checked against the receipt:
  `dcc8b21109d3a6578513b1e178a5cff735f8d080d6941cac61a67fa4d189c088`.
  Raw filenames/private inventories remain only under protected backup ACLs.
- Retain until Faz B completes. Revalidate against frozen sources before A2;
  a verified snapshot is not proof that later source edits are already backed up.

Two independent shell-less reviewers APPROVED the frozen backup implementation
with correctness/integrity and contract/privacy lenses. They checked exact hashes,
source/tests and worker/leader evidence, and executed no tests. Fixed findings:
exclusive destination creation (including a competing same-ACL directory), real
robocopy failure propagation, largest-image identity, file/directory ADS restore,
separate source stability, missing-source gates and failed-copy ACL recovery.
The leader then executed the approved actual backup and the receipt/hash audit.

A1.6 transition/catalog delta was also read by both reviewers; active old-root
policies remain unchanged. Its before/after hashes and patch are retained in
`.local-state/migration/a1-transition-note/`. Original member repos, harness
configuration, broker and runners were not modified; no Git commit or push.

### Remaining gates

The publication hold was released on 2026-10-23. A1.4 is WAIVED by the user;
no live agent startup test or model/profile answer remains pending.
Production signing is not configured at the current
Call Tracker stage, so production-key restore is N/A; QA signature continuity
remains a cutover smoke check.
[GO checklist](a2-go-checklist.md) records the old-root inventory and gate status.
Production freeze, whole-member governance, effective harness denies,
runner access, selected-memory integrity, worktree/AVD/device acceptance and final cleanup remain
the scoped migration gates. None is certified by a fixture or static review.
Current scope and actual execution: [partial adoption](partial-migration-2026-10-23.md).

### Deferred-layout preparation — 2026-10-23

The current manifest explicitly defers DriveTrace at its planned future path. It is
metadata only: no source/Git/docs/runner probes; explicit operational targets refuse
before native calls, bulk operations skip it, and the portable workspace has zima
plus four active entries. Normal non-Pending verification retains all active-member
checks. Pending remains A1-only and is refused for PARTIAL phase.

The existing all-active synthetic regression coverage remains 151 assertions. The
new deferred suite passed 43 assertions, including no native calls for explicit
refusal, no source probes, scoped runner queries, bulk exclusion and invalid metadata.

This is layout preparation, not proof that project copy/activation or full-workspace
configuration, runner-label, memory or cleanup gates have completed. Actual scoped
execution is recorded in [partial adoption](partial-migration-2026-10-23.md).
