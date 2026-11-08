#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM2_NAMESPACE" exec rm2-artifacts -- rm -f /artifacts/dbt-status.txt /artifacts/dbt-checks.json
run_job rm2-dbt "$RM2_DIR/k8s/dbt-job.yaml"
