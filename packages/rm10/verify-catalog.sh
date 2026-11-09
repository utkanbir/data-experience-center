#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM10_NAMESPACE" exec rm10-artifacts -- rm -f /artifacts/governance-status.txt /artifacts/governance-checks.json
run_job rm10-catalog-verify "$RM10_DIR/k8s/catalog-verify-job.yaml"
