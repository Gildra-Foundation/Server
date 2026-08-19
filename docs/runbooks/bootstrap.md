# Bootstrap runbook

Operation family: `GLD-HOST-BOOTSTRAP`. A real server bootstrap is production-impacting
R3 work. The repository scaffold itself is R1.

## Preconditions

1. Confirm the OVH server identifier and that Gildra owns it.
2. Confirm Debian 13 and the expected public-key fingerprint.
3. Verify OVH console or rescue access; keep the current SSH session open.
4. Record RAID1, disk SMART, filesystem, memory, listening ports, and current users.
5. Create a change record with the exact inventory revision and operator.
6. Do not paste credentials into the repository, chat, terminal history, or evidence.

## Read-only audit

```bash
cd ansible
ansible-playbook playbooks/audit.yml \
  --inventory inventories/production/hosts.yml \
  --limit gildra_prod
```

Review output before saving it. Redact IP addresses, usernames, serial numbers, and
other host identifiers from any evidence committed to Git.

## Check mode

```bash
cd ansible
ansible-playbook playbooks/bootstrap.yml \
  --inventory inventories/production/hosts.yml \
  --limit gildra_prod \
  --check --diff \
  --extra-vars gildra_change_approved=true
```

Check mode is advisory. Package/service behavior still requires human review.

## Apply

Apply only after the check-mode diff has been approved for the exact host and commit.

```bash
cd ansible
ansible-playbook playbooks/bootstrap.yml \
  --inventory inventories/production/hosts.yml \
  --limit gildra_prod \
  --extra-vars gildra_change_approved=true
```

## Verification

- Reconnect in a second SSH session before closing the first one.
- Run `systemctl is-active docker` and `docker version`.
- Confirm `/srv/gildra` ownership and free disk space.
- Run the audit playbook again and attach redacted evidence to the operation record.
- Do not run `docker compose up` until secrets, image digests, backup destination,
  and restore procedure have been approved.

## Rollback

The current playbook does not change SSH or firewall policy. If Docker configuration
validation fails, do not restart Docker. Restore the previous `/etc/docker/daemon.json`
through Ansible or the verified OVH console, then rerun validation.
