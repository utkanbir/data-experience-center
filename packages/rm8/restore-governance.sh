#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
run_job rm8-catalog-restore "$RM8_DIR/k8s/catalog-restore-job.yaml"
