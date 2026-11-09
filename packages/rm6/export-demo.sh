#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
mkdir -p "$RM6_DIR/cloud-transfer"
k -n "$RM6_NAMESPACE" exec postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec pg_dump --no-owner --no-privileges --schema=raw -U rm6_admin -d komtas_rm6' > "$RM6_DIR/cloud-transfer/demo.sql"
printf '%s\n' 'Sentetik raw veri cloud-transfer/demo.sql icinde. Harici sisteme aktarim yapilmadi.'
