---
name: zima-leader
description: Leader protocol for the zima workspace — use when spawning any subagent, assigning a review tier, running a cross-repo task, or deciding how a task is decomposed. Read fully BEFORE the first spawn in a session.
license: Proprietary
compatibility: agentskills.io/v1
metadata: {}
---

# zima-leader — spawn, isolation and review protocol

You (the main-session agent) are the LEADER. Subagents report to you; you are the only
channel to the user (chain of command, decision 2026-10-16). Telegram is leader-only and
one-way (`docs/telegram/NOTIFICATIONS.md`).

## 1. Task sizing (decide FIRST — no ceremony for trivia)

| Size | Definition | Execution |
|---|---|---|
| TRIVIAL | no behavior/policy change: typo/format, generated-file regen, read-only analysis | Leader does it directly. No spawn. Repo rules still read (rules-read record). |
| NORMAL | typical code change | Leader + 1 worker. Review per tier below. |
| RISKY | risk class touched, large scope, or cross-repo | Full taxonomy + Tier 3 review. |

## 2. Roles

- **explorer** — read-only across repos; parallel-safe; no file writes, no git state changes.
- **worker** — write-scoped to ONE repo; exclusive (no other write-subagent in the same
  repo concurrently).
- **reviewer** — shell-less: reads diff/criteria/evidence, runs NO commands.

Parallelism comes from read-only exploration and cross-repo fan-out — never from parallel
writers in one repo. Worktrees, if needed, are created by the LEADER only.

## 3. Spawn preamble (verbatim, every spawn)

Copy from [references/preamble.md](references/preamble.md) — do not paraphrase. Fill the
`<repo>` absolute path and the task block.

## 4. Review tiering (leader decides; record "Review: Tier N because ...")

Self-check, in order: (1) no behavior OR policy change → **T0** (no review; leader 30-second diff
glance). (2) Risk class touched — evidence/data integrity, data contracts, CI policy,
device lanes, security/secrets, money/PII → **T3**. (3) Diff >~300 lines or cross-repo →
**T3**. (4) ≤~50 lines + single file + existing test covering behavior, passing → **T1**
(leader self-review against the checklist; record it). (5) Otherwise → **T2** (one
independent reviewer). When unsure, go one tier UP. "It will be merged" is NEVER a Tier 3
reason. Repos may require stricter tiers (never looser).

Instructions, workflow rules and security documentation change behavior too. A textual
change affecting a risk class is T3, even when it changes no executable code.

- **T3**: two independent reviewers with DIFFERENT lenses (e.g. correctness vs
  contract-compliance); the first reviewer's findings are withheld from the second; the
  leader's implementation rationale is NEVER given to reviewers; output ≤40 lines
  (finding/severity/file:line/suggestion).
- Reviewers distinguish `evidence_review` (what they checked) from `test_execution` (run
  by worker/leader, not by the shell-less reviewer).
- Post the review summary as a `<!-- zima:review -->` comment (leader-only gh write).

## 5. Cross-repo tasks

One PRIMARY repo (its rules, issue log, CI and evidence conventions govern) + secondary
repos touched read-first. Before writing in a secondary repo, read its card + its own
rules and check its runner label. Cross-repo SHAs are listed in the primary issue.
If multiple repos need device/AVD/engine resources, the TASK holds the lock, not each repo.

## 6. Context discipline

- Subagent reports: ≤~30 lines, evidence by path reference, never pasted logs.
- Workers write artifacts to the filesystem and return lightweight references.
- At every phase transition (implement → review → CI → close), re-read the specific gate
  section of the governing doc (compaction can silently evict rules read at session start).

## 7. Task log

Every NORMAL/RISKY task records in the issue status comment: target repo, tier decision,
rules-read record (which repo rule files were read), and the review outcome. Do not start
implementation before the rules-read record exists.

Bootstrap exception: before zima's initial history/managed issue exists, keep that record
in `.agent-tmp/<task>/task.md`, then preserve the final audit in `docs/` before commit.
Creating or posting an issue still follows the user's authorization and is leader-only.
