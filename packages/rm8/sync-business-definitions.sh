#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM8_NAMESPACE" create configmap rm8-dual --from-file="$RM8_DIR/bridge" --dry-run=client -o yaml | k apply -f -
bash "$RM8_DIR/run-cdgc.sh"
run_job rm8-dual-sync "$RM8_DIR/k8s/dual-sync-job.yaml"
