#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf 'ALTER TABLE raw.dim_outlet RENAME TO dim_outlet_unavailable;\n' | k -n "$RM9_NAMESPACE" exec -i postgres-reference-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql -h 127.0.0.1 -U rm9_admin -d komtas_rm9_reference -v ON_ERROR_STOP=1'
