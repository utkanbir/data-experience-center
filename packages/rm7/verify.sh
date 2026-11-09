#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
run_job rm7-verify "$RM7_DIR/k8s/verify-job.yaml"
