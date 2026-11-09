#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
sl_host="${1:-}"; sl_environment="${2:-}"
[[ -n "$sl_host" ]] || read -r -p 'dbt Semantic Layer host (yalniz host adi): ' sl_host
[[ -n "$sl_environment" ]] || read -r -p 'dbt deployment Environment ID: ' sl_environment
[[ "$sl_host" =~ ^[a-z0-9.-]+$ && "$sl_host" =~ (^|\.)semantic-layer\. && "$sl_host" =~ \.(getdbt\.com|dbt\.com)$ ]] || { echo 'Resmi Semantic Layer host gerekli.' >&2; exit 1; }
[[ "$sl_environment" =~ ^[0-9]{1,20}$ && "$sl_environment" =~ [1-9] ]] || { echo 'Pozitif Environment ID gerekli.' >&2; exit 1; }
read -r -s -p 'Semantic Layer service token (gizli): ' sl_token; printf '\n'
[[ -n "$sl_token" ]] || { echo 'Token bos olamaz.' >&2; exit 1; }
umask 077
credential_dir="$(mktemp -d)"
trap 'rm -f -- "$credential_dir/api-token" "$credential_dir/host" "$credential_dir/environment-id"; rmdir -- "$credential_dir"' EXIT
printf '%s' "$sl_token" > "$credential_dir/api-token"; unset sl_token
printf '%s' "$sl_host" > "$credential_dir/host"
printf '%s' "$sl_environment" > "$credential_dir/environment-id"
k -n "$RM6_NAMESPACE" create secret generic rm6-dbt-service --from-file="$credential_dir" --dry-run=client -o yaml | k apply -f -
printf '%s\n' 'Servis bilgileri yerel Kubernetes Secret icinde. Gercek servis testi: bash run-remote-checks.sh'

printf 'connect\n' > "$RM6_DIR/managed/connection-mode.txt"
