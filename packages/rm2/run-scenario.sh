#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
mkdir -p "$RM2_DIR/reports"
report_dir="$(mktemp -d "$RM2_DIR/reports/run-$(date -u +%Y%m%d-%H%M%S)-XXXXXX")"
mkdir "$report_dir/kanitlar"
if ! bash "$RM2_DIR/build-models.sh"; then printf '%s\n' 'dbt build/test failed; report will preserve evidence.'; fi
models=not_tested; tests=not_tested; docs=not_tested
status_text="$(k -n "$RM2_NAMESPACE" exec rm2-artifacts -- cat /artifacts/dbt-status.txt 2>/dev/null || true)"
mapfile -t tool_states <<< "$status_text"
if [[ "${#tool_states[@]}" -eq 3 ]]; then
  if [[ "${tool_states[0]}" =~ ^(passed|failed|not_tested)$ && "${tool_states[1]}" =~ ^(passed|failed|not_tested)$ && "${tool_states[2]}" =~ ^(passed|failed|not_tested)$ ]]; then
    models="${tool_states[0]}"; tests="${tool_states[1]}"; docs="${tool_states[2]}"
  fi
fi
for artifact in manifest.json build_results.json catalog.json static_index.html dbt-checks.json; do
  k -n "$RM2_NAMESPACE" cp "rm2-artifacts:/artifacts/$artifact" "$report_dir/kanitlar/$artifact" 2>/dev/null || true
done
report_sql="$(cat "$RM2_DIR/sql/report.sql")"
report_sql="${report_sql//__DBT_MODELS__/$models}"
report_sql="${report_sql//__DBT_TESTS__/$tests}"
report_sql="${report_sql//__DBT_DOCS__/$docs}"
executions='' 
failed=0
for sql in 01-kanal-geliri.sql 02-horeca-degisim.sql 03-distributor-urun.sql verify.sql; do
  printf 'Running: %s\n' "$sql"
  cp "$RM2_DIR/sql/$sql" "$report_dir/kanitlar/$sql"
  if { printf 'SET ROLE rm2_bi;\n'; cat "$RM2_DIR/sql/$sql"; } | k -n "$RM2_NAMESPACE" exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -h 127.0.0.1 -U rm2_admin -d komtas_rm2 -v ON_ERROR_STOP=1' > "$report_dir/kanitlar/$sql.txt" 2>&1; then
    status='passed'
  else
    status='failed'; failed=1
  fi
  cat "$report_dir/kanitlar/$sql.txt"
  executions+="${executions:+,}{\"file\":\"$sql\",\"status\":\"$status\"}"
done
observation='null'
if { printf 'SET ROLE rm2_bi;\n'; printf '%s\n' "$report_sql"; } | k -n "$RM2_NAMESPACE" exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -Atq -h 127.0.0.1 -U rm2_admin -d komtas_rm2 -v ON_ERROR_STOP=1' > "$report_dir/kanitlar/observation.json" 2> "$report_dir/kanitlar/report-error.txt"; then
  observation="$(cat "$report_dir/kanitlar/observation.json")"
  if [[ -z "$observation" ]]; then observation='null'; failed=1; fi
  if [[ "$observation" == *'"failed"'* ]]; then failed=1; fi
else
  failed=1
fi
if [[ "$observation" == null ]]; then
  observation='{"checks":[{"id":"schemas","status":"not_tested"},{"id":"rows","status":"not_tested"},{"id":"months","status":"not_tested"},{"id":"horeca","status":"not_tested"},{"id":"volume","status":"not_tested"},{"id":"price","status":"not_tested"},{"id":"bi_role","status":"not_tested"},{"id":"no_insert","status":"not_tested"},{"id":"dbt_models","status":"'"$models"'"},{"id":"dbt_tests","status":"'"$tests"'"},{"id":"dbt_docs","status":"'"$docs"'"}],"metrics":{"janRevenue":null,"febRevenue":null,"janLiters":null,"febLiters":null,"change":null}}'
fi
printf '{"schemaVersion":1,"architecture":"rm-2","architectureVersion":"1.0","scenario":"beverage-revenue-v1","generatedAt":"%s","namespace":"%s","executions":[%s],"observation":%s}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$RM2_NAMESPACE" "$executions" "$observation" > "$report_dir/sonuc.json"
encoded="$(base64 < "$report_dir/sonuc.json" | tr -d '\r\n')"
while IFS= read -r line || [[ -n "$line" ]]; do
  printf '%s\n' "${line//__RESULT_BASE64__/$encoded}"
done < "$RM2_DIR/report-template.html" > "$report_dir/rapor.html"
printf 'Rapor: %s/rapor.html\nUygulamaya yukle: %s/sonuc.json\n' "$report_dir" "$report_dir"
if [[ "$failed" -ne 0 ]]; then printf '%s\n' 'Deney tam dogrulanmadi. Raporu ve kanitlari inceleyin.' >&2; exit 1; fi
