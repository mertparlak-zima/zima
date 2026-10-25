# docs/telegram

The workspace Telegram contract lives here.

## Contents / rules
- `NOTIFICATIONS.md` - outbound command, ignored `.env` configuration, message
  format and notification timing. Questions stay in the main agent conversation.
- The sender is [telegram-notify.mjs](../../scripts/telegram-notify.mjs).
  No broker, MCP server or incoming-message runtime is required.

## Related
- [../issues.md](../issues.md) - [../../AGENTS.md](../../AGENTS.md)
