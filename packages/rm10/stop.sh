#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
k -n "$RM10_NAMESPACE" scale statefulset/postgres --replicas=0
k -n "$RM10_NAMESPACE" scale deployment/cube deployment/cubestore deployment/dashboard deployment/dbt-docs deployment/openmetadata --replicas=0
k -n "$RM10_NAMESPACE" scale statefulset/metadata-postgres statefulset/elasticsearch --replicas=0
printf '%s\n' 'PostgreSQL ve servisler durduruldu. PVC ve Secret korundu. Yeniden baslat: bash deploy.sh'

k -n "$RM10_NAMESPACE" scale statefulset/neo4j --replicas=0
