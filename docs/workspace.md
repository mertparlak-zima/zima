# Current workspace

All six catalogued repositories are active under `projects/`: DriveTrace, Coin Tracker,
Daily Moods, LG Channel List Editor, str-fixer, and Tahmin Ligi. Open the Zima folder
directly in VS Code: Explorer has one Zima root and Source Control lists all seven
repositories. The shared [settings](../.vscode/README.md) enable Git discovery to depth
two. Member repositories remain independent Git boundaries.

Workspace notifications use `scripts/telegram-notify.mjs`. It reads the Telegram token
and chat ID from ignored root `.env`, sends one outbound message, and exits. No workspace
MCP server, listener, broker or reply handling is used. See
[notification rules](telegram/NOTIFICATIONS.md).

## Preserved recovery record

The pre-adoption external recovery copy, verified on 2026-10-21, remains at
`D:\projects\zima\backups\pre-cutover-2026-10-20`. Its redacted receipt is retained at
`.local-state/migration/backup-2ece30b732914ea0b77439aeb7deef7c/receipt.json` (SHA-256
`15982b946e872d78aa0b947224d2591dcbaf1e409d93e2cb6489fa3ee2987ec1`). The recorded
inventory covered 2,577 files, 136 directories, one named NTFS stream, and seven restore
checks; the recovery record does not certify product, device, AVD or CI acceptance.
See [local-state policy](local-state.md) for protected data categories and preservation
rules. Documentation cleanup does not remove local data or recovery copies.

[Workspace router](../AGENTS.md) · [Repository catalog](../repos/repos.md) ·
[Notification policy](telegram/NOTIFICATIONS.md)
