# GLD-INFRA-0006 — additional engineering skills

Status: `partially_verified`

- Owner: Gildra project owner
- Environment: Codex user profiles on the server
- Risk: R1, reversible user-scoped agent configuration
- Prepared: 2026-09-02
- Target services: none
- Privilege: no production privilege or service mutation
- Secret material: none

## Objective

Extend the shared engineering skill set with API design, delivery automation,
context management, documentation, frontend engineering, Git workflow,
performance, planning, source-driven development, dependency maintenance, and
living repository documentation.

## Source pins

| Repository | Revision | Skills |
|---|---|---|
| `addyosmani/agent-skills` | `d2c37ef6225dd8726cdd369a8030307f48592d26` | `api-and-interface-design`, `ci-cd-and-automation`, `context-engineering`, `documentation-and-adrs`, `frontend-ui-engineering`, `git-workflow-and-versioning`, `performance-optimization`, `planning-and-task-breakdown`, `source-driven-development`, `using-agent-skills` |
| `YurunChen/repo-docs-skills` | `52674499dce957deb146fa51363f6e8e42802097` | `repo-docs`, `repo-docs-zh` |
| `softaworks/agent-toolkit` | `3027f20f3181758385a1bb8c022d4041dfb4de84` | `dependency-updater` |

All entries use the exact upstream paths and full immutable commit SHAs in
`agent/skills.lock.json`. The Repo-Docs repository explicitly provides both
language variants, so both are installed.

## Apply and verification evidence

The 13 skills were installed for both `debian` and `gildra-admin` into their
user-scoped `.agents/skills` directories, with corresponding `.codex/skills`
links. Existing skills were not overwritten. The lock manifest passed JSON and
manager validation before installation; both real provenance catalogs and a
fresh empty catalog passed the 134-entry `--check-catalog` verification. The
upstream `SKILL.md` files were read from the pinned revisions and passed the
installer frontmatter checks.

No server daemon, application, database, network listener, production data, or
secret was changed. A new Codex process is needed to refresh its skill index.

The revision is published to the GitHub branch
`chore/codex-review-action` and has been fast-forwarded to the default
`main` branch at commit `92a41ff6068a254adcc9edb483dad010aba5398c`.
The feature branch and `main` currently point to the same revision. The
pull-request review workflow is not applicable to this direct fast-forward;
push-triggered validation remains subject to the GitHub Actions run.

## Recovery

Remove only the 13 new user-scoped links and revert this manifest/card change.
Preserve catalog contents for audit; no service restart or data restore is
required.
