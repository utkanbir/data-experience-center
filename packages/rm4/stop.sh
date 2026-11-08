#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM4_NAMESPACE" scale statefulset/postgres --replicas=0
k -n "$RM4_NAMESPACE" scale deployment/cube deployment/cubestore deployment/dashboard deployment/dbt-docs --replicas=0
printf '%s\n' 'PostgreSQL ve servisler durduruldu. PVC ve Secret korundu. Yeniden baslat: bash deploy.sh'
