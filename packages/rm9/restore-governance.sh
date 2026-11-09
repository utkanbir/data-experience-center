#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
run_job rm9-catalog-restore "$RM9_DIR/k8s/catalog-restore-job.yaml"
