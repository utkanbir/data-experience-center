#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM10_NAMESPACE" create configmap rm10-graph-code --from-file="$RM10_DIR/graph" --dry-run=client -o yaml | k apply -f -
k -n "$RM10_NAMESPACE" exec rm10-artifacts -- rm -f /artifacts/graph-status.txt /artifacts/graph-checks.json /artifacts/graph-results.json
run_job rm10-graph-sync "$RM10_DIR/k8s/graph-sync-job.yaml"
