# GLD-INFRA-0008 — architecture and React skill expansion

Status: `partially_verified`

- Owner: Gildra project owner
- Environment: Codex profiles on the server
- Risk: R1, reversible user-scoped agent configuration
- Prepared: 2026-09-02
- Target services: none
- Privilege: no production privilege or service mutation
- Secret material: none

## Objective

Add the requested decision-record, modularity, React, Next.js, web-quality, and
React-pattern skills to the reproducible Server catalog. Ignore sources that
are already represented or do not publish a standalone skill.

## Source pins

| Repository | Revision | Installed entries | Notes |
|---|---|---:|---|
| `me2resh/agent-decision-record` | `e4e1a4e1702951a1a28bae918381daa61a792b70` | 2 | `decide` and the Codex-specific `agdr-decide`. |
| `vladikk/modularity` | `bcdca9a595764b9aa88d5d8d6020f52e7f5f1f52` | 4 | `balanced-coupling`, `design`, `document`, and `review`. |
| `millionco/react-doctor` | `fd23edca7eaa76b7f2b66795cfc829cc1967b7f3` | 4 | `improve-react`, `improve-threejs`, `react-doctor`, and `performance` stored as `react-doctor-performance` to avoid the web-quality name collision. |
| `addyosmani/web-quality-skills` | `afa8da942115f2961fdbfa80807ea0b232ff6c00` | 6 | Canonical `skills/*` copies: accessibility, best-practices, core-web-vitals, performance, SEO, and web-quality-audit. |
| `jezweb/claude-skills` | `e875a6bfff809e5d42c584104031e36e1f014f18` | 1 | The explicitly requested `plugins/frontend/skills/react-patterns`. |

`vercel-labs/next-skills` remains deferred at
`b76d687cf3e026eac3b1032f610f06b47a56377c`: its current repository is a
redirect to version-matched skills in `vercel/next.js` and contains no
standalone `SKILL.md`.

## Apply and verification evidence

The lock manifest now contains 304 installable skills, including 17 new
entries. Both user catalogs passed `--check-catalog` for all 304 entries. All
217 skills assigned to the `server` profile are present in both users' 
`.agents/skills` and `.codex/skills` paths. Existing directories were preserved
and no existing skill name was overwritten.

No daemon, application, database, network listener, production data, or secret
was changed.

## Recovery

Revert this manifest/card change and remove only the newly created user-scoped
links if rollback is required. Preserve catalog directories for audit; no
service restart or data restore is required.
