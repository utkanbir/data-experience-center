#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' 'Server: 127.0.0.1:15437' 'Database: komtas_rm6' 'Username: rm6_bi'
printf 'Password: '
k -n "$RM6_NAMESPACE" get secret rm6-credentials -o 'jsonpath={.data.bi-password}' | base64 --decode
printf '\n'
