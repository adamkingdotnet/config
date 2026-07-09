#!/usr/bin/env bash
# verify-gate.sh — Stop hook: block turn-end until this repo's declared gate passes.
#
# Contract:
#   stdin  = the Stop hook JSON payload (contains "stop_hook_active")
#   cwd    = the repo root (Claude Code runs Stop hooks from the project dir)
#   config = .claude/king.json -> {"verify": {"cmd": "<shell to run>"}}
#
# Behavior: no king.json / empty cmd => exit 0 (advisory-only repo). stop_hook_active
# true => exit 0 (we already blocked once this turn; don't loop). cmd passes => exit 0.
# cmd fails => exit 2 with the command + last log lines on stderr (becomes the block reason).
set -uo pipefail

input="$(cat)"

active="$(printf '%s' "$input" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin).get("stop_hook_active", False))' 2>/dev/null \
  || echo False)"
[ "$active" = "True" ] && exit 0

cfg=".claude/king.json"
[ -f "$cfg" ] || exit 0

cmd="$(python3 -c 'import json; print(json.load(open(".claude/king.json")).get("verify",{}).get("cmd",""))' 2>/dev/null || true)"
[ -n "$cmd" ] || exit 0

log="$(mktemp)"
if eval "$cmd" >"$log" 2>&1; then
  rm -f "$log"
  exit 0
fi

{
  echo "verify-before-done gate failed: \`$cmd\`"
  echo "--- last 30 lines ---"
  tail -n 30 "$log"
} >&2
rm -f "$log"
exit 2
