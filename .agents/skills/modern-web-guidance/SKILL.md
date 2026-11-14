---
name: modern-web-guidance
description: Modern web platform guidance (GoogleChrome/modern-web-guidance) for web-facing work — panel/UI, CSS, accessibility, performance. Use when implementing, analyzing or reviewing browser-facing code; provides offline expert guides via the modern-web-guidance CLI.
license: Proprietary
compatibility: agentskills.io/v1
metadata: {}
---

# modern-web-guidance — modern web platform guides (CLI wrapper)

## Purpose

Steers web-facing work toward modern, platform-native solutions instead of legacy
patterns, using GoogleChrome's [Modern Web Guidance](https://github.com/GoogleChrome/modern-web-guidance)
(250 modern features, 203 use cases; stewarded by Chrome/Edge/Firefox/MDN). Guides are
bundled with the CLI — queries run locally with no API keys; install/update require
normal npm network access.

## Rules (binding)

- ALWAYS set `DISABLE_TELEMETRY=1` on the invocation line, every time. If you cannot
  set it, do NOT run the CLI — refusal is the enforcement path.
- CLI version is PINNED (`modern-web-guidance@1.0.0`). Never use `@latest`. Bumping the
  pin is a deliberate, reviewed zima change (see Update).
- Scope: web-facing work only (panel UI, CSS, accessibility, browser performance).
  It is NOT an input for backend/architecture/infrastructure decisions.
- Guides are ADVISORY. Repo SKILL.md contracts, tests and acceptance rules always
  win on conflict.
- Volatile features and Origin Trials stay gated: do not set
  `allowVolatileFeatures`/`allowOriginTrials` (`.mwgrc`) without explicit user approval.
- Scan/report outputs never enter commits; write them under `.agent-tmp/<task>/`
  in the TARGET repo, never in zima root.

## Usage

```powershell
# Search guides (PowerShell)
$env:DISABLE_TELEMETRY='1'; npx -y modern-web-guidance@1.0.0 search "dark mode color-scheme"

# Retrieve a guide by id
$env:DISABLE_TELEMETRY='1'; npx -y modern-web-guidance@1.0.0 retrieve dark-mode

# Scan a codebase for legacy patterns — ALWAYS redirect output into .agent-tmp/<task>/
$env:DISABLE_TELEMETRY='1'; npx -y modern-web-guidance@1.0.0 legacy-scan . 2>&1 |
  Tee-Object -FilePath .agent-tmp/<task>/legacy-scan.txt
```

(sh: prefix with `DISABLE_TELEMETRY=1 npx -y modern-web-guidance@1.0.0 ...`)

## Update

1. `npm view modern-web-guidance version` (deliberate check)
2. Update the pin in this file via a reviewed zima change
3. Verify one `search` + `retrieve` round with `DISABLE_TELEMETRY=1` before commit

Workspace skill record: [README](README.md).
