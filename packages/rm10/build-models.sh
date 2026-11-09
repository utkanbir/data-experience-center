#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM10_NAMESPACE" exec rm10-artifacts -- rm -f /artifacts/dbt-status.txt /artifacts/dbt-checks.json
run_job rm10-dbt "$RM10_DIR/k8s/dbt-job.yaml"
