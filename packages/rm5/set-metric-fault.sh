#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
mode="${1:-}"
[[ "$mode" == inject || "$mode" == restore ]] || { echo 'inject veya restore gerekli' >&2; exit 1; }
temp_model="$(mktemp -d)"
trap 'rm -f -- "$temp_model/Sales.js"; rmdir -- "$temp_model"' EXIT
if [[ "$mode" == inject ]]; then
  sed 's/gross_revenue_eur - discount_amount_eur - return_amount_eur/gross_revenue_eur/' "$RM5_DIR/cube/schema/Sales.js" > "$temp_model/Sales.js"
else
  cp "$RM5_DIR/cube/schema/Sales.js" "$temp_model/Sales.js"
fi
k -n "$RM5_NAMESPACE" create configmap rm5-cube-model --from-file="$temp_model/Sales.js" --dry-run=client -o yaml | k apply -f -
k -n "$RM5_NAMESPACE" rollout restart deployment/cube
k -n "$RM5_NAMESPACE" rollout status deployment/cube --timeout=180s
printf 'Metric formula mode: %s. Run-scenario ile raporu yeniden uretin.\n' "$mode"
