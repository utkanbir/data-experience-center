#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' '127.0.0.1:15439 - bu terminal acik kalmali. Durdurmak icin Ctrl+C.'
k -n "$RM8_NAMESPACE" port-forward --address=127.0.0.1 service/postgres 15439:5432
