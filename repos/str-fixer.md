# str-fixer — subtitle toolkit

## Identity

| Field | Value |
|---|---|
| Dir | `projects/str-fixer` |
| GitHub | https://github.com/mertparlak-zima/str-fixer |
| Product | str-fixer |
| Stack | Python: Turkish `.srt` encoding repair, re-sync vs reference, PGS OCR extraction from MKV |
| Default branch | `main` |
| Local state | **irreplaceable** — local-only media in `input/`, `output/`, `samples/`, root `*.srt`; missing directory requires restore, never auto-clone |

## Entry documents

- [README](../projects/str-fixer/README.md)
- [AGENTS.md](../projects/str-fixer/AGENTS.md) — reviewed workspace routing; applied during partial adoption
- Skills in `.claude/skills/` (read fully before each matching task):
  [srt-fixing](../projects/str-fixer/.claude/skills/srt-fixing/SKILL.md) ·
  [srt-resync](../projects/str-fixer/.claude/skills/srt-resync/SKILL.md) ·
  [pgs-extract](../projects/str-fixer/.claude/skills/pgs-extract/SKILL.md)
- Tools: [fix_srt.py](../projects/str-fixer/scripts/fix_srt.py) ·
  [resync_srt.py](../projects/str-fixer/scripts/resync_srt.py) (`--cal`, `--audit`) ·
  [extract_pgs.py](../projects/str-fixer/scripts/extract_pgs.py)

## CI and runner

None by design.

## Workspace quirks

- Subtitle/media content is NEVER committed (`input/`, `output/`, `samples/`, root
  `*.srt` are gitignored local-only).
- Stremio verification rule: the .srt is dragged onto the player while the video plays —
  "Unsupported file" means wrong method, not a PASS.

## Leader notes

- Encoding/mojibake pitfalls on this host are documented in workspace memory — prefer the
  scripts over ad-hoc conversions.

Workspace router: [AGENTS.md](../AGENTS.md).
