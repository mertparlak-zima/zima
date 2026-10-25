# tahmin-ligi - Tahmin Ligi

[Workspace rules](../AGENTS.md) - [Index](repos.md)

## Identity

- Path: `projects/tahmin-ligi`
- GitHub: https://github.com/mertparlak-zima/tahmin-ligi
- Product: friends' football prediction league; Turkish UI
- Stack: Gea/TypeScript/Vite, Vercel functions, Supabase Postgres, ESPN
- Default branch: `main`
- Local state: **irreplaceable** - `backups/` contains local database snapshots;
  `.env`, `.env.local` and `.vercel/` stay local and never enter Zima's index.

## Entry documents

- [README](../projects/tahmin-ligi/README.md)
- [AGENTS](../projects/tahmin-ligi/AGENTS.md)
- [Gea framework skill](../projects/tahmin-ligi/.agents/skills/gea-framework/SKILL.md)
- [Known upstream compiler issues](../projects/tahmin-ligi/docs/gea-upstream-bugs.md)

## CI and deployment

Vercel deployment; no GitHub Actions/self-hosted runner configured. Existing
Vercel linkage is retained. Workspace adoption does not deploy the application.

## Workspace quirks

Read the member's verified Gea restrictions before UI edits. Product credentials
stay in its local env files; never log them. Preserve database backups and follow
the README's backup/restore procedure. Use the member's own commands and tests;
workspace checks are not application acceptance.
