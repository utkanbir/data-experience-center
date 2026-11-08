#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' 'dbt dokumani ve model grafigi: http://127.0.0.1:18084/static_index.html' 'Terminal acik kalmali. Durdurmak icin Ctrl+C.'
k -n "$RM4_NAMESPACE" port-forward --address=127.0.0.1 service/dbt-docs 18084:8080
