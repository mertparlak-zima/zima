# Partial project adoption — 2026-10-23

User authorization: publish zima with commit/push and gradually transfer existing
projects, except DriveTrace, where another agent is actively working. This
releases the earlier publication hold. The [full migration runbook](migration-2026-10.md)
remains the integrity baseline; actual partial execution is being prepared.

## Authorized scope

| Project | Source under old workspace | Target under zima |
|---|---|---|
| Coin Tracker | `coin-tracker/` | `projects/coin-tracker/` |
| LG Channel List Editor | `lg-tv-channel-sort/` | `projects/lg-tv-channel-sort/` |
| str-fixer | `str-fixer/` | `projects/str-fixer/` |
| Daily Moods | `call-tracker/` | `projects/call-tracker/` |

DriveTrace remains at its current location and outside this operation. Its source,
worktrees, evidence, policies, CI jobs and runner are excluded. `drive-trace-prd/`
and shared old-root infrastructure/configuration stay in place for the active
workspace. This operation cannot satisfy the full-cutover G18 old-root cleanup.

## Current execution status

- A1 publication completed: `cce0781591a9bedffca5e6a742cdd5cc17136570` pushed to
  `origin/main`, with the remote ref verified. Remote was empty before publication.
- Project metadata, policy applicability, capacity and scoped freeze are being
  revalidated. No project transfer has occurred in this run yet.
- Mixed layout is explicit in the manifest: `deferred: true` with `defer_reason`
  keeps DriveTrace as metadata only at its planned future path. It is omitted from
  the generated workspace; bulk operations skip it and explicit operational targets
  refuse before native calls. No legacy-source fallback or external path is introduced.
  Four active entries still require normal non-Pending verification after adoption.
- Existing dirty/index/stash/local data must survive. Copy-only verification and
  scoped COMMITTED evidence precede any source cleanup. Unknown targets are refused.
- Only zima commits/pushes are authorized here. Member histories remain independent;
  their contents and private migration evidence never enter zima's Git index.
- Live AI startup tests remain waived. Backup/restore, Git/data integrity and
  applicable functional/security checks retain their documented requirements.
- Full-workspace global-config/permission relocation, runner-label changes and
  old-root cleanup remain deferred with the shared infrastructure. They are not
  claimed complete by a successful active-member structural check. Each project
  still requires its scoped integrity/activation evidence before source cleanup.

Record actual results and deferred gates here as execution progresses.
[Readiness](a1-readiness.md) · [GO checklist](a2-go-checklist.md) ·
[workspace decisions](decisions.md).
