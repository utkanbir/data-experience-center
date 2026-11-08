#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
case "${1:-}" in
  inject) file=fault-inject.sql;;
  restore) file=fault-restore.sql;;
  *) printf '%s\n' 'Kullanim: bash set-demo-fault.sh inject|restore' >&2; exit 1;;
esac
cat "$RM4_DIR/sql/$file" | k -n "$RM4_NAMESPACE" exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -h 127.0.0.1 -U rm4_admin -d komtas_rm4 -v ON_ERROR_STOP=1'
printf '%s\n' 'Run-Scenario ile model/test ve raporu yeniden olusturun.'
