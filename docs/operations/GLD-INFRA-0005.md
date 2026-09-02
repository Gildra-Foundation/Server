# GLD-INFRA-0005 — engineering skill catalog extension

Status: `partially_verified`

- Owner: Gildra project owner
- Environment: Codex user profiles on the server
- Risk: R1, reversible user-scoped agent configuration
- Prepared: 2026-09-02
- Target services: none
- Privilege: no sudo for the repository change
- Secret material: none

## Objective

Add the requested engineering skills to the reproducible Server catalog and
make the programming-book rules usable by Codex without pretending that a
guidance-only repository is a standalone skill.

## Planned change

- pin `clean-architecture` and `kent-beck-style` from
  `nathankim0/clean-architecture-skills`;
- pin `codebase-design`, `diagnosing-bugs`, `domain-modeling`,
  `improve-codebase-architecture`, and `resolving-merge-conflicts` from
  `mattpocock/skills`;
- record `ciembor/agent-rules-books` as a deferred source because it has no
  standalone `SKILL.md`; the reviewed local `agent-rules-books` adapter exposes
  its compact rule references under `references/` for both Codex users;
- keep all sources at immutable full commit SHAs and leave activation to the
  existing profile manager.

## Source pins

| Repository | Revision | Installed skill paths |
|---|---|---|
| `nathankim0/clean-architecture-skills` | `0022fbb712f28517aa07a531fd82c70a9e531beb` | `plugins/clean-architecture/skills/clean-architecture`, `plugins/kent-beck-style/skills/kent-beck-style` |
| `mattpocock/skills` | `6654f6b60cd9d5be8b54c6fafe46dabeb3b76` | `skills/engineering/codebase-design`, `diagnosing-bugs`, `domain-modeling`, `improve-codebase-architecture`, `resolving-merge-conflicts` |
| `ciembor/agent-rules-books` | `9c8763613514e4047d75c089533e09bc4b493c28` | deferred source; local reviewed adapter `agent-rules-books` |

## Apply and verification evidence

Installed on 2026-09-02 for both `debian` and `gildra-admin` under their
user-scoped `.agents/skills` and `.codex/skills` paths. The seven standalone
skills passed the Codex skill validator. The local `agent-rules-books` adapter
contains 14 compact (`mini`) references and passed the same validator.

The lock manifest passes JSON and manager manifest validation. A fresh catalog
installation from all 121 pinned entries completed successfully and
`--check-catalog` verified all 121 `SKILL.md` files and provenance markers. The
same seven entries were then installed into both real user catalogs and each
catalog passed the 121-entry check. The two user profiles contain the seven new
standalone skills plus the local rules adapter. No server daemon, application,
database, network listener, production data, or secret was changed.

The revision is published to the GitHub branch
`chore/codex-review-action` at commit `8a1bbbb532b291cde1a78defa3e605961e566deb`.
The default `main` branch was not changed. CI and pull-request review remain
pending until a pull request is opened.

## Recovery

Revert this lock-file/card change and remove only the newly managed user-scoped
skill links. Preserve catalog contents for audit; no production restart or data
restore is required.
