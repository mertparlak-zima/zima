# modern-web-guidance skill

Thin workspace wrapper around GoogleChrome's Modern Web Guidance CLI so agents query
expert, eval-backed web-platform guides (modern CSS, dialogs/popover, accessibility,
performance, view transitions) during web-facing work instead of defaulting to legacy
patterns from training data. CLI version is pinned (`1.0.0`); guides are bundled with
the package (queries local, no API keys; install/update use npm network).

## Why a wrapper (not the vendor installer)

The vendor wizard targets Claude/Codex/Cursor plugin formats; zima runs its own skill
layout. This folder wraps the CLI with zima binding rules and stays vendor-format-free.

## Rules

- `DISABLE_TELEMETRY=1` on every invocation (Google collects anonymous usage otherwise).
- Web-facing scope only; advisory content — repo contracts win.
- Volatile/Origin-Trial guides stay gated; no `.mwgrc` opt-ins without user approval.
- Outputs to `.agent-tmp/<task>/`, never committed.

## Links

- Source/upstream: https://github.com/GoogleChrome/modern-web-guidance (Apache-2.0 code,
  CC-BY-4.0 guides)
- Docs: https://developer.chrome.com/docs/modern-web-guidance
- Skill contract: [SKILL.md](SKILL.md) · Adopted: 2026-11-14 (coin-tracker platform
  refactor planning; baseline scan feeds its B-track UX work)
