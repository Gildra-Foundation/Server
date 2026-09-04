#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PUBLISHER=${PUBLISHER:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/refresh-graph-site.sh}
test_root=$(mktemp -d /tmp/gildra-graph-refresh-test.XXXXXX)

cleanup() {
  case "$test_root" in
    /tmp/gildra-graph-refresh-test.*) find "$test_root" -depth -delete ;;
  esac
}
trap cleanup EXIT

fail() {
  printf '[test] FAIL: %s\n' "$*" >&2
  exit 1
}

assert_eq() {
  [[ "$1" == "$2" ]] || fail "expected '$2', got '$1'"
}

create_repo() {
  local name=$1 bare work
  bare=$test_root/$name.git
  work=$test_root/$name-work
  git init --quiet --bare --initial-branch=main "$bare"
  git clone --quiet "$bare" "$work"
  git -C "$work" config user.email graph-test@example.invalid
  git -C "$work" config user.name 'Graph Test'
  printf 'package %s\n\nfunc Main() {}\n' "$name" > "$work/main.go"
  git -C "$work" add main.go
  git -C "$work" commit --quiet -m initial
  git -C "$work" push --quiet origin main
}

commit_repo() {
  local name=$1 value=$2 work
  work=$test_root/$name-work
  printf 'package %s\n\nfunc Main() { /* %s */ }\n' "$name" "$value" > "$work/main.go"
  git -C "$work" add main.go
  git -C "$work" commit --quiet -m "update $value"
  git -C "$work" push --quiet origin main
}

create_repo gildra
create_repo server
mkdir -p "$test_root/bin" "$test_root/site" "$test_root/work" "$test_root/run"

fake_graphify=$test_root/bin/graphify
# The single-quoted lines intentionally defer expansion to the generated stub.
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'if [[ "${1:-}" == --version ]]; then printf "graphify 0.9.53\\n"; exit 0; fi' \
  'if [[ "${1:-}" == export && "${2:-}" == html ]]; then printf "<!doctype html><html><body>graph</body></html>\\n" > graph.html; if [[ "${FAKE_GRAPHIFY_SECRET:-0}" == 1 ]]; then printf "%s\\n" "GITLEAKS_ONLY_TEST_SECRET" >> graph.html; fi; exit 0; fi' \
  '[[ "${1:-}" == extract ]] || exit 64' \
  'source_dir=$2; shift 2; output_dir=' \
  'while (($#)); do if [[ $1 == --out ]]; then output_dir=$2; shift 2; else shift; fi; done' \
  '[[ -n "$output_dir" ]] || exit 64' \
  'printf x >> "$FAKE_GRAPHIFY_CALL_LOG"' \
  '[[ "${FAKE_GRAPHIFY_FAIL:-0}" != 1 ]] || exit 42' \
  'mkdir -p "$output_dir/graphify-out"' \
  'label=$(basename "$source_dir")' \
  'source_path=main.go; if [[ "${FAKE_UNSAFE_PATH:-0}" == 1 ]]; then source_path=/etc/passwd; fi' \
  'printf "{\"nodes\":[{\"id\":\"%s\",\"source_file\":\"%s\"}],\"links\":[]}\n" "$label" "$source_path" > "$output_dir/graphify-out/graph.json"' \
  > "$fake_graphify"
chmod 0755 "$fake_graphify"

fake_gitleaks=$test_root/bin/gitleaks
# The single-quoted lines intentionally defer expansion to the generated stub.
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'if [[ "${1:-}" == version ]]; then printf "8.21.2\\n"; exit 0; fi' \
  'source_dir=; report_path=' \
  'while (($#)); do case $1 in --source) source_dir=$2; shift 2 ;; --report-path) report_path=$2; shift 2 ;; *) shift ;; esac; done' \
  '[[ -n "$source_dir" && -n "$report_path" ]] || exit 64' \
  'if grep -RFl "GITLEAKS_ONLY_TEST_SECRET" "$source_dir" >/dev/null; then exit 1; fi' \
  'printf "[]\\n" > "$report_path"' \
  > "$fake_gitleaks"
chmod 0755 "$fake_gitleaks"

printf '%s\n' '33362d969292b57eda82f3fbd9eb5f3f5bc9bbc2' > "$test_root/graphify.pin"
printf '%s\n' '<!doctype html><iframe src="/gildra.html"></iframe><iframe src="/server.html"></iframe>' > "$test_root/index.html"
: > "$test_root/graphify.calls"

export GRAPHIFY_BIN=$fake_graphify
export GITLEAKS_BIN=$fake_gitleaks
fake_gitleaks_sha=$(sha256sum "$fake_gitleaks" | awk '{print $1}')
export GITLEAKS_SHA256=$fake_gitleaks_sha
export GRAPHIFY_PIN_FILE=$test_root/graphify.pin
export GILDRA_REPO_URL=$test_root/gildra.git
export SERVER_REPO_URL=$test_root/server.git
export SITE_ROOT=$test_root/site
export SHELL_TEMPLATE=$test_root/index.html
export WORK_ROOT=$test_root/work
export LOCK_FILE=$test_root/run/refresh.lock
export RETENTION_COUNT=3
export FAKE_GRAPHIFY_CALL_LOG=$test_root/graphify.calls
export ALLOW_TEST_REPOSITORIES=1

"$PUBLISHER" >/dev/null
first_target=$(readlink "$SITE_ROOT/current")
[[ -f "$SITE_ROOT/current/gildra.html" ]] || fail 'Gildra artifact was not published'
[[ -f "$SITE_ROOT/current/server.html" ]] || fail 'Server artifact was not published'
assert_eq "$(wc -c < "$FAKE_GRAPHIFY_CALL_LOG" | tr -d ' ')" 2

"$PUBLISHER" >/dev/null
assert_eq "$(readlink "$SITE_ROOT/current")" "$first_target"
assert_eq "$(wc -c < "$FAKE_GRAPHIFY_CALL_LOG" | tr -d ' ')" 2

printf 'corrupted\n' >> "$SITE_ROOT/current/gildra.html"
"$PUBLISHER" >/dev/null
integrity_target=$(readlink "$SITE_ROOT/current")
[[ "$integrity_target" != "$first_target" ]] || fail 'artifact corruption did not trigger a rebuild'
assert_eq "$(wc -c < "$FAKE_GRAPHIFY_CALL_LOG" | tr -d ' ')" 4
first_target=$integrity_target

absolute_target=$(readlink -f "$SITE_ROOT/current")
unlink "$SITE_ROOT/current"
ln -s "$absolute_target" "$SITE_ROOT/current"
if "$PUBLISHER" >/dev/null 2>&1; then
  fail 'unexpected current target did not block pruning'
fi
[[ -d "$absolute_target" ]] || fail 'unexpected current target was pruned'
unlink "$SITE_ROOT/current"
ln -s "$first_target" "$SITE_ROOT/current"

commit_repo gildra rejected-generator
if FAKE_GRAPHIFY_FAIL=1 "$PUBLISHER" >/dev/null 2>&1; then
  fail 'generator failure unexpectedly succeeded'
fi
assert_eq "$(readlink "$SITE_ROOT/current")" "$first_target"

if FAKE_UNSAFE_PATH=1 "$PUBLISHER" >/dev/null 2>&1; then
  fail 'unsafe source path unexpectedly passed validation'
fi
assert_eq "$(readlink "$SITE_ROOT/current")" "$first_target"

if FAKE_GRAPHIFY_SECRET=1 "$PUBLISHER" >/dev/null 2>&1; then
  fail 'sensitive artifact unexpectedly passed validation'
fi
assert_eq "$(readlink "$SITE_ROOT/current")" "$first_target"

"$PUBLISHER" >/dev/null
second_target=$(readlink "$SITE_ROOT/current")
[[ "$second_target" != "$first_target" ]] || fail 'successful update did not switch current'

for sequence in 1 2 3 4 5; do
  commit_repo server "$sequence"
  "$PUBLISHER" >/dev/null
done
release_count=$(find "$SITE_ROOT/releases" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq "$release_count" 3
[[ -f "$SITE_ROOT/current/manifest.json" ]] || fail 'retention removed the active release'

python3 - "$SITE_ROOT/current/manifest.json" "$test_root/gildra-work" "$test_root/server-work" <<'PY'
import json
import subprocess
import sys

manifest_path, gildra_repo, server_repo = sys.argv[1:]
with open(manifest_path, encoding="utf-8") as handle:
    manifest = json.load(handle)
for key, repo in (("gildra", gildra_repo), ("server", server_repo)):
    expected = subprocess.check_output(["git", "-C", repo, "rev-parse", "HEAD"], text=True).strip()
    assert manifest["repositories"][key]["sha"] == expected
    assert manifest["repositories"][key]["nodes"] == 1
    assert manifest["repositories"][key]["edges"] == 0
assert manifest["generator"]["commit"] == "33362d969292b57eda82f3fbd9eb5f3f5bc9bbc2"
assert manifest["generator"]["version"] == "0.9.53"
assert manifest["scanner"]["version"] == "8.21.2"
assert len(manifest["scanner"]["sha256"]) == 64
PY

printf '[test] PASS: atomic refresh, no-op, failure preservation, screening, and retention\n'
