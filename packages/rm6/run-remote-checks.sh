#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM6_NAMESPACE" create configmap rm6-managed --from-file="$RM6_DIR/managed" --dry-run=client -o yaml | k apply -f -
k -n "$RM6_NAMESPACE" exec rm6-artifacts -- rm -f /artifacts/managed-status.txt /artifacts/managed-checks.json
run_job rm6-managed "$RM6_DIR/k8s/managed-job.yaml"
