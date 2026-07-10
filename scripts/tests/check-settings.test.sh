#!/usr/bin/env bash
# check-settings.test.sh — offline tests for check-settings.sh via KING_CONFIG_RAW=file://
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/../check-settings.sh"

pass=0 fail=0
check() { if [ "$2" -eq "$3" ]; then pass=$((pass+1)); printf '  ok   %s\n' "$1"
  else fail=$((fail+1)); printf '  FAIL %s (want %s got %s)\n' "$1" "$2" "$3"; fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/config/plugins/king-agents/settings-templates"
printf '{"a":1}\n' > "$TMP/config/plugins/king-agents/settings-templates/next.json"
export KING_CONFIG_RAW="file://$TMP/config"

printf '{"a":1}\n' > "$TMP/match.json"
( "$SCRIPT" next "$TMP/match.json" >/dev/null 2>&1 ); check "match -> 0" 0 $?

printf '{"a":2}\n' > "$TMP/drift.json"
( "$SCRIPT" next "$TMP/drift.json" >/dev/null 2>&1 ); check "drift -> 1" 1 $?

echo; echo "  $pass passed, $fail failed"
[ "$fail" -eq 0 ]
