#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' 'Server: 127.0.0.1:15433' 'Database: komtas_rm2' 'Username: rm2_bi'
printf 'Password: '
k -n "$RM2_NAMESPACE" get secret rm2-credentials -o 'jsonpath={.data.bi-password}' | base64 --decode
printf '\n'
