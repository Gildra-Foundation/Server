# GLD-INFRA-0003 — Stage 1 host baseline and safe access

Status: `draft_blocked`

- Owner: Gildra project owner
- Environment: production candidate via SSH alias `gildra-prod`
- Risk: R3, access/network/runtime changes
- Prepared: 2026-08-20
- Server source revision audited: `402d0434c95176aa11da21daf64a5fb506470683`
- Target mutation: not authorized
- Secret material: references only; management ranges and recipients stay outside Git

## Objective

Implement Stage 1 from `docs/deployment-plan.md`: a minimal Debian 12 host
baseline with verified access, disk/RAID monitoring, Docker Engine plus Compose
v2, one reviewed firewall backend, no public LLMNR, reviewed sysctls and an empty
`/srv/gildra` runtime root. Do not start Compose or create production data.

This card is a plan, not apply approval. It is blocked by incomplete privileged
evidence and missing owner decisions below.

## Inputs and observed facts

Observed at the pinned revision and audit window:

- Debian 12, x86_64, low load, ample current memory/filesystem headroom;
- two software RAID1 arrays clean and non-degraded through procfs/sysfs;
- SSH, AppArmor, unattended upgrades and RAID monitoring active;
- LLMNR and SSH listen beyond loopback; Docker and Gildra runtime are absent;
- iptables 1.8.9 uses the nf_tables backend, while the `nft` CLI is absent;
- local Debian 12 APT metadata offers `docker.io` 20.10 and
  `docker-compose` 1.29.2, but no Compose v2 package candidate;
- effective SSH, firewall rules, AppArmor profiles, authentication history,
  sudo rules and root backup jobs are not proven;
- `smartctl` is absent and external RAID alert delivery is not proven.

Official Docker documentation supports Debian 12 through Docker's APT repository
and provides Compose v2 as `docker-compose-plugin`. It also states that Docker
creates firewall rules and that disabling its firewall integration is generally
unsafe. Native nftables support in Docker 29 is still experimental. References:

- [Install Docker Engine on Debian](https://docs.docker.com/engine/install/debian/)
- [Install the Docker Compose plugin](https://docs.docker.com/compose/install/linux/)
- [Packet filtering and firewalls](https://docs.docker.com/engine/network/packet-filtering-firewalls/)
- [Docker with nftables](https://docs.docker.com/engine/network/firewall-nftables/)

## Assumptions requiring owner decision

1. The official Docker APT repository is an acceptable third-party package
   source. Exact key fingerprint/hash and package versions must be pinned in the
   final diff; no convenience script is allowed.
2. The firewall implementation will use Docker's stable iptables integration
   through the current iptables-nft frontend, not Docker's experimental native
   nftables backend and not UFW.
3. Management IPv4/IPv6 source ranges are stable enough for an allowlist and can
   be stored only in ignored production inventory.
4. An external RAID/SMART alert recipient and transport owner will be provided.
5. Docker access remains through sudo; no human account is added to the
   root-equivalent `docker` group.
6. No application, database, edge or public HTTPS listener belongs to Stage 1.

Any rejected assumption returns this card to design; it does not authorize an
alternative automatically.

## Entry gates

All gates must be recorded as evidence before check mode:

- privileged audit repeated successfully for SSH, listeners, IPv4/IPv6 firewall,
  mdadm detail, AppArmor, sudoers, authentication events and root backup jobs;
- owner verifies OVH console/rescue and keeps the existing SSH session open;
- second independent key-based SSH session succeeds;
- no RAID degradation, SMART failure, package conflict or unexpected listener;
- provider firewall state is known, without changing it in this card;
- management source ranges and alert destination are approved outside Git;
- selected Docker repository key and exact package versions are reviewed;
- firewall/Docker interaction is proven first on an isolated Debian 12 test host;
- complete Ansible `--check --diff`, rendered firewall policy and rollback
  artifacts are reviewed for the exact target and commit.

## Proposed repository diff

The following is the bounded candidate diff. It must be made concrete and
reviewed in a follow-up revision before `draft_blocked` can change to
`ready_for_approval`.

| Path | Proposed change |
|---|---|
| `ansible/inventories/production/group_vars/all.yml` | remove `docker.io` and Compose v1; declare approved Docker CE package names, pinned-version variables, Stage 1 safety gates, sysctl values and firewall backend |
| ignored production `host_vars` | store management source ranges, expected admin identities and external alert references; never commit rendered values |
| `ansible/roles/common/tasks/main.yml` | split package installation, timezone, sysctl, resolver, SSH and filesystem work into independently validated task blocks |
| `ansible/roles/common/templates/00-gildra-sshd.conf.j2` | first-match-safe policy candidate: public-key auth enabled, password/keyboard-interactive/root login/X11 disabled; do not change forwarding until the effective contract is known |
| `ansible/roles/common/templates/60-gildra-sysctl.conf.j2` | candidate: `kptr_restrict=2`, loose reverse-path validation (`rp_filter=2`) and redirects/source routing disabled for IPv4/IPv6; do not force Docker forwarding off |
| `ansible/roles/common/templates/50-gildra-resolved.conf.j2` | set `LLMNR=no`; preserve the existing DNS source and mDNS state |
| `ansible/roles/firewall/` | add an iptables-nft policy and validation that preserves established traffic, loopback, required ICMP/ICMPv6 and DHCP, allows management SSH only from private inventory ranges, drops other inbound traffic and integrates future container filtering through `DOCKER-USER` |
| `ansible/roles/docker_host/tasks/main.yml` | add the reviewed Docker APT key/source without shell installers, install pinned `docker-ce`, `docker-ce-cli`, `containerd.io` and `docker-compose-plugin`, validate daemon config, and avoid adding users to the Docker group |
| `ansible/roles/docker_host/templates/daemon.json.j2` | retain bounded json-file logs and live-restore; keep Docker firewall management enabled; do not enable experimental native nftables |
| `ansible/roles/host_monitoring/` | install approved SMART tooling, read health/attributes without automatically starting a long self-test, and configure RAID/SMART delivery only through an external secret reference |
| `ansible/playbooks/audit.yml` | add a separate explicitly privileged read-only play/path whose commands have `changed_when: false` and whose committed evidence is redacted |
| `ansible/playbooks/bootstrap.yml` | sequence preflight, configuration validation, controlled activation and post-change verification; retain explicit approval and exact host limit gates |
| `docs/runbooks/bootstrap.md` | document Docker source/version pinning, iptables-nft/Docker ordering, second-session tests, external port verification and rollback commands |

Before approval, the complete generated diff must include exact file contents,
package versions and handler order. This draft deliberately does not invent the
unknown firewall ruleset, admin identities, source ranges or alert destination.

## Proposed target sequence

1. **Preflight only:** repeat the privileged audit; record redacted policy and
   private rollback evidence; verify console and second SSH access.
2. **Repository validation:** render all templates using redacted test inventory,
   run YAML/Ansible/Compose validation, secret scans and isolated Debian 12 tests.
3. **Target check mode:** run the exact pinned playbook with `--limit` and
   `--check --diff`; treat results as advisory.
4. **Approved package/config staging:** install only pinned packages and place
   reviewed files without starting Compose. Account for package post-install
   service activation in the approved diff.
5. **Validate before activation:** run `sshd -t`, effective `sshd -T`, firewall
   syntax/restore test, `dockerd --validate` and sysctl/resolver config checks.
6. **Controlled access activation:** apply SSH/firewall/resolver/sysctl ordering
   defined by the final diff while the original session and console remain open.
7. **Docker activation:** start the pinned daemon only after firewall integration
   is proven; do not pull images or run `hello-world` on production.
8. **Monitoring verification:** read SMART and mdadm detail, then prove an alert
   reaches the approved external recipient without simulating disk failure.
9. **Observation:** verify user access, listeners, rulesets, failed units,
   Docker/Compose versions, RAID/SMART and logs over the approved window.

Each activation group requires its own explicit approval. Approval of this draft
does not imply approval of all groups.

## Verification criteria

- existing and second SSH sessions remain usable; a new key login succeeds;
- `sshd -t` passes and effective policy matches the reviewed table;
- only approved management SSH is reachable externally; IPv4 and IPv6 agree;
- LLMNR is absent beyond loopback and DNS resolution still works;
- effective sysctls match the reviewed drop-in without breaking Docker networks;
- Docker daemon and containerd are healthy with failed units=0;
- `docker compose version` reports v2; installed package versions equal pins;
- no Compose project, application image, database or production volume exists;
- `/srv/gildra` and empty subdirectories have reviewed ownership and mode;
- both disks pass the approved SMART health read and RAID remains non-degraded;
- a test notification reaches the external alert owner;
- no secret, address, account identity or raw ruleset enters Git evidence.

## Abort conditions

Abort before or during apply on any of:

- console/rescue or second SSH path unavailable;
- effective firewall backend/rules differ from preflight;
- management source range is unknown or changes during the window;
- `sshd -t` failure or effective-policy mismatch;
- RAID degradation, SMART failure, filesystem error or unexpected disk activity;
- conflicting Docker/containerd/runc packages or unpinned package resolution;
- Docker changes forwarding/firewall behavior outside the isolated test result;
- DNS failure, new public listener, failed systemd unit or loss of alert path;
- check-mode/apply diff differs from the reviewed revision;
- any credential-like value appears in output.

No troubleshooting mutation is authorized after an abort. Preserve the current
session and use the approved rollback or provider console.

## Rollback and recovery

The final ready card must record private locations and hashes for previous SSH,
resolver, sysctl, firewall and Docker configs without committing their contents.
Rollback order:

1. keep the original SSH session open and use console/rescue if reachability is
   uncertain;
2. restore the previous IPv4/IPv6 ruleset atomically and verify management SSH;
3. restore previous SSH/resolver/sysctl files, validate syntax, then perform only
   the specifically approved reloads;
4. stop/disable newly introduced Docker services if they caused the failure;
5. restore the prior Docker config and package selection according to the pinned
   package rollback matrix; do not delete `/var/lib/docker` or any volume;
6. rerun the privileged read-only audit and observe for the approved window.

Because Stage 1 creates no application data, database restore is not expected.
Any discovered stateful data stops rollback and invokes the Stage 2 recovery
boundary instead of deleting data.

## Out of scope

- `docker compose up`, image pulls/builds and application containers;
- PostgreSQL, ClickHouse, Redis, migrations, secrets or volumes;
- backup execution or restore testing, which belong to Stage 2;
- Cloudflare, DNS, TLS, provider firewall mutation and public HTTPS;
- OAuth, monitoring hub, Sentry, Plausible, Postal or external paid resources;
- any write to another Gildra Foundation repository.

## Current decision

`blocked`: repeat and complete the privileged audit, verify console/rescue, choose
the external alert route, approve stable management ranges, and produce the exact
reviewed Ansible diff/package pins before requesting any Stage 1 target mutation.
