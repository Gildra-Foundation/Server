# Implementation Plan: server agent execution contract

## Overview

Make the repository's root agent contract executable: every Codex session must
select the relevant installed skills, read shared session state, write or reuse
a plan for multi-step work, use the available MCP servers and project checks,
and leave an auditable handoff for the next session.

## Architecture Decisions

- `AGENTS.md` remains the authoritative entry point for every path in the
  repository; it will require the workflow without duplicating every skill
  document.
- `docs/runbooks/agent-execution.md` contains the concrete routing matrix,
  commands, skip rules, and evidence format so the root contract stays concise.
- The installed catalog and `agent/skills.lock.json` remain the source of truth
  for skills. Agents load only the skills relevant to the task, while the
  server profile remains the default.
- MCP tools are mandatory when their domain is in scope: Serena for repository
  navigation, Context7 for current library documentation, Playwright for
  browser flows, and Cloudflare only for approved edge work.
- `make check` is the default verification gate. Missing stacks are recorded as
  explicit skips; present stacks must run their configured linters and tests.

## Task List

### Phase 1: Contract and routing

#### Task 1: Define the executable workflow — complete

**Description:** Add mandatory session, planning, skill-selection, MCP, test,
and handoff rules to the root agent contract.

**Acceptance criteria:**
- [x] A new session reads shared state and claims paths before editing.
- [x] Multi-step work preserves existing plans and records acceptance criteria.
- [x] Relevant skills and installed tools are selected explicitly.

**Verification:** `sed` review of `AGENTS.md`; shell syntax checks in the runbook.

**Dependencies:** None

**Files likely touched:** `AGENTS.md`

**Estimated scope:** Small: 1 file

#### Task 2: Add the tool and evidence matrix — complete

**Description:** Document the exact frontend, Go, API, security, MCP, and
cross-session commands and the required skip/evidence behavior.

**Acceptance criteria:**
- [x] Every installed tool is routed to a concrete project condition or MCP use.
- [x] Linters, tests, build, fuzzing, profiling, and security checks have clear
      commands and do not receive production secrets by default.
- [x] Another session can continue from the recorded handoff.

**Verification:** Run the repository's `make check` and the runbook's read-only
tool probes; verify commands match installed executables.

**Dependencies:** Task 1

**Files likely touched:** `docs/runbooks/agent-execution.md`

**Estimated scope:** Medium: 2-4 files

### Checkpoint: Contract — complete

- [x] Root contract and runbook are internally consistent.
- [x] No existing incomplete plan or task list was overwritten.
- [x] Shared-session path check reports no ownership conflict.

### Phase 2: Validation

#### Task 3: Validate and record — complete

**Description:** Check Markdown, manifest/tool references, repository checks,
and the complete diff; commit only the server-repository changes.

**Acceptance criteria:**
- [x] `make check` passes or reports only justified empty-stack skips.
- [x] Skill manifest and both catalogs remain valid.
- [x] A change record and symbiosis handoff identify commit, tests, risks, and
      the next action.

**Verification:** `make check`, skill manager checks, `git diff --check`, and
`team_state.py check-paths`.

**Dependencies:** Tasks 1-2

**Files likely touched:** `tasks/plan.md`, `tasks/todo.md`,
`docs/operations/GLD-INFRA-0013.md`

**Estimated scope:** Medium: 3-5 files

### Checkpoint: Complete

- [x] All acceptance criteria are satisfied.
- [x] No production service, database, MCP credential, or external repository
      was changed.
- [x] Codex restart is the only user-facing reload step.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Loading every skill at once exceeds context budget | Medium | Select relevant skills by routing matrix; keep the catalog pinned and inactive by default. |
| A second session edits the same contract | High | Shared preflight, path claims, `check-paths`, and handoff are mandatory. |
| A tool is unavailable in a project | Low | Record a precise skip; never claim a check that did not run. |
| External docs or MCP content is stale | Medium | Prefer Context7/official docs and record the source/version used. |

## Open Questions

- Application repositories will later add their own project-local checks; this
  server contract must remain the cross-repository baseline.

## Follow-up: response validation and publication

### Task 4: Add an optional response-format checker — complete

**Description:** Provide a small local validator for saved agent responses. It
checks the concise contract without attempting to infer quality or inspect live
chat transcripts.

**Acceptance criteria:**
- [x] A valid response contains an outcome, `Push`, `Deploy`, and next steps.
- [x] Invalid or overlong responses fail with actionable diagnostics.
- [x] The checker is opt-in and does not block unrelated repository checks.

**Verification:** Run valid and invalid fixture strings through the checker and
`make check-agent-response`.

**Dependencies:** Existing response contract in `AGENTS.md`.

**Files likely touched:** `scripts/validate-agent-response.py`, `Makefile`,
`AGENTS.md`, `docs/runbooks/agent-execution.md`

**Estimated scope:** Medium: 3-5 files

### Task 5: Publish the policy branch

**Description:** Commit the validator and policy documentation, then push the
current `chore/codex-review-action` branch to the configured `Server` remote.

**Acceptance criteria:**
- [x] The branch contains the policy commits and validator.
- [x] The remote branch advances without force-push.
- [x] The handoff records the pushed commit and remote status.

**Verification:** `git ls-remote` matches the pushed commit.

**Result:** Published as `f05942459001961bdc6162b84dc7362392835f74` on
`origin/chore/codex-review-action`; no deployment performed.

**Dependencies:** Task 4

**Files likely touched:** Repository history only.

**Estimated scope:** Small: no source files beyond Task 4
