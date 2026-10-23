# JARVIS Telegram MCP agent instructions (one-way contract)

This is the pinned-path stub for the common Telegram contract. The full specification
lives in [`docs/telegram/NOTIFICATIONS.md`](docs/telegram/NOTIFICATIONS.md) (schema,
when-to-notify matrix, enforcement map, park protocol). Read it before sending anything.

## One-way only

- Permitted tool: `telegram_send_notification` (plus `telegram_connection_status` for
  diagnostics). Fixed message schema — see the full spec.
- Prohibited by policy: `telegram_ask_user` and session mailbox tools
  (`telegram_session_register/receive/ack/reply`). Effective settings-level denial is
  tested during A2; it is not an established A1 fact. Blocking decisions use park files,
  never Telegram replies.

## Removed mechanisms — operational notes

- Preserve the current broker's single polling ownership. Relocation and real ownership
  checks happen in A2; do not run another poller or infer product-bot identity.
- Agents never consume Telegram replies. Decision-needed notifications carry
  the footer "Reply here is not read. Decision is applied at the next session start."
- Do not modify `.jarvis-telegram-mcp/` sources without an explicit JARVIS maintenance task.

## Local server configuration

- Server: `C:\Users\mertp\Desktop\projects\zima\.jarvis-telegram-mcp\server.mjs`
  (local Node.js stdio MCP; bot `@BosAdam_bot`).
- Secrets (`TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`): Windows USER environment only —
  never read, printed, logged, or copied into any file, message, commit or config.
- Transport: free Bot API over HTTPS. Personal Telegram session / MTProto / webhooks /
  VPS: prohibited. The server is deliberately narrow (verify, send, no admin surface).
- If the tool is unavailable, start a new agent/terminal session; diagnose with
  `telegram_connection_status`; never debug by dumping secrets.
