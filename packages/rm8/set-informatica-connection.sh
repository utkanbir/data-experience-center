#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
api_host="${1:-}"; org_id="${2:-}"
[[ -n "$api_host" ]] || read -r -p 'Resmi CDGC idmc-api host: ' api_host
[[ -n "$org_id" ]] || read -r -p 'Informatica Org ID: ' org_id
[[ "$api_host" =~ ^idmc-api(\.[a-z0-9-]+)+\.informaticacloud\.com$ ]] || { echo 'Resmi API host gerekli.' >&2; exit 1; }
[[ "$org_id" =~ ^[A-Za-z0-9_-]{1,100}$ ]] || { echo 'Org ID gecersiz.' >&2; exit 1; }
read -r -s -p 'CDGC JWT (gizli): ' infa_token; printf '\n'
[[ -n "$infa_token" && "$infa_token" != *$'\r'* && "$infa_token" != *$'\n'* ]] || { echo 'JWT gecersiz.' >&2; exit 1; }
umask 077
credential_dir="$(mktemp -d)"
trap 'rm -f -- "$credential_dir/api-token" "$credential_dir/api-host" "$credential_dir/org-id"; rmdir -- "$credential_dir"' EXIT
printf '%s' "$infa_token" > "$credential_dir/api-token"; unset infa_token
printf '%s' "$api_host" > "$credential_dir/api-host"
printf '%s' "$org_id" > "$credential_dir/org-id"
k -n "$RM8_NAMESPACE" create secret generic rm8-informatica --from-file="$credential_dir" --dry-run=client -o yaml | k apply -f -
printf '%s\n' 'JWT yerel Secret icinde. Varlik eslemesi: cdgc/settings.json. Test: bash run-cdgc.sh'

printf 'connect\n' > "$RM8_DIR/cdgc/connection-mode.txt"
