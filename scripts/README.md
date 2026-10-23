# scripts

Workspace orchestration code. Scripts never build or push. `update` permits only a
fast-forward of a clean default branch tracking its matching origin branch; it never
creates a merge commit. See [workspace rules](../AGENTS.md).

## Contents / rules
- `zima.ps1` - the workspace CLI: status, repo card, issues, clone, sync, update,
  new-repo, verify, gen, runners, locks. Windows PowerShell 5.1 target (pwsh 7 not
  installed on this host); file is UTF-8 WITH BOM.
- A `deferred` member is metadata only. Explicit clone/sync/update/issues targets
  refuse before native validation; bulk operations skip it. Status uses null/uninspected
  source fields and a DEFERRED reason. Normal verification explicitly reports excluded
  source/Git/docs/preamble checks; active members retain every existing check.
  Runner queries are scoped to each active container; excluded runners are not inspected.
- `migration-rehearsal.ps1` - synthetic copy/hash/failure/rollback rehearsal; does
  not perform production cutover or operate real member repositories.
- `backup-local-state.ps1` - copy-only A1 external backup; run only after the leader's
  two independent Tier 3 reviews. `-Execute` uses the fixed approved old workspace
  and `D:\projects\zima\backups\pre-cutover-2026-10-20`; execution must be as
  `Zima\mertp`, the approved workspace owner. No source or member-repo writes,
  deletion, overwrite, resume, move, mirror, purge, runner or user-config operations.
  Existing destinations are refused atomically, including empty directories.
- The backup preflight rejects reparse points, hard links, extended attributes,
  sparse/compressed/encrypted/offline and unknown NTFS attributes. It requires NTFS,
  no running emulator and space for all default/named DATA streams plus the largest
  isolated restore and at least 1 GiB margin. SHA-256 inventories compare every
  selected file, ADS and empty directory before/after; original owner/group/DACL are
  recorded only inside the protected external copy. Backup root creation atomically
  allows only workspace owner, SYSTEM and Administrators, inherited by its data.
  DOS attributes and creation/write times are preserved; last-access times, SACL,
  object IDs and USN are excluded. This is a data backup, not filesystem cloning.
- Restore checks cover each present category, a named-stream item when present,
  the largest AVD image and a signing artifact when present. Actual keystore validity
  and AVD boot remain separate gates; filename extensions select opaque samples.
  Missing/empty categories and missing signing material are explicitly reported,
  without invented restore results. `VERIFIED` certifies the existing selected data's
  integrity, never A2 readiness or cutover authorization. Private inventories and
  sample paths stay external; only redacted receipts enter `.local-state/migration/`.
  On failure the owned partial copy is re-hardened and its ACLs rechecked; the receipt
  records protection as VERIFIED, UNKNOWN or FAILED. An unconfirmed protection state
  requires attention; it is never described as protected. Sources stay authoritative,
  retained backup data is never automatically deleted. See [local state](../docs/local-state.md).
  Missing irreplaceable member roots stop before copying. Missing/empty critical
  categories explicitly block readiness even when the remaining existing data is
  verified (exit 2); absent optional samples/root SRT are reported without failure.
  Exit 0 = verified copy with critical categories present; exit 1 = failed operation.
- `tests/run-tests.ps1` + `tests/fixtures/` - schema, path, generation, CLI, Git state,
  external failure, lock race/ownership and Full verification regressions.
  Run after ANY change to zima.ps1 or repos.schema.json.
- `tests/backup-tests.ps1` - isolated synthetic binary/ADS/ACL/copy/restore failures;
  no production sources or D: writes. Run after any backup-script change.
- `tests/deferred-tests.ps1` - synthetic exclusion/default/schema/generation/CLI and
  no-probe regressions. It never accesses actual member sources, runners or networks.
- Exit contract for verify: 0 PASS / 2 PASS_WITH_WARNINGS / 1 FAIL.
- `verify -Pending` defers absent member checks only; generated drift remains an error.
  Pending is accepted only with exact `A1` in `.local-state/migration/PHASE`, or no
  marker on a fresh clone. Later/unknown markers refuse Pending in verify and status.
  `verify -Full -Pending` adds the actual rg probe, `.env` and entire-index scans.
  Duplicate `.env` keys are rejected with Windows case-insensitive semantics.
  Every indexed blob is scanned, including unchanged tracked files; local-state,
  archive, evidence, harness/IDE and member paths are forbidden. The exact
  `projects/.gitkeep` skeleton is allowed. UTF-8/NUL index parsing preserves Unicode
  and spaces in filenames, and reads indexed object IDs rather than worktree files.
  Full certifies automated structure; operational permission/runner/device gates
  remain separately required by [the runbook](../docs/migration-2026-10.md).
- `repos.schema.json` is evaluated before semantic validation. The fail-closed draft-07
  subset supports object/array/string/integer/number/boolean/null types, properties,
  required, additionalProperties=false, items, local definition references, oneOf,
  enum, const, pattern and minLength, plus schema annotations. Unknown keywords fail.
  Defaults normalize omitted repo owner/branch; explicit overrides are preserved.
- Paths are canonical Windows paths with an existing-ancestor reparse check. Repo
  commands verify the actual Git root and origin before acting. `sync` only fetches.
- `gen` catalogs every registered repo, explicitly labels deferred metadata and includes
  only active entries in the portable workspace (even if their adoption is pending).
  Outputs are deterministic BOM-less UTF-8/LF without timestamps.
- `locks acquire|release <resource> -Owner <token>` uses atomic creation and a local
  named mutex, explicit ownership and traversal-safe names. Keep the owner token for
  release; stale locks require a human decision. `locks list` never creates directories.
- `new-repo` validates/render-preflights all files before writing manifest, card and
  generated outputs; rejected input leaves the workspace unchanged. It does not clone.

## Related
- [../repos.schema.json](../repos.schema.json) - [../docs/README.md](../docs/README.md)
