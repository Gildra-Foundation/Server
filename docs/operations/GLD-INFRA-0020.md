# GLD-INFRA-0020 — Publish Graphify viewer on production origin

Status: `applied`

- Owner: Gildra project owner
- Environment: current Gildra production host and Cloudflare zone `gildra.net`
- Risk: R2, additive static origin route and DNS record
- Prepared: 2026-09-04
- Secret material: none

## Objective

Serve the generated Graphify viewer from the existing production nginx at
`https://graph.gildra.net/`. Cloudflare Pages is not used.

## Approved scope

- Copy the generated `graph.html` as the static site index and `graph.json` as
  the machine-readable graph payload for inspection and future query tooling.
- Mount a dedicated read-only web root into the existing nginx container.
- Add a dedicated nginx virtual host for `graph.gildra.net`.
- Add a proxied Cloudflare DNS record after the origin passes local checks.
- Do not change application, database, SSH, firewall, or existing site routes.

## Preflight evidence

- Production host: current Debian host; nginx runs in Docker Compose project
  `gildra` and publishes ports 80/443.
- Existing Cloudflare Origin certificate covers `*.gildra.net`.
- Existing nginx configuration passed `nginx -t` before the change.
- Graphify viewer exists at `graphify-out/graph.html`.
- Rollback copies of the compose and nginx files are required before apply.

## Apply plan

1. Save `/opt/gildra/compose.prod.yml` and nginx configuration in a timestamped
   directory below `/opt/gildra/rollback/`.
2. Install the static viewer under `/opt/gildra/static/graph/index.html`.
3. Install the dedicated nginx vhost and add read-only mounts to the production
   compose override.
4. Render Compose, recreate only `nginx`, run `nginx -t`, and verify existing
   hosts plus the graph origin locally.
5. Add the proxied `graph.gildra.net` DNS record in Cloudflare and verify public
   DNS and HTTPS.

## Abort and rollback

- Abort before recreation if Compose rendering or nginx validation fails.
- On failed health verification, restore the saved compose/nginx files and
  recreate only nginx.
- Remove the new Cloudflare DNS record if it was created.
- Do not remove or recreate application/database containers.

## Verification criteria

- `nginx -t` passes after apply.
- `https://127.0.0.1/healthz` with host `graph.gildra.net` returns `200` and
  body `ok`.
- `/` returns the Graphify HTML and security headers.
- Existing `gildra.net`, `api.gildra.net`, and `cms.gildra.net` paths remain
  healthy.
- Public DNS and HTTPS resolve through Cloudflare after the DNS record exists.

## Applied evidence

- Rollback snapshot:
  `/opt/gildra/rollback/graph-site-20260904T135233Z/`.
- Static files installed read-only under `/opt/gildra/static/graph/`.
- Dedicated nginx configuration installed as
  `/opt/gildra/infra/nginx/graph.conf`.
- Production Compose mounts the vhost and static directory read-only.
- Compose rendering and isolated nginx `nginx -t` passed before recreation.
- Only `gildra-nginx-1` was recreated; application and database containers were
  not recreated.
- Post-apply `nginx -t` passed.
- Installed HTML SHA-256 matches the reviewed `graphify-out/graph.html` SHA-256.
- Installed nginx vhost SHA-256 matches `deploy/graph-site/nginx.conf`.
- Origin checks with local address resolution:
  - `graph.gildra.net/`: HTTP 200, Graphify HTML served;
  - `graph.gildra.net/healthz`: HTTP 200, body `ok`;
  - `gildra.net/`: HTTP 200;
  - `api.gildra.net/`: HTTP 200;
  - `cms.gildra.net/`: HTTP 404, matching its pre-existing root behavior.

## Cloudflare DNS and public verification

Cloudflare MCP OAuth was completed through a local-browser SSH callback tunnel.
The active `gildra.net` zone was found and a proxied A record for
`graph.gildra.net` was created with automatic TTL and the same origin as the
single apex A record. Readback confirmed the name, type, proxy state, and TTL.

Public verification passed: DNS resolves, HTTPS `/` returns HTTP 200 through
Cloudflare with the expected Graphify HTML, and `/healthz` returns `ok`.
Public HTTP redirects to the fixed HTTPS hostname. The edge certificate is
valid for `gildra.net`, and the expected content/security headers are present.
A headless Chromium check loaded the public page with HTTP 200, found the
Graphify title and one rendered canvas, and reported no console or page errors.

## Temporary direct-origin preview

At the owner's request, an unmatched-host HTTP-only nginx vhost serves the same
read-only graph root directly through the server IPv4 address. It is marked
`noindex, nofollow` and `no-store`. Existing named HTTPS vhosts remain
unchanged. Remove this default HTTP vhost after Cloudflare DNS and public HTTPS
verification are complete.

The complete deployed `nginx -T` output was checked after apply. The only
port-80 servers are the existing named redirect for Gildra hosts, the explicit
`graph.gildra.net` redirect, and this temporary default preview. Before this
change unmatched hosts fell through to the first named server and redirected
to HTTPS using the unmatched Host value, which made raw-IP preview unusable.
Named-host checks confirm that behavior for `gildra.net`, `api.gildra.net`, and
`graph.gildra.net` remains selected by their explicit server names.

The preview was removed after Cloudflare DNS and HTTPS verification succeeded.
The named `graph.gildra.net` origin vhost remains active. Its pre-removal config
is retained under
`/opt/gildra/rollback/graph-direct-preview-20260904T192643Z/graph.conf`.

## Luna review disposition

- Fixed the open redirect concern by pinning the HTTP redirect destination to
  `https://graph.gildra.net`.
- Added a repeatable production-origin publishing runbook and absolute mount
  sources to remove Compose path ambiguity.
- HSTS is intentionally deferred until public DNS/TLS verification succeeds.
- The integrity-pinned `unpkg.com` viewer dependency remains an accepted
  availability risk for the first publication; self-hosting is follow-up work.
