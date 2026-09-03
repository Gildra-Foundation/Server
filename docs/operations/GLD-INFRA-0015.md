# GLD-INFRA-0015 — Response validator and policy publication

Status: `in progress`

- Owner: Gildra project owner
- Environment: Server repository agent workflow
- Risk: R1, local validator and documentation; GitHub branch publication is
  explicitly requested and uses a normal non-force push
- Prepared: 2026-09-03
- Secret material: none

## Objective

Keep the concise response contract enforceable and publish the accumulated
policy changes to the `Server` repository.

## Changes

- Added `scripts/validate-agent-response.py`, an opt-in checker for outcome,
  `Push`, `Deploy`, and two or three numbered next steps.
- Added `make check-agent-response`; it skips safely unless
  `AGENT_RESPONSE_FILE` is provided, so live chat output is never written to or
  required by the repository.
- Linked the checker from `AGENTS.md` and
  `docs/runbooks/agent-execution.md`.

The validator checks response shape only. Repository tests, tool output, and
symbiosis handoffs remain the source of truth for whether the work was actually
completed.

## Verification before publication

- Valid fixture accepted and invalid fixture rejected with actionable errors.
- `make check-agent-response` passed its documented no-file skip.
- `make check`, hook validation, `git diff --check`, and symbiosis path checks
  are required before the push.

## Publication gate

The current branch is `chore/codex-review-action` and contains local
policy/tooling commits ahead of its remote tracking branch. The requested
normal push will publish the complete local branch history; no force-push,
merge, deploy, or production mutation is part of this operation.
