#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 022

GRAPHIFY_BIN=${GRAPHIFY_BIN:-/usr/local/lib/gildra-graph/venv/bin/graphify}
GRAPHIFY_PIN=${GRAPHIFY_PIN:-33362d969292b57eda82f3fbd9eb5f3f5bc9bbc2}
GRAPHIFY_PIN_FILE=${GRAPHIFY_PIN_FILE:-/usr/local/lib/gildra-graph/graphify.pin}
GRAPHIFY_EXPECTED_VERSION=${GRAPHIFY_EXPECTED_VERSION:-0.9.53}
GRAPHIFY_MAX_WORKERS=${GRAPHIFY_MAX_WORKERS:-4}
GITLEAKS_BIN=${GITLEAKS_BIN:-/usr/local/lib/gildra-graph/gitleaks}
GITLEAKS_EXPECTED_VERSION=${GITLEAKS_EXPECTED_VERSION:-8.21.2}
GITLEAKS_SHA256=${GITLEAKS_SHA256:-5bc41815076e6ed6ef8fbecc9d9b75bcae31f39029ceb55da08086315316e3ba}
GILDRA_REPO_URL=${GILDRA_REPO_URL:-https://github.com/Gildra-Foundation/Gildra.git}
SERVER_REPO_URL=${SERVER_REPO_URL:-https://github.com/Gildra-Foundation/Server.git}
ALLOW_TEST_REPOSITORIES=${ALLOW_TEST_REPOSITORIES:-0}
SITE_ROOT=${SITE_ROOT:-/var/lib/gildra-graph/site}
SHELL_TEMPLATE=${SHELL_TEMPLATE:-/usr/local/lib/gildra-graph/index.html}
WORK_ROOT=${WORK_ROOT:-/var/lib/gildra-graph}
LOCK_FILE=${LOCK_FILE:-/run/gildra-graph/refresh.lock}
RETENTION_COUNT=${RETENTION_COUNT:-5}
MAX_CHECKOUT_BYTES=${MAX_CHECKOUT_BYTES:-1073741824}
MAX_SOURCE_FILES=${MAX_SOURCE_FILES:-100000}
MAX_GRAPH_JSON_BYTES=${MAX_GRAPH_JSON_BYTES:-52428800}
MAX_GRAPH_HTML_BYTES=${MAX_GRAPH_HTML_BYTES:-20971520}
GIT_BIN=${GIT_BIN:-git}
PYTHON_BIN=${PYTHON_BIN:-python3}

RELEASES_DIR=$SITE_ROOT/releases
CURRENT_LINK=$SITE_ROOT/current
work_dir=
release_tmp=
next_link=

log() {
  printf '[graph-refresh] %s\n' "$*"
}

fail() {
  printf '[graph-refresh] ERROR: %s\n' "$*" >&2
  exit 1
}

cleanup_tree() {
  local target=$1
  [[ -n "$target" && -e "$target" ]] || return 0
  find "$target" -depth -delete
}

cleanup() {
  case "$work_dir" in
    "$WORK_ROOT"/graph-refresh.*) cleanup_tree "$work_dir" ;;
  esac
  case "$release_tmp" in
    "$RELEASES_DIR"/.build-*) cleanup_tree "$release_tmp" ;;
  esac
  case "$next_link" in
    "$SITE_ROOT"/.current.next.*) [[ ! -e "$next_link" && ! -L "$next_link" ]] || unlink "$next_link" ;;
  esac
}
trap cleanup EXIT

require_file() {
  [[ -f "$1" ]] || fail "required file is missing: $1"
}

validate_configuration() {
  [[ "$SITE_ROOT" == /* && "$SITE_ROOT" != / ]] || fail 'SITE_ROOT must be a specific absolute path'
  [[ "$WORK_ROOT" == /* && "$WORK_ROOT" != / ]] || fail 'WORK_ROOT must be a specific absolute path'
  [[ "$LOCK_FILE" == /* ]] || fail 'LOCK_FILE must be absolute'
  [[ "$GRAPHIFY_PIN" =~ ^[0-9a-f]{40}$ ]] || fail 'GRAPHIFY_PIN must be a full commit SHA'
  [[ "$GITLEAKS_SHA256" =~ ^[0-9a-f]{64}$ ]] || fail 'GITLEAKS_SHA256 must be a SHA-256 digest'
  [[ "$GRAPHIFY_EXPECTED_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'invalid Graphify version'
  [[ "$GRAPHIFY_MAX_WORKERS" =~ ^[1-9][0-9]*$ ]] || fail 'GRAPHIFY_MAX_WORKERS must be positive'
  [[ "$RETENTION_COUNT" =~ ^[1-9][0-9]*$ ]] || fail 'RETENTION_COUNT must be positive'
  [[ "$MAX_CHECKOUT_BYTES" =~ ^[1-9][0-9]*$ ]] || fail 'MAX_CHECKOUT_BYTES must be positive'
  [[ "$MAX_SOURCE_FILES" =~ ^[1-9][0-9]*$ ]] || fail 'MAX_SOURCE_FILES must be positive'
  [[ "$MAX_GRAPH_JSON_BYTES" =~ ^[1-9][0-9]*$ ]] || fail 'MAX_GRAPH_JSON_BYTES must be positive'
  [[ "$MAX_GRAPH_HTML_BYTES" =~ ^[1-9][0-9]*$ ]] || fail 'MAX_GRAPH_HTML_BYTES must be positive'
  [[ "$ALLOW_TEST_REPOSITORIES" == 0 || "$ALLOW_TEST_REPOSITORIES" == 1 ]] || fail 'ALLOW_TEST_REPOSITORIES must be 0 or 1'
  if [[ "$ALLOW_TEST_REPOSITORIES" == 0 ]]; then
    [[ "$GILDRA_REPO_URL" == 'https://github.com/Gildra-Foundation/Gildra.git' ]] || fail 'Gildra repository URL is not allowlisted'
    [[ "$SERVER_REPO_URL" == 'https://github.com/Gildra-Foundation/Server.git' ]] || fail 'Server repository URL is not allowlisted'
  fi
  command -v "$GIT_BIN" >/dev/null || fail "git executable is unavailable: $GIT_BIN"
  command -v "$PYTHON_BIN" >/dev/null || fail "python executable is unavailable: $PYTHON_BIN"
  [[ -x "$GRAPHIFY_BIN" ]] || fail "Graphify executable is unavailable: $GRAPHIFY_BIN"
  [[ -x "$GITLEAKS_BIN" ]] || fail "Gitleaks executable is unavailable: $GITLEAKS_BIN"
  require_file "$GRAPHIFY_PIN_FILE"
  require_file "$SHELL_TEMPLATE"
  grep -Fq '/gildra.html' "$SHELL_TEMPLATE" || fail 'selector template does not reference /gildra.html'
  grep -Fq '/server.html' "$SHELL_TEMPLATE" || fail 'selector template does not reference /server.html'
}

verify_graphify_runtime() {
  local installed_pin version_output gitleaks_version gitleaks_sha
  installed_pin=$(tr -d '[:space:]' < "$GRAPHIFY_PIN_FILE")
  [[ "$installed_pin" == "$GRAPHIFY_PIN" ]] || fail 'installed Graphify pin does not match the configured pin'
  version_output=$($GRAPHIFY_BIN --version)
  [[ "$version_output" == "graphify $GRAPHIFY_EXPECTED_VERSION" ]] || {
    fail "unexpected Graphify version: $version_output"
  }
  gitleaks_version=$($GITLEAKS_BIN version)
  [[ "$gitleaks_version" == "$GITLEAKS_EXPECTED_VERSION" ]] || {
    fail "unexpected Gitleaks version: $gitleaks_version"
  }
  gitleaks_sha=$(sha256sum "$GITLEAKS_BIN" | awk '{print $1}')
  [[ "$gitleaks_sha" == "$GITLEAKS_SHA256" ]] || fail 'Gitleaks binary checksum mismatch'
}

resolve_default_revision() {
  local repo_url=$1 output branch sha
  output=$($GIT_BIN ls-remote --symref "$repo_url" HEAD)
  branch=$(awk '$1 == "ref:" && $3 == "HEAD" { sub(/^refs\/heads\//, "", $2); print $2; exit }' <<< "$output")
  sha=$(awk '$2 == "HEAD" { print $1; exit }' <<< "$output")
  [[ -n "$branch" ]] || fail "could not resolve the default branch for $repo_url"
  [[ "$sha" =~ ^[0-9a-f]{40}$ ]] || fail "could not resolve the default revision for $repo_url"
  printf '%s\t%s\n' "$branch" "$sha"
}

manifest_matches() {
  local manifest=$1 gildra_sha=$2 server_sha=$3 template_sha=$4
  [[ -f "$manifest" ]] || return 1
  "$PYTHON_BIN" - "$manifest" "$gildra_sha" "$server_sha" "$GRAPHIFY_PIN" \
    "$GRAPHIFY_EXPECTED_VERSION" "$GITLEAKS_EXPECTED_VERSION" "$GITLEAKS_SHA256" "$template_sha" <<'PY'
import json
import sys

path, gildra_sha, server_sha, pin, version, scanner_version, scanner_sha, template_sha = sys.argv[1:]
try:
    with open(path, encoding="utf-8") as handle:
        manifest = json.load(handle)
except (OSError, json.JSONDecodeError):
    raise SystemExit(1)

matches = (
    manifest.get("schema_version") == 1
    and manifest.get("repositories", {}).get("gildra", {}).get("sha") == gildra_sha
    and manifest.get("repositories", {}).get("server", {}).get("sha") == server_sha
    and manifest.get("generator", {}).get("commit") == pin
    and manifest.get("generator", {}).get("version") == version
    and manifest.get("scanner", {}).get("version") == scanner_version
    and manifest.get("scanner", {}).get("sha256") == scanner_sha
    and manifest.get("template_sha256") == template_sha
)
if matches:
    import hashlib
    root = __import__("pathlib").Path(path).parent
    for name in ("index.html", "gildra.html", "server.html"):
        artifact = root / name
        expected = manifest.get("artifacts", {}).get(name, {}).get("sha256")
        try:
            actual = hashlib.sha256(artifact.read_bytes()).hexdigest()
        except OSError:
            matches = False
            break
        if actual != expected:
            matches = False
            break
raise SystemExit(0 if matches else 1)
PY
}

checkout_revision() {
  local repo_url=$1 sha=$2 destination=$3 actual_sha checkout_bytes source_files
  mkdir -p "$destination"
  $GIT_BIN -C "$destination" init --quiet
  $GIT_BIN -C "$destination" remote add origin "$repo_url"
  $GIT_BIN -C "$destination" fetch --quiet --depth=1 origin "$sha"
  $GIT_BIN -C "$destination" -c advice.detachedHead=false checkout --quiet --detach FETCH_HEAD
  actual_sha=$($GIT_BIN -C "$destination" rev-parse HEAD)
  [[ "$actual_sha" == "$sha" ]] || fail "fetched revision mismatch for $repo_url"
  cleanup_tree "$destination/.git"
  find "$destination" -type l -delete
  checkout_bytes=$(du -sb "$destination" | awk '{print $1}')
  source_files=$(find "$destination" -type f -printf '.' | wc -c | tr -d ' ')
  ((checkout_bytes <= MAX_CHECKOUT_BYTES)) || fail "checkout exceeds byte limit for $repo_url"
  ((source_files <= MAX_SOURCE_FILES)) || fail "checkout exceeds file-count limit for $repo_url"

  # Use a fixed ignore policy in the disposable checkout. Removing repository
  # symlinks first prevents source-controlled links from escaping the workspace.
  [[ ! -e "$destination/.graphifyignore" ]] || unlink "$destination/.graphifyignore"
  {
    printf '# Gildra graph publisher safety ignores\n'
    printf '%s\n' '.env' '.env.*' '*.pem' '*.key' '*.p12' '*.pfx'
    printf '%s\n' 'node_modules/' 'vendor/' 'dist/' 'build/' 'coverage/'
    printf '%s\n' 'uploads/' 'backups/' '*.dump' '*.sql.gz' '*.log'
  } >> "$destination/.graphifyignore"
}

validate_graph() {
  local label=$1 graph_dir=$2 graph_json graph_html json_bytes html_bytes
  graph_json=$graph_dir/graphify-out/graph.json
  graph_html=$graph_dir/graphify-out/graph.html
  require_file "$graph_json"
  require_file "$graph_html"
  [[ -s "$graph_json" && -s "$graph_html" ]] || fail "$label graph output is empty"
  json_bytes=$(stat -c '%s' "$graph_json")
  html_bytes=$(stat -c '%s' "$graph_html")
  ((json_bytes <= MAX_GRAPH_JSON_BYTES)) || fail "$label graph JSON exceeds the size limit"
  ((html_bytes <= MAX_GRAPH_HTML_BYTES)) || fail "$label graph HTML exceeds the size limit"
  "$PYTHON_BIN" - "$label" "$graph_json" <<'PY'
import json
import pathlib
import sys

label, path = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    graph = json.load(handle)
nodes = graph.get("nodes")
edges = graph.get("links", graph.get("edges"))
if not isinstance(nodes, list) or not nodes:
    raise SystemExit(f"{label} graph has no nodes")
if not isinstance(edges, list):
    raise SystemExit(f"{label} graph has no edge list")
for item in (*nodes, *edges):
    source = item.get("source_file") if isinstance(item, dict) else None
    if isinstance(source, str) and (pathlib.PurePosixPath(source).is_absolute() or ".." in pathlib.PurePosixPath(source).parts):
        raise SystemExit(f"{label} graph contains an unsafe source path")
print(f"{len(nodes)}\t{len(edges)}")
PY
  if LC_ALL=C grep -Eil \
    -- '-----BEGIN ([A-Z0-9 ]+ )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|/(root|home|etc|var/(lib|log)|opt|srv|run|mnt|media)/' \
    "$graph_json" "$graph_html" >/dev/null; then
    fail "$label graph failed the credential/private-path screen"
  fi
}

generate_graph() {
  local label=$1 source_dir=$2 output_dir=$3
  log "generating $label graph"
  "$GRAPHIFY_BIN" extract "$source_dir" --out "$output_dir" --code-only \
    --max-workers "$GRAPHIFY_MAX_WORKERS"
  (
    cd "$output_dir/graphify-out"
    "$GRAPHIFY_BIN" export html --graph "$output_dir/graphify-out/graph.json"
  )
}

write_manifest() {
  local output=$1 generated_at=$2 template_sha=$3
  local gildra_branch=$4 gildra_sha=$5 gildra_nodes=$6 gildra_edges=$7
  local server_branch=$8 server_sha=$9 server_nodes=${10} server_edges=${11}
  "$PYTHON_BIN" - "$output" "$generated_at" "$template_sha" \
    "$GRAPHIFY_PIN" "$GRAPHIFY_EXPECTED_VERSION" "$GITLEAKS_EXPECTED_VERSION" "$GITLEAKS_SHA256" \
    "$GILDRA_REPO_URL" "$gildra_branch" "$gildra_sha" "$gildra_nodes" "$gildra_edges" \
    "$SERVER_REPO_URL" "$server_branch" "$server_sha" "$server_nodes" "$server_edges" <<'PY'
import json
import sys

(
    output,
    generated_at,
    template_sha,
    pin,
    version,
    scanner_version,
    scanner_sha,
    gildra_url,
    gildra_branch,
    gildra_sha,
    gildra_nodes,
    gildra_edges,
    server_url,
    server_branch,
    server_sha,
    server_nodes,
    server_edges,
) = sys.argv[1:]

manifest = {
    "schema_version": 1,
    "generated_at": generated_at,
    "repositories": {
        "gildra": {
            "url": gildra_url,
            "default_branch": gildra_branch,
            "sha": gildra_sha,
            "nodes": int(gildra_nodes),
            "edges": int(gildra_edges),
        },
        "server": {
            "url": server_url,
            "default_branch": server_branch,
            "sha": server_sha,
            "nodes": int(server_nodes),
            "edges": int(server_edges),
        },
    },
    "generator": {
        "name": "graphify",
        "version": version,
        "commit": pin,
        "mode": "code-only",
    },
    "scanner": {"name": "gitleaks", "version": scanner_version, "sha256": scanner_sha},
    "template_sha256": template_sha,
}
import hashlib
from pathlib import Path

root = Path(output).parent
manifest["artifacts"] = {}
for name in ("index.html", "gildra.html", "server.html"):
    artifact = root / name
    manifest["artifacts"][name] = {
        "bytes": artifact.stat().st_size,
        "sha256": hashlib.sha256(artifact.read_bytes()).hexdigest(),
    }
with open(output, "w", encoding="utf-8") as handle:
    json.dump(manifest, handle, indent=2, sort_keys=True)
    handle.write("\n")
PY
}

scan_release() {
  local release_dir=$1 report_path=$work_dir/gitleaks-report.json
  if ! "$GITLEAKS_BIN" detect --source "$release_dir" --no-git --redact \
    --no-banner --no-color --log-level error --report-format json \
    --report-path "$report_path"; then
    fail 'staged public release failed the Gitleaks scan'
  fi
}

prune_releases() {
  local current_target current_name='' name candidate kept=0
  local -a release_names=()
  current_target=$(readlink "$CURRENT_LINK" 2>/dev/null) || fail 'current release link is missing'
  [[ "$current_target" =~ ^releases/([0-9]{8}T[0-9]{15}Z-[0-9a-f]{12}-[0-9a-f]{12})$ ]] || {
    fail 'current release link has an unexpected target; refusing to prune'
  }
  current_name=${BASH_REMATCH[1]}
  [[ -d "$RELEASES_DIR/$current_name" && ! -L "$RELEASES_DIR/$current_name" ]] || {
    fail 'current release target is unavailable; refusing to prune'
  }
  kept=1
  mapfile -t release_names < <(
    find "$RELEASES_DIR" -mindepth 1 -maxdepth 1 -type d \
      -name '20*T*Z-????????????-????????????' -printf '%T@ %f\n' \
      | sort -rn | awk '{print $2}'
  )
  for name in "${release_names[@]}"; do
    [[ "$name" == "$current_name" ]] && continue
    if ((kept < RETENTION_COUNT)); then
      ((kept += 1))
      continue
    fi
    [[ "$name" =~ ^[0-9]{8}T[0-9]{15}Z-[0-9a-f]{12}-[0-9a-f]{12}$ ]] || continue
    candidate=$RELEASES_DIR/$name
    [[ -d "$candidate" && ! -L "$candidate" ]] || continue
    log "pruning release $name"
    cleanup_tree "$candidate"
  done
}

main() {
  local gildra_branch gildra_sha server_branch server_sha template_sha
  local generated_at release_id release_final gildra_counts server_counts
  local gildra_nodes gildra_edges server_nodes server_edges

  validate_configuration
  verify_graphify_runtime
  install -d -m 0755 "$WORK_ROOT" "$SITE_ROOT" "$RELEASES_DIR" "$(dirname "$LOCK_FILE")"

  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    log 'another refresh is active; exiting without changes'
    return 0
  fi

  read -r gildra_branch gildra_sha < <(resolve_default_revision "$GILDRA_REPO_URL")
  read -r server_branch server_sha < <(resolve_default_revision "$SERVER_REPO_URL")
  template_sha=$(sha256sum "$SHELL_TEMPLATE" | awk '{print $1}')

  if manifest_matches "$CURRENT_LINK/manifest.json" "$gildra_sha" "$server_sha" "$template_sha"; then
    log "already current: Gildra ${gildra_sha:0:12}, Server ${server_sha:0:12}"
    prune_releases
    return 0
  fi

  work_dir=$(mktemp -d "$WORK_ROOT/graph-refresh.XXXXXX")
  checkout_revision "$GILDRA_REPO_URL" "$gildra_sha" "$work_dir/gildra"
  checkout_revision "$SERVER_REPO_URL" "$server_sha" "$work_dir/server"
  generate_graph Gildra "$work_dir/gildra" "$work_dir/gildra-output"
  generate_graph Server "$work_dir/server" "$work_dir/server-output"

  gildra_counts=$(validate_graph Gildra "$work_dir/gildra-output")
  server_counts=$(validate_graph Server "$work_dir/server-output")
  IFS=$'\t' read -r gildra_nodes gildra_edges <<< "$gildra_counts"
  IFS=$'\t' read -r server_nodes server_edges <<< "$server_counts"
  generated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  release_id=$(date -u +%Y%m%dT%H%M%S%NZ)-${gildra_sha:0:12}-${server_sha:0:12}
  release_tmp=$RELEASES_DIR/.build-$release_id
  release_final=$RELEASES_DIR/$release_id
  install -d -m 0755 "$release_tmp"
  install -m 0644 "$SHELL_TEMPLATE" "$release_tmp/index.html"
  install -m 0644 "$work_dir/gildra-output/graphify-out/graph.html" "$release_tmp/gildra.html"
  install -m 0644 "$work_dir/server-output/graphify-out/graph.html" "$release_tmp/server.html"
  write_manifest "$release_tmp/manifest.json" "$generated_at" "$template_sha" \
    "$gildra_branch" "$gildra_sha" "$gildra_nodes" "$gildra_edges" \
    "$server_branch" "$server_sha" "$server_nodes" "$server_edges"
  chmod 0644 "$release_tmp/manifest.json"
  scan_release "$release_tmp"

  mv -T -- "$release_tmp" "$release_final"
  release_tmp=
  next_link=$SITE_ROOT/.current.next.$$
  ln -s "releases/$release_id" "$next_link"
  mv -Tf -- "$next_link" "$CURRENT_LINK"
  next_link=
  prune_releases
  log "published $release_id"
}

main "$@"
