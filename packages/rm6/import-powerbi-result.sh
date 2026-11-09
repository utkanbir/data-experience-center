#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ $# -eq 1 && -f "$1" ]] || { echo 'Kullanim: bash import-powerbi-result.sh /path/result.csv' >&2; exit 1; }
k -n "$RM6_NAMESPACE" create configmap rm6-powerbi-export --from-file="result.csv=$1" --dry-run=client -o yaml | k apply -f -
printf '%s\n' 'Manuel Power BI CSV kaydedildi. Run-Scenario icindeki gercek API ve referans kontroluyle degerlendirilir.'
