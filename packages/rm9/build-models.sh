#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM9_NAMESPACE" exec rm9-artifacts -- rm -f /artifacts/dbt-status.txt /artifacts/dbt-checks.json
run_job rm9-dbt "$RM9_DIR/k8s/dbt-job.yaml"
