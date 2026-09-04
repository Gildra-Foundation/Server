# GLD-INFRA-0021 — Dual-repository Graphify viewer

## Operation, owner, and policy

- Operation ID: `ops-gld-graph-dual-repo-20260904`
- Requester / accountable owner: workspace user / Gildra service owner
- Policy: `default-baseline` v2.0
- Data classification: public
- Status: verified

## Objective and target

Publish Gildra as the default graph at `graph.gildra.net` and add an accessible
switch to the Server graph. The target is the existing production nginx origin;
DNS and Cloudflare configuration are unchanged.

## Confirmed facts

- The current graph site is served by the existing production nginx container.
- The Gildra source artifact was generated read-only from the remote default
  branch's immutable revision `8dac4fbddbcb3ced13c9a57c0e39fe7bce573d5b`
  via a temporary `git archive`. HTTPS `ls-remote` and the deployed application
  image metadata agree on this revision.
- Graphify extracted 4,466 nodes and 11,812 edges from 583 code files. It
  conservatively skipped `tokens.css`; 137 SQL files were skipped because the
  optional SQL parser is not installed.
- The Server artifact was regenerated from Server revision
  `82130437a24da029d1feba7b7c1ccd475dded5b4` and matched the previously
  generated HTML byte-for-byte.
- Sensitive-token and private-host-path scans returned no findings in the
  generated Gildra HTML/JSON artifacts.
- Symbiosis production, edge, nginx, and exact repository path locks are held
  by `codex-graph-switch-20260904`.

## Exact change and approval

- Risk: R3, reversible production static/proxy change; no persistent data,
  database, DNS, secret, or application service mutation.
- Plan digest:
  `sha256:d10f3592dadfca371fd946c1468e074ce879d54b5b6e2445d49634445301f6fc`
- Scope: `/opt/gildra/static/graph`, the graph nginx vhost, and nginx recreation
  only.
- Approval evidence: the service owner's current Codex task request to show the
  Gildra repository and provide a Server repository switch.
- Execution window: 2026-09-04 21:35–23:05 UTC.

## Abort, rollback, and verification

- Abort before nginx recreation if the lock changes, artifacts fail screening,
  rollback capture fails, Compose/nginx validation fails, or the live target
  differs materially from the recorded plan.
- Roll back by restoring the timestamped graph static directory and graph vhost,
  validating nginx, and recreating nginx only.
- Verify Compose render, disposable and live nginx syntax, public HTTPS and
  health, both graph canvases and selector behavior, browser console, and the
  existing web/API paths. Observe the public path for five minutes.

The rollback snapshot is
`/opt/gildra/rollback/graph-multi-repo-20260904T213829Z`. It contains the prior
graph vhost, static graph directory, and production/runtime Compose overlays.

## Selected capabilities

- Used: Luna context scout, Graphify, planning/task breakdown, frontend UI,
  Gildra symbiosis, DevOps core/contracts, Docker operations, Linux operations,
  and network-edge operations.
- Skipped: Cloudflare mutation because DNS and edge routing already exist and
  are outside this change; data recovery because no stateful data changes.

## Result

- Published `index.html`, `gildra.html`, and `server.html` under the existing
  read-only nginx graph mount. Recreated only `gildra-nginx-1`; its pinned image
  remained unchanged and healthy.
- Disposable and live `nginx -t`, rendered Compose validation, `/healthz`, the
  graph shell, both graph artifacts, the main site, and the API live endpoint
  passed. Public paths remained healthy after a greater-than-five-minute
  observation window.
- Chromium confirmed Gildra is the default, both canvas graphs render, the
  keyboard switch selects Server in 54 ms, the 320 px layout fits, and no
  console errors occur.
- Fresh Luna review found a slow single-iframe switch and missing failure state;
  both were fixed by preloading isolated same-origin viewers and adding a
  30-second timeout, `error` handling, and a direct-view link.
- HSTS was intentionally not added: a long-lived browser policy is not required
  for this selector change and needs a separate domain-level decision.
- Generated Graphify controls retain upstream mouse-oriented interactions, and
  no permanent Playwright dependency was added to this infrastructure-only
  repository. The executed containerized Chromium journey is the release
  evidence; improving generator accessibility and adding a reusable smoke
  target remain follow-ups.
