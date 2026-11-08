#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
for artifact in metricflow-results.csv metricflow-sql.txt; do k -n "$RM3_NAMESPACE" exec rm3-artifacts -- cat "/artifacts/$artifact"; done
