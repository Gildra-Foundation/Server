# GLD-INFRA-0009 — design skills and code-quality toolchain

Status: `applied`

- Owner: Gildra project owner
- Environment: server host, user-scoped Codex catalogs and shared CLI tools
- Risk: R1, reversible developer tooling; no application or production service change
- Prepared: 2026-09-02
- Secret material: none

## Objective

Install the requested design skills for both `debian` and `gildra-admin`, and
provide one `make check` entry point for repositories that contain frontend,
Go, OpenAPI, or Protobuf code.

## Skill source pins

| Repository | Revision | Entry | Profiles |
|---|---|---|---|
| `mblode/agent-skills` | `ac090cd9dc16346258763fa9cbff1c29dd466277` | `ui-design` | design, frontend |
| `softaworks/agent-toolkit` | `3027f20f3181758385a1bb8c022d4041dfb4de84` | `design-system-starter` | design, frontend |
| `nutlope/hallmark` | `13ac0ec7e148655948100b6396439e481361d690` | `hallmark` | design, frontend |
| `arvindrk/extract-design-system` | `1873741ba8dea755e35e6e15134f7918cd58e036` | `extract-design-system` | design, frontend |

The lock manifest now contains 308 installable skills. The four new entries
are cataloged for the `design` and `frontend` profiles; the management default
`server` profile remains unchanged at 217 skills.

## Installed tools

Shared executables are available through `/usr/local/bin` for both users:

- Node.js `v22.23.2`, npm `10.9.8`, pnpm `11.25.0`.
- TypeScript `7.0.2`, ESLint `10.9.1`, Biome `2.5.11`, Knip `6.34.0`,
  Vitest `4.1.11`, Playwright `1.62.1`, Spectral `6.16.3`.
- Go `1.27.1`, Staticcheck `2026.2.1 (0.8.1)`, golangci-lint `2.13.2`,
  govulncheck `1.7.0`.
- Schemathesis `4.25.2`, Semgrep `1.176.0`, Buf `1.72.0`, Trivy `0.74.0`.

Playwright's CLI is installed; browser binaries are intentionally not
downloaded on the production candidate. Next.js projects should declare their
matching `eslint-config-next` in the project dependencies.

## Check entry point

`Makefile` adds `make check`. It runs the requested frontend and Go checks when
the corresponding project files exist, runs Spectral/Schemathesis and Buf when
schemas are present, and skips empty stacks. `make check-security` is opt-in via
`SECURITY_CHECKS=1` because Trivy and Semgrep filesystem scans are expensive.

On this infrastructure repository the check completed with expected skips:
there is no `package.json`, `go.mod`, OpenAPI schema, or `buf.yaml`.

## Verification

- `manage-agent-skills.py --check-manifest` passed with 308 entries.
- `manage-agent-skills.py --check-catalog` passed for both user catalogs.
- All four users can execute the shared toolchain; version probes passed.
- `make check` and `make check-security` completed with expected skips.
- No application process, database, listener, deployment, or secret was changed.

## Recovery

Remove the four new catalog entries and manifest records through the skill
manager's reviewed rollback procedure. Remove only the explicitly installed
tool versions or restore their previous symlinks; do not remove the existing
application Node runtime or unrelated user skills.
