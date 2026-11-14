# drizzle skill

Official Drizzle ORM & Drizzle Kit agent skill (`drizzle-kit@1.0.0-rc.5`, revision 15),
adopted at the workspace level (and in member repos using Drizzle such as `coin-tracker`)
so agents follow canonical Drizzle schema, query, `drizzle.config.ts`, `generate`/`push`/`pull`/`up`/`check`
JSON-envelope workflows, and `missing_hints` resolution rules.

## Contents

- [SKILL.md](SKILL.md) — entry point, staleness check (`drizzle-kit skills version`), and surface selection (`--output json` / SDK).
- [migrations.md](migrations.md) — `defineConfig`, `generate` vs `push`, dialect quirks (`sqlite`, `postgresql`, etc.), snapshot format, branch merges, and `drizzle-kit up`.
- [generate.md](generate.md) — offline SQL migration generation via CLI (`--output json`) and SDK.
- [push.md](push.md) — direct schema application and `confirm_data_loss` handling.
- [pull.md](pull.md) — database introspection into Drizzle `schema.ts` and `relations.ts`.
- [hints.md](hints.md) — resolving `missing_hints` (`rename_or_create` and `confirm_data_loss`).
- [output-modes.md](output-modes.md) — `--output json` vs `--output text` and interactivity rules.
- [responses-and-errors.md](responses-and-errors.md) — discriminated-union response envelopes and error codes.

## Update

Run `npx --no-install drizzle-kit skills` inside the member repo that owns `drizzle-kit`
(or unpack the pinned `drizzle-kit` package and sync `skills/drizzle/*` here) whenever
`drizzle-kit skills version` exceeds `metadata.revision` in [SKILL.md](SKILL.md).

## Related

- [Parent skills index](../README.md) · [Workspace router](../../../AGENTS.md)
- Docs: https://orm.drizzle.team/docs/drizzle-kit-skills
