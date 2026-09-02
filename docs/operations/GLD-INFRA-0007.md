# GLD-INFRA-0007 — context, research, and QA skill catalog expansion

Status: `partially_verified`

- Owner: Gildra project owner
- Environment: Codex profiles on the server
- Risk: R1, reversible user-scoped agent configuration
- Prepared: 2026-09-02
- Target services: none
- Privilege: no production privilege or service mutation
- Secret material: none

## Objective

Add the requested context-engineering, autonomous-iteration, GitHub project,
synthesis, and test-automation skills to the reproducible Server catalog. Keep
the catalog pinned to immutable upstream revisions and make the server profile
available to both Codex users.

## Source pins

| Repository | Revision | Installed entries | Notes |
|---|---|---:|---|
| `muratcankoylan/Agent-Skills-for-Context-Engineering` | `6dbe1a1d868eab51a3bc9011b0f55e2891513e40` | 7 | The seven paths explicitly requested: context compression, degradation, fundamentals, optimization, filesystem context, multi-agent patterns, and long-horizon prompting. |
| `uditgoenka/autoresearch` | `050e30dc4ba0974b03f2873111b9901ec3211390` | 1 | Canonical `plugins/autoresearch/skills/autoresearch` package selected; duplicate platform copies were not added. |
| `netresearch/github-project-skill` | `287380028699f62301e61966499ffca284199746` | 1 | `github-project`. |
| `synthesisengineering/synthesis-skills` | `f1b9bb69f9698e23a8f8287e0b4d523151ab19e2` | 63 | All standalone `skills/*/SKILL.md` entries at the pinned revision. |
| `fugazi/test-automation-skills-agents` | `4a813b0534ed14a937c3931bfb2057ace31b5af2` | 10 | All standalone QA/test-automation skills. |
| `LambdaTest/agent-skills` | `0491a3a29aa18558d2c3c64ff09367adb976c56f` | 71 | All standalone skills except `api-designer`, which would collide with the existing pinned `Jeffallan/claude-skills` entry. |

The requested `balyakin/skill-eval-runner` revision
`b957be87d76c6718d74f601cefb0297fc9ca242e` is recorded under
`deferred_project_tools`: it is a CLI runner and exposes only test fixtures,
not a production standalone `SKILL.md`.

## Apply and verification evidence

The lock manifest now contains 287 installable skills (134 existing plus 153
new entries), all assigned to the `backend`, `frontend`, and `server` profiles.
The official Codex installer populated both user catalogs:

- `/home/debian/.local/share/gildra-agent-skills/catalog`;
- `/home/gildra-admin/.local/share/gildra-agent-skills/catalog`.

Both catalogs passed `--check-catalog` for all 287 entries. All 200 skills in
the `server` profile are present in both users' `.agents/skills` and
`.codex/skills` paths. Existing legacy directories were preserved rather than
overwritten; new entries use catalog-backed links. No daemon, application,
database, network listener, production data, or secret was changed.

## Recovery

Revert this manifest/card change and remove only the newly created
user-scoped links if rollback is required. Preserve catalog directories for
audit; no service restart or data restore is required.
