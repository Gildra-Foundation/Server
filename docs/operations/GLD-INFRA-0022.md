# GLD-INFRA-0022 — Automated Graphify refresh

## Operation, owner, and policy

- Operation ID: `ops-gld-graph-auto-refresh-20260904`
- Requester / accountable owner: workspace user / Gildra service owner
- Policy: `default-baseline` v2.0
- Data classification: public
- Risk: R3, reversible production automation and nginx static-root change
- Status: implementation in progress

## Objective and target

Refresh the Gildra and Server viewers at `graph.gildra.net` automatically from
their remote default branches. The target is the existing production origin;
Cloudflare DNS, application containers, databases, and sibling worktrees are
outside the mutation scope.

## Confirmed facts and assumptions

- Gildra's remote default branch is `master`; its initial resolved SHA is
  `8dac4fbddbcb3ced13c9a57c0e39fe7bce573d5b`.
- Server's remote default branch is `main`; its initial resolved SHA is
  `06df9c19a3b99ea8f5272726cbe640883b4353f5`.
- Both repositories are readable over HTTPS without deployment credentials.
- The Graphify skill lock pins
  `33362d969292b57eda82f3fbd9eb5f3f5bc9bbc2`, whose package version is
  `0.9.53`.
- The official Gitleaks `8.21.2` Linux x64 archive checksum resolves to
  `5bc41815076e6ed6ef8fbecc9d9b75bcae31f39029ceb55da08086315316e3ba`.
  Its extracted binary checksum is
  `50b742abd7daad8bbddb6301f3017efb680632d9a5b3b4d8f137b3aac250e359`.
- The requested automation cadence was not specified. The selected default is
  hourly with up to ten minutes of jitter; it can be changed with a timer
  override.
- GitHub Actions was considered, but a server-side timer is smaller and avoids
  creating or relying on an unconfirmed production SSH/deploy secret.

## Exact change and approval

- Add an unprivileged systemd oneshot/timer and a root-owned pinned Graphify
  runtime under `/usr/local/lib/gildra-graph`.
- Generate both viewers in disposable exact-SHA checkouts, validate them, and
  atomically switch `/opt/gildra/static/graph/current`.
- Scan the exact staged public release with pinned Gitleaks, verify recorded
  artifact hashes before a no-op, and enforce repository URL/resource limits.
- Point only the graph nginx vhost at the `current` release and keep five
  rollback releases.
- Approval evidence: the service owner's current Codex request for automated
  graph updates.
- Planned execution window: 2026-09-04 22:00–23:59 UTC.
- Plan digest and operation-request evidence: pending final pre-deploy gate.

## Abort, rollback, and verification

- Abort if symbiosis ownership changes, the rollback snapshot fails, the pinned
  runtime cannot be reproduced, local tests fail, either source cannot be
  fetched by exact SHA, generated output fails screening, or Compose/nginx/unit
  validation fails.
- A service-private bind mount exposes only the graph publication directory to
  the unprivileged account; that publication directory is owned by the account,
  while `/opt/gildra` remains `0700 root:root`.
- A refresh failure before the atomic symlink switch preserves the currently
  served release. Deployment rollback restores the graph directory, nginx
  vhost, unit files, and `/opt/gildra` access metadata from the timestamped
  snapshot, then recreates only nginx.
- Verify local integration tests, Bash/unit/nginx syntax, first service
  status/journal, timer schedule, manifest SHAs, public HTTPS/health, both
  browser canvases, and existing web/API paths.

## Selected capabilities

- Used: Luna context scout, Gildra symbiosis, planning/task breakdown, DevOps
  core/platform contracts, Linux/systemd operations, network-edge operations,
  Bash generation/validation, Gitleaks secret scanning, and Git
  workflow/versioning.
- Skipped: Cloudflare mutation because DNS already routes correctly; GitHub
  Actions because no CI-to-production credential is required; database/data
  recovery because no persistent application data changes.

## Evidence and result

### Review and local verification

- Luna context scout `01a06e73-6be7-78c0-a06d-e4a9e315d0d0` completed before
  skill selection and found no active conflict.
- Luna reviews `01a06e87-598f-7ad3-a73c-bc45cb9b6680`,
  `01a06e97-1891-7242-8424-e344fc489bcc`, and final focused reviewer
  `01a06e9d-39d9-7763-bfec-d8bb94d82a34` were all explicitly spawned with
  model `gpt-5.6-luna`. Their retention, artifact-integrity, secret-screening,
  URL, rollback, notifier, CI, resource-limit, bind-ownership, DNS, and path
  findings were resolved and rechecked.
- The final sub-agent incorrectly self-reported that Luna orchestration was
  unavailable while returning the requested Luna review. The root accepts the
  orchestrator's explicit model selection and agent ID as authoritative runtime
  evidence; its actual control review found no remaining implementation defect.
- The integration test covers success, verified no-op, corruption-triggered
  rebuild, generator failure, unsafe path rejection, Gitleaks rejection,
  unexpected-link pruning refusal, atomic switching, and retention.
- Both scripts pass `bash -n`, the Bash validator, and ShellCheck. `make
  check`, `actionlint .github/workflows/validate.yml`, and `git diff
  --check` pass.
- A full disposable run against both real remote default-branch SHAs succeeded:
  Gildra produced 4,474 nodes / 11,820 edges and Server produced 21 nodes / 43
  edges. The staged public release passed Gitleaks and the second run was a
  hash-verified no-op.

Production gate, deployment, live systemd/nginx/browser verification, final
commit evidence, and push are pending.
