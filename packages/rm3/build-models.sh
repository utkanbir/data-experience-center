#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM3_NAMESPACE" exec rm3-artifacts -- rm -f /artifacts/dbt-status.txt /artifacts/dbt-checks.json
run_job rm3-dbt "$RM3_DIR/k8s/dbt-job.yaml"
