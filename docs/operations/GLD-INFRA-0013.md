# GLD-INFRA-0013 — Mandatory agent execution contract

Status: `applied`

- Owner: Gildra project owner
- Environment: Server repository and shared Codex workflow for `debian` and
  `gildra-admin`
- Risk: R1, repository instructions and documentation only
- Prepared: 2026-09-02
- Secret material: none

## Objective

Make installed skills, linters, MCP servers, tests, and cross-session
coordination part of the server agent's required execution path rather than an
unreferenced tool collection.

## Changes

- `AGENTS.md` now requires session preflight/registration/claims, planning for
  multi-file work, deliberate selection of pinned skills, MCP use by domain,
  evidence-backed checks, diff/path review, and a final handoff/release.
- `docs/runbooks/agent-execution.md` provides the concrete routing matrix for
  Serena, Context7, Playwright, GitHub, Sentry, Cloudflare, Codex Security,
  frontend/Go/API/security checks, fuzzing, profiling, hooks, and observability
  tools.
- `tasks/plan.md` and `tasks/todo.md` preserve the implementation acceptance
  criteria and completed checkpoint for future sessions.

The current MCP inventory is enabled for both users: Serena and headless
Playwright require no login; `debian` has OAuth state for Context7 and
Cloudflare, while `gildra-admin` remains `Not logged in` for those two
credentialed endpoints. The execution contract requires a visible fallback or
skip until that account is authorized; it does not copy or create credentials.

The rule is “all applicable tools,” not blind execution of all 335 catalog
skills or every expensive scan on every task. Empty stacks are explicit skips;
missing binaries, failed commands, unavailable MCP servers, and unconfigured
credentials remain visible as limitations.

## Verification

- `make check` passed with justified skips: no `package.json`, `go.mod`,
  OpenAPI/Swagger schema, or `buf.yaml` exists in this infrastructure scaffold;
  GitHub Actions validation ran through `actionlint`.
- `make check-security` reported its documented opt-in skip.
- `pre-commit validate-config` passed.
- `pre-commit run --all-files` passed (`git diff --check` and `actionlint`).
- `lefthook validate` and `lefthook dump` passed.
- Skill manifest/catalog checks remained valid for both users.
- Symbiosis `check-paths` reported no overlap with another active session.
- No production process, database, MCP credential, external repository, or
  deployment was changed.

## Follow-up

After application repositories appear, their local manifests and contracts will
activate the matching frontend/Go/API checks. Production or credentialed MCP
mutations still require the separate gates in `AGENTS.md` and
`docs/deployment-plan.md`.
