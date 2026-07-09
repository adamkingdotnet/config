#!/usr/bin/env bash
# verify-gate.test.sh — plain-bash tests for verify-gate.sh (mirrors host-infra/tests/run.sh).
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
GATE="$DIR/verify-gate.sh"

pass=0 fail=0
check() { # <name> <want-rc> <got-rc>
  if [ "$2" -eq "$3" ]; then pass=$((pass+1)); printf '  ok   %s\n' "$1"
  else fail=$((fail+1)); printf '  FAIL %s (want rc=%s got %s)\n' "$1" "$2" "$3"; fi
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.claude"
run() { ( cd "$TMP" && printf '%s' "$1" | "$GATE" >/dev/null 2>&1 ); echo $?; }

# 1. No king.json -> no-op
check "no king.json -> 0" 0 "$(run '{"stop_hook_active": false}')"

# 2. Empty cmd -> no-op
printf '{"verify":{"cmd":""}}' > "$TMP/.claude/king.json"
check "empty cmd -> 0" 0 "$(run '{"stop_hook_active": false}')"

# 3. Passing cmd -> 0
printf '{"verify":{"cmd":"true"}}' > "$TMP/.claude/king.json"
check "passing cmd -> 0" 0 "$(run '{"stop_hook_active": false}')"

# 4. Failing cmd -> 2 (block turn-end)
printf '{"verify":{"cmd":"false"}}' > "$TMP/.claude/king.json"
check "failing cmd -> 2" 2 "$(run '{"stop_hook_active": false}')"

# 5. Loop guard: failing cmd but already active -> 0
check "loop guard -> 0" 0 "$(run '{"stop_hook_active": true}')"

echo; echo "  $pass passed, $fail failed"
[ "$fail" -eq 0 ]
