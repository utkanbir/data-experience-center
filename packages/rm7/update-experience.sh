#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM7_NAMESPACE" create configmap rm7-consumers --from-file="$RM7_DIR/consumers" --dry-run=client -o yaml | k apply -f -
k -n "$RM7_NAMESPACE" create configmap rm7-governance --from-file="$RM7_DIR/governance" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM7_DIR/k8s/dashboard.yaml"
k -n "$RM7_NAMESPACE" rollout restart deployment/dashboard
k -n "$RM7_NAMESPACE" rollout status deployment/dashboard --timeout=900s
