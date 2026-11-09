#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM8_NAMESPACE" create configmap rm8-cdgc --from-file="$RM8_DIR/cdgc" --dry-run=client -o yaml | k apply -f -
k -n "$RM8_NAMESPACE" exec rm8-artifacts -- rm -f /artifacts/cdgc-status.txt /artifacts/cdgc-checks.json /artifacts/cdgc-approval-template.json
run_job rm8-cdgc "$RM8_DIR/k8s/cdgc-job.yaml"
