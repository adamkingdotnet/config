#!/usr/bin/env bash
# check-settings.sh <type> <local settings.json> — assert a repo's committed
# .claude/settings.json is byte-identical to config's settings-templates/<type>.json
# (adamkingdotnet/config, public, @main). Same byte-gate guarantee as check-vendored.sh.
#
# KING_CONFIG_RAW overrides the canonical base URL (used by the offline test).
set -euo pipefail

type="${1:?usage: check-settings.sh <type> <local settings.json>}"
local="${2:?usage: check-settings.sh <type> <local settings.json>}"
RAW="${KING_CONFIG_RAW:-https://raw.githubusercontent.com/adamkingdotnet/config/main}"
url="$RAW/plugins/king-agents/settings-templates/$type.json"

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
if ! curl -fsSL "$url" -o "$tmp"; then
  echo "::error::could not fetch settings-templates/$type.json from $RAW" >&2
  exit 1
fi
if diff -u "$tmp" "$local"; then
  echo "ok: $local matches config settings-templates/$type.json"
else
  echo "::error file=$local::$local drifted from config settings-templates/$type.json — re-vendor it" >&2
  exit 1
fi
