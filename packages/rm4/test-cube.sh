#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM4_NAMESPACE" exec rm4-artifacts -- rm -f /artifacts/cube-status.txt
run_job rm4-cube-check "$RM4_DIR/k8s/cube-check-job.yaml"
