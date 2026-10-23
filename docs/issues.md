# Task & Issue standard

The standard lives HERE; the issues live in the repo they belong to — a member repo's work
in that repo (`github.com/mertparlak-zima/<repo>/issues`), zima's own development in the
zima repo. No cross-posting: link with `Refs #N` instead. `zima.ps1 issues [-R <repo>]`
reads/aggregates (zima included by default); every write goes to an explicit `-R` target
and is performed by the LEADER only (never a subagent).

## Managed vs legacy

A managed issue body starts with the marker `<!-- zima-issue:v1 -->`. An issue WITHOUT the
marker is LEGACY: read-only for agents — never edit its body, labels, milestone or title,
and never close it. New work on a legacy topic opens a new managed issue whose References
section says `Supersedes #N`.

Repos with their own issue governance keep it: drive-trace issues use the
`<!-- drive-trace-implementation-form:v1 -->` form, which SATISFIES zima's minimum
contract (managed marker + acceptance criteria + close-evidence). The repo's own form wins
there; `zima issues` parses both.

## Issue body template (docs/templates/issue.md)

Fixed headings — models parse structured headings better than prose; put the exact
verification command FIRST in Verification Plan. Optional `## Boundaries` (always /
ask-first / never) for risk-carrying tasks. Metadata block: Owner, Category
(feature|bug|chore|docs), Priority (P0-P3), Milestone.

## Comment types (first line marker, greppable)

| Type | Marker + header | Content |
|---|---|---|
| Status | `<!-- zima:status -->` + `### 📍 Status — YYYY-MM-DD HH:MM` | Done (SHAs/PR#), Next, Blocked/decisions needed, verification state. Append-only log; the NEWEST status comment is the current state ("where we left off"). Written at start, at meaningful checkpoints, and when parking. |
| Evidence | `<!-- zima:evidence -->` | Commands + results + artifact paths/SHA256. REQUIRED before close (drive-trace's own evidence marker satisfies this). |
| Decision | `<!-- zima:decision -->` | Decision + rationale + date (mini-ADR); repo-wide significance also goes into the repo's docs per its rules. |
| Review | `<!-- zima:review -->` | `Review: Tier N because ...` + findings (finding/severity/file:line/suggestion, Conventional Comments labels: issue/suggestion/nitpick + (blocking)/(non-blocking)). Reviewer states `evidence_review` and `test_execution` SEPARATELY — a shell-less reviewer does not run tests. |
| Note | `<!-- zima:note -->` | Reference/context notes (links, run URLs). |

## Workflow (tracked via status comments; no GitHub Projects)

`OPEN (form valid) → IN-PROGRESS (status comment) → IN-REVIEW (review comment) →
VERIFY/CI → CLOSED (evidence comment + merged PR)`.

Safe linking: the PR BODY carries `Closes #N`. Commit messages use `Refs #N` ONLY —
commit-message keywords (`fix: #N`) auto-close at merge time before evidence review and
are FORBIDDEN.

## Milestones

Milestones are roadmap phases/releases: at most 2 open per repo (active + next); every
planned issue gets a milestone at triage (Backlog = none); milestone titles are stable
(renames break references).

## Labels

Text-first: the Metadata block is authoritative. Labels are optional; where a repo has an
existing label set, use the mapping documented in that repo's card (never rename or delete
existing labels — legacy issues depend on them). New repos start with a minimal taxonomy
(type: feature/bug/chore/docs × risk: standard/high) via the roadmap-JSON bootstrap
pattern (see `zima-new-repo` skill; pattern reference: coin-tracker
`scripts/github-roadmap.json` + `scripts/bootstrap-github.mjs`).
