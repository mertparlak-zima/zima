# Comment templates (issue comments)

Copy verbatim, fill placeholders. First line marker is REQUIRED (greppable by zima and by
agents). Full policy: `../issues.md`.

## Status (append-only; newest = current state)

```markdown
<!-- zima:status -->
### 📍 Status — 2026-10-19 14:30
Done: <what, with SHAs / PR #>
Next: <single next action>
Blocked: <decision needed / physical action, or "none">
Verification: <state: pending | command + result>
Rules read: <repo rule files read this session (rules-read record)>
```

## Evidence (REQUIRED before close)

```markdown
<!-- zima:evidence -->
### 🔬 Evidence
<command> → <result>
Artifacts: <paths + SHA256>
Conclusion: meets / does not meet acceptance criteria <#>
```

## Decision (mini-ADR)

```markdown
<!-- zima:decision -->
### ⚖️ Decision — 2026-10-19
Context: <one line>
Decision: <what was decided>
Rationale: <why>
```

## Review (leader posts after each review round)

```markdown
<!-- zima:review -->
### 🔍 Review — 2026-10-19
Review: Tier N because <risk class / scope / trivial>
Reviewer lens: <correctness | contract-compliance | ...>
Findings:
- <finding> · severity · file:line · suggestion (Conventional Comments label: issue/suggestion/nitpick, (blocking)/(non-blocking))
evidence_review: <reviewed evidence quality — what the reviewer checked>
test_execution: <run by worker/leader, NOT by the shell-less reviewer — commands + exit codes, or "not re-run">
Verdict: approve | request-changes
```

## Note

```markdown
<!-- zima:note -->
<reference/context: links, run URLs, related issues>
```
