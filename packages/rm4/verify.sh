#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
run_job rm4-verify "$RM4_DIR/k8s/verify-job.yaml"
