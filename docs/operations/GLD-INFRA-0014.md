# GLD-INFRA-0014 — Concise agent response contract

Status: `applied`

- Owner: Gildra project owner
- Environment: Server repository agent instructions
- Risk: R1, instruction and documentation change only
- Prepared: 2026-09-03
- Secret material: none

## Objective

Make Codex final answers short, factual, and useful for project decisions.

## Changes

- `AGENTS.md` now requires an outcome first, a compact change/check summary,
  explicit repository/branch plus `Push` and `Deploy` status, and two or three
  concrete next-step options.
- Blocked work must name the blocker, evidence already collected, and the exact
  user action needed. Failed checks may not be presented as completed work.
- `docs/runbooks/agent-execution.md` contains a reusable response template and
  keeps routine logs and secrets out of user-facing responses.

## Verification

- `git diff --check` passed.
- Existing repository workflow and tool rules remain unchanged.
- No production service, deployment, MCP credential, or sibling repository was
  changed.

## Recovery

Revert this documentation-only commit if the response format needs to change;
no runtime rollback is required.
