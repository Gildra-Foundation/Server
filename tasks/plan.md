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

## Follow-up: Luna context and review workflow

### Task 6: Add the mandatory pre-task Luna context scout

**Description:** Require a read-only `gpt-5.6-luna` context pass before skill
selection or implementation, with shared-session evidence and an explicit
fallback policy.

**Acceptance criteria:**
- [x] `AGENTS.md` requires a Luna context scout before skills are selected.
- [x] The runbook defines read-only scope, required brief, and no silent skip.
- [x] Fallback and production/shared-database blocking behavior are explicit.

**Verification:** Context scout handoff reviewed; contract and repository checks
passed.

**Dependencies:** Existing symbiosis and skill-routing gates.

**Files likely touched:** `AGENTS.md`, `docs/runbooks/agent-execution.md`,
`tasks/plan.md`, `tasks/todo.md`

**Estimated scope:** Medium: 4 files

### Task 7: Add the post-change Luna reviewer/documenter

**Description:** Require a fresh `gpt-5.6-luna` pass after implementation to
check code quality and architecture, update claimed documentation, and provide
evidence-backed context for the next session.

**Acceptance criteria:**
- [x] The reviewer checks errors, bugs, tests, cleanliness, and architecture.
- [x] Documentation writes are limited to explicitly claimed paths.
- [x] Findings, fixes/acceptance, and selected tools are recorded in handoff.

**Verification:** Luna review completed and recorded in
`docs/operations/GLD-INFRA-0016-luna-review.md` and the operation card.

**Dependencies:** Task 6.

**Files likely touched:** `AGENTS.md`, `docs/runbooks/agent-execution.md`,
`docs/operations/GLD-INFRA-0016.md`

**Estimated scope:** Medium: 3 files

### Task 8: Root quality gate and continuation point

**Description:** Verify the complete policy diff, run repository checks, and
leave a handoff that distinguishes reviewer findings from root verification.

**Acceptance criteria:**
- [x] `make check`, focused checks, `git diff --check`, and `check-paths` pass
      or have justified skips.
- [x] The operation card records model passes, selected skills/tools, risks,
      commit/branch, and deployment state.
- [x] Session locks are released after handoff.

**Verification:** Commands listed in the runbook passed; the handoff will be
published and locks released after the final documentation commit.

**Dependencies:** Tasks 6-7.

**Files likely touched:** `docs/operations/GLD-INFRA-0016.md`,
`tasks/plan.md`, `tasks/todo.md`

**Estimated scope:** Small: 3 files

**Result:** Policy implementation committed locally as `ef6a720` on
`chore/codex-review-action`; no push or deployment was requested.

## Follow-up: core engineering principles

### Task 9: Add think-simple-surgical-verifiable rules

**Description:** Add a concise, enforceable decision and implementation
contract to the server instructions and runbook.

**Acceptance criteria:**
- [x] The contract requires assumptions, material-ambiguity questions, options,
      trade-offs, and explicit unknowns before coding.
- [x] The contract requires the smallest safe design and surgical diffs without
      opportunistic refactoring or unauthorized deletion.
- [x] The contract maps bug fixes, validation, refactors, and multi-step work
      to concrete tests and stage-level acceptance checks, with a narrow
      documented emergency-mitigation exception, while allowing applicable
      config/lint/health evidence for infrastructure and documentation work.

**Verification:** Luna context/review passes and the repository quality gate
passed; evidence is recorded in `docs/operations/GLD-INFRA-0017.md`.

**Dependencies:** Existing Luna orchestration and planning gates.

**Files likely touched:** `AGENTS.md`, `docs/runbooks/agent-execution.md`,
`tasks/plan.md`, `tasks/todo.md`, `docs/operations/GLD-INFRA-0017.md`

**Estimated scope:** Medium: 5 files

## Follow-up: dual-repository Graphify viewer

### Task 10: Build the Gildra graph artifact

**Description:** Export the immutable Gildra application revision into a
temporary directory and generate a secret-screened Graphify viewer without
modifying the sibling checkout.

**Acceptance criteria:**
- [x] The published default graph comes from the Gildra default-branch revision
      `8dac4fbddbcb3ced13c9a57c0e39fe7bce573d5b`.
- [x] The sibling repository remains unchanged by this task.
- [x] Generated public artifacts contain no secrets or private host paths.

**Verification:** Compare the sibling status before/after, inspect generated
metadata, and run bounded sensitive-pattern checks.

**Dependencies:** Existing Graphify viewer deployment.

**Files likely touched:** `graph-site/gildra.html`,
`graph-site/server.html`

**Estimated scope:** Small: 2 generated files

### Task 11: Add the repository switcher

**Description:** Add an accessible static selector that opens Gildra by
default and switches the embedded viewer to the Server graph.

**Acceptance criteria:**
- [x] Gildra is selected on first load.
- [x] Both graph canvases render after keyboard-usable repository selection.
- [x] Same-origin framing is permitted while cross-origin framing stays denied.

**Verification:** Validate nginx syntax and exercise both selector states in a
headless browser without console errors.

**Dependencies:** Task 10

**Files likely touched:** `graph-site/index.html`,
`deploy/graph-site/nginx.conf`

**Estimated scope:** Small: 2 files

### Task 12: Deploy and record the production change

**Description:** Snapshot the current graph site, deploy only the graph static
files and nginx vhost, verify public and existing routes, then publish the
Server repository commit.

**Acceptance criteria:**
- [x] Rollback artifacts exist before the nginx service is recreated.
- [x] `https://graph.gildra.net/` serves the selector and both graphs.
- [x] Existing Gildra web/API routes remain healthy.

**Verification:** Compose render, disposable and live `nginx -t`, HTTP/TLS
checks, browser smoke test, `make check`, `git diff --check`, and symbiosis
path validation.

**Dependencies:** Tasks 10-11

**Files likely touched:** `docs/runbooks/graph-publishing.md`,
`docs/operations/GLD-INFRA-0021.md`, `tasks/plan.md`, `tasks/todo.md`

**Estimated scope:** Medium: 4 files plus deployed static artifacts

### Checkpoint: dual-repository viewer

- [x] Local artifacts and proxy configuration validate.
- [x] Fresh Luna review findings are resolved or explicitly accepted.
- [x] Production and public browser verification pass before locks are released.

## Risks and mitigations: dual-repository viewer

| Risk | Impact | Mitigation |
|------|--------|------------|
| Dirty sibling checkout leaks uncommitted work | High | Generate only from an exact `git archive` revision in `/tmp`. |
| Generated graph exposes sensitive content | High | Use code-only extraction, explicit ignores, and pattern scans before publication. |
| Framing policy breaks the embedded viewers | Medium | Allow only same-origin frames and verify both canvases in Chromium. |
| Nginx recreation interrupts unrelated services | Medium | Recreate only nginx, keep a timestamped rollback, and smoke-test existing routes. |

## Follow-up: automated graph refresh

### Assumptions and decision

- Refresh both repositories once per hour. A later timer override can change the
  cadence without changing the publisher.
- Track each repository's remote default branch, but fetch and build the exact
  SHA resolved at the beginning of a run.
- Run on the existing origin with a hardened systemd oneshot/timer. This avoids
  introducing a CI deploy credential; both repositories are readable over
  HTTPS.
- Keep Graphify at the repository-locked commit
  `33362d969292b57eda82f3fbd9eb5f3f5bc9bbc2` (`0.9.53`).
- Unknown before deployment: actual first-run duration and peak memory on the
  production host. The first manual service run and journal are the acceptance
  evidence; the live symlink is not changed if generation or screening fails.

### Requirement map

| ID | Requirement | Evidence |
|---|---|---|
| REQ-001 | Hourly refresh with a no-op when both source SHAs, the template, and Graphify runtime are unchanged | Script integration test and timer state |
| REQ-002 | Build immutable revisions without using sibling worktrees | Local bare-repository test and deployed manifest |
| REQ-003 | Use the pinned Graphify commit/version | Pin file, runtime version check, and manifest |
| REQ-004 | Reject malformed, empty, path-leaking, or credential-like generated artifacts | Failure-path tests and bounded artifact scans |
| REQ-005 | Publish both viewers as one atomic release through a service-private bind mount | Symlink-preservation and successful-switch tests |
| REQ-006 | Retain bounded rollback releases without deleting the active target | Retention integration test |
| REQ-007 | Prevent overlapping runs and fail visibly through systemd | `flock`, unit verification, and journal/status checks |

### Task 13: Implement and test the atomic publisher

**Description:** Add a fail-fast Bash publisher that resolves remote default
branches, checks out exact SHAs in temporary directories, generates and screens
both Graphify viewers, and atomically switches a versioned release symlink.

**Acceptance criteria:**
- [x] Matching manifests produce a no-op without invoking Graphify.
- [x] A generator or validation failure preserves the previous `current` link.
- [x] A successful run publishes the selector, both viewers, and a source/runtime manifest.
- [x] Retention keeps at most the configured number of releases and never removes `current`.

**Verification:** `bash -n`, the Bash skill validator, and
`scripts/test-refresh-graph-site.sh`.

**Dependencies:** Existing dual-repository viewer and pinned Graphify source.

**Files likely touched:** `scripts/refresh-graph-site.sh`,
`scripts/test-refresh-graph-site.sh`, `graph-site/index.html`, `Makefile`

**Estimated scope:** Medium: 3 files plus one reused template

### Task 14: Add the hardened schedule and publishing contract

**Description:** Add a systemd oneshot/timer, point nginx at the atomic
`current` release, and document installation, operation, failure handling, and
rollback.

**Acceptance criteria:**
- [x] The timer is persistent, hourly, randomized, and cannot overlap itself.
- [x] The service has no capabilities and can write only graph state/runtime paths.
- [x] Nginx serves the release symlink through the existing read-only mount.
- [x] The runbook and operation card name exact checks and rollback steps.

**Verification:** `systemd-analyze verify`, disposable and live `nginx -t`,
operation gate, and production service/timer status.

**Dependencies:** Task 13.

**Files likely touched:** `deploy/graph-site/gildra-graph-refresh.service`,
`deploy/graph-site/gildra-graph-refresh.timer`,
`deploy/graph-site/nginx.conf`, `docs/runbooks/graph-publishing.md`,
`docs/operations/GLD-INFRA-0022.md`

**Estimated scope:** Medium: 5 files

### Task 15: Deploy, review, and publish

**Description:** Install the pinned runtime and automation, run an initial
manual refresh, switch nginx to the atomic release, enable the timer, complete
fresh Luna/root reviews, and push only the claimed Server paths.

**Acceptance criteria:**
- [x] A timestamped rollback snapshot exists before production mutation.
- [x] The first refresh records both current remote SHAs and Graphify provenance.
- [x] Public health, selector, both canvases, main web, and API checks pass.
- [x] Luna findings are resolved or explicitly accepted; repository checks pass.

**Verification:** Service journal/status, timer listing, public HTTP/browser
smoke tests, `make check`, `git diff --check`, and symbiosis `check-paths`.

**Dependencies:** Tasks 13-14.

**Files likely touched:** `docs/operations/GLD-INFRA-0022.md`,
`tasks/plan.md`, `tasks/todo.md`

**Estimated scope:** Medium: repository evidence plus production artifacts

### Checkpoint: automated graph refresh

- [x] Local publisher failure/success/no-op/retention tests pass.
- [x] Fresh Luna review findings are resolved or explicitly accepted.
- [x] Production timer and public graph site remain healthy after the first run.

### Risks and mitigations: automated graph refresh

| Risk | Impact | Mitigation |
|---|---|---|
| Upstream changes contain sensitive material | High | Code-only extraction, explicit ignores, bounded token/path scan, atomic abort |
| Branch moves between resolution and fetch | Low | Fetch exact resolved SHA; abort and retry next schedule if unavailable |
| Graphify/runtime drift changes output unexpectedly | High | Immutable Graphify commit, checked version and pin marker, provenance manifest |
| Failed or overlapping generation damages the site | High | Non-blocking `flock`, isolated staging, validation before atomic symlink switch |
| Generated releases consume disk | Medium | Keep a bounded release count after each successful publication |
