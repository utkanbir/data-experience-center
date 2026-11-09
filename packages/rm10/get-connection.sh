#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' 'Server: 127.0.0.1:15441' 'Database: komtas_rm10' 'Username: rm10_bi'
printf 'Password: '
k -n "$RM10_NAMESPACE" get secret rm10-credentials -o 'jsonpath={.data.bi-password}' | base64 --decode
printf '\n'
