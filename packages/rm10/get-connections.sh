#!/usr/bin/env bash
set -euo pipefail
task_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
task_namespace='komtas-rm10'
task_context='docker-desktop'
printf '=== RM10 | TUM BAGLANTILAR | %s ===\n' "$task_namespace"
while IFS='|' read -r task_id task_name task_remote task_port task_target task_kind task_path task_db task_user; do
 task_status='Connect henuz calistirilmadi'
 if [[ -f "$task_dir/.connections/runtime.tsv" ]]; then
  task_saved="$(awk -F'|' -v id="$task_id" '$1==id{print $2"|"$3}' "$task_dir/.connections/runtime.tsv")"
  if [[ -n "$task_saved" ]]; then task_port="${task_saved%%|*}";task_status="${task_saved#*|}"; fi
 fi
 printf '\n--- %s [%s]\n' "$task_name" "$task_status"
 if [[ "$task_kind" == http ]]; then printf 'http://127.0.0.1:%s%s\n' "$task_port" "$task_path"; elif [[ "$task_id" == neo4j-bolt ]]; then printf 'bolt://127.0.0.1:%s\n' "$task_port"; else printf '127.0.0.1:%s\n' "$task_port"; fi
 [[ -z "$task_db" ]] || printf 'Database: %s | User: %s\n' "$task_db" "$task_user"
 if [[ "$task_id" == trino ]]; then printf 'JDBC: jdbc:trino://127.0.0.1:%s/models/dwh | user rm9_reader | yerel HTTP, auth yok\n' "$task_port"; fi
done < "$task_dir/connections.tsv"
cat "$task_dir/connection-notes.txt"
for task_settings in managed/settings.json governance/settings.json cdgc/settings.json; do
 if [[ -f "$task_dir/$task_settings" ]]; then
  printf '\nHarici servis ayarlari: %s (tunel acilmaz)\n' "$task_settings"
  sed -nE '/"(host|apiHost|environmentId|orgId)"[[:space:]]*:/p' "$task_dir/$task_settings"
 fi
done
if [[ "${1:-}" == --no-secrets ]]; then echo 'Parola ve Cube JWT dahil tam bilgiler: bash get-connections.sh'; exit 0; fi
echo 'Gizli bilgiler yalniz bu terminalde gosterilir; paylasmayin. Dosyaya kaydedilmez.'
while IFS='|' read -r task_name task_secret task_key; do
 if task_encoded="$(kubectl --context "$task_context" -n "$task_namespace" get secret "$task_secret" -o "jsonpath={.data.$task_key}" 2>/dev/null)" && [[ -n "$task_encoded" ]]; then
  printf '%s: ' "$task_name";printf '%s' "$task_encoded" | base64 --decode;printf '\n'
 else printf '%s: henuz hazir degil; Deploy durumunu kontrol edin.\n' "$task_name"; fi
done < "$task_dir/connection-credentials.tsv"
if [[ -f "$task_dir/Get-ApiToken.ps1" ]]; then echo 'Cube JWT (5 dakika):';bash "$task_dir/get-api-token.sh"; fi
