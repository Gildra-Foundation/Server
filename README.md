# Gildra infrastructure

Reproducible, reviewable infrastructure for the Gildra project. The repository is
currently at **stage 0**: it prepares an empty Debian host and defines the isolated
data services. It does not deploy application code or modify the purchased server.

## Safety model

- No IP addresses, passwords, API tokens, private keys, or production inventory are committed.
- Example files use documentation-only values and cannot authorize a deployment.
- Stateful services expose no host ports.
- Server changes require an explicit host limit, check-mode review, a change record,
  and a verified OVH console or rescue path.
- Production images must be locked by digest. Exact tags in `compose/env.example`
  are review defaults, not production approval.

## Repository map

```text
ansible/                 Host audit and Debian bootstrap
compose/                 Isolated PostgreSQL, ClickHouse and Redis services
docs/architecture.md     Scope and trust boundaries
docs/runbooks/           Human-operated procedures
docs/operations/         Append-only change records
scripts/validate.ps1     Local, secret-safe validation
.github/workflows/       Pull-request checks only
```

## Local validation

Requirements: PowerShell 7, Docker Compose, Python 3.11+, `ansible-core==2.19.12`, and
`yamllint==1.38.0`.

Run Ansible from Linux, WSL, or CI; native Windows is not an Ansible control node.

```powershell
./scripts/validate.ps1
```

Use the production switch only after replacing image tags with reviewed digests:

```powershell
./scripts/validate.ps1 -Production
```

## Preparing an inventory

Copy the example locally. The destination is ignored by Git.

```powershell
Copy-Item ansible/inventories/production/hosts.example.yml `
  ansible/inventories/production/hosts.yml
```

Put only a hostname or SSH-config alias in `hosts.yml`; never put a password or
private key in it. Follow [the bootstrap runbook](docs/runbooks/bootstrap.md) before
using a mutating playbook.

## Current non-goals

- Application Dockerfiles: Go and Next.js do not exist yet.
- Cloudflare, DNS, firewall, and SSH mutations.
- Database initialization or migrations.
- Deployment to the purchased server.
- GitHub push: this local repository has no configured remote yet.
