#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
run_job rm2-verify "$RM2_DIR/k8s/verify-job.yaml"
