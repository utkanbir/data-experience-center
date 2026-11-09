#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' 'Server: 127.0.0.1:15438' 'Database: komtas_rm7' 'Username: rm7_bi'
printf 'Password: '
k -n "$RM7_NAMESPACE" get secret rm7-credentials -o 'jsonpath={.data.bi-password}' | base64 --decode
printf '\n'
