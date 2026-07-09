#!/usr/bin/env bash
# check-vendored.sh — assert a repo's vendored copy of a shared fragment is
# byte-identical to the canonical in adamkingdotnet/config (public, @main).
#
# Usage (one or more pairs of <canonical-path> <local-file>):
#   scripts/check-vendored.sh host-infra/backup-lib.sh host-infra/backup-lib.sh \
#                             host-infra/netdata-apps-off.conf netdata/netdata.conf
#
# Run from a host repo's CI. Fails (non-zero) with a diff on any drift, so the
# vendored copy and canonical move in lockstep (same guarantee as .editorconfig).
set -euo pipefail

RAW="https://raw.githubusercontent.com/adamkingdotnet/config/main"
rc=0

[ $(( $# % 2 )) -eq 0 ] || { echo "usage: check-vendored.sh <canon> <local> [<canon> <local>...]" >&2; exit 2; }

while [ $# -gt 0 ]; do
  canon="$1"; local="$2"; shift 2
  tmp="$(mktemp)"
  if ! curl -fsSL "$RAW/$canon" -o "$tmp"; then
    echo "::error::could not fetch canonical config/$canon" >&2; rc=1; rm -f "$tmp"; continue
  fi
  if diff -u "$tmp" "$local"; then
    echo "ok: $local matches config/$canon"
  else
    echo "::error file=$local::$local drifted from config/$canon — re-vendor it" >&2
    rc=1
  fi
  rm -f "$tmp"
done

exit "$rc"
