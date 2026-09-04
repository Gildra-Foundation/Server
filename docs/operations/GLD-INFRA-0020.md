# GLD-INFRA-0020 — Publish Graphify viewer on production origin

Status: `partially_applied`

- Owner: Gildra project owner
- Environment: current Gildra production host and Cloudflare zone `gildra.net`
- Risk: R2, additive static origin route and DNS record
- Prepared: 2026-09-04
- Secret material: none

## Objective

Serve the generated Graphify viewer from the existing production nginx at
`https://graph.gildra.net/`. Cloudflare Pages is not used.

## Approved scope

- Copy only the generated `graph.html` as the static site index.
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

## Remaining blocker

The Cloudflare plugin available in the current session exposes documentation
skills but no callable DNS or Zone mutation tool. No Cloudflare API credential
is present in the operator environment. Therefore the proxied DNS record for
`graph.gildra.net` has not been created. The origin is ready, but public deploy
verification remains blocked until a Cloudflare DNS-capable connector is made
available or an operator creates the proxied record targeting the existing
Gildra origin.

## Luna review disposition

- Fixed the open redirect concern by pinning the HTTP redirect destination to
  `https://graph.gildra.net`.
- Added a repeatable production-origin publishing runbook and absolute mount
  sources to remove Compose path ambiguity.
- HSTS is intentionally deferred until public DNS/TLS verification succeeds.
- The integrity-pinned `unpkg.com` viewer dependency remains an accepted
  availability risk for the first publication; self-hosting is follow-up work.
