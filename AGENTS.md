# AGENTS.md — zima workspace router

zima is the meta-repo that manages this workspace (`C:\Users\mertp\Desktop\projects`) as a
virtual monorepo. zima holds the rules, the manifest (`repos.json`), docs, skills and scripts.
Every repository under `projects/` is an INDEPENDENT git boundary with its own structure,
history, CI and rules. zima provides surface-level oversight only.

## Startup protocol

0. Read pending decisions in `.local-state/parked/` and surface them. Resume dependent
   work only after an explicit answer; independent work may continue. Preserve resolved
   decisions in `.local-state/decisions/` before removing their pending files.
1. Read this file fully.
2. If target is unknown, read `repos/` cards or run `powershell -File scripts/zima.ps1
   status -q` (A1 only: add `-Pending`; never use Pending during/after cutover).
3. Read the target repo's card: `repos/<name>.md`. A manifest member marked `deferred`
   is metadata only: stop target operations, leave its source/runner untouched and
   respect its recorded reason. Bulk commands skip it; it is absent from the workspace.
4. Run `powershell -File scripts/zima.ps1 issues -R <name>` and read the newest status
   comment of the relevant issues — that is "where we left off".
5. If the repo directory is missing: clone it with `zima.ps1 clone <name>`. EXCEPTION: if
   the card/manifest says `local_state: irreplaceable`, NEVER auto-clone — a missing
   directory means lost irreplaceable local state; STOP and notify the user.
6. Read the repo's own AGENTS.md / README / skills through the card's links. They are NOT
   auto-loaded from a zima-root session. Record which rule files you read (rules-read
   record) in the task log. Do not start implementation before reading them.
7. Repo-local rules win over zima for project-specific work — EXCEPT the never-loosened
   set: secrets handling, chain of command, one-way Telegram, git boundaries (never treat
   `projects/` as one repo; run git only at the verified repo root), evidence retention,
   review-tier minimums, issue standard (legacy issues are read-only; `gh` writes are
   leader-only). Member adoption follows the scoped migration record; deferred members
   keep their existing rules/location until a separate authorized transition.
8. Scope all content searches under `projects/<repo>/`. Root-wide searches only for
   cross-repo questions (the `.ignore` whitelist makes source searchable; sensitive paths
   are excluded).

## Chain of command: subagent → leader → user

A subagent NEVER contacts the user directly — through any channel, Telegram included.
It reports to the leader; the leader asks the user and carries the decision back. Only the
leader sends Telegram notifications. Every subagent prompt must include the verbatim
preamble from `.agents/skills/zima-leader/references/preamble.md`.

## Skill index (read the SKILL.md fully before the matching task)

| Skill | Path | Read before |
|---|---|---|
| zima-leader | `.agents/skills/zima-leader/SKILL.md` | spawning any subagent; assigning review tiers; cross-repo tasks |
| zima-sync | `.agents/skills/zima-sync/SKILL.md` | manifest edits, sync/update operations, adding repos |
| zima-new-repo | `.agents/skills/zima-new-repo/SKILL.md` | onboarding a new repo into zima |

Docs referenced by the router instead of skills: Telegram → `docs/telegram/NOTIFICATIONS.md`
(before sending ANY notification); runners → `docs/runners.md` (before any runner action);
issues → `docs/issues.md` (before creating/commenting/closing any issue).

## Telegram notifications — one-way only

Only the leader may use `telegram_send_notification`; `telegram_connection_status` is
allowed for read-only diagnostics. Denying ask/session tools in every harness is an A2
gate, not an established A1 fact. When a blocking
decision is needed: write a park file (`.local-state/parked/<task-id>.md`), notify with
`[INPUT-NEEDED] ... NEEDS DECISION <task-id>` and the fixed footer "Reply here is not read.
Decision is applied at the next session start." Full schema and matrix:
`docs/telegram/NOTIFICATIONS.md`.

## CI runners — summary

Self-hosted, one shared Docker engine, one container per repo (`<repo>-docker-N`, label =
repo slug; labels are ROUTING, not isolation — isolation comes from per-repo registration).
NEVER stop/restart another repo's runner and NEVER quit/restart Docker Desktop without
`zima.ps1 locks list` clean + user approval. Label add/rename sequences: `docs/runners.md`.

## Workspace rules

- Agent temp files live in `.agent-tmp/<task>/` inside the relevant project dir; never in
  AppData; never committed; cleaned task-scoped. PARKED decision files live in
  `.local-state/parked/` (durable — temp cleanup must never touch them).
- No precautionary archives/backups of temp build outputs unless explicitly asked
  (decision 2026-10); permanent acceptance evidence is exempt and never deleted.
- Automation-first (decision 2026-10-18): do yourself what you can do via tooling (adb,
  scripts, APIs) and verify by measurement; ask the user for UI only when physically
  required.
- Machine config lives in `.env` (gitignored). Workspace automation/JARVIS credentials
  live only in HKCU; never copy their values into files, logs, messages or commits.
  Existing product signing/private artifacts follow repo-local protection rules; this
  never authorizes exposing or committing secrets. `.env` must contain no secret values.
- Every committed folder carries a short technical `README.md` (what/why/rules/links).
  New folder ⇒ README in the same change. Exceptions are listed in the verify checker.

## Documentation linking

Every zima doc cross-links up and down (AGENTS.md ↔ cards ↔ repo docs). zima never copies
repo content — a link plus a one-line description only. When a repo doc moves, its card is
updated in the same change. Generated artifacts (`repos/repos.md`, runner registry in
`docs/runners.md`, `zima.code-workspace`) are produced by `zima.ps1 gen` — never hand-edited.

## Catalog

The live repo index is `repos/repos.md` (GENERATED from `repos.json`). `repos.json` is the
single source of truth; `repos/<name>.md` cards are hand-written views.

## Out of scope for zima

Repo-internal rules and docs; repo skill contents and their storage conventions; runner
compose files and Dockerfiles; CI workflow internals; `.jarvis-telegram-mcp/` code; the
Daily Moods product Telegram feature (separate from workspace JARVIS); third-party repo
contents; `artifacts/` evidence.
