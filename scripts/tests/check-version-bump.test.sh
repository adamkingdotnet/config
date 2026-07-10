#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"; SCRIPT="$DIR/../check-version-bump.sh"
pass=0 fail=0
check(){ if [ "$2" -eq "$3" ]; then pass=$((pass+1)); printf '  ok   %s\n' "$1"; else fail=$((fail+1)); printf '  FAIL %s (want %s got %s)\n' "$1" "$2" "$3"; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
git -C "$TMP" init -q
mkdir -p "$TMP/plugins/king-agents/.claude-plugin" "$TMP/other"
printf '{"version":"0.1.0"}\n' > "$TMP/plugins/king-agents/.claude-plugin/plugin.json"
printf 'x\n' > "$TMP/other/f.txt"
git -C "$TMP" add -A && git -C "$TMP" -c user.email=t@t -c user.name=t commit -qm base
BASE="$(git -C "$TMP" rev-parse HEAD)"
# (a) change outside plugin -> 0
printf 'y\n' > "$TMP/other/f.txt"; git -C "$TMP" add -A && git -C "$TMP" -c user.email=t@t -c user.name=t commit -qm a
( cd "$TMP" && "$SCRIPT" "$BASE" >/dev/null 2>&1 ); check "no-plugin-change -> 0" 0 $?
# (b) plugin change + bump -> 0
printf '{"version":"0.2.0"}\n' > "$TMP/plugins/king-agents/.claude-plugin/plugin.json"; git -C "$TMP" add -A && git -C "$TMP" -c user.email=t@t -c user.name=t commit -qm b
( cd "$TMP" && "$SCRIPT" "$BASE" >/dev/null 2>&1 ); check "plugin+bump -> 0" 0 $?
# (c) plugin change without bump -> 1
BASE2="$(git -C "$TMP" rev-parse HEAD)"
mkdir -p "$TMP/plugins/king-agents/scripts"
printf 'echo hi\n' > "$TMP/plugins/king-agents/scripts/new.sh"; git -C "$TMP" add -A && git -C "$TMP" -c user.email=t@t -c user.name=t commit -qm c
( cd "$TMP" && "$SCRIPT" "$BASE2" >/dev/null 2>&1 ); check "plugin+no-bump -> 1" 1 $?
echo; echo "  $pass passed, $fail failed"; [ "$fail" -eq 0 ]
