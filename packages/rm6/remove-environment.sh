#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
if [[ ! "$RM6_NAMESPACE" =~ ^komtas-[a-z0-9][a-z0-9-]{0,39}$ ]]; then printf '%s\n' 'Namespace izin verilen lab araliginda degil.' >&2; exit 1; fi
existing="$(k get namespace "$RM6_NAMESPACE" --ignore-not-found=true -o name)"
if [[ -z "$existing" ]]; then printf '%s\n' 'Ortam zaten silinmis.'; exit 0; fi
owner="$(k get namespace "$RM6_NAMESPACE" -o 'jsonpath={.metadata.labels.app\.kubernetes\.io/part-of}')"
if [[ "$owner" != "$RM6_NAMESPACE" ]]; then printf '%s\n' 'Lab sahiplik etiketi eslesmiyor. Otomatik silme durduruldu.' >&2; exit 1; fi
printf 'Context: %s\nSILINECEK NAMESPACE: %s\n' "$RM6_CONTEXT" "$RM6_NAMESPACE"
k -n "$RM6_NAMESPACE" get all,pvc,secret,configmap
printf '%s\n' 'Namespace icindeki tum kaynaklar, PostgreSQL verisi ve parolalar silinecek. Bu islem geri alinamaz. Saklayacaginiz veriyi once yedekleyin.'
printf 'Onay icin namespace adini yazin (%s): ' "$RM6_NAMESPACE"
read -r answer
if [[ "$answer" != "$RM6_NAMESPACE" ]]; then printf '%s\n' 'Iptal edildi.'; exit 0; fi
k delete namespace "$RM6_NAMESPACE" --wait=true --timeout=120s
printf '%s\n' 'Namespace ve lab kaynaklari silindi. Tekrar kurmak icin bash deploy.sh calistirin. PVC verisinin fiziksel temizlenmesi StorageClass reclaim politikasina baglidir.'
