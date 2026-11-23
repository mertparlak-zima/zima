# Publish and operate a web service on Coolify

Workspace runbook for opening a new web service to the internet. Current model
(2026-11): one **proxied Cloudflare A record** plus one **Coolify HTTPS domain**
per public service. Per-project tunnels, manual certificates and firewall rules
are no longer created; Coolify obtains and renews the certificate automatically.

Read [AGENTS.md](../AGENTS.md) and the target [repo card](../repos/repos.md)
first. For Cloudflare account access and MCP/OAuth tooling see
[cloudflare.md](cloudflare.md). Application rules stay in the member repo.

## Connect a new repository

1. Onboard the repository through the [workspace catalog](../repos/repos.md)
   and follow [its runner policy](runners.md). Keep its deployment runbook,
   production image or Compose definition, and secret-free environment
   template in that repository. Identify the production branch, application
   port, internal dependencies, health checks, persistent data and access model.
2. For a private GitHub repository, generate a dedicated deploy key in
   Coolify **Keys & Tokens**. Add only the public key under the repository's
   **Settings → Deploy keys**, with write access disabled. Create a Coolify
   **Private Repository (with deploy key)** application using the Git SSH URL.
   Select the deployment server, branch and build pack. For Docker Compose,
   verify that **Base directory** and **Compose file** resolve to the intended
   file and that relative build contexts reach the source tree.
3. Add runtime secrets under the Coolify application's **Environment
   Variables**. Generate separate values for separate roles. Reserve build-time
   variables for the build inputs required by the application. Keep environment
   values, private keys and webhook secrets out of source, build artifacts and
   logs. If Compose reports an unresolved required value in
   `/artifacts/build-time.env`, check the runtime entry and the installed
   Coolify version's Compose interpolation before changing secret scope.
4. Use health checks for the application and its dependencies. Keep data in
   persistent mounts that survive container replacement. Publish only the
   web service through the proxy. Test the first deployment and login with
   an explicit deploy before turning on the production webhook.

## Cloudflare DNS, HTTPS and Access

1. Create a **proxied A record** for `<subdomain>.zimastack.com` pointing to
   the confirmed VPS. Obtain the address from the server panel or a known
   proxied record on that VPS. Keep it out of Git, logs, issues and screenshots.
2. In Coolify **Domains → Add Domain**, select the web service and enter
   `https`, the bare hostname, and the service's internal listening port
   in their respective fields. Leave the path empty for a whole-site route.
   Coolify obtains and renews the certificate. Use the standard HTTPS URL
   in the browser.
3. For an operator-only service, create Cloudflare Access protection on the
   application hostname. Verify the unauthenticated edge redirects or denies
   access, and test whether the origin is reachable directly from an external
   network. Record the scope of the observation. A proxied DNS record
   provides an edge route and does not enforce access restrictions on an
   independently reachable origin.
4. Deploy and verify HTTPS, health and authorized login. If TLS terminates at
   the proxy and the backend serves HTTP, preserve the external Host and use
   the application's exact public HTTPS origin in CSRF or origin checks.
   Keep cookie protections and verify unexpected origins are rejected.

## Which service needs a domain?

| Service | What you do |
|---|---|
| Site or API opened to the outside | Proxied A record + Coolify HTTPS domain |
| Postgres, Redis or a worker used only by other containers | No DNS record, no public port — stays on the Coolify internal network |
| Coolify admin panel | Stays on the existing tunnel/Access application (`admin.zimastack.com`). For automated GitHub auto-deploy webhooks, a more specific Cloudflare Access self-hosted application (`Coolify GitHub Webhook` on `/webhooks/source/github/events/manual`) with a `bypass` policy allows GitHub event delivery while keeping all other panel endpoints behind authentication. |

## Enable automatic deploys

1. In **Webhooks → Manual Git webhooks → GitHub**, generate a secret and
   copy the provided GitHub webhook URL. In the matching repository's
   **Settings → Webhooks**, enter that URL and the same secret, select
   `application/json`, keep SSL verification enabled, and subscribe to
   **Just the push event**.
2. In Coolify **Advanced → Deployment → Auto deploy**, select **Deploy on
   push (webhooks)**. Verify the existing path-specific Cloudflare Access
   bypass reaches the GitHub webhook while the rest of the admin host stays
   protected. Coolify still verifies signatures on the bypassed path.
3. Keep PR checks on the repository's local self-hosted Docker runner.
   Verify the protected-branch decision for the repository. Where direct
   pushes are allowed, those pushes can trigger deploy independently of PR
   checks.
4. Match one actual push of the configured branch to the GitHub delivery,
   Coolify deployment log, and running commit. A successful GitHub ping
   confirms reachability; the push and deployment confirm the trigger.
   Verify login and state persistence after redeploy. Record cache-enabled
   deployment time, resource usage and observed HTTP interruption if relevant.
   Keep useful previous images and test an application rollback only after
   checking database and storage compatibility.

## Design backups before relying on persistent data

For every stateful service, record the data location, backup method, owning
job, time zone and schedule, retention, off-server destination, and restore
procedure in the member repo's runbook.

| Data | Backup approach |
| --- | --- |
| PostgreSQL or another supported database | Use the engine-aware Coolify database backup when the resource exposes it. For a repo-backed Compose app that only exposes Storage backups, schedule the engine's logical dump separately, such as `pg_dump`. Verify the dump before publishing it and rotate only the job's completed files. |
| Application SQLite or Redis AOF volumes | Use an application-aware snapshot when available. For a Coolify storage archive of a live data directory, coordinate a quiet window or stop the owning container long enough to capture its complete on-disk state. Include journal/WAL sidecars or AOF manifests as applicable. |
| Several stores that must recover together | Quiesce writers and capture a consistent set in one maintenance window. Independent archive schedules protect individual stores. Record the coordinated set and test joint recovery when required. |

In Coolify use **Backups → Storage backups**, choose the specific volume
and set a retention count. Check the time zone shown in the schedule.
Schedule disruptive archives during idle hours and avoid overlapping jobs.
Where the host clock and intended maintenance clock differ, use an explicit
IANA time zone in a host timer where supported, especially across DST
transitions. Local archives share the VPS failure boundary. Configure a
separate destination when the data must survive losing that server.

Run the backup once, inspect the result, and restore it into disposable
containers with separate volumes before relying on it. Confirm application
data and engine integrity. After any coordinated stop, verify the runtime
returns to health. Image rollback preserves the current data and requires
its own check when a migration has run.

## Sources and related documents

- [zima issue #8](https://github.com/mertparlak-zima/zima/issues/8) — workflow as specified by the owner
- [Coolify documentation](https://coolify.io/docs)
- [Compose deployment](https://coolify.io/docs/applications/builds/docker-compose)
- [Manual Git webhooks](https://coolify.io/docs/applications/deployments/manual-webhooks)
- [Database backups](https://coolify.io/docs/databases/backups) · [storage backups](https://coolify.io/docs/core/persistent-storage/storage-mounts/backups)
- [Cloudflare DNS record types](https://developers.cloudflare.com/dns/manage-dns-records/reference/record-types/)
- [Coin Tracker repository card](../repos/coin-tracker.md) — link to a validated workspace deployment and backup example.
- [Workspace router](../AGENTS.md) · [documentation index](README.md) · [cloudflare.md](cloudflare.md)
