#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM8_NAMESPACE" exec rm8-artifacts -- rm -f /artifacts/dbt-status.txt /artifacts/dbt-checks.json
run_job rm8-dbt "$RM8_DIR/k8s/dbt-job.yaml"
