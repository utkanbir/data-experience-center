#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' 'Server: 127.0.0.1:15440' 'Database: komtas_rm9' 'Username: rm9_bi'
printf 'Password: '
k -n "$RM9_NAMESPACE" get secret rm9-credentials -o 'jsonpath={.data.bi-password}' | base64 --decode
printf '\n'
