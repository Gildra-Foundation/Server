# Publish the Graphify viewer on the production origin

This runbook serves and automatically refreshes a two-repository Graphify
viewer from the existing production nginx at `https://graph.gildra.net/`. The
selector opens the Gildra application graph by default and can switch to the
Server infrastructure graph. Cloudflare Pages is not used.

## Preconditions

- Retain the current session and verify an independent recovery path.
- Confirm the wildcard origin certificate covers `*.gildra.net`.
- Run `nginx -t` against the current container.
- Create a timestamped rollback directory under `/opt/gildra/rollback/` and
  copy `compose.prod.yml`, `compose.runtime.yml`, and the current nginx files.
- Confirm the reviewed graphs contain no secrets, inventories, raw logs,
  database dumps, private host identifiers, or rendered secret configuration.
- Generate artifacts from disposable checkouts of exact remote SHAs. Never run
  Graphify against or write into a sibling checkout.
- Confirm the existing `gildra-notify@.service` and its handler are installed;
  the graph refresh service uses that platform notifier on failure.

## Automated publishing contract

`scripts/refresh-graph-site.sh` resolves each repository's remote default
branch, fetches the exact resolved SHA over HTTPS, removes repository symlinks,
and runs the pinned Graphify runtime in code-only mode. It publishes only the
selector, two generated viewers, and a provenance manifest.

The publisher validates the Graphify pin/version, graph JSON shape, source
paths, bounded credential/private-path patterns, artifact sizes, and artifact
hashes. Gitleaks scans the complete staged public release before publication.
A matching manifest is a no-op only while all three published artifact hashes
still match. A failed fetch, generation, or validation leaves the current
release untouched. `flock` makes overlapping invocations a successful no-op.

Completed releases live under `/opt/gildra/static/graph/releases/`. Nginx serves
the relative `/opt/gildra/static/graph/current` symlink, which is replaced
atomically only after both viewers pass. Five releases are retained by default.
The public `manifest.json` records both source SHAs/default branches, node and
edge counts, the selector checksum, and Graphify provenance.

The systemd timer runs hourly with up to ten minutes of jitter and catches up
after downtime. The oneshot service runs as the unprivileged `gildra-graph`
user, has no capabilities, and can write only its state/runtime directories.
Systemd bind-mounts `/opt/gildra/static/graph` into the service namespace as
`/var/lib/gildra-graph/site`; the account receives no traversal access to the
mode-`0700` `/opt/gildra` tree or its secrets and backups.
The unit also caps Graphify at 300% CPU, 6 GiB memory, and 128 tasks; the
publisher separately caps checkout file count/bytes and generated artifact
sizes.

## Install or upgrade

1. Install `deploy/graph-site/nginx.conf` as
   `/opt/gildra/infra/nginx/graph.conf` with mode `0644`.
2. Create the locked `gildra-graph` system account, its
   `/var/lib/gildra-graph` home, and an empty `site` bind-mount target. Keep
   `/opt/gildra` at `0700 root:root`. Make only
   `/opt/gildra/static/graph` owned and writable by `gildra-graph`; verify write
   access through the service-private bind target as that account.
3. Build `/usr/local/lib/gildra-graph/venv` from the immutable Graphify commit
   `33362d969292b57eda82f3fbd9eb5f3f5bc9bbc2`; verify it reports
   `graphify 0.9.53`. Install the matching full SHA in
   `/usr/local/lib/gildra-graph/graphify.pin`.
4. Install the official Gitleaks `8.21.2` Linux x64 binary as
   `/usr/local/lib/gildra-graph/gitleaks`. Verify the release checksum is
   `5bc41815076e6ed6ef8fbecc9d9b75bcae31f39029ceb55da08086315316e3ba`
   before installation and verify `gitleaks version`.
5. Install `scripts/refresh-graph-site.sh` and `graph-site/index.html` under
   `/usr/local/lib/gildra-graph/`, owned by root and not writable by the
   service account.
6. Install the service and timer from `deploy/graph-site/` into
   `/etc/systemd/system/`, run `systemd-analyze verify`, and reload systemd.
7. Add the two read-only mounts from
   `deploy/graph-site/compose.prod.override.yml` to the final production Compose
   rendering. Account for any `volumes: !override` section in later overlays.
8. Start `gildra-graph-refresh.service` manually before changing nginx. Inspect
   its status, journal, `current` target, and `manifest.json`.
9. Run `docker compose config --quiet`, then use a disposable nginx service to
   run `nginx -t` before recreating only the nginx service. Enable and start
   `gildra-graph-refresh.timer` after the live checks pass.

Do not update Graphify automatically. Change its locked commit/version through
a separately reviewed repository change, then rebuild the root-owned runtime.

## Verify

- Run `nginx -t` in the recreated nginx container.
- Confirm `systemctl is-active gildra-graph-refresh.timer`, inspect the next
  trigger with `systemctl list-timers`, and confirm the last service result is
  successful.
- Compare both remote default-branch SHAs with `current/manifest.json`.
- Resolve `graph.gildra.net` locally to the origin and verify `/` returns the
  Graphify HTML and `/healthz` returns `ok`.
- Verify existing public hosts before changing DNS.
- If this is a first-time site deployment and no DNS route exists, create the
  proxied Cloudflare record only through a separate approved DNS operation.
- Verify public DNS, HTTP-to-HTTPS redirect, TLS, `/`, `/healthz`, security
  headers, and both interactive graphs in a browser. Confirm Gildra is the
  default and the `Server` control switches to the second graph with keyboard
  and pointer input.

## Rollback

For a generated-content rollback, stop the timer, select a retained release
only after verifying its `manifest.json` and recorded artifact hashes, create
a temporary relative link named `.current.rollback` to
`releases/<known-good-release>`, and atomically rename that link to `current`.
Verify `/healthz`, the selector, and both viewers before restarting the timer.

For a full automation rollback, stop and disable the timer, then restore the
saved graph directory, nginx vhost, service/unit files, and root-owned runtime.
Reload systemd, validate the restored Compose/nginx configuration, and recreate
only nginx. Remove the dedicated account/runtime only if this deployment
created them and the rollback snapshot no longer references them. Do not
recreate application or database services, and do not alter Cloudflare DNS for
an automation-only rollback.
