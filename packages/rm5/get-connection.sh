#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' 'Server: 127.0.0.1:15436' 'Database: komtas_rm5' 'Username: rm5_bi'
printf 'Password: '
k -n "$RM5_NAMESPACE" get secret rm5-credentials -o 'jsonpath={.data.bi-password}' | base64 --decode
printf '\n'
