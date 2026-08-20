# GLD-INFRA-0002 — product context and actual host alignment

- Owner: Gildra project owner
- Environment: Server repository only
- Risk: R1, reversible documentation and pre-deployment configuration
- Date: 2026-08-20
- Target server: no mutation
- Secret material: none

## Objective

Make the Server repository sufficient context for a new infrastructure agent:
describe Gildra, its requested stack, repository ownership, actual Debian version,
target architecture, staged production gates and the redacted initial audit.

## Changes

- Added root agent contract restricting writes to `Gildra-Foundation/Server`.
- Linked the organization repository index for read-only contract monitoring.
- Documented the product, full stack, target architecture and deployment phases.
- Recorded the 2026-08-20 non-privileged audit without host identifiers.
- Changed the Ansible expected OS from Debian 13 to the observed Debian 12.
- Updated bootstrap prerequisites and removed the stale “no Git remote” claim.

## Acceptance criteria

- A fresh agent can explain what Gildra is before proposing server changes.
- Sibling repositories are explicitly read-only; design cannot be modified.
- Documentation distinguishes current state, target state and unknown contracts.
- Debian assertion matches the purchased host.
- No production address, hostname, identifier, credential, private key or token
  is tracked.
- Repository validation and CI pass on the committed revision.

## Recovery

Git revert of this change restores the previous scaffold. No server, Docker,
database, DNS, Cloudflare or external-provider state is changed.

## Verification evidence

- Initial host observations: recorded as `partially_verified` in the audit.
- `git diff --check`: passed locally.
- Secret-path, known credential-pattern, mutable-tag and published-database-port
  checks: passed locally.
- GitHub Actions `Validate infrastructure` run
  [32403580754](https://github.com/Gildra-Foundation/Server/actions/runs/32403580754)
  passed for revision `7223d281a41d5f12b0a0c65c2c6cde69c0e0e46e`,
  including Docker Compose render, yamllint and Ansible syntax.
- Server mutation: not applicable.

Status: `verified` for the repository-only scope. The host audit remains
`partially_verified` as documented separately.
