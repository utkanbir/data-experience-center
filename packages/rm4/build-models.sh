#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM4_NAMESPACE" exec rm4-artifacts -- rm -f /artifacts/dbt-status.txt /artifacts/dbt-checks.json
run_job rm4-dbt "$RM4_DIR/k8s/dbt-job.yaml"
