#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM8_NAMESPACE" create configmap rm8-dual --from-file="$RM8_DIR/bridge" --dry-run=client -o yaml | k apply -f -
k -n "$RM8_NAMESPACE" exec rm8-artifacts -- rm -f /artifacts/dual-status.txt /artifacts/dual-checks.json
run_job rm8-dual-verify "$RM8_DIR/k8s/dual-verify-job.yaml"
