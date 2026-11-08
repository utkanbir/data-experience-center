#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' 'Server: 127.0.0.1:15435' 'Database: komtas_rm4' 'Username: rm4_bi'
printf 'Password: '
k -n "$RM4_NAMESPACE" get secret rm4-credentials -o 'jsonpath={.data.bi-password}' | base64 --decode
printf '\n'
