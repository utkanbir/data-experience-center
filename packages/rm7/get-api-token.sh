#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
printf '%s\n' '5 dakika gecerli lab tokeni; paylasmayin. API: http://127.0.0.1:4007/cubejs-api/v1/meta'
k -n "$RM7_NAMESPACE" exec deployment/dashboard -- python -c 'import sys;sys.path.insert(0,"/consumer");from client import token;print(token())'
