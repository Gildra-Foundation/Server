# Graph publishing

The Graphify output is a static Cloudflare Pages deployment. The intended
custom domain is `graph.gildra.net`; no production server or database is
required for this viewer.

## Build

From the repository root, regenerate the safe local graph and report:

```bash
graphify . --code-only
graphify cluster-only .
```

Do not include production inventories, raw logs, database dumps, secrets, or
rendered secret-bearing configuration in the input corpus.

## Deploy

Create or select the Cloudflare Pages project `gildra-graph`, then deploy the
prebuilt directory using the repository Wrangler configuration:

```bash
npx wrangler pages deploy graphify-out --project-name=gildra-graph \
  --commit-hash="$(git rev-parse HEAD)"
```

Attach `graph.gildra.net` under the Pages project's Custom domains. Cloudflare
must manage the `gildra.net` zone for this custom domain. Verify DNS, HTTPS,
the graph viewer, and that no private source paths or secrets are published.

The Pages project, custom domain, account ID, and API token are external
configuration and must not be committed. Use a scoped token through the
operator environment or CI secret store.
