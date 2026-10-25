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

Workflow: `ci.yml` (`npm ci`, `npm run test:server`, `npm run build`).
Runner: `tahmin-ligi-docker-1`, label `tahmin-ligi` (`[self-hosted, linux, x64, docker, tahmin-ligi]`),
lifecycle **stop-when-idle**, compose `infra/runner/compose.yml` (start via `scripts/start-ci-runner.ps1`).
GitHub-hosted runners are forbidden. Vercel deployment linkage is retained alongside local Docker CI.

## Workspace quirks

Read the member's verified Gea restrictions before UI edits. Product credentials
stay in its local env files; never log them. Preserve database backups and follow
the README's backup/restore procedure. Use the member's own commands and tests;
workspace checks are not application acceptance.
