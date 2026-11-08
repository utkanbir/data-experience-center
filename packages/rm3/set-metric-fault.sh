#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
project="$(cat "$RM3_DIR/dbt-project.json")"
case "${1:-}" in
  inject) project="${project//gross_revenue_eur - discount_amount_eur - return_amount_eur/gross_revenue_eur}";;
  restore) ;;
  *) printf '%s\n' 'Kullanim: bash set-metric-fault.sh inject|restore' >&2; exit 1;;
esac
file="$(mktemp)"
trap 'rm -f -- "$file"' EXIT
printf '%s' "$project" > "$file"
k -n "$RM3_NAMESPACE" create configmap rm3-dbt --from-file="project.json=$file" --from-file="runner.py=$RM3_DIR/runner.py" --dry-run=client -o yaml | k apply -f -
printf '%s\n' 'Run-Scenario ile metrik tanimini ve referans eslesmesini yeniden kontrol edin.'
