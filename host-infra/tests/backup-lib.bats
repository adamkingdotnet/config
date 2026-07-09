#!/usr/bin/env bats
# Tests for host-infra/backup-lib.sh. Run with bats, or via the plain-bash
# harness in tests/run.sh (no bats install required).

setup() {
  # shellcheck source=../backup-lib.sh
  source "$BATS_TEST_DIRNAME/../backup-lib.sh"
  TMP="$BATS_TEST_TMPDIR"
}

@test "verify_dump rejects a missing file" {
  run verify_dump "$TMP/nope" 1
  [ "$status" -ne 0 ]
}

@test "verify_dump rejects an undersized dump" {
  printf 'x' > "$TMP/small"
  run verify_dump "$TMP/small" 100
  [ "$status" -ne 0 ]
}

@test "verify_dump accepts a big-enough plain dump" {
  head -c 200 /dev/zero > "$TMP/ok.dump"
  run verify_dump "$TMP/ok.dump" 100
  [ "$status" -eq 0 ]
}

@test "verify_dump rejects a corrupt .gz even above the size floor" {
  head -c 200 /dev/zero > "$TMP/bad.gz"   # 200B of non-gzip
  run verify_dump "$TMP/bad.gz" 1
  [ "$status" -ne 0 ]
}

@test "verify_dump accepts a valid .gz" {
  head -c 500 /dev/zero | gzip > "$TMP/good.gz"
  run verify_dump "$TMP/good.gz" 10
  [ "$status" -eq 0 ]
}

@test "atomic_publish renames into place" {
  echo hi > "$TMP/t"
  run atomic_publish "$TMP/t" "$TMP/final"
  [ "$status" -eq 0 ]
  [ -f "$TMP/final" ]
  [ ! -e "$TMP/t" ]
}

@test "prune_keep keeps only the N newest matches" {
  for i in 1 2 3 4 5; do touch -t "2026010100${i}0" "$TMP/d-$i.sql"; done
  run prune_keep "$TMP" "d-*.sql" 2
  [ "$status" -eq 0 ]
  [ -f "$TMP/d-5.sql" ]
  [ -f "$TMP/d-4.sql" ]
  [ ! -e "$TMP/d-3.sql" ]
  [ ! -e "$TMP/d-1.sql" ]
}

@test "prune_keep is a no-op when fewer than N exist" {
  touch "$TMP/only-1.sql"
  run prune_keep "$TMP" "only-*.sql" 5
  [ "$status" -eq 0 ]
  [ -f "$TMP/only-1.sql" ]
}
