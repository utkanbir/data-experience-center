#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
bash "$RM3_DIR/build-models.sh"
bash "$RM3_DIR/show-metrics.sh"
