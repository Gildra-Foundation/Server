SHELL := /bin/bash

.DEFAULT_GOAL := check
.PHONY: check check-frontend check-backend check-api check-workflows check-graph-refresh check-security check-agent-response

# Run the checks that match the repository. Empty stacks are skipped so this
# infrastructure repository can use the same entry point as application repos.
check: check-frontend check-backend check-api check-workflows check-graph-refresh

check-graph-refresh:
	@bash -n scripts/refresh-graph-site.sh scripts/test-refresh-graph-site.sh
	@scripts/test-refresh-graph-site.sh

check-frontend:
	@set -euo pipefail; \
	if [[ ! -f package.json ]]; then \
		echo '[skip] frontend: package.json not found'; \
		exit 0; \
	fi; \
	command -v pnpm >/dev/null || { echo '[fail] frontend: pnpm is not installed'; exit 1; }; \
	 pnpm tsc --noEmit; \
	 pnpm eslint .; \
	 pnpm biome check .; \
	 pnpm knip; \
	 pnpm vitest run; \
	 if find tests e2e -type f \( -name '*.spec.*' -o -name '*.test.*' \) -print -quit 2>/dev/null | grep -q .; then \
		pnpm playwright test; \
	 else \
		echo '[skip] frontend: no Playwright scenarios found'; \
	 fi; \
	 pnpm build

check-backend:
	@set -euo pipefail; \
	mapfile -t modules < <(find . -type f -name go.mod -not -path './vendor/*' -print); \
	if (($${#modules[@]} == 0)); then \
		echo '[skip] backend: go.mod not found'; \
		exit 0; \
	fi; \
	command -v gofmt >/dev/null || { echo '[fail] backend: Go is not installed'; exit 1; }; \
	command -v staticcheck >/dev/null || { echo '[fail] backend: staticcheck is not installed'; exit 1; }; \
	command -v golangci-lint >/dev/null || { echo '[fail] backend: golangci-lint is not installed'; exit 1; }; \
	command -v govulncheck >/dev/null || { echo '[fail] backend: govulncheck is not installed'; exit 1; }; \
	mapfile -t gofiles < <(find . -type f -name '*.go' -not -path './vendor/*' -print); \
	if (($${#gofiles[@]} > 0)); then gofmt -w "$${gofiles[@]}"; fi; \
	for module in "$${modules[@]}"; do \
		dir=$$(dirname "$$module"); \
		pushd "$$dir" >/dev/null; \
		go vet ./...; \
		staticcheck ./...; \
		golangci-lint run; \
		go test ./...; \
		go test -race ./...; \
		govulncheck ./...; \
		popd >/dev/null; \
	done

check-api:
	@set -euo pipefail; \
	mapfile -t schemas < <(find . -type f \( -iname '*openapi*.yaml' -o -iname '*openapi*.yml' -o -iname '*openapi*.json' -o -iname 'swagger*.yaml' -o -iname 'swagger*.yml' -o -iname 'swagger*.json' \) -not -path './node_modules/*' -print); \
	if (($${#schemas[@]} > 0)); then \
		command -v spectral >/dev/null || { echo '[fail] API: spectral is not installed'; exit 1; }; \
		for schema in "$${schemas[@]}"; do spectral lint "$$schema"; done; \
		if [[ -n "$${API_BASE_URL:-}" ]]; then \
			command -v schemathesis >/dev/null || { echo '[fail] API: schemathesis is not installed'; exit 1; }; \
			for schema in "$${schemas[@]}"; do schemathesis run "$$schema" --url "$$API_BASE_URL"; done; \
		else \
			echo '[skip] API: set API_BASE_URL to run Schemathesis'; \
		fi; \
	else \
		echo '[skip] API: OpenAPI/Swagger schema not found'; \
	fi; \
	if [[ -f buf.yaml ]]; then \
		command -v buf >/dev/null || { echo '[fail] API: buf is not installed'; exit 1; }; \
		buf lint; \
	else \
		echo '[skip] API: buf.yaml not found'; \
	fi

check-workflows:
	@set -euo pipefail; \
	if ! find .github/workflows -type f \( -name '*.yml' -o -name '*.yaml' \) -print -quit 2>/dev/null | grep -q .; then \
		echo '[skip] workflows: no GitHub Actions workflow files found'; \
		exit 0; \
	fi; \
	command -v actionlint >/dev/null || { echo '[fail] workflows: actionlint is not installed'; exit 1; }; \
	actionlint

# Opt-in because filesystem vulnerability and secret scans can be expensive.
check-security:
	@set -euo pipefail; \
	if [[ "$${SECURITY_CHECKS:-0}" != 1 ]]; then \
		echo '[skip] security: set SECURITY_CHECKS=1 to run Trivy and Semgrep'; \
		exit 0; \
	fi; \
	command -v trivy >/dev/null || { echo '[fail] security: trivy is not installed'; exit 1; }; \
	command -v semgrep >/dev/null || { echo '[fail] security: semgrep is not installed'; exit 1; }; \
	trivy fs --scanners vuln,secret,misconfig .; \
	semgrep --config auto .

# Optional because a live Codex response is not stored in the repository.
# Usage: make check-agent-response AGENT_RESPONSE_FILE=/path/to/response.md
check-agent-response:
	@set -euo pipefail; \
	if [[ -z "$${AGENT_RESPONSE_FILE:-}" ]]; then \
		echo '[skip] agent response: set AGENT_RESPONSE_FILE to validate a saved response'; \
		exit 0; \
	fi; \
	python3 scripts/validate-agent-response.py "$${AGENT_RESPONSE_FILE}"
