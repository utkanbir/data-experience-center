#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM5_NAMESPACE" exec rm5-artifacts -- rm -f /artifacts/dbt-status.txt /artifacts/dbt-checks.json
run_job rm5-dbt "$RM5_DIR/k8s/dbt-job.yaml"
