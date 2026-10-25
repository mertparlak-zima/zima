# Local state — irreplaceable data inventory and backup policy

`local_state: irreplaceable` in `repos.json` is a STOP sign, not a backup. This file is the
secret-free inventory of what cannot be regenerated and where it lives. Do not auto-clone
missing irreplaceable repos or delete their local data or recovery copies.

## Inventory

These are protection categories; a category does not certify a current file inventory.

| Repo | Path (relative to repo root) | Content | Why irreplaceable |
|---|---|---|---|
| call-tracker | `private/` | personal AVD configuration/snapshots, build scripts; signing artifacts when configured | private QA files and configured signing identities |
| call-tracker | `.planning/` | issue acceptance evidence, AVD run logs | acceptance history (partially mirrored in GitHub issues) |
| drive-trace | `artifacts/device-evidence/` | device acceptance evidence with SHA256SUMS hash chains | evidence policy: never uploaded, permanent retention |
| str-fixer | `input/`, `output/`, `samples/`, root `*.srt` | user media files | personal media, deliberately never committed |
| tahmin-ligi | `.env*`, `backups/`, `.vercel/` | local configuration, database recovery copies and deployment linkage | deliberately excluded from Git |

## Rules

1. `zima.ps1 clone` refuses to create a directory for an `irreplaceable` repo; a missing
   directory is a STOP condition for the leader.
2. Preserve existing local data and external recovery copies. The verified pre-adoption
   recovery copy is recorded in [workspace.md](workspace.md); do not delete it as part of
   workspace documentation cleanup. Future backup frequency/retention is not specified here.
3. Do not record secret values or full personal file listings — categories and
   paths only.

See [workspace setup and recovery record](workspace.md) for verified recovery receipt
references and current scope. These historical checks do not claim product, device, AVD
or CI acceptance. No external production signing key was covered by that recovery copy;
current signing rules belong to the [Daily Moods repo](../repos/call-tracker.md).
