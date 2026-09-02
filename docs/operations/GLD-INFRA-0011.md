# GLD-INFRA-0011 — Go API and repository hook checks

Status: `applied`

- Owner: Gildra project owner
- Environment: shared server developer tooling for `debian` and `gildra-admin`
- Risk: R1, local validation tooling and repository configuration only
- Prepared: 2026-09-02
- Secret material: none

## Installed tools

The following executables are available to both users through
`/usr/local/bin`:

| Tool | Version | Purpose |
|---|---:|---|
| `oapi-codegen` | 2.8.0 | Generate Go API clients/servers from OpenAPI |
| `actionlint` | 1.7.12 | Validate GitHub Actions workflow files |
| `pre-commit` | 4.6.2 | Run repository hooks |
| `lefthook` | 2.1.9 | Orchestrate Git hooks |

The binaries were built or installed from the official upstream distribution
paths. Go uses the shared 1.27.1 toolchain.

## Built-in Go diagnostics

No separate package was installed for Go fuzzing or profiling. The installed Go
toolchain already provides:

```bash
go test ./... -fuzz=Fuzz -fuzztime=30s
go tool pprof
go tool trace
```

## Repository integration

- `make check` now includes `check-workflows`, which runs `actionlint` when
  `.github/workflows/*.yml` or `.yaml` files exist.
- `.pre-commit-config.yaml` contains autonomous local hooks for
  `git diff --check` and `actionlint`; `make check` is available as a manual
  hook (`pre-commit run --hook-stage manual`).
- `lefthook.yml` delegates its `pre-commit` group to the same pre-commit
  configuration, so the two tools do not maintain separate rule sets.

The Git hook was not installed automatically into `.git/hooks`: this checkout
is shared by two OS users, and silently replacing an existing hook would be an
unsafe state change. To opt in, run one of the following in the repository:

```bash
pre-commit install
lefthook install
```

Use one hook manager as the active Git hook; both configurations remain
available for explicit runs.

## Verification

- `oapi-codegen --version`, `actionlint -version`, `pre-commit --version`, and
  `lefthook version` passed for both users.
- `actionlint -color=false` passed for the repository workflows.
- `pre-commit validate-config` and `pre-commit run --all-files` passed.
- `lefthook validate` and `lefthook dump` passed.
- `make check` passed with expected skips for absent frontend, Go module, API,
  and Protobuf stacks.
- `go tool pprof` and `go tool trace` are available from Go 1.27.1.
- No application process, database, production service, or deployment was
  changed.

## Recovery

Remove only the explicitly installed binaries and the new repository config
files if this toolchain is no longer desired. If a hook was installed, use
`pre-commit uninstall` or `lefthook uninstall` from the repository first.
