#!/usr/bin/env bash
# Scratch PostgreSQL 16 run of the Goora migrations, seed and pgTAP files, for
# a machine where Docker (and so `supabase start`) is not answering (013 D15).
# Reported as "scratch PG16 + shim" — the real run is `supabase db reset` and
# `supabase test db` (README).
#
# Needs a running PostgreSQL 16 you may drop databases on — NOT a service you
# care about. Start a throwaway one:
#   initdb -D <dir> -U postgres -A trust -E UTF8 --locale=C
#   pg_ctl -D <dir> -o "-p 55499 -c listen_addresses=127.0.0.1" start
#
# Env: PGBIN (dir of psql), PGPORT (default 55499), PGTAP_SQL (path to a built
# pgtap.sql — pgTAP v1.3.3 `sql/pgtap.sql.in` with MODULE_PATHNAME, __OS__ and
# __VERSION__ substituted; no patches needed on PG16).
# Args: ["reset"]  → drop/create the database, shim, pgTAP, migrations, seed
#       ["test" [file…]] → run test files (default all supabase/tests/*.test.sql)
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
PGBIN="${PGBIN:-/c/Program Files/PostgreSQL/16/bin}"
PGPORT="${PGPORT:-55499}"
DB=goora_scratch
psqlc() { "$PGBIN/psql.exe" -h 127.0.0.1 -p "$PGPORT" -U postgres -X -q "$@"; }

reset() {
  psqlc -d postgres -c "drop database if exists $DB with (force)" -c "create database $DB" || exit 1
  psqlc -d $DB -v ON_ERROR_STOP=1 -f "$here/00_supabase_shim.psql" || exit 1
  if [ -n "${PGTAP_SQL:-}" ]; then
    psqlc -d $DB -v ON_ERROR_STOP=1 -c "set search_path = extensions, public" -f "$PGTAP_SQL" >/dev/null || exit 1
  fi
  for f in "$root"/supabase/migrations/*.sql; do
    echo "migration $(basename "$f")"
    # PostGIS is not installed on the scratch server: the shim supplies the types.
    sed -e '/create extension if not exists postgis/d' \
        -e '/create extension if not exists pg_cron/d' \
        -e '/create extension if not exists pg_net/d' \
        -e 's/extensions\.geography(point, 4326)/extensions.geography/g' "$f" |
      psqlc -d $DB -v ON_ERROR_STOP=1 -f - || { echo "FAILED: $f"; exit 1; }
  done
  if [ -f "$root/supabase/seed.sql" ]; then
    echo "seed.sql"
    sed -e 's/extensions\.geography(point, 4326)/extensions.geography/g' "$root/supabase/seed.sql" |
      psqlc -d $DB -v ON_ERROR_STOP=1 -f - || { echo "FAILED: seed.sql"; exit 1; }
  fi
}

run_tests() {
  cd "$root/supabase/tests" || exit 1
  local files=("$@")
  [ ${#files[@]} -eq 0 ] && files=(./*.test.sql)
  local total_ok=0 total_bad=0 files_bad=0
  for f in "${files[@]}"; do
    # The product tests `create extension pgtap`; here pgTAP is loaded by reset.
    out="$(sed -e '/create extension if not exists pgtap/d' "$f" | psqlc -At -d $DB -f - 2>&1)"
    ok=$(printf '%s\n' "$out" | grep -c -E '^ok ')
    bad=$(printf '%s\n' "$out" | grep -c -E '^not ok ')
    err=$(printf '%s\n' "$out" | grep -c -E 'ERROR:|FATAL:')
    echo "== $(basename "$f"): ok=$ok not_ok=$bad sql_errors=$err"
    printf '%s\n' "$out" | grep -E '^not ok |ERROR:|^# (Failed|Looks|have|want|     )' | head -30
    total_ok=$((total_ok + ok)); total_bad=$((total_bad + bad))
    [ "$bad" -gt 0 ] || [ "$err" -gt 0 ] && files_bad=$((files_bad + 1))
  done
  echo "TOTAL ok=$total_ok not_ok=$total_bad files_with_problems=$files_bad"
}

case "${1:-}" in
  reset) reset ;;
  test) shift; run_tests "$@" ;;
  *) echo "usage: $0 reset | test [file…]"; exit 2 ;;
esac
