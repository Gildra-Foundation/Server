# GLD-INFRA-0004 — pinned user-scoped Codex skill catalog

Status: `approved_in_progress`

- Owner: Gildra project owner
- Environment: `gildra-admin` account on production candidate
- Risk: R1, reversible user-scoped agent configuration
- Prepared: 2026-08-20
- Target services: none
- Privilege: no sudo
- Secret material: none

## Objective

Make the infrastructure agent's third-party instructions reproducible and
reviewable without mixing them into the server runtime. Install compatible
requested skills at immutable Git revisions into an inactive user catalog and
activate only the `server` profile.

## Authorization and boundaries

The owner explicitly requested installation of the listed skills and tools on
2026-08-20. This card authorizes only user-owned files below:

- `~/.local/share/gildra-agent-skills/catalog`;
- managed symlinks and state below `~/.agents/skills`.

It does not authorize `sudo`, APT changes, daemon changes, execution of bundled
third-party scripts, use of paid APIs, application-repository writes, or global
installation of project developer tools. It is independent of the still
partially verified Stage 0 audit and does not unblock Stage 1.

## Planned change

- add a lock manifest containing 114 compatible standalone skills and immutable
  source SHAs;
- add a standard-library-only manager which delegates downloads to Codex's
  bundled official GitHub skill installer;
- validate skill frontmatter, provenance markers and symlink containment;
- keep backend, frontend, design, security and unrelated cloud/platform skills
  catalog-only;
- activate the minimal `server` profile;
- record incompatible plugin/guidance repositories and project tools as
  deferred rather than fabricating adapters or installing globals.

## Preflight and abort conditions

Abort on a dirty or unexpected repository state, missing official installer,
invalid manifest, non-public source requiring credentials, source SHA mismatch,
existing unmarked catalog directory, unmanaged active-path collision, escaping
symlink, malformed `SKILL.md`, `sudo` request, or any attempt to execute content
from an installed skill.

## Verification

- repository validation and CI pass;
- all catalog entries contain `SKILL.md` and exact `.gildra-source.json` data;
- every active managed path is a symlink into the pinned catalog;
- `.gildra-managed.json` lists the selected profile and exact managed names;
- no system package, service, listening port, container or repository outside
  `Server` changes;
- a fresh Codex session discovers the active profile.

Observed evidence and final status will be appended after the approved apply.

## Recovery

Move only the symlinks recorded in `.gildra-managed.json` and the state file to a
private backup directory, restart Codex, and verify deactivation. Preserve the
catalog for evidence and rollback. No production service restart or data restore
is required.
