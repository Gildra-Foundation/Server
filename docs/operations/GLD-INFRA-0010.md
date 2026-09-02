# GLD-INFRA-0010 — Serena and developer-tool runtime

Status: `applied`

- Owner: Gildra project owner
- Environment: server host, shared developer tooling for `debian` and `gildra-admin`
- Risk: R1, reversible tooling and per-user MCP configuration; no application or production service change
- Prepared: 2026-09-02
- Secret material: none

## Objective

Install Serena, browser/API/code-quality tooling, and the requested analysis
utilities on the server. Configure MCP entries at user scope so either Codex
user can use the same tools from any project.

## Installed runtimes and tools

Shared executables are available through `/usr/local/bin`:

| Tool | Version | Notes |
|---|---:|---|
| Serena | 1.7.0 | Installed with uv and initialized for both users; LSP backend |
| uv / uvx | 0.12.9 | Shared Python tool runner |
| Playwright MCP | 0.0.80 | Headless stdio server; Chromium/FFmpeg browser assets installed |
| dependency-cruiser | 18.2.0 | `dependency-cruise` and `depcruise` commands |
| Knip | 6.34.0 | Already present and verified |
| Semgrep | 1.176.0 | Already present and verified |
| Schemathesis | 4.25.2 | Already present and verified |
| sqlc | 1.31.1 | Standalone binary |
| OpenTelemetry Collector Contrib | 0.159.0 | Binary only; no service enabled and no exporter selected |
| Renovate | 44.59.2 | Runs on the isolated Node.js 24.20.0 runtime |
| CodeQL CLI bundle | 2.26.4 | CLI plus compatible language packs and queries |

The existing Node.js 22.23.2 runtime and previously installed frontend tools
remain unchanged. Renovate requires Node.js 24, so it is exposed through the
separate `/opt/gildra/node-v24.20.0-linux-x64` runtime rather than changing the
default Node executable.

Testcontainers for Go is a Go module, not a host-wide executable. Projects
that need it should add `github.com/testcontainers/testcontainers-go` to their
own `go.mod` and run integration tests with Docker access.

## MCP configuration

Both `/home/debian/.codex/config.toml` and
`/home/gildra-admin/.codex/config.toml` contain:

- `serena`: `serena start-mcp-server --context=codex --project-from-cwd`;
  Serena detects the current Git project for each session.
- `playwright`: `playwright-mcp --headless` with the shared
  `PLAYWRIGHT_BROWSERS_PATH=/opt/gildra/playwright-browsers`.
- `context7`: existing streamable HTTP endpoint
  `https://mcp.context7.com/mcp`.
- `cloudflare-api`: existing endpoint, unchanged.

Context7 and Cloudflare OAuth state is user-specific. The `debian` account has
its existing OAuth state; `gildra-admin` remains `Not logged in` until that
account completes its own browser login. No tokens were copied or printed.

Serena's project-local generated state is ignored with `.serena/` in the
repository `.gitignore`; this prevents two OS users from racing on generated
files.

## Verification

- Version probes passed for every executable listed above under both users.
- Playwright MCP starts successfully in headless stdio mode and finds the
  shared Chromium assets.
- Serena starts successfully in Codex context and auto-detects
  `/home/debian/Server`; its language-server warning for PowerShell is expected
  because `pwsh` is not part of this host's requested stack.
- `codex mcp get` confirms matching Serena and Playwright entries for both
  users; Context7 remains present at the configured endpoint.
- No production process, database, listener, deployment, or external service
  was restarted or modified.

## Recovery

Remove only the `serena` and `playwright` MCP entries with `codex mcp remove`
for the affected user, restore the previous Playwright URL if required, and
remove the explicitly installed versioned tool directories/symlinks. Do not
remove the existing Node 22 runtime, user credentials, or unrelated caches.
