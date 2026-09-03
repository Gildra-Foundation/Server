# GLD-INFRA-0017 — Core engineering principles

Status: `applied`

- Owner: Gildra project owner
- Environment: Server repository agent workflow
- Risk: R1, policy/documentation only; no production mutation
- Prepared: 2026-09-03
- Secret material: none

## Objective

Add four mandatory principles to the server contract: think before coding,
prefer simplicity, make surgical changes, and work toward verifiable goals.

## Context pass

- Agent: `context_scout_rules` (5.6 Luna)
- Scope: read-only review of the server contract, runbook, task state, project
  docs, Git state, and shared symbiosis state
- Result: no active conflicts; recommended placement is a dedicated section in
  `AGENTS.md` and an operational section in the runbook. Existing Luna,
  planning, and quality gates already cover related behavior.

## Selected skills and tools

- `gildra-engineering-symbiosis`: shared state, path claims, handoff, release
- `planning-and-task-breakdown`: acceptance criteria and task continuation
- `context-engineering`: focused persistent instructions and ambiguity handling
- `multi-agent-patterns`: isolated Luna passes and evidence handoff
- `git-workflow-and-versioning`: surgical diff and local commit hygiene

No MCP/plugin was needed: this is policy documentation and does not require
live library, browser, GitHub, Sentry, or Cloudflare data.

## Changes

- Added assumptions/questions/options/trade-off and uncertainty requirements.
- Added a smallest-safe-solution rule with security and architecture guardrails.
- Added surgical-diff and deletion/refactor boundaries.
- Added explicit success criteria and test expectations for common task types.
- Added a narrow emergency-mitigation exception that preserves rollback/health
  evidence and requires a same-follow-up regression test.
- Clarified that infrastructure/documentation work uses applicable config,
  lint, schema, health, or reproducible checks rather than artificial tests.

## Luna review

Completed in three bounded `gpt-5.6-luna` passes:

- Initial reviewer: [`GLD-INFRA-0017-luna-review.md`](GLD-INFRA-0017-luna-review.md)
  identified and resolved the emergency-test and evidence-scope clarifications.
- Follow-up reviewer: [`GLD-INFRA-0017-luna-final-review.md`](GLD-INFRA-0017-luna-final-review.md)
  found no blocking issues after the emergency exception was added.
- Final reviewer: [`GLD-INFRA-0017-luna-final-check.md`](GLD-INFRA-0017-luna-final-check.md)
  confirmed the final evidence wording and found no blocking security,
  architecture, or scope defects.

All findings were resolved or explicitly accepted. Runtime spawning cannot be
proven by repository automation; the policy requires model, scope, result, and
degraded-mode evidence in the handoff instead.

## Root quality gate

Completed after the final Luna review:

- `make check`: passed; absent frontend, backend, OpenAPI, and Buf stacks were
  justified skips and actionlint passed.
- `make check-agent-response`: passed its documented no-file skip.
- `pre-commit validate-config`, `pre-commit run --all-files`, and `lefthook
  validate`: passed.
- `git diff --check`: passed.
- Symbiosis `check-paths`: passed with no conflicts.
- No source, production, database, credential, sibling-repository, generated,
  or secret files were changed.

## Final state

- Implementation commit: `7bc650d` (`docs: add core engineering principles`).
- This operation card and the Luna review artifacts are included in the same
  committed policy change.
- Branch: `chore/codex-review-action`.
- Push: not performed; no target/approval was included in this request.
- Deploy: not performed.

## Risks

- “Simple” must not be interpreted as permission to remove security controls or
  required tests.
- The policy guides agent behavior; repository evidence and the root quality
  gate remain authoritative.
