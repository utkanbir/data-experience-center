#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' 'Server: 127.0.0.1:15439' 'Database: komtas_rm8' 'Username: rm8_bi'
printf 'Password: '
k -n "$RM8_NAMESPACE" get secret rm8-credentials -o 'jsonpath={.data.bi-password}' | base64 --decode
printf '\n'
