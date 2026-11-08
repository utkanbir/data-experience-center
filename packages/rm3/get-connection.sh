#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' 'Server: 127.0.0.1:15434' 'Database: komtas_rm3' 'Username: rm3_bi'
printf 'Password: '
k -n "$RM3_NAMESPACE" get secret rm3-credentials -o 'jsonpath={.data.bi-password}' | base64 --decode
printf '\n'
