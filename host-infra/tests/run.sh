#!/usr/bin/env bash
# Plain-bash harness for backup-lib.sh (mirrors backup-lib.bats; no bats needed).
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../backup-lib.sh
source "$DIR/../backup-lib.sh"

pass=0 fail=0
assert() { # <name> <expected 0|nonzero flag: eq0|ne0> <actual-rc>
  local name="$1" want="$2" rc="$3"
  if { [ "$want" = eq0 ] && [ "$rc" -eq 0 ]; } || { [ "$want" = ne0 ] && [ "$rc" -ne 0 ]; }; then
    pass=$((pass+1)); printf '  ok   %s\n' "$name"
  else
    fail=$((fail+1)); printf '  FAIL %s (rc=%s)\n' "$name" "$rc"
  fi
}
assert_true() { # <name> <cond-rc>
  if [ "$2" -eq 0 ]; then pass=$((pass+1)); printf '  ok   %s\n' "$1"
  else fail=$((fail+1)); printf '  FAIL %s\n' "$1"; fi
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

verify_dump "$TMP/nope" 1;      assert "reject missing"     ne0 $?
printf 'x' > "$TMP/small"
verify_dump "$TMP/small" 100;   assert "reject undersized"  ne0 $?
head -c 200 /dev/zero > "$TMP/ok.dump"
verify_dump "$TMP/ok.dump" 100; assert "accept big plain"   eq0 $?
head -c 200 /dev/zero > "$TMP/bad.gz"
verify_dump "$TMP/bad.gz" 1;    assert "reject corrupt .gz" ne0 $?
head -c 500 /dev/zero | gzip > "$TMP/good.gz"
verify_dump "$TMP/good.gz" 10;  assert "accept valid .gz"   eq0 $?

echo hi > "$TMP/t"
atomic_publish "$TMP/t" "$TMP/final"
[ -f "$TMP/final" ] && [ ! -e "$TMP/t" ]; assert_true "atomic_publish renames" $?

for i in 1 2 3 4 5; do touch -t "2026010100${i}0" "$TMP/d-$i.sql"; done
prune_keep "$TMP" "d-*.sql" 2
[ -f "$TMP/d-5.sql" ] && [ -f "$TMP/d-4.sql" ] && [ ! -e "$TMP/d-3.sql" ] && [ ! -e "$TMP/d-1.sql" ]
assert_true "prune keeps newest 2" $?

touch "$TMP/only-1.sql"
prune_keep "$TMP" "only-*.sql" 5
[ -f "$TMP/only-1.sql" ]; assert_true "prune no-op under N" $?

echo; echo "  $pass passed, $fail failed"
[ "$fail" -eq 0 ]
