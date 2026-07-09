#!/usr/bin/env bash
# check-agreement.sh <file> — assert the vendored "Working agreement" block inside
# <file> (an AGENTS.md) is byte-identical to the canonical in adamkingdotnet/config
# (agents/working-agreement.md, public, @main).
#
# The block is delimited by HTML-comment markers:
#   <!-- BEGIN working-agreement (vendored from adamkingdotnet/config ...) -->
#   ...canonical content...
#   <!-- END working-agreement -->
# Everything strictly between the markers must equal the canonical, so the 4 tenets +
# 4 instructions stay in lockstep fleet-wide (same guarantee as check-vendored.sh).
set -euo pipefail

file="${1:?usage: check-agreement.sh <AGENTS.md>}"
url="https://raw.githubusercontent.com/adamkingdotnet/config/main/agents/working-agreement.md"

canon="$(mktemp)"; block="$(mktemp)"
trap 'rm -f "$canon" "$block"' EXIT

curl -fsSL "$url" -o "$canon"
awk '/<!-- BEGIN working-agreement/{f=1;next} /<!-- END working-agreement/{f=0} f' "$file" > "$block"

if [ ! -s "$block" ]; then
  echo "::error file=$file::no working-agreement block found (BEGIN/END markers missing)" >&2
  exit 1
fi
if diff -u "$canon" "$block"; then
  echo "ok: $file working-agreement matches config/agents/working-agreement.md"
else
  echo "::error file=$file::working-agreement drifted from config/agents/working-agreement.md — re-vendor it" >&2
  exit 1
fi
