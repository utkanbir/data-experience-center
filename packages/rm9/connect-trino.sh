#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
port="${1:-18099}"
[[ "$port" =~ ^[0-9]+$ ]] && ((port>=1024 && port<=65535)) || exit 1
printf 'Trino: http://127.0.0.1:%s | terminal acik kalmali.\n' "$port"
k -n "$RM9_NAMESPACE" port-forward --address=127.0.0.1 service/trino "$port:8080"
