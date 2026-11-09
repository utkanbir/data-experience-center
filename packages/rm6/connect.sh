#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' '127.0.0.1:15437 - bu terminal acik kalmali. Durdurmak icin Ctrl+C.'
k -n "$RM6_NAMESPACE" port-forward --address=127.0.0.1 service/postgres 15437:5432
