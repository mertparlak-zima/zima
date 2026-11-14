---
name: opencode-cli
description: Delegate zima-leader subagent roles (explorer, worker, reviewer, independent acceptance) to the local opencode CLI (v2.3.0) on the owner's zai-coding-plan GLM subscription to conserve primary-model quota — non-interactive PowerShell invocation, model selection, agent mapping, and leader-only boundaries.
license: Proprietary
compatibility: agentskills.io/v1
metadata: {}
---

# opencode-cli — quota-saving subagent delegation

Run subagent work through the local `opencode` CLI (v2.3.0) instead of spending primary
leader-session quota. The CLI bills the owner's `zai-coding-plan` GLM subscription — a
separate quota pool. The leader stays the orchestrator: gh writes, pushes, merges and
Telegram remain leader-only (§4).

## 1. Model selection

| Model | Use for |
|---|---|
| `zai-coding-plan/glm-5.3` | complex coding, architecture, Tier-3 review, independent acceptance |
| `zai-coding-plan/glm-5.3-flash` | fast exploration, Focused tasks |

Default to `glm-5.3`; drop to `flash` only for read-heavy, low-risk work (`glm-5.3-highspeed` is not included in the owner's subscription plan — do not use it).

## 2. CRITICAL — non-interactive PowerShell invocation

`opencode run` waits for EOF on stdin and may sit at interactive prompts. ALWAYS pipe
`$null` into the command and pass `--auto --archived`:

```powershell
$null | opencode run -m zai-coding-plan/glm-5.3 --agent <build|explore|plan> --auto --archived --title <task> <prompt>
```

- `$null |` closes stdin immediately — without it the run HANGS.
- `--auto` auto-approves permissions not explicitly denied.
- `--archived` keeps scripted sessions out of session lists.
- `--title <task>` names the session for audit.

For long prompts containing quotes/newlines, do NOT inline them. Write the prompt to
`.agent-tmp/<task>/prompt.md` (in the relevant project dir) and pass its content:

```powershell
$null | opencode run -m zai-coding-plan/glm-5.3 --agent build --auto --archived --title <task> (Get-Content -Raw .agent-tmp/<task>/prompt.md)
# or attach it as a file:
$null | opencode run -m zai-coding-plan/glm-5.3 --agent build --auto --archived --title <task> -f .agent-tmp/<task>/prompt.md
```

## 3. Role → agent mapping (zima-leader §2)

| zima-leader role | opencode agent | Notes |
|---|---|---|
| explorer (read-only) | `--agent explore` | parallel-safe; no writes, no git state changes |
| reviewer (shell-less / edit-denied) | `--agent plan` | prompt MUST explicitly instruct: run NO shell/test commands |
| worker / independent-acceptance | `--agent build` | scope with `Set-Location <repo>` first; max 1 write worker per repo at a time |

Worker example (prompt file lives in the target repo's `.agent-tmp`):

```powershell
Set-Location C:\Users\mertp\Desktop\projects\<repo>
$null | opencode run -m zai-coding-plan/glm-5.3 --agent build --auto --archived --title <task> (Get-Content -Raw .agent-tmp\<task>\prompt.md)
```

## 4. Preamble and leader-only boundaries

- EVERY prompt passed to `opencode run` MUST begin with the verbatim preamble from
  `.agents/skills/zima-leader/references/preamble.md` (fill `<repo>` and the task block;
  do not paraphrase).
- `gh` writes and `git push` / `gh pr merge` remain LEADER-ONLY unless explicitly
  delegated in a controlled step that names the exact command — never by default.
- Review tiers (zima-leader §4) are unchanged: Tier-3 review and independent acceptance
  run on `zai-coding-plan/glm-5.3`, never on `flash`.
- Reports still follow context discipline: ≤~30 lines, evidence by path, no pasted logs.

## Related

- [zima-leader](../zima-leader/SKILL.md) — roles, tiers, verbatim preamble
- [README.md](README.md) — folder doc
