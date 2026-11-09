#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM7_NAMESPACE" exec rm7-artifacts -- rm -f /artifacts/cube-status.txt
run_job rm7-cube-check "$RM7_DIR/k8s/cube-check-job.yaml"
