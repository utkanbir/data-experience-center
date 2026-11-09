#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM9_NAMESPACE" exec rm9-artifacts -- rm -f /artifacts/cube-status.txt
run_job rm9-cube-check "$RM9_DIR/k8s/cube-check-job.yaml"
