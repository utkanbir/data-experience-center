#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM10_NAMESPACE" exec rm10-artifacts -- cat /artifacts/graph-results.json
