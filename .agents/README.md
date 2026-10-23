# .agents

Agent-facing assets in the cross-tool `.agents` convention (natively discovered by Codex,
OpenCode, Cursor, Gemini CLI, Amp; consumed by Claude Code through the AGENTS.md skill
index).

## Contents / rules
- `skills/` - the three zima skills. Claude Code does not auto-discover this folder; the
  AGENTS.md skill index points to the exact SKILL.md paths instead.
- No harness-specific files (no CLAUDE.md, no .claude/) at the zima root - harness
  bridges live in USER-level configs, never in this repo.

## Related
- [../AGENTS.md](../AGENTS.md) skill index
