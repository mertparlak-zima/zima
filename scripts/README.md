# scripts

Workspace orchestration code. Scripts never build or push. `update` permits only a
fast-forward of a clean default branch tracking its matching origin branch; it never
creates a merge commit. See [workspace rules](../AGENTS.md).

## Contents / rules
- `zima.ps1` - the workspace CLI: status, repo card, issues, clone, sync, update,
  new-repo, verify, gen, runners, locks. Windows PowerShell 5.1 target (pwsh 7 not
  installed on this host); file is UTF-8 WITH BOM.
- `telegram-notify.mjs` - leader-only outbound Telegram notifications using Node 18+
  standard libraries. Pipe message text to stdin; optional `--silent` disables the
  notification sound. It reads only `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` from
  the ignored `.env` next to `env.example`, independently of the current directory.
  Never put credentials in command arguments. It sends one fixed HTTPS sendMessage
  POST, refuses redirects, bounds the request/body read to ten seconds and emits
  generic success/failure only. There is no incoming-message listener or service.
  See [notification rules](../docs/telegram/NOTIFICATIONS.md).
- A `deferred` member is metadata only. Explicit clone/sync/update/issues targets
  refuse before native validation; bulk operations skip it. Status uses null/uninspected
  source fields and a DEFERRED reason. Normal verification explicitly reports excluded
  source/Git/docs/preamble checks; active members retain every existing check.
  Runner queries are scoped to each active container; excluded runners are not inspected.
- `tests/run-tests.ps1` + `tests/fixtures/` - fast in-memory manifest, runner rule,
  path, deferred-member and generated artifact checks. Run after ANY change to
  zima.ps1 or repos.schema.json.
- Exit contract for verify: 0 PASS / 2 PASS_WITH_WARNINGS / 1 FAIL.
- `verify -Pending` defers absent member checks only; generated drift remains an error.
  Pending is accepted only with exact `A1` in `.local-state/migration/PHASE`, or no
  marker on a fresh clone. Later/unknown markers refuse Pending in verify and status.
  `verify -Full -Pending` adds the actual rg probe, `.env` and entire-index scans.
  Duplicate `.env` keys are rejected with Windows case-insensitive semantics.
  Only the two local Telegram credential fields are allowed and redacted from
  `Read-ZimaEnv` maps; other credential keys and secret-shaped values remain errors.
  This local exception never permits credentials or `.env` in indexed files.
  Every indexed blob is scanned, including unchanged tracked files; local-state,
  archive, evidence, harness/IDE and member paths are forbidden. The exact
  `projects/.gitkeep` skeleton and exactly `.vscode/settings.json` plus
  `.vscode/README.md` are allowed with case-sensitive paths. These files still pass
  the regular-file, index-stage and secret scans; other VS Code paths remain ignored
  and forbidden even when force-added. UTF-8/NUL index parsing preserves Unicode
  and spaces in filenames, and reads indexed object IDs rather than worktree files.
  Full certifies automated structure; operational permission/runner/device gates
  remain separately governed by their active policies.
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
