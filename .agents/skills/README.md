# .agents/skills

The three workspace-level skills (few by design - every skill costs startup context in
harnesses that auto-load them):

- `zima-leader/` - spawn/isolation/review-tier protocol (+ references: verbatim preamble,
  workspace-context block inserted into member repos).
- `zima-sync/` - manifest hygiene, sync-vs-update semantics, verify triage.
- `zima-new-repo/` - onboarding do/don't checklist.

## Contents / rules
- One folder per skill with a `SKILL.md` (agentskills.io spec: six frontmatter fields;
  tool-specific keys under `metadata`).
- Telegram and runner procedures are DOCS, not skills: `docs/telegram/NOTIFICATIONS.md`
  and `docs/runners.md` (pointers live in the AGENTS.md index).
- Per-repo skills stay in their repos (indexed by cards); never mirrored here.

## Related
- [../../AGENTS.md](../../AGENTS.md) - [../../docs/issues.md](../../docs/issues.md)
