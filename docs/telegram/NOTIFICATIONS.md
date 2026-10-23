# Telegram notifications — one-way contract

Bot: `@BosAdam_bot` (JARVIS). Channel: `telegram_send_notification` ONLY. The reply/ask
mechanism (`telegram_ask_user`, session-mailbox tools) is prohibited by workspace policy.
Removing it from every harness surface is an A2 gate; current enforcement is not assumed
from this document. `telegram_connection_status` is permitted for diagnostics. These
rules are a POLICY layer, not a network boundary.

Do not modify broker code or start another polling consumer. A2 must discover the
current polling owner and preserve single-consumer ownership across relocation.
Product-bot credentials and ownership are separate facts to verify, not inferred from
shared environment-variable names. See [runbook](../migration-2026-10.md).

## Message schema (every notification, English, ≤6 lines)

```
[STATUS] PROJECT - one-line headline
Result: <what was done, one line>
Verification: PASS | FAIL | N/A - <command run, or evidence link (issue/PR/file path)>
Next: <single sentence>
```
…or, when blocked, the last line is replaced by:
```
Blocker: <single sentence; what the user must decide or do>
```

- STATUS vocabulary: `DONE`, `FAIL`, `BLOCKED`, `INPUT-NEEDED`, `INFO`.
- `Next` XOR `Blocker` — exactly one of them, always.
- Decisions: `[INPUT-NEEDED] PROJECT - NEEDS DECISION <task-id>` plus the FIXED footer:
  **"Reply here is not read. Decision is applied at the next session start."**
  (A Telegram reply is never consumed — without this footer the user will believe they
  answered. The decision itself is recorded via the park-file protocol in AGENTS.md.)

## When to notify

| Event | Notify | Status | silent flag |
|---|---|---|---|
| Long task completed AND verified | yes | DONE | true |
| Build / test / deployment finished | yes | DONE or FAIL | FAIL false, DONE true |
| Blocked; needs user decision or physical action | yes | BLOCKED or INPUT-NEEDED | false |
| Parked decision older than N days (best-effort, session start) | yes | INPUT-NEEDED | false |
| Intermediate step, trivial op, routine status | no | — | — |
| Anything by a subagent | NEVER — leader only | — | — |

Never send: secrets, credentials, personal device data, raw logs longer than 3 lines
(evidence is a link/path, not a paste). Never notify completion before tests/verification
finish.

## Enforcement map

| Surface | Mechanism |
|---|---|
| Claude Code | `~/.claude/settings.json` deny: `mcp__telegram__telegram_ask_user`, `mcp__telegram__telegram_session_register`, `..._receive`, `..._ack`, `..._reply`; allow: `..._send_notification`, `..._connection_status` |
| Codex | `~/.codex/config.toml` `enabled_tools = ["telegram_connection_status", "telegram_send_notification"]` (ask_user removed, tool_timeout_sec removed) |
| OpenCode | discover active `opencode.json` / `opencode.jsonc`; deny ask/session tools and any plugin auto-registration route; mandatory one-way policy cannot be deferred |
| All agents | This document + AGENTS.md router line; subagents get the verbatim preamble (no Telegram authority) |

## Workspace vs product separation

The Daily Moods app's own Telegram feature (personal product bot, START/END call messages)
is SEPARATE from workspace JARVIS notifications. Environment NAMES may be shared; that
does not establish shared credential values, bot identity or polling ownership. Never
inspect values to compare them or let product features reconfigure the workspace broker.

## Parked-decision record

Use `.local-state/parked/<safe-task-id>.md`, outside disposable temp. Required fields:
`id`, `repo`, `created_at`, `last_notified_at`, `status`, `question`, `decision`, `evidence`.
Status is `pending` until an explicit user answer in the main conversation. Never infer
approval from silence. Independent work may continue. When resolved, preserve the answer
and evidence in `.local-state/decisions/<id>.md` before removing the pending file.
Session-start reminders are best effort; there is no background reminder scheduler.

## A2 enforcement test matrix

| Test | Required evidence |
|---|---|
| Current and legacy ask/session names | Each effective tool name denied or absent in each harness. |
| Wildcard/alias matching | Test real resolved names; a settings text grep alone is insufficient. |
| Subagent notification attempt | Tool unavailable/denied where supported; explicit no-contact policy always supplied. |
| Terminal/HTTP alternative | Prohibited by agent contract; MCP deny does not imply network egress isolation. |
| Destructive Git/context escape | The separate harness packet tests force-push, hard-reset and destructive-clean denies, aliases/flag variants and cross-repo targets; path instructions alone are not a sandbox. |
| Connection and send | Leader diagnostics and a real notification succeed without another poller. |

Record command/result and active configuration source, never secret values. A deny
mention in a comment or rule file is not proof of effective enforcement.
Router: [AGENTS.md](../../AGENTS.md). Current evidence: [readiness](../a1-readiness.md).
