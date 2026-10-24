# Four-project workspace setup

The four authorized projects are available under `projects/`. DriveTrace remains
at its original location and was excluded from source, worktree, job and runner
operations. Shared old-root infrastructure and global settings remain in place.

| Project | Active directory |
|---|---|
| LG Channel List Editor | `projects/lg-tv-channel-sort/` |
| str-fixer | `projects/str-fixer/` |
| Coin Tracker | `projects/coin-tracker/` |
| Daily Moods | `projects/call-tracker/` |

## Current outcome ? 2026-10-25

Git checks confirmed all four original repositories clean. Complete existing
copies are used, preserving their Git history, branches and local ignored data.
Target changes are the workspace instruction patches and Daily Moods local-path
repairs. Member repositories remain independent; no member commit/push occurred.
All four original directories are retained. No migration COMMITTED boundary or
source cleanup occurred. Protected recovery records remain under the existing
C/D run `partial-20261023-b279d9711e44`.

The user explicitly rejected the bespoke migration workflow and its resource
cost on 2026-10-25. Do not resume its attestation/COMMITTED/cleanup sequence or add
more migration tests. Use ordinary Git checks and cloning when needed, preserving
any required local ignored configuration. The unpublished migration engine and
its dedicated tests were removed from the deliverable; task-only copies remain.
The earlier full migration runbook is not a requirement for using these copies.

Live AI tests and Call AVD boot were explicitly waived. No boot or product/device
acceptance PASS is claimed. Source data was not deleted. DriveTrace and global
infrastructure relocation remain outside this task.

The stopped Daily Moods runner now uses the target readonly bind; its five new
registration files were verified and it remains stopped. Coin's existing runner
was left stopped; neither runner listener nor the shared engine was restarted.

Zima's status command disables optional Git index writes. Its existing validation
passed 151 baseline and 45 deferred/status assertions. Only Zima metadata/code
is published; member data, local state and credentials remain ignored.

[Router](../AGENTS.md) ? [Readiness](a1-readiness.md) ? [Runner policy](runners.md)
