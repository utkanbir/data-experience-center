#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM6_NAMESPACE" scale statefulset/postgres --replicas=0
k -n "$RM6_NAMESPACE" scale deployment/dbt-docs --replicas=0
printf '%s\n' 'PostgreSQL durduruldu. PVC ve Secret korundu. Yeniden baslat: bash deploy.sh'
