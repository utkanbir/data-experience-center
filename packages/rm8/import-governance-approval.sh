#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
approval_file="${1:?JSON dosyasi gerekli}"
[[ -f "$approval_file" && $(wc -c < "$approval_file") -le 500000 ]] || { echo 'En fazla 500 KB JSON gerekli.' >&2; exit 1; }
k -n "$RM8_NAMESPACE" create configmap rm8-approval --from-file="approval.json=$approval_file" --dry-run=client -o yaml | k apply -f -
echo 'Manuel kayit yuklendi. Onay islemi yapilmadi; Run-Scenario gercek API surumune karsi tutarlilik kontrolu yapar.'
