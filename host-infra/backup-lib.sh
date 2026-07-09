#!/usr/bin/env bash
# Shared backup verify/publish/prune helpers for the docker host stacks.
#
# Vendored byte-identical into nas-docker and vps-docker (each repo's CI diffs
# its copy against this canonical via scripts/check-vendored.sh). Source it and
# keep your own dump driver — these are the integrity primitives, not the loop.
#
# Canonical: adamkingdotnet/config -> host-infra/backup-lib.sh
# shellcheck shell=bash

# verify_dump <file> <min_bytes>
#   Fail (non-zero) if <file> is missing, smaller than <min_bytes>, or — when it
#   ends in .gz — not a valid gzip stream. An interrupted-but-flushed gzip can
#   still pass `gzip -t`, so the size floor is a second, independent guard.
verify_dump() {
  local f="$1" min="${2:-1}" size
  [ -f "$f" ] || { echo "verify_dump: missing $f" >&2; return 1; }
  size=$(wc -c < "$f")
  if [ "$size" -lt "$min" ]; then
    echo "verify_dump: $f is ${size}B (< ${min}B floor); treating as corrupt" >&2
    return 1
  fi
  case "$f" in
    *.gz)
      if ! gzip -t "$f" 2>/dev/null; then
        echo "verify_dump: $f failed gzip -t" >&2
        return 1
      fi
      ;;
  esac
  return 0
}

# atomic_publish <tmp> <final>
#   Publish a verified dump with a single rename, so a reader (or a prune pass)
#   never sees a half-written file under the final name.
atomic_publish() {
  mv -f "$1" "$2"
}

# prune_keep <dir> <glob> <keep_n>
#   Keep the <keep_n> newest files matching <dir>/<glob>; delete the rest.
#   Runs only after a successful publish, so a failed dump can never evict a
#   good generation. Operates on our own dated dump names (no odd characters).
prune_keep() {
  local dir="$1" glob="$2" keep="$3"
  ( cd "$dir" 2>/dev/null || return 0
    # shellcheck disable=SC2012,SC2086  # ls -t gives us mtime order; $glob must word-split
    ls -1t $glob 2>/dev/null | tail -n +"$((keep + 1))" | while IFS= read -r old; do
      rm -f -- "$old"
    done )
}
