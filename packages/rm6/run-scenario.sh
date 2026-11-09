#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
require_complete=0
if [[ "${1:-}" == --require-complete ]]; then require_complete=1; elif [[ $# -gt 0 ]]; then echo 'Bilinmeyen parametre' >&2; exit 1; fi
mkdir -p "$RM6_DIR/reports"
report_dir="$(mktemp -d "$RM6_DIR/reports/run-$(date -u +%Y%m%d-%H%M%S)-XXXXXX")"
mkdir "$report_dir/kanitlar"
if ! bash "$RM6_DIR/build-models.sh"; then printf '%s\n' 'dbt build/test failed; report will preserve evidence.'; fi
if ! bash "$RM6_DIR/run-remote-checks.sh"; then echo "Managed checks failed; preserving evidence."; fi
sl_metadata=not_tested; sl_query=not_tested; sl_sql=not_tested; sl_match=not_tested; sl_powerbi=not_tested
mapfile -t remote_states < <(k -n "$RM6_NAMESPACE" exec rm6-artifacts -- cat /artifacts/managed-status.txt 2>/dev/null || true)
if [[ "${#remote_states[@]}" -eq 5 ]]; then
  valid=1; for state in "${remote_states[@]}"; do [[ "$state" =~ ^(passed|failed|not_tested)$ ]] || valid=0; done
  if [[ "$valid" -eq 1 ]]; then sl_metadata="${remote_states[0]}"; sl_query="${remote_states[1]}"; sl_sql="${remote_states[2]}"; sl_match="${remote_states[3]}"; sl_powerbi="${remote_states[4]}"; fi
fi
models=not_tested; tests=not_tested; docs=not_tested; semantic_model=not_tested
status_text="$(k -n "$RM6_NAMESPACE" exec rm6-artifacts -- cat /artifacts/dbt-status.txt 2>/dev/null || true)"
mapfile -t tool_states <<< "$status_text"
if [[ "${#tool_states[@]}" -eq 4 ]]; then
  if [[ "${tool_states[0]}" =~ ^(passed|failed|not_tested)$ && "${tool_states[1]}" =~ ^(passed|failed|not_tested)$ && "${tool_states[2]}" =~ ^(passed|failed|not_tested)$ && "${tool_states[3]}" =~ ^(passed|failed|not_tested)$ ]]; then
    models="${tool_states[0]}"; tests="${tool_states[1]}"; docs="${tool_states[2]}"; semantic_model="${tool_states[3]}"
  fi
fi
for artifact in manifest.json build_results.json catalog.json static_index.html dbt-checks.json semantic_manifest.json managed-checks.json managed-results.json managed-sql.txt powerbi-results.json; do
  k -n "$RM6_NAMESPACE" cp "rm6-artifacts:/artifacts/$artifact" "$report_dir/kanitlar/$artifact" 2>/dev/null || true
done
report_sql="$(cat "$RM6_DIR/sql/report.sql")"
report_sql="${report_sql//__DBT_MODELS__/$models}"
report_sql="${report_sql//__DBT_TESTS__/$tests}"
report_sql="${report_sql//__DBT_DOCS__/$docs}"
report_sql="${report_sql//__SEMANTIC_MODEL__/$semantic_model}"
report_sql="${report_sql//__SL_METADATA__/$sl_metadata}"
report_sql="${report_sql//__SL_QUERY__/$sl_query}"
report_sql="${report_sql//__SL_SQL__/$sl_sql}"
report_sql="${report_sql//__SL_MATCH__/$sl_match}"
report_sql="${report_sql//__SL_POWERBI__/$sl_powerbi}"
executions=''
failed=0
for sql in 01-kanal-geliri.sql 02-horeca-degisim.sql 03-distributor-urun.sql verify.sql; do
  printf 'Running: %s\n' "$sql"
  cp "$RM6_DIR/sql/$sql" "$report_dir/kanitlar/$sql"
  if { printf 'SET ROLE rm6_bi;\n'; cat "$RM6_DIR/sql/$sql"; } | k -n "$RM6_NAMESPACE" exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -h 127.0.0.1 -U rm6_admin -d komtas_rm6 -v ON_ERROR_STOP=1' > "$report_dir/kanitlar/$sql.txt" 2>&1; then
    status='passed'
  else
    status='failed'; failed=1
  fi
  cat "$report_dir/kanitlar/$sql.txt"
  executions+="${executions:+,}{\"file\":\"$sql\",\"status\":\"$status\"}"
done
observation='null'
if { printf 'SET ROLE rm6_bi;\n'; printf '%s\n' "$report_sql"; } | k -n "$RM6_NAMESPACE" exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -Atq -h 127.0.0.1 -U rm6_admin -d komtas_rm6 -v ON_ERROR_STOP=1' > "$report_dir/kanitlar/observation.json" 2> "$report_dir/kanitlar/report-error.txt"; then
  observation="$(cat "$report_dir/kanitlar/observation.json")"
  if [[ -z "$observation" ]]; then observation='null'; failed=1; fi
  if [[ "$observation" == *'"failed"'* ]]; then failed=1; fi
else
  failed=1
fi
if [[ "$observation" == null ]]; then
  observation='{"checks":[{"id":"schemas","status":"not_tested"},{"id":"rows","status":"not_tested"},{"id":"months","status":"not_tested"},{"id":"horeca","status":"not_tested"},{"id":"volume","status":"not_tested"},{"id":"price","status":"not_tested"},{"id":"bi_role","status":"not_tested"},{"id":"no_insert","status":"not_tested"},{"id":"dbt_models","status":"'"$models"'"},{"id":"dbt_tests","status":"'"$tests"'"},{"id":"dbt_docs","status":"'"$docs"'"},{"id":"semantic_model","status":"'"$semantic_model"'"},{"id":"sl_metadata","status":"'"$sl_metadata"'"},{"id":"sl_query","status":"'"$sl_query"'"},{"id":"sl_sql","status":"'"$sl_sql"'"},{"id":"sl_match","status":"'"$sl_match"'"},{"id":"sl_powerbi","status":"'"$sl_powerbi"'"}],"metrics":{"janRevenue":null,"febRevenue":null,"janLiters":null,"febLiters":null,"change":null}}'
fi
printf '{"schemaVersion":1,"architecture":"rm-6","architectureVersion":"1.0","scenario":"beverage-revenue-v1","generatedAt":"%s","namespace":"%s","executions":[%s],"observation":%s}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$RM6_NAMESPACE" "$executions" "$observation" > "$report_dir/sonuc.json"
encoded="$(base64 < "$report_dir/sonuc.json" | tr -d '\r\n')"
while IFS= read -r line || [[ -n "$line" ]]; do
  printf '%s\n' "${line//__RESULT_BASE64__/$encoded}"
done < "$RM6_DIR/report-template.html" > "$report_dir/rapor.html"
printf 'Rapor: %s/rapor.html\nUygulamaya yukle: %s/sonuc.json\n' "$report_dir" "$report_dir"
if [[ "$models" != passed || "$tests" != passed || "$docs" != passed || "$semantic_model" != passed ]]; then echo "Yerel dbt / semantic manifest dogrulanmadi." >&2; exit 1; fi
if [[ "$failed" -ne 0 ]]; then printf '%s\n' 'Deney tam dogrulanmadi. Raporu ve kanitlari inceleyin.' >&2; exit 1; fi

if [[ "$observation" == *'"not_tested"'* ]]; then echo "Deney kismi: harici dbt / Power BI kontrolleri denenmedi."; [[ "$require_complete" -eq 0 ]] || exit 1; fi
