# Execution contract checklist

- [x] Add mandatory execution protocol to `AGENTS.md`.
- [x] Add skill/MCP/tool routing and evidence rules to the execution runbook.
- [x] Validate manifest, catalogs, Makefile checks, and the complete diff.
- [x] Record the change and publish the cross-session handoff.

## Response policy follow-up

- [x] Add and test the optional response-format validator.
- [x] Commit the validator and policy updates.
- [x] Push `chore/codex-review-action` to the `Server` remote and verify its SHA.

## Checkpoint

- [x] No production or sibling repository changes.
- [x] The next Codex session can continue from the runbook and handoff.

## Luna workflow follow-up

- [x] Add the pre-task `gpt-5.6-luna` context-scout gate.
- [x] Add the post-change `gpt-5.6-luna` reviewer/documenter gate.
- [x] Run the root quality gate and record the two-pass evidence.
- [x] Commit locally; push remains pending an explicit target/approval.

## Core engineering principles

- [x] Add think-before-code, simplicity, surgical-change, and verifiable-goal
  rules to the server contract and runbook.
- [x] Run Luna review and record assumptions, options, trade-offs, and findings.
- [x] Run the root quality gate, commit locally, and release the session.

## Dual-repository Graphify viewer

- [x] Generate and screen the immutable Gildra graph artifact.
- [x] Add the accessible `Gildra / Server` selector and same-origin frame policy.
- [x] Validate and deploy only the graph static files and nginx service.
- [x] Verify both graphs publicly and run the Luna/root quality gates.
- [ ] Commit and push the reviewed Server repository changes.
