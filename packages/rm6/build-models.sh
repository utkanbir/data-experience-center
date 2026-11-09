#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM6_NAMESPACE" exec rm6-artifacts -- rm -f /artifacts/dbt-status.txt /artifacts/dbt-checks.json
run_job rm6-dbt "$RM6_DIR/k8s/dbt-job.yaml"
