# .agents/skills

The workspace-level skills (few by design - every skill costs startup context in
harnesses that auto-load them):

- `zima-leader/` - spawn/isolation/review-tier protocol (+ references: verbatim preamble,
  workspace-context block inserted into member repos).
- `zima-sync/` - manifest hygiene, sync-vs-update semantics, verify triage.
- `zima-new-repo/` - onboarding do/don't checklist.
- `modern-web-guidance/` - modern web platform guides CLI wrapper (telemetry off,
  web-facing scope, advisory only; adopted 2026-11-14).
- `drizzle/` - official Drizzle ORM & Drizzle Kit (`1.0.0-rc.5`, rev 15) workflow skill
  for `schema.ts`, `drizzle.config.ts`, migrations (`generate`/`push`/`pull`/`up`/`check`),
  and `missing_hints` resolution (adopted 2026-11-14).
- `cypress-author/`, `cypress-docs/`, `cypress-explain/`, `cypress-tap/` - official Cypress
  AI toolkit (`cypress-io/ai-toolkit`) skills for authoring, explaining, documenting, and
  live-inspecting Cypress E2E & Component tests in TypeScript (adopted 2026-11-15).
- `opencode-cli/` - delegate subagent roles (explorer/worker/reviewer/acceptance) to the
  local `opencode` CLI (v2.3.0) on `zai-coding-plan/glm-5.3` (`glm-5.3-flash` for fast read
  tasks) to save primary-model quota (adopted 2026-11-14).

## Contents / rules
- One folder per skill with a `SKILL.md` (agentskills.io spec: six frontmatter fields;
  tool-specific keys under `metadata`).
- Telegram and runner procedures are DOCS, not skills: `docs/telegram/NOTIFICATIONS.md`
  and `docs/runners.md` (pointers live in the AGENTS.md index).
- Per-repo skills stay in their repos (indexed by cards); never mirrored here.

## Related
- [../../AGENTS.md](../../AGENTS.md) - [../../docs/issues.md](../../docs/issues.md)
