#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM8_NAMESPACE" exec rm8-artifacts -- rm -f /artifacts/governance-status.txt /artifacts/governance-checks.json
run_job rm8-catalog-verify "$RM8_DIR/k8s/catalog-verify-job.yaml"
