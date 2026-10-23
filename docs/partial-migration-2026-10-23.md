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

- A1 publication authorized; remote checked empty immediately before publication.
- Project metadata, policy applicability, capacity and scoped freeze are being
  revalidated. No project transfer has occurred in this run yet.
- A mixed layout must be represented explicitly before activation; a deferred
  project must never be silently cloned, fetched, updated or policy-patched.
- Existing dirty/index/stash/local data must survive. Copy-only verification and
  scoped COMMITTED evidence precede any source cleanup. Unknown targets are refused.
- Only zima commits/pushes are authorized here. Member histories remain independent;
  their contents and private migration evidence never enter zima's Git index.
- Live AI startup tests remain waived. Backup/restore, Git/data integrity and
  applicable functional/security checks retain their documented requirements.

Record actual results and deferred gates here as execution progresses.
[Readiness](a1-readiness.md) · [GO checklist](a2-go-checklist.md) ·
[workspace decisions](decisions.md).
