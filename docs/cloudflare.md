# Cloudflare MCP and deployment tooling

Workspace runbook for Cloudflare tasks across agents and sessions.
Read [AGENTS.md](../AGENTS.md), the target [repo card](../repos/repos.md), and that
repo's rules first. Product architecture and application rules remain in the member repo.

## Connection identity and reuse

| Item | Value |
|---|---|
| Codex server name | `cloudflare-api` |
| Official Streamable HTTP endpoint | `https://mcp.cloudflare.com/mcp` |
| Authentication | Native client OAuth; user chooses the account and granted permissions |
| Codex configuration | User-profile `~/.codex/config.toml`; not a tracked zima file |
| Secret storage | The MCP client's native authorization store; never zima or a member's Git history |

Cloudflare's unified server exposes API discovery/execution and documentation tools
(`search`, `execute`, `docs` in the current server). Use the actual tool schemas;
do not invent method names or assume every Cloudflare permission was granted.

New Codex sessions under the **same OS user and Codex profile** can load the existing
configuration and saved OAuth grant. A repository clone does not install the server,
transfer credentials, or connect a different machine/user/client. Claude/OpenCode or
another MCP client needs its own supported HTTP configuration and native OAuth flow;
do not copy Codex's credential files into it.

## Start every Cloudflare task with a live check

1. Inspect the active tool inventory for `cloudflare-api` tools. A config entry or an
   earlier successful login does not prove this particular session loaded the tools.
2. If absent, check only redacted connection metadata. In PowerShell:

   ```powershell
   $cloudflareServers = codex mcp list --json | ConvertFrom-Json
   $cloudflareServers | Where-Object name -EQ 'cloudflare-api' |
       Select-Object name, enabled, auth_status
   ```

   Never print the full JSON/config: other MCP entries or headers can contain secrets.
   If the sandbox cannot access the native user profile, use the approved user-context
   CLI. Do not repoint HOME/CODEX_HOME or duplicate config/auth files as a workaround.
3. If configured and authorized but tools are missing, reload/reconnect the MCP client
   or start a fresh session, then inspect its tool inventory again. Do not remove a
   healthy connection or log it out merely to refresh one session.
4. With tools available, use API discovery to find a read-only account/resource-list
   operation, then execute it. Confirm the task's account and expected project resource
   before a mutation. If multiple accounts are possible and context cannot select one,
   the leader asks the user in the main conversation.
5. Distinguish configured, OAuth-authenticated, tools-loaded, and operation-authorized
   states in reports. A read probe does not prove write permission. If unavailable,
   report the exact missing state; use authorized Wrangler/API tooling when sufficient.

## Install or reauthorize only when needed

Check for an existing entry first. For an authorized setup on a new profile:

```powershell
codex mcp add cloudflare-api --url https://mcp.cloudflare.com/mcp
```

The CLI may immediately start OAuth. Complete that flow once; use a separate login
only if the saved connection needs authentication:

```powershell
codex mcp login cloudflare-api
```

The user signs in and selects account/permissions on Cloudflare's authorization page.
Never request a password, callback authorization code, access token or refresh token
in chat. Do not persist an authorization URL/state as a reusable setup link; it expires.
Preserve unrelated MCP entries and client settings.

## Carry out the authorized task

- Use discovery/documentation tools for current endpoint schemas and platform behavior;
  use execution tools for account/resource operations covered by the user's task.
- Pin the account, environment and resource identity in the operation context. Read
  existing state before changing it; never replace an unrelated Worker/database.
- A task requesting development setup authorizes its necessary reversible setup steps;
  do not request confirmation again for each one. An installed MCP does not extend that
  task to unrelated production, billing, deletion or destructive data migrations.
- If a requested operation needs permissions not granted, identify the missing product
  permission and complete the client's normal authorization flow. Do not widen unrelated
  scopes or reuse another project's credentials.
- Use Wrangler for reproducible project builds, deployments and versioned D1 migrations
  when the repo's workflow calls for it. MCP account/resource management and Wrangler's
  native authentication are separate; do not extract MCP tokens to feed the CLI.
- CI build/test/deploy jobs stay on each repo's own local self-hosted Docker runner
  under [runner policy](runners.md). Cloudflare hosts the application runtime; do not
  enable Cloudflare-hosted Builds or hosted-runner fallbacks for workspace CI.
- Use product-approved secret stores/Worker secrets and CI secrets where applicable.
  Cloudflare credentials never go into zima `.env` (its credential exception is Telegram
  only), tracked config, issue bodies, logs, screenshots or agent prompts.
- Record non-secret resource identities, commands and measured outcomes in the target
  issue under [issue rules](issues.md). The leader performs GitHub writes and user contact.

## Verified setup and limits — 2026-10-26

The owner requested installation and completed the official OAuth flow. Codex CLI
reported successful login; redacted status showed `cloudflare-api`, enabled, OAuth,
and the official hostname. The existing running session still had no Cloudflare tools
in its inventory. No Cloudflare product API call or resource mutation was verified in
that session. A later session must perform the live checks above before claiming access.

This observation is a dated setup record, not a guarantee that a grant remains valid
or that all product permissions exist. Review and verification evidence belongs to
[zima issue #2](https://github.com/mertparlak-zima/zima/issues/2).

## Sources and related documents

- [Cloudflare's official MCP servers](https://developers.cloudflare.com/agents/model-context-protocol/cloudflare/servers-for-cloudflare/)
- [Official Cloudflare API MCP implementation](https://github.com/cloudflare/mcp)
- [Official Codex MCP configuration](https://developers.openai.com/codex/mcp/)
- [Wrangler installation and updates](https://developers.cloudflare.com/workers/wrangler/install-and-update/)
- [Workspace router](../AGENTS.md) · [documentation index](README.md) · [workspace README](../README.md)
- [Coin-tracker card](../repos/coin-tracker.md) — first consumer; application rules remain in its repo.
