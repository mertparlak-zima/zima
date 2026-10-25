# Telegram notifications - outbound only

Only the leader sends concise notifications. There is no incoming Telegram path:
no broker, polling, webhook, server, session mailbox, question or reply tool.
Use the active agent conversation for questions. Unattended blocked work may
leave a durable park file and send a one-way notification.

## Configuration

The sender reads only the ignored Zima root `.env`, independently of its current
working directory. Set `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` there. Real
values never enter env.example, source, logs, arguments, notifications or Git.
The CLI does not fall back to process environment or HKCU. Existing unrelated
user-environment credentials are left unchanged.

## Send

Run from the Zima root (message via stdin, credentials never via arguments):

```powershell
'Zima: work completed.' | node scripts/telegram-notify.mjs --silent
```

From a member root use `node ../../scripts/telegram-notify.mjs --silent`.
The command exits after one HTTPS `sendMessage` request. It creates no listener,
port, daemon, session state or local message archive. Success/error output is
generic and never prints Telegram's response or a token-bearing request URL.

## When and what to send

Notify after verified completion of long implementation/build/test/deployment
work, or when blocked and user input is needed. No trivial/intermediate spam.
Messages are English, at most six lines; Next and Blocker are mutually exclusive:

```text
[DONE] PROJECT - short result
Result: what changed
Verification: PASS/FAIL and command or evidence reference
Next: one concrete next step
```

Use `[FAIL]`, `[BLOCKED]` or `[INPUT-NEEDED]` when appropriate, with a `Blocker:`
line instead of `Next:`. State that decisions must be made in the main agent
conversation; Telegram replies are never read. Never send credentials, personal
device data or raw logs. Product Telegram features remain separate.

[Workspace router](../../AGENTS.md) - [Workspace setup](../partial-migration-2026-10-23.md).
