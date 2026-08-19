# GLD-INFRA-0001 — initial infrastructure scaffold

- Owner: Gildra project owner
- Environment: local repository only
- Risk: R1, reversible local files
- Date: 2026-08-19
- Target server: not contacted
- Secret material: none

## Objective

Create a reviewable, secret-free starting point for Debian bootstrap, Docker Compose,
CI validation, and future production change records.

## Acceptance criteria

- No production address, credential, private key, or token is tracked.
- Ansible inventory is an ignored local file with a committed example.
- Host-changing playbook requires explicit approval input and host limit.
- Compose publishes no database ports and uses file-backed secrets.
- CI has read-only permissions and no deployment credentials.
- Local validation reports actionable failures.

## Recovery

All changes in this operation are new local files. Recovery is a reviewed Git revert.
No server, cloud, DNS, database, or GitHub control-plane state is changed.

## Verification evidence

- Secret-path and credential-pattern checks: passed locally.
- YAML lint: passed locally with `yamllint==1.38.0`.
- Ansible syntax: pending Linux/CI runner.
- Docker Compose render: pending Docker/CI runner.
- Server verification: not applicable; server was not contacted.

Status: `partially_verified` until CI completes on the pushed revision.
