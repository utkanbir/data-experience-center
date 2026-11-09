#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
run_job rm10-catalog-fault "$RM10_DIR/k8s/catalog-fault-job.yaml"
