# Privileged read-only host audit attempt — 2026-08-20

Status: `partially_verified`

Operation family: `GLD-HOST-AUDIT-PRIVILEGED`

Audit window: `2026-08-20T19:20:10Z`–`2026-08-20T19:24:36Z`

Target: production candidate via SSH alias `gildra-prod`

Server source revision: `402d0434c95176aa11da21daf64a5fb506470683`

Hostnames, addresses, source ranges, account names, fingerprints, serials, UUIDs,
raw logs and provider identifiers: intentionally omitted

## Executive summary

Владелец запросил privileged read-only audit и запретил installation, mutation и
service restart. Все root-only команды были вызваны с `sudo -n`; их полезный
вывод подавлялся до redaction. На target отсутствует non-interactive sudo:
каждый privileged probe завершился до запуска audit tool с `password required`.
Пароль не запрашивался и не передавался.

Поэтому audit расширил baseline безопасными world-readable проверками, но не
закрыл privileged controls. RAID остаётся clean и non-degraded, failed units не
обнаружены, package cache не показывает ожидающих обновлений, Docker/Gildra
runtime отсутствует. Effective SSH policy, active firewall ruleset, privileged
listener ownership, full AppArmor profile set, authentication events, sudo rules,
SMART и root backup jobs остаются недоказанными.

Stage 0 остаётся `in progress`. Этот документ не разрешает Stage 1 apply.

## Preconditions

| Precondition | Result | Redacted summary |
|---|---|---|
| exact target and read-only scope | `verified` | target identity matched the existing production-candidate baseline; identifiers omitted |
| clean pinned Server revision | `verified` | clean `main`, aligned with local `origin/main`, revision recorded above |
| current SSH session | `verified` | active management session observed; endpoints omitted |
| OVH console/rescue path | `not_verified` | owner confirmation was not available as audit evidence |
| evidence redaction | `verified` | privileged raw output was suppressed; only summaries are committed |
| absent tools remain absent | `verified` | no package installation or substitute download was performed |

## Tool identities

| Tool | Observed identity |
|---|---|
| OpenSSH server | OpenSSH 9.2, OpenSSL 3.0.20 |
| socket inspection | iproute2 `ss` 6.1.0 |
| iptables frontend | iptables 1.8.9 using the nf_tables backend |
| sysctl | procps-ng 4.0.2 |
| software RAID | mdadm 4.2 |
| service manager/journal | systemd 252 |
| privilege boundary | sudo 1.9.13p3 |
| `nft` CLI | `tool_absent` |
| `smartctl` | `tool_absent` |
| Docker | `tool_absent` |
| Ansible on target | `tool_absent` |

## Control evidence

Raw evidence was not retained in Git or another storage location during this
pass. For blocked probes, command output was discarded and only the exit result
was recorded.

| Control | Timestamp UTC | Tool | Result | Redacted summary | Raw evidence | Candidate change |
|---|---|---|---|---|---|---|
| `target.identity-time` | 19:20 | coreutils | `verified` | expected baseline and UTC observed; identity omitted | not retained | none |
| `repository.pin` | 19:20 | Git | `verified` | clean pinned revision recorded above | Git history | none |
| `access.console-rescue` | 19:20 | owner evidence | `not_verified` | cannot be proven from the host | none | owner verifies provider console/rescue before any mutation |
| `ssh.syntax` | 19:21 | `sudo sshd -t` | `blocked` | sudo authentication was unavailable | suppressed | repeat with approved scoped privilege |
| `ssh.effective-policy` | 19:21 | `sudo sshd -T` | `blocked` | root-only include remains unreadable; visible file says password and keyboard-interactive auth off, X11 on | suppressed | prepare a first-match-safe SSH drop-in only after effective output is reviewed |
| `network.listeners` | 19:21 | `sudo ss -lntup` | `blocked` | non-privileged view confirms SSH and LLMNR beyond loopback plus DHCP client; owning processes are not fully proven | suppressed | restrict management ingress and disable unneeded LLMNR in Stage 1 |
| `firewall.nft` | 19:21 | `nft` | `tool_absent` | native nft CLI is absent | none | do not install until firewall backend is approved |
| `firewall.iptables-v4` | 19:21 | `sudo iptables-save` | `blocked` | iptables package exists with nf_tables backend; effective rules unknown | suppressed | select one Docker-compatible backend after privileged evidence |
| `firewall.iptables-v6` | 19:21 | `sudo ip6tables-save` | `blocked` | effective IPv6 rules unknown | suppressed | cover IPv4 and IPv6 in the same reviewed policy |
| `firewall.provider` | 19:21 | provider control plane | `not_verified` | provider firewall state is outside host visibility | none | separate read-only owner/provider verification |
| `network.sysctl` | 19:22 | sysctl 4.0.2 | `verified` | ASLR=2 and dmesg restriction=1; kptr restriction=0, rp_filter=0, IPv4 redirects/send_redirects=1, IPv6 accept_redirects=1 | not retained | reviewed sysctl drop-in in Stage 1 |
| `raid.summary` | 19:22 | procfs/sysfs | `verified` | two RAID1 arrays clean, degraded=0, sync idle, mismatch count=0 | not retained | none while state remains clean |
| `raid.detail` | 19:21 | `sudo mdadm --detail` | `blocked` | per-member state and full mdadm detail not collected | suppressed | repeat before package or storage work |
| `disk.smart` | 19:22 | `smartctl` | `tool_absent` | SMART health and attributes cannot be collected | none | approved Stage 1 package install, then read health without starting a self-test |
| `services.failed-enabled` | 19:22 | systemd 252 | `verified` | failed units=0; SSH, AppArmor, unattended upgrades and RAID monitor active; Docker/containerd absent | not retained | preserve baseline and recheck after every apply wave |
| `apparmor.profile-state` | 19:21 | `sudo aa-status` | `blocked` | service is active, but profile/enforcement set needs privilege | suppressed | repeat before Docker activation |
| `packages.security-state` | 19:22 | APT metadata | `verified` | fresh local package lists, zero pending upgrades, no reboot marker; no network refresh was performed | not retained | rerun preflight immediately before an approved change |
| `accounts.sudo-membership` | 19:22 | NSS | `verified` | two interactive accounts are members of the administrative group; names omitted | not retained | owner confirms expected account inventory |
| `sudo.effective-rules` | 19:21 | `sudo -n -l` | `blocked` | effective grants and command restrictions unknown | suppressed | obtain redacted scoped output from an approved privileged session |
| `auth.events` | 19:21 | `sudo journalctl` | `blocked` | full success/failure history is unavailable | suppressed | private review with source addresses redacted before Git evidence |
| `backup.jobs-destination` | 19:23 | systemd/NSS-visible files | `not_verified` | only OS package-database backup timer observed; no Gildra runtime, off-host job or destination reference observed; root jobs remain unproven | not retained | Stage 2 recovery design; privileged root-job check before Stage 1 |
| `backup.restore-proof` | 19:23 | operation evidence | `not_verified` | no isolated Gildra restore evidence exists | none | stateful deployment remains blocked until Stage 2 acceptance |
| `raid.alert-delivery` | 19:23 | mdadm/service inventory | `not_verified` | RAID monitor runs, but no local external-delivery transport was detected | not retained | choose an external recipient/path and prove delivery during Stage 1 |

## Findings and gates

### Blockers

1. `sudo` privilege is unavailable non-interactively, so the privileged audit is
   incomplete. Do not request or paste a password into chat. Repeat via an
   owner-operated privileged session or a separately approved, time-bounded
   command allowlist.
2. Provider console/rescue access has not been recorded as owner-verified.
3. Effective SSH, IPv4/IPv6 firewall and provider-firewall state remain unknown.

### Confirmed Stage 1 candidates, not authorization

- disable LLMNR on the public path;
- replace permissive redirect/rp_filter/kptr sysctl values with an approved
  single-host baseline;
- disable SSH X11 only after first-match effective policy and a second key login
  are proven;
- install SMART tooling only in the approved Stage 1 change and verify both disks;
- connect RAID alerts to a tested external delivery path;
- install a Compose v2-capable Docker package set, not Debian's Compose v1 package.

## Completion state

No host file, package, account, firewall rule, sysctl, service, Docker object,
database, backup or external control plane was changed. No service was reloaded
or restarted. No sibling Gildra repository was accessed because Stage 0/1 host
baseline does not require an application contract.

The separate Stage 1 draft is
[`GLD-INFRA-0003`](../operations/GLD-INFRA-0003.md).
