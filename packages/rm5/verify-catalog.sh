#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM5_NAMESPACE" exec rm5-artifacts -- rm -f /artifacts/governance-status.txt /artifacts/governance-checks.json
run_job rm5-catalog-verify "$RM5_DIR/k8s/catalog-verify-job.yaml"
