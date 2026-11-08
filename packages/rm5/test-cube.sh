#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM5_NAMESPACE" exec rm5-artifacts -- rm -f /artifacts/cube-status.txt
run_job rm5-cube-check "$RM5_DIR/k8s/cube-check-job.yaml"
