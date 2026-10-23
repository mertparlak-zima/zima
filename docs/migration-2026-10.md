# Migration 2026-10 — deferred cutover runbook

Status: full workspace cutover remains deferred. On 2026-10-23 the user authorized
commit/push and [four-project partial adoption](partial-migration-2026-10-23.md),
excluding active DriveTrace and shared old-root infrastructure. Applicable integrity
gates remain required before actual activation. Preparing A1 never
modifies member repos, user configs, runners or broker. A1.6 adds only a dated
old-root transition note and factual catalog maintenance; active old-root
policies remain in force until cutover.
Links: [readiness](a1-readiness.md), [router](../AGENTS.md), [local state](local-state.md),
[runners](runners.md), [notifications](telegram/NOTIFICATIONS.md).

## Three gates

1. **READY TO START:** tests, generated checks, document-read records, reviewed policy
   diffs, copy/resume/rollback rehearsal and verified external backups. Each result has
   timestamp, command/exit code, source hashes and evidence. User GO starts the window;
   it never waives a data-integrity requirement.
2. **READY TO COMMIT CUTOVER:** source freeze still holds, inventories/Git state match,
   mandatory repairs/policies and G01–G17/G19–G20 pass. Persist COMMITTED in both journals
   BEFORE deleting ANY source copy. This is a migration boundary, not a Git commit.
3. **CLEANED:** controlled source cleanup completed; G18 proves only `zima/` remains in
   the old root. Persist CLEANED. G18 is post-cleanup, not a circular start precondition.
   A cleanup interruption resumes from COMMITTED.

## A1.7 readiness package

- `verify -Fast -Pending` and `scripts/tests/run-tests.ps1` pass. Pending is A1-only;
  never use it for A2 acceptance. Preserve final audit evidence in versioned docs.
- Initial commits/push were authorized on 2026-10-23. Recheck remote history
  before first push; if history appears, fetch and reconcile, never force-push.
- [Policy pack](policy-patch-pack.md): exact source hashes, candidate diffs,
  `git apply --check` on frozen copies and tests preserving local acceptance rules.
  Dirty call-tracker needs a non-destructive patch; inability to apply means NO-GO.
- Back up every irreplaceable category outside BOTH workspace trees. Verify a complete
  inventory and a restored sample per category. The migration copy is not this backup.
  Record destination, capacity, privacy protection and retention explicitly.
- Rehearse on synthetic repositories with dirty/staged/untracked/ignored files, stash
  and linked worktree. Inject copy failure, missing/changed files and interrupted journal
  transitions; demonstrate deterministic resume and rollback.
- Inventory EVERY old-root entry, including nonempty archives and infrastructure runtime
  state. Each has a destination. Unknown entries are never silently deleted.

## Journal and state machine

Durable evidence: `.local-state/migration/<run-id>/`, never disposable temp. Keep
`journal.jsonl` there and a second copy outside zima. Records contain `run_id, attempt,
step, repo, state, source, destination, pre_hash, post_hash, timestamp, result, evidence`.
Flush both copies before acting on a transition. Truncated/disagreeing journals or
missing evidence mean STOP and inspect the last proven state.

`PREPARED -> COPIED -> VERIFIED -> RECONFIGURED -> SMOKE_TESTED -> COMMITTED -> CLEANED`

Revalidate actual files/configs against recorded hashes before skipping a successful
step. A historical OK alone is not idempotency. Never overwrite an unknown destination
or merge independently edited source/target trees.

| Failure state | Recovery |
|---|---|
| PREPARED | Abort; production sources untouched. |
| COPIED | Preserve source; inspect only the recorded target, verifying resolved path before cleanup. |
| VERIFIED | Revalidate both trees; resume or discard target copy. No source deletion. |
| RECONFIGURED | Stop new consumer; restore configs and external worktree pointers to source; start one old-path consumer. |
| SMOKE_TESTED | Recheck all gates; use the same rollback if needed. |
| COMMITTED | Target authoritative. Resume verified cleanup; reverting requires a separate restore decision protecting target changes. |
| CLEANED | Separate restore operation using retained backups and journal. |

## Maintenance-window sequence

1. **FREEZE:** inventory agents/processes/open files and prevent new writers/jobs.
   Query queued, in-progress, requested, waiting and pending GitHub runs across affected
   repos with pagination. Record zero or explicit cancellation; `docker ps` alone proves
   nothing. Do not restart unrelated runners or the shared engine.
2. **SNAPSHOT/BACKUP:** capture HEAD/branch, binary staged/unstaged diffs, porcelain
   status, untracked/ignored inventories, stash refs/content, worktrees, `.git` type,
   config/hooks/alternates and reparse points. Save durable evidence. Verify external
   backups and targeted config recovery copies without dumping credentials.
3. **COPY-ONLY (transaction A):** one repo at a time. No rename, `/MOVE`, content mutation
   or source deletion before COMMITTED. Robocopy `/E /COPY:DAT /DCOPY:DAT /R:2 /W:2`:
   0–7 transport success, >=8 STOP; no `/MT` on Git trees. Compare full inventory +
   SHA-256 on EVERY copy path, including tracked/untracked/ignored files and Git metadata.
   Record ACL/ADS/reparse/sparse requirements separately; unsupported metadata is NO-GO.
   Never blindly follow reparse points. Transport success alone proves no equivalence.
4. **REPAIR (planned mutation):** after move-only verification, repair external worktree
   pointers and verify dirty contents; rewrite critical AVD/script paths and boot the
   AVD. Journal separate before/after diffs and reversal steps. Performance caches may wait.
5. **CONFIGURE:** stop affected Telegram clients/consumers; copy broker without code
   changes; verify dependencies/runtime ownership; apply reviewed redacted patches to
   discovered Claude/Codex/OpenCode/Startup paths. Retain originals. Scan ACTIVE managed
   configs for old paths (historical logs/backups excluded deliberately). Start exactly
   one new-path polling owner; test connection and real send. Deny ask/session tools on
   each harness. Shell wildcards do not provide a sandbox; test actual permission behavior.
   The redacted permission packet must include destructive-Git denies from plan D6:
   `git push --force*`, `git reset --hard`, `git clean -fdx*`, plus equivalent short-flag,
   flag-order, alias, shell-wrapper and worktree-target variants. Never broadly allow
   a mutating Git or zima CLI command solely because its path is workspace-scoped.
6. **MEMORY:** copy selected content to discovered new Claude project keys, preserve
   originals, and avoid copying cached permissions/settings wholesale. Record selected
   source/destination paths and verify matching content hashes against the frozen
   originals. No model/session spot-check is required.
7. **POLICY PATCHES (transaction B):** apply reviewed diffs to frozen content. Preserve
   repo evidence rules and stricter acceptance gates. All mandatory conflicts are fixed,
   including dirty call-tracker; no Faz B exception. LG/str-fixer receive minimal reviewed
   AGENTS files with the workspace block and pointers to their existing canonical skills.
8. **SMOKE:** run the matrix WITHOUT Pending; inspect a fresh VS Code workspace; verify
   source freeze, target inventories/Git integrity, worktrees/AVD, effective permissions,
   task-log document reads and selected-memory path/content hashes. Live agent startup
   and context callbacks are waived by the user; functional/security checks remain.
9. **COMMITTED:** only after all pre-cleanup gates pass, flush both journal records.
   Target becomes authoritative; stop using source. No silent rollback after this boundary.
10. **CLEANUP:** verify each resolved source is an inventoried old-root target before
    deletion. Move permanent evidence/archives/planning docs to recorded destinations.
    Unknown entries cause STOP. Preserve the recovery journal outside cleanup targets
    until finalized. Check G18, then record CLEANED.
11. **RECORD:** completion evidence and backup-retention decision; verified DONE
    notification. Optional cache/performance/document-size work belongs to Faz B.

## Gate matrix (all applicable rows blocking)

| ID | Test | Required result / timing |
|---|---|---|
| G01 | robocopy >=8 injection | abort; source preserved / rehearsal |
| G02 | missing/changed/extra file | mismatch; no cleanup / rehearsal + real copy |
| G03 | dirty/staged/untracked/ignored/stash | content and Git state equal |
| G04 | interruption/resume/rollback | revalidate evidence; deterministic recovery |
| G05 | external worktree | new-main binding and dirty state healthy; reversal tested |
| G06 | managed old paths | zero active-config old references |
| G07 | Telegram | one polling owner; connection and real send succeed |
| G08 | document reads | task log records zima AGENTS, target card and linked member rules/skills read before work; no live startup test |
| G09 | ripgrep | source visible; private/metadata/media/build/credentials absent |
| G10 | permissions | effective tool denies tested; path scope documented as policy |
| G11 | freeze | no active/queued/waiting jobs or writers; recheck before COMMITTED |
| G12 | backup restore | verified external copy + sample per category |
| G13 | manifest | schema/type/path/origin fixtures fail nonzero |
| G14 | zima Git index | no member content, secrets or local-state tracked |
| G15 | VS Code | zima + five independent Git repositories visible |
| G16 | call-tracker AVD | new-path boot, acceptance state retained |
| G17 | verify Fast + Full | PASS; no unaccepted warnings, no Pending |
| G18 | old root | only zima / AFTER cleanup |
| G19 | selected memory | source/destination paths and content hashes match frozen originals; originals retained; no model/session spot-check |
| G20 | policy scan/review | no mandatory contradiction; stricter local gates retained |

Unexpected loss, unsupported metadata, patch/backup failure, unfrozen writer, second
consumer, broken worktree/AVD or ambiguous journal means STOP. This runbook is not a
production engine; a fixture rehearsal never proves production backup, permissions,
runner isolation or device acceptance passed.
