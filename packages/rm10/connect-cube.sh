#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
port="${1:-4010}"
[[ "$port" =~ ^[0-9]+$ ]] && ((port>=1024 && port<=65535)) || { echo 'Gecersiz port' >&2; exit 1; }
printf 'Cube: http://127.0.0.1:%s | Terminal acik kalmali.\n' "$port"
k -n "$RM10_NAMESPACE" port-forward --address=127.0.0.1 service/cube "$port:4000"
