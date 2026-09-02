# GLD-INFRA-0012 — Codex SEO skill suite

Status: `applied`

- Owner: Gildra project owner
- Environment: shared Codex skill catalogs for `debian` and `gildra-admin`
- Risk: R1, third-party instruction files and catalog links only; no application
  or production service change
- Prepared: 2026-09-02
- Secret material: none

## Source pin

The public MIT repository `AgriciDaniel/codex-seo` was reviewed read-only and
pinned to commit `9a4a0b9e3c44eec2ceedcc21d10659427ee3bc1c` (tag
`v1.9.6-codex.5`). It provides one orchestrator and 26 specialist SEO
workflows. The lock manifest records all 27 standalone `SKILL.md` entries.

The orchestrator is exposed as `codex-seo` because the catalog already contains
an unrelated `seo` skill from `addyosmani/web-quality-skills`. Its copied
frontmatter uses the collision-free `codex-seo` name; the upstream source path
and immutable revision remain recorded in `.gildra-source.json`.

## Installation

The suite was installed into both user catalogs:

- `/home/debian/.local/share/gildra-agent-skills/catalog`
- `/home/gildra-admin/.local/share/gildra-agent-skills/catalog`

The 27 entries are linked into each user's `~/.agents/skills` and
`~/.codex/skills` roots, so Codex discovers them after its next restart. The
optional DataForSEO, Firecrawl, Banana/Gemini, and Google integrations were not
bootstrapped: they require separate credentials or MCP configuration and are
reported by the suite as setup-required until explicitly configured.

The skill manager now handles a source path whose catalog name is different
from the path basename, preventing the existing `seo` entry from being
overwritten during future idempotent installs.

## Verification

- `manage-agent-skills.py --check-manifest` passed with 335 installable skills.
- `manage-agent-skills.py --check-catalog` passed for both user catalogs.
- Every new entry has valid `SKILL.md` frontmatter, a source marker, and an
  immutable upstream SHA.
- Both users have all 27 new active links; the pre-existing `seo` skill remains
  intact.
- No production process, database, listener, deployment, or external service
  was changed.

## Recovery

Deactivate only the new `codex-seo`/`seo-*` links and remove their catalog
entries through the reviewed skill-manager rollback procedure. Restore the
previous manifest and manager revision if the custom-name handling is no
longer needed. Do not delete the pre-existing `seo` skill or user credentials.
