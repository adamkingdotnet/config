#!/usr/bin/env bash
# check-version-bump.sh <base-ref> — if the diff base..HEAD touches plugins/king-agents/**,
# require plugins/king-agents/.claude-plugin/plugin.json "version" to differ from <base-ref>.
set -euo pipefail
base="${1:?usage: check-version-bump.sh <base-ref>}"
manifest="plugins/king-agents/.claude-plugin/plugin.json"
if git diff --quiet "$base" -- plugins/king-agents/; then
  echo "ok: no plugins/king-agents change"; exit 0
fi
now="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("version",""))' "$manifest")"
was="$(git show "$base:$manifest" 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin).get("version",""))' 2>/dev/null || echo "")"
if [ -n "$now" ] && [ "$now" != "$was" ]; then
  echo "ok: plugin changed and version bumped ($was -> $now)"; exit 0
fi
echo "::error::plugins/king-agents/** changed but plugin.json version not bumped (still $now) — bump it" >&2
exit 1
