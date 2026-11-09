#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ -f "$RM6_DIR/external/mode.txt" ]] || exit 0
mode="$(tr -d '\r\n' < "$RM6_DIR/external/mode.txt")"
if [[ "$mode" != connect ]]; then echo 'Dis servis sonraya birakildi; ilgili kontroller erisim saglanana kadar denenmedi kalir.'; exit 0; fi
task_host="$(tr -d '\r\n' < "$RM6_DIR/external/host.txt")"
task_identity="$(tr -d '\r\n' < "$RM6_DIR/external/identity.txt")"
existing="$(k -n "$RM6_NAMESPACE" get secret rm6-dbt-service --ignore-not-found=true -o name)"
if [[ -n "$existing" ]]; then
 token_present="$(k -n "$RM6_NAMESPACE" get secret rm6-dbt-service -o 'jsonpath={.data.api-token}')"
 [[ -n "$token_present" ]] || { echo 'Yerel Secret token icermiyor; Set baglanti scriptini kullanin.' >&2; exit 1; }
 unset token_present
 old_host="$(k -n "$RM6_NAMESPACE" get secret rm6-dbt-service -o 'jsonpath={.data.host}' | base64 -d)"
 old_identity="$(k -n "$RM6_NAMESPACE" get secret rm6-dbt-service -o 'jsonpath={.data.environment-id}' | base64 -d)"
 if [[ ( -n "$task_host" && "$task_host" != "$old_host" ) || ( -n "$task_identity" && "$task_identity" != "$old_identity" ) ]]; then echo 'Mevcut Secret farkli baglantiya ait. bash set-dbt-connection.sh ile bilerek guncelleyin.' >&2; exit 1; fi
 echo 'Ayni baglanti Secret icinde var; token yeniden sorulmadi. Suresi dolunca bash set-dbt-connection.sh ile yenileyin.'
 exit 0
fi
bash "$RM6_DIR/set-dbt-connection.sh" "$task_host" "$task_identity"
