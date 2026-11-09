#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM9_NAMESPACE" exec rm9-artifacts -- rm -f /artifacts/governance-status.txt /artifacts/governance-checks.json
run_job rm9-catalog-sync "$RM9_DIR/k8s/catalog-sync-job.yaml"
