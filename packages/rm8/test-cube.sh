#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM8_NAMESPACE" exec rm8-artifacts -- rm -f /artifacts/cube-status.txt
run_job rm8-cube-check "$RM8_DIR/k8s/cube-check-job.yaml"
