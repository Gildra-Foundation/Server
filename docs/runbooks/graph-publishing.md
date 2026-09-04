# Publish the Graphify viewer on the production origin

This runbook serves a two-repository Graphify viewer from the existing
production nginx at `https://graph.gildra.net/`. The selector opens the Gildra
application graph by default and can switch to the Server infrastructure graph.
Cloudflare Pages is not used.

## Preconditions

- Retain the current session and verify an independent recovery path.
- Confirm the wildcard origin certificate covers `*.gildra.net`.
- Run `nginx -t` against the current container.
- Create a timestamped rollback directory under `/opt/gildra/rollback/` and
  copy `compose.prod.yml`, `compose.runtime.yml`, and the current nginx files.
- Confirm the reviewed graphs contain no secrets, inventories, raw logs,
  database dumps, private host identifiers, or rendered secret configuration.
- Generate the Gildra artifact from an immutable `git archive` in a temporary
  directory. Never run Graphify against or write into a dirty sibling checkout.

## Install

1. Install `deploy/graph-site/nginx.conf` as
   `/opt/gildra/infra/nginx/graph.conf` with mode `0644`.
2. Install `graph-site/index.html`, `graph-site/gildra.html`, and
   `graph-site/server.html` under `/opt/gildra/static/graph/` with mode `0644`.
3. Keep Graphify JSON and reports in the repository or private build workspace;
   the public site requires only the reviewed HTML artifacts.
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
  headers, and both interactive graphs in a browser. Confirm Gildra is the
  default and the `Server` control switches to the second graph with keyboard
  and pointer input.

## Rollback

Remove the graph DNS record if created, restore the saved Compose and nginx
files, validate the restored configuration, and recreate only nginx. Do not
recreate application or database services.
