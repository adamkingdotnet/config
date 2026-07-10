#!/usr/bin/env bash
# verify-gate.sh — Stop hook: block turn-end until this repo's declared gate passes.
#
# Contract:
#   stdin  = the Stop hook JSON payload (contains "stop_hook_active")
#   cwd    = the repo root (Claude Code runs Stop hooks from the project dir)
#   config = .claude/king.json -> {"verify": {"cmd": "<shell to run>"}}
#
# Behavior: no king.json => exit 0 (repo opted out of the gate). stop_hook_active
# true => exit 0 (we already blocked once this turn; don't loop — matched without
# python3 so the guard always works). A king.json that EXISTS but cannot be read
# (missing python3 / malformed JSON) FAILS CLOSED (exit 2) so a broken gate config
# is never mistaken for "no gate". Empty verify.cmd => exit 0. cmd passes => exit 0;
# cmd fails => exit 2 with the command + log tail on stderr.
set -uo pipefail

input="$(cat)"

# Loop guard (dependency-free): if we already blocked once this turn, let it end.
compact="${input//[[:space:]]/}"
case "$compact" in *'"stop_hook_active":true'*) exit 0 ;; esac

cfg=".claude/king.json"
[ -f "$cfg" ] || exit 0

if ! command -v python3 >/dev/null 2>&1; then
  echo "verify-before-done: python3 required to read $cfg but not found — cannot verify (failing closed)" >&2
  exit 2
fi

if ! cmd="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("verify",{}).get("cmd",""))' "$cfg" 2>/dev/null)"; then
  echo "verify-before-done: $cfg is present but unreadable (malformed JSON?) — cannot verify (failing closed)" >&2
  exit 2
fi
[ -n "$cmd" ] || exit 0

log="$(mktemp)"; trap 'rm -f "$log"' EXIT
if eval "$cmd" >"$log" 2>&1; then
  exit 0
fi

{
  echo "verify-before-done gate failed: \`$cmd\`"
  echo "--- last 30 lines ---"
  tail -n 30 "$log"
} >&2
exit 2
