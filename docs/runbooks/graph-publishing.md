# Publish the Graphify viewer on the production origin

This runbook serves `graphify-out/graph.html` from the existing production
nginx at `https://graph.gildra.net/`. Cloudflare Pages is not used.

## Preconditions

- Retain the current session and verify an independent recovery path.
- Confirm the wildcard origin certificate covers `*.gildra.net`.
- Run `nginx -t` against the current container.
- Create a timestamped rollback directory under `/opt/gildra/rollback/` and
  copy `compose.prod.yml`, `compose.runtime.yml`, and the current nginx files.
- Confirm the reviewed graph contains no secrets, inventories, raw logs,
  database dumps, private host identifiers, or rendered secret configuration.

## Install

1. Install `deploy/graph-site/nginx.conf` as
   `/opt/gildra/infra/nginx/graph.conf` with mode `0644`.
2. Install `graphify-out/graph.html` as
   `/opt/gildra/static/graph/index.html` with mode `0644`.
3. Install `graphify-out/graph.json` beside it for inspection and future query
   tooling.
4. Add the two read-only mounts from
   `deploy/graph-site/compose.prod.override.yml` to the final production Compose
   rendering. Account for any `volumes: !override` section in later overlays.
5. Run `docker compose config --quiet`, then use a disposable nginx service to
   run `nginx -t` before recreating only the nginx service.

## Verify

- Run `nginx -t` in the recreated nginx container.
- Resolve `graph.gildra.net` locally to the origin and verify `/` returns the
  Graphify HTML and `/healthz` returns `ok`.
- Verify existing public hosts before changing DNS.
- Create a proxied Cloudflare DNS record for `graph.gildra.net` targeting the
  existing Gildra origin.
- Verify public DNS, HTTP-to-HTTPS redirect, TLS, `/`, `/healthz`, security
  headers, and the interactive graph in a browser.

## Rollback

Remove the graph DNS record if created, restore the saved Compose and nginx
files, validate the restored configuration, and recreate only nginx. Do not
recreate application or database services.
