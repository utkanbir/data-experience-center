#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
run_job rm10-catalog-restore "$RM10_DIR/k8s/catalog-restore-job.yaml"
