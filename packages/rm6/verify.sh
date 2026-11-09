#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
run_job rm6-verify "$RM6_DIR/k8s/verify-job.yaml"
