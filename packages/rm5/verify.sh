#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
run_job rm5-verify "$RM5_DIR/k8s/verify-job.yaml"
