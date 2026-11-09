#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM7_NAMESPACE" create configmap rm7-governance --from-file="$RM7_DIR/governance" --dry-run=client -o yaml | k apply -f -
k -n "$RM7_NAMESPACE" exec rm7-artifacts -- rm -f /artifacts/cdgc-status.txt /artifacts/cdgc-checks.json /artifacts/cdgc-approval-template.json
start_job rm7-governance "$RM7_DIR/k8s/governance-job.yaml"
