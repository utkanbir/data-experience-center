#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM10_NAMESPACE" exec rm10-artifacts -- rm -f /artifacts/cube-status.txt
run_job rm10-cube-check "$RM10_DIR/k8s/cube-check-job.yaml"
