# Codex context, usage limits and handoff

Reusable operator runbook for long Codex work. Start at [AGENTS.md](../AGENTS.md);
see the [docs index](README.md), [issue standard](issues.md) and
[leader protocol](../.agents/skills/zima-leader/SKILL.md).
Checked on 9 November 2026 with native `codex-cli 0.167.0`.

## Two different budgets

| Signal | Meaning | Suitable source |
|---|---|---|
| Active context | Working history available to this thread/model | Client context indicator, interactive `/status`, or this thread's token-usage notification |
| Subscription allowance | Account/profile usage within a returned quota window | `account/rateLimits/read` |
| Cumulative tokens | Activity accumulated over requests/time | Usage history; **not** remaining context or subscription allowance |

Compaction can reduce carried context; it does not restore subscription quota.
Resetting a subscription allowance does not clear a thread's history. Each subagent
has its own context; do not infer its context from the leader's. Use the actual
returned account buckets when tracking shared allowance, rather than adding
agent token estimates or assuming a fixed number of messages.

## Check context without confusing it with quota

In a supported interactive client, `/status` reports context/usage information;
`/compact` compacts the current conversation. These are **client slash commands**,
not shell commands: `codex /status` is not the equivalent. Follow the enabled
computer-use policy; do not automate a prohibited Codex/terminal UI to enter them.

For an integration already receiving events for the intended thread, the documented
`thread/tokenUsage/updated` notification carries `threadId`, `turnId` and `tokenUsage`.
The locally generated 0.167.0 schema exposes `tokenUsage.last`, `tokenUsage.total`
and nullable `tokenUsage.modelContextWindow`; each breakdown includes `totalTokens`.
Use the latest matching thread/turn observation. `total` is cumulative; do not
divide it by the model window and call that context occupancy. A ratio using
`last.totalTokens` and a valid `modelContextWindow` is only a diagnostic estimate,
not a promise to match client-reserved capacity or compaction thresholds.

If the client exposes no context metric/event, say **context usage unavailable**.
A fresh standalone app-server cannot reconstruct the active GUI thread's context
merely by reading account quota. Do not create/resume unrelated threads, scan
transcripts, or hard-code a model window to manufacture a percentage.

Verify local schema names when the installed version differs:

```powershell
codex --version
codex app-server generate-json-schema --out .agent-tmp/codex-usage/protocol
# Inspect v2/ThreadTokenUsageUpdatedNotification.json in that task directory.
```

## Read real allowance through the native CLI

Prefer an available read-only connector exposing the same metric. Otherwise use
the existing authenticated native Codex CLI under the intended OS user/profile.
The example below uses its default profile; establish that this is the intended
account/profile before attributing its quota to the active client. Never move
`HOME`/`CODEX_HOME`, copy auth/config files, or print credentials to repair access.

The verified fallback is `codex app-server --stdio`, with this handshake:
`initialize` request, `initialized` notification, then `account/rateLimits/read`.
No thread or model turn is needed. `app-server proxy` timed out in the observed
session; that was not evidence of an invalid login. Try the standalone read
instead of repeatedly retrying the proxy or reauthorizing a healthy account.

Save the following as `.agent-tmp/codex-usage/read-quota.mjs` in the target repo.
It prints only observation time and numeric quota windows, discards native stderr
and unrelated protocol messages, and exits instead of leaving a monitor running.

```javascript
import { spawn } from 'node:child_process'
import { createInterface } from 'node:readline'

if (!process.argv[2]) throw new Error('Native Codex executable path required')
const child = spawn(process.argv[2], ['app-server', '--stdio'], {
  windowsHide: true, stdio: ['pipe', 'pipe', 'pipe'],
})
const lines = createInterface({ input: child.stdout })
let finished = false
const timer = setTimeout(() => finish(null), 20000)
function finish(buckets) {
  if (finished) return
  finished = true
  clearTimeout(timer)
  lines.close()
  child.stdin.end()
  child.stdout.resume()
  const shutdown = setTimeout(() => child.kill(), 2000)
  shutdown.unref()
  child.once('exit', () => clearTimeout(shutdown))
  console.log(JSON.stringify({ observedAt: new Date().toISOString(),
    status: buckets ? 'observed' : 'unavailable', buckets }))
  process.exitCode = buckets ? 0 : 1
}
function window(value) {
  if (!value || !Number.isFinite(value.usedPercent) ||
      value.usedPercent < 0 || value.usedPercent > 100 ||
      !Number.isSafeInteger(value.windowDurationMins) ||
      value.windowDurationMins <= 0) return null
  return { usedPercent: value.usedPercent,
    remainingPercent: 100 - value.usedPercent,
    windowDurationMins: value.windowDurationMins,
    resetsAt: Number.isSafeInteger(value.resetsAt) ? value.resetsAt : null }
}
const send = value => child.stdin.write(JSON.stringify(value) + '\n')
child.stderr.on('data', () => {})
child.on('error', () => finish(null))
child.stdin.on('error', () => finish(null))
child.on('exit', () => { if (!finished) finish(null) })
lines.on('line', line => {
  try {
    const message = JSON.parse(line)
    if (message.id === 1) {
      if (message.error || !message.result) return finish(null)
      send({ method: 'initialized' })
      send({ method: 'account/rateLimits/read', id: 2 })
    }
    if (message.id !== 2) return
    if (message.error || !message.result) return finish(null)
    const raw = message.result.rateLimitsByLimitId ??
      { codex: message.result.rateLimits }
    if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return finish(null)
    const buckets = Object.entries(raw).slice(0, 32).map(([id, value]) => ({
      id: /^[a-z0-9_.-]{1,80}$/i.test(id) ? id : 'unknown',
      primary: window(value?.primary), secondary: window(value?.secondary),
    }))
    finish(buckets.some(b => b.primary || b.secondary) ? buckets : null)
  } catch { finish(null) }
})
send({ method: 'initialize', id: 1, params: {
  clientInfo: { name: 'zima_usage_reader', version: '1.0.0' },
} })
```

Windows PowerShell invocation (Node 18+ and an installed native CLI):

```powershell
New-Item -ItemType Directory -Force .agent-tmp/codex-usage | Out-Null
# Save the JavaScript above, then resolve the existing executable:
$codexExecutable = (Get-Command codex.exe -ErrorAction Stop).Source
node .agent-tmp/codex-usage/read-quota.mjs $codexExecutable
```

Use the normal tool approval path if the sandbox cannot access the native profile
or network. Do not weaken the sandbox/config or invent a replacement credential.
An unavailable result is not zero usage, zero remaining quota, or a failed login.
If no working read path exists, disclose the missing metric and keep checkpoints;
elapsed wall time and local token counts are not substitutes.

Interpret each returned window by `windowDurationMins`: a five-hour window is
300 minutes **when returned**, not necessarily always `primary`. `usedPercent`
is used quota; remaining is `100 - usedPercent`. `resetsAt` is Unix seconds, not
milliseconds. Inspect other relevant buckets/windows too; do not assume the
largest remaining value is the applicable limit. Missing windows stay unknown.
Keep only sanitized numeric observations in ignored task evidence; do not retain
raw auth/protocol output, account identities, reset-credit details or tokens.
The helper never redeems resets/credits, starts a turn, changes login, or sends
an owner email.

## Keep work resumable before a limit

When the owner requests allowance monitoring/handoff, agree or state a reserve
before large work. A practical default is to prepare the handoff by about 20%
remaining, earlier for a large review/build; the owner's explicit threshold wins.
Read quota after significant phases and at most 15 minutes apart during long work;
check more frequently near the reserve. Include the observation time. Do not
promise automatic monitoring if no usable read path is available.

Keep the current checkpoint ready before the reserve: verified Git root/branch/SHA,
dirty paths/source hashes, what passed/failed/not run, exact logs/manifests, review
scope, pending CI IDs, unresolved decisions and the single next command/step.
Context compaction is another reason to refresh that checkpoint, not permission
to restart work or reinterpret missing state.

On the owner's requested stop/low-allowance handoff, stop new implementation,
interrupt active model agents, and publish the complete current state to the
**target repo's** managed issue plus ignored `.agent-tmp/<task>/` resume notes.
Follow [parked-decision rules](../AGENTS.md#startup-protocol) if an actual decision
is needed. Do not cancel CI or stop/restart shared runners merely to finish a
handoff; record existing jobs and follow [runner policy](runners.md).
Keep failures honest and the task open when required gates remain. Only the leader
sends the completion/blocking [Telegram notification](telegram/NOTIFICATIONS.md).
An owner-requested pause/stop requires fresh continuation; compaction alone does not.

## Sources and validation boundary

- [Official developer commands](https://learn.chatgpt.com/docs/developer-commands?surface=cli): `/status` and `/compact`.
- [Official app-server protocol](https://learn.chatgpt.com/docs/app-server): initialization, quota reads and thread usage notifications.
- Local generated `ThreadTokenUsageUpdatedNotification` schema, codex-cli 0.167.0,
  and the native read-only quota probe were checked on 9 November 2026. Schema export
  validates field availability; it is not a live reading of another thread's context.
- No personal quota value, credential store, thread transcript or machine-specific
  executable path belongs in this document or Git. No background service is required.
