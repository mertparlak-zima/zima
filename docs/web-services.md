# Web service exposure — Cloudflare DNS + Coolify domains

Workspace runbook for opening a new web service to the internet. Current model
(2026-11): one **proxied Cloudflare A record** plus one **Coolify HTTPS domain**
per public service. Per-project tunnels, manual certificates and firewall rules
are no longer created; Coolify obtains and renews the certificate automatically.

Read [AGENTS.md](../AGENTS.md) and the target [repo card](../repos/repos.md)
first. For Cloudflare account access and MCP/OAuth tooling see
[cloudflare.md](cloudflare.md). Application rules stay in the member repo.

## Workflow (example: `status.zimastack.com`)

1. **Add the service in Coolify.** Choose the Git repo or a ready-made app;
   enter the environment values it needs.
2. **Create the DNS record in Cloudflare.** Cloudflare → DNS → Add record:
   - Type `A`, Name `<subdomain>` (e.g. `status`),
   - IPv4: the zimastack origin server's address — copy it from an existing
     proxied A record in the Cloudflare dashboard or the server panel. The
     literal origin IPv4 is intentionally never recorded in this public
     repository (issues, docs, logs and screenshots included).
   - Proxy status: **Proxied** (orange cloud).
3. **Add the domain in Coolify.** Coolify → Domains → Add Domain: select HTTPS
   and `<subdomain>.zimastack.com`. In a Compose stack, select the correct
   service and enter the port the container actually listens on (CoinBot's was
   3000 — every service differs; check, don't assume).
4. **Save → Deploy**, then open `https://<subdomain>.zimastack.com` and verify.

## Which service needs a domain?

| Service | What you do |
|---|---|
| Site or API opened to the outside | Proxied A record + Coolify HTTPS domain |
| Postgres, Redis or a worker used only by other containers | No DNS record, no public port — stays on the Coolify internal network |
| Coolify admin panel | Stays on the existing tunnel; do not touch it when adding new apps |

## Notes

- Certificate lifecycle is Coolify's job (automatic obtain + renew). Do not
  hand-create per-project certificates or firewall rules.
- The Cloudflare proxy keeps the origin hidden; keep it that way — no origin
  IPv4 in Git, issues, logs or screenshots.
- Member CI stays on each repo's local self-hosted Docker runners under
  [runner policy](runners.md); this page covers public exposure, not CI.

## Sources and related documents

- [zima issue #8](https://github.com/mertparlak-zima/zima/issues/8) — workflow as specified by the owner
- [Coolify documentation](https://coolify.io/docs)
- [Cloudflare DNS record types](https://developers.cloudflare.com/dns/manage-dns-records/reference/record-types/)
- [Workspace router](../AGENTS.md) · [documentation index](README.md) · [cloudflare.md](cloudflare.md)
