#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
run_job rm3-verify "$RM3_DIR/k8s/verify-job.yaml"
