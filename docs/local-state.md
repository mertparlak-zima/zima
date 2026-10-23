# Local state — irreplaceable data inventory and backup policy

`local_state: irreplaceable` in `repos.json` is a STOP sign, not a backup. This file is the
secret-free inventory of what cannot be regenerated, where it lives, and the backup/restore
procedure that must be verified BEFORE cutover (A2 GO precondition, plan Y13).

## Inventory

These are protection categories; measured presence is recorded below, not
implied by a category name.

| Repo | Path (relative to repo root) | Content | Why irreplaceable |
|---|---|---|---|
| call-tracker | `private/` | personal AVD `avd-8` (with embedded absolute paths), personal build scripts; signing artifacts when configured | AVD holds app-local acceptance state; configured signing identities would be irreplaceable |
| call-tracker | `.planning/` | issue acceptance evidence, AVD run logs | acceptance history (partially mirrored in GitHub issues) |
| drive-trace | `artifacts/device-evidence/` | device acceptance evidence with SHA256SUMS hash chains | evidence policy: never uploaded, permanent retention |
| str-fixer | `input/`, `output/`, `samples/`, root `*.srt` | user media files | personal media, deliberately never committed |

## Rules

1. `zima.ps1 clone` refuses to create a directory for an `irreplaceable` repo; a missing
   directory is a STOP-and-notify condition.
2. Before cutover (A1.7): one verified backup copy of every irreplaceable path above,
   stored OUTSIDE both the old root and the zima tree. Approved location:
   `D:\projects\zima\backups\pre-cutover-2026-10-20` under the shared programming
   storage root `D:\projects` (user decision, 2026-10-20).
3. Verify the full backup inventory, then restore at least one representative item PER
   category to an isolated location and compare SHA-256 against the source. Record counts,
   category, hashes and result in the durable migration journal; do not log personal
   filenames or secret values. A single text-file sample does not prove a keystore/AVD
   can be restored. Device/AVD startup is an additional A2 gate.
4. Post-cutover backups are a separate long-term policy (frequency/retention = user
   decision); the pre-cutover backup is retained until Faz B completes.
5. This file never contains secret values or full personal file listings — categories and
   paths only.

## Measured preflight — 2026-10-21

Read-only metadata inventory found 2,577 files, 136 directories and 3,559,533,103
logical bytes across the documented categories. The largest file is a
2,684,420,096-byte AVD image. `str-input` contains one named NTFS stream of 143
bytes; it must be included in copy/hash/restore verification. No reparse,
sparse, compressed or encrypted entries were observed. Recheck before copying.

`str-samples` is absent and root SRT selection is empty. No actual signing-key
file was identified; JSON/PowerShell files with signing-related names are not
keystores. Public Call Tracker toolchain/build rules confirm that production
signing is not configured yet and QA uses the default SDK debug key. Production
key restore is therefore N/A for this stage, not a missing-key blocker or a
PASS. The backup does not claim coverage of an external key; QA signature
continuity remains an A2 smoke check. See the [repo card](../repos/call-tracker.md)
for the canonical signing reference.

See [readiness](a1-readiness.md) for measured backup results and
[GO checklist](a2-go-checklist.md) for outstanding production gates.
