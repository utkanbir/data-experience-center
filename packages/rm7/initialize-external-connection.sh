#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ -f "$RM7_DIR/external/mode.txt" ]] || exit 0
mode="$(tr -d '\r\n' < "$RM7_DIR/external/mode.txt")"
if [[ "$mode" != connect ]]; then echo 'Dis servis sonraya birakildi; ilgili kontroller erisim saglanana kadar denenmedi kalir.'; exit 0; fi
task_host="$(tr -d '\r\n' < "$RM7_DIR/external/host.txt")"
task_identity="$(tr -d '\r\n' < "$RM7_DIR/external/identity.txt")"
existing="$(k -n "$RM7_NAMESPACE" get secret rm7-informatica --ignore-not-found=true -o name)"
if [[ -n "$existing" ]]; then
 token_present="$(k -n "$RM7_NAMESPACE" get secret rm7-informatica -o 'jsonpath={.data.api-token}')"
 [[ -n "$token_present" ]] || { echo 'Yerel Secret token icermiyor; Set baglanti scriptini kullanin.' >&2; exit 1; }
 unset token_present
 old_host="$(k -n "$RM7_NAMESPACE" get secret rm7-informatica -o 'jsonpath={.data.api-host}' | base64 -d)"
 old_identity="$(k -n "$RM7_NAMESPACE" get secret rm7-informatica -o 'jsonpath={.data.org-id}' | base64 -d)"
 if [[ ( -n "$task_host" && "$task_host" != "$old_host" ) || ( -n "$task_identity" && "$task_identity" != "$old_identity" ) ]]; then echo 'Mevcut Secret farkli baglantiya ait. bash set-informatica-connection.sh ile bilerek guncelleyin.' >&2; exit 1; fi
 echo 'Ayni baglanti Secret icinde var; token yeniden sorulmadi. Suresi dolunca bash set-informatica-connection.sh ile yenileyin.'
 exit 0
fi
bash "$RM7_DIR/set-informatica-connection.sh" "$task_host" "$task_identity"
