# opencode-cli skill

Workspace convention for delegating zima-leader subagent roles (explorer, worker,
reviewer, independent acceptance) to the local `opencode` CLI (v2.3.0) on the owner's
`zai-coding-plan` GLM subscription, so routine subagent work does not consume primary
leader-session model quota.

## What it covers

- Model split: `zai-coding-plan/glm-5.3` (complex coding, architecture, Tier-3 review,
  acceptance) vs `zai-coding-plan/glm-5.3-flash` (fast exploration, Focused tasks;
  `glm-5.3-highspeed` is not in the active subscription plan).
- Non-interactive PowerShell invocation (`$null | opencode run ... --auto --archived`) so
  runs never hang on stdin EOF or permission prompts.
- Role mapping: `--agent explore` (explorer), `--agent plan` (shell-less reviewer),
  `--agent build` (worker / acceptance; one write worker per repo, scoped via
  `Set-Location <repo>`).
- Verbatim preamble requirement and leader-only gh/push/merge boundaries.

## Rules

- The leader remains the orchestrator; opencode subagents never contact the user.
- Every prompt begins with the zima-leader preamble
  (`../zima-leader/references/preamble.md`), filled per task.
- Prompt files live under `.agent-tmp/<task>/` in the relevant project dir; never committed.

## Links

- Skill contract: [SKILL.md](SKILL.md)
- [zima-leader skill](../zima-leader/SKILL.md) · [Parent skills index](../README.md) ·
  [Workspace router](../../../AGENTS.md)
