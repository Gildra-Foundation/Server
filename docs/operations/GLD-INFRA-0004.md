# GLD-INFRA-0004 — pinned user-scoped Codex skill catalog

Status: `verified`

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

## Apply and verification evidence

Applied at `2026-08-20T20:15:25Z` as `gildra-admin` from reviewed Server
revision `8511c68ed71167a0ec07ee26ef3c7834d7ec2057`.

- GitHub Actions run
  [32412763659](https://github.com/Gildra-Foundation/Server/actions/runs/32412763659)
  passed for the revision before target apply.
- The manager validated 114 manifest entries and installed 114 catalog
  directories from their pinned source revisions.
- A complete post-install `--check-catalog` verified all 114 `SKILL.md` files,
  provenance markers and containment rules.
- Profile `server` activated 28 managed symlinks; broken active links: 0.
- Catalog size after installation: 19 MiB.
- The credential-pattern scan found no private-key or GitHub-token pattern.
  Three AWS-key-shaped matches were all the canonical public documentation
  example and occurred only in security guidance/reference files; no credential
  value was printed or copied into this repository.
- The target checkout was clean and aligned with `origin/main` after apply.
- No sudo, system package, service, container, port, application repository or
  external control-plane change was part of the operation.

A new Codex process must be started to refresh skill discovery. This is a client
refresh, not a host or service restart.

## Recovery

Move only the symlinks recorded in `.gildra-managed.json` and the state file to a
private backup directory, restart Codex, and verify deactivation. Preserve the
catalog for evidence and rollback. No production service restart or data restore
is required.
