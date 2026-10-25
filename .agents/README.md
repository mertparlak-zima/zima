# .agents

Agent-facing assets in the cross-tool `.agents` convention (natively discovered by Codex,
OpenCode, Cursor, Gemini CLI, Amp; consumed by Claude Code through the AGENTS.md skill
index).

## Contents / rules
- `skills/` - the three zima skills. Claude Code does not auto-discover this folder; the
  AGENTS.md skill index points to the exact SKILL.md paths instead.
- No tracked harness-specific files at the zima root - local Claude settings live in
  ignored `.claude/`, never in the Zima index.

## Related
- [../AGENTS.md](../AGENTS.md) skill index
