# GLD-INFRA-0016 — Mandatory Luna context and review workflow

Status: `applied`

- Owner: Gildra project owner
- Environment: Server repository agent workflow
- Risk: R1, policy/documentation only; no production mutation
- Prepared: 2026-09-03
- Secret material: none

## Objective

Make every repository/production task begin with a read-only `gpt-5.6-luna`
context scout, continue with deliberate skill/tool selection, and finish with a
fresh Luna review/documentation pass plus a root quality gate.

## Context pass

- Agent: `context_scout` (5.6 Luna)
- Scope: read-only audit of `AGENTS.md`, task files, runbook, repository status,
  branch, and shared symbiosis state
- Result at context-pass start: no active locks or conflicts; the branch was
  clean and synced at `2d2748615612975fea448ccd28a08920a86c5b18` before this
  policy diff was created. The recommended placement was the root contract and
  execution runbook.

## Selected skills and tools

- `gildra-engineering-symbiosis`: preflight, registration, path claims,
  handoff, and lock release
- `planning-and-task-breakdown`: acceptance criteria, verification, and
  continuation plan
- `context-engineering`: persistent rules and focused context loading
- `multi-agent-patterns`: isolated passes, bounded roles, and evidence-backed
  handoffs
- `git-workflow-and-versioning`: reviewable local commit and hygiene

No MCP/plugin was needed: this change is repository policy documentation and
does not require live library, browser, GitHub, Sentry, or Cloudflare context.

## Changes

- Added a mandatory pre-task Luna context-scout stage to `AGENTS.md` and the
  execution runbook.
- Added a mandatory post-change Luna reviewer/documenter stage with explicit
  path claims and no production/credential permissions.
- Added root-agent final checks for errors, bugs, cleanliness, tests, generated
  files, secrets, coupling, and architecture.
- Added explicit fallback/degraded-mode behavior when Luna is unavailable.

## Verification and publication

The reviewer pass and root checks are recorded below. This task does not
authorize a GitHub push or deployment; the local commit and branch are reported
explicitly.

### Luna reviewer pass

Completed by `gpt-5.6-luna` (`01a020dd-e325-7e51-a86a-726eab3a6ede-luna-review`).
The review is documented in
[`GLD-INFRA-0016-luna-review.md`](GLD-INFRA-0016-luna-review.md). It found no
secrets or generated files and passed `git diff --check`. Its three findings
were resolved or explicitly accepted:

- P2 snapshot wording is now explicitly marked as a pre-change snapshot.
- P2 task checkboxes remain open until the root quality gate and handoff finish.
- P3 model selection cannot be proven by repository automation; the policy
  therefore requires the exact runtime model and degraded mode in the operation
  record/handoff, with production/shared-database work blocked on fallback.

### Root quality gate

Completed by the root session after resolving/accepting all Luna findings:

- `make check`: passed; frontend, backend, OpenAPI, and Buf stacks were skipped
  because their project files are absent, while actionlint passed.
- `pre-commit validate-config` and `pre-commit run --all-files`: passed.
- `lefthook validate` and `lefthook dump`: passed.
- `git diff --check`: passed.
- Symbiosis `check-paths`: passed with no conflicts for all claimed paths.
- No source, generated, secret, production, or sibling-repository files were
  changed.

## Final state

- Commit: `ef6a720` (`chore: require Luna context and code review`)
- Branch: `chore/codex-review-action`
- Push: not performed; no target/approval was included in this request.
- Deploy: not performed.
- Handoff: published after the final documentation commit; session locks
  released.

## Risks

- A model fallback can reduce review quality; production/shared-database work is
  blocked until Luna or an approved reviewer is available.
- Sub-agent reports are not proof by themselves; the root agent must verify all
  findings and checks.
