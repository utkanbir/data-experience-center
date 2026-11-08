#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
mkdir -p "$RM5_DIR/reports"
report_dir="$(mktemp -d "$RM5_DIR/reports/run-$(date -u +%Y%m%d-%H%M%S)-XXXXXX")"
mkdir "$report_dir/kanitlar"
if ! bash "$RM5_DIR/build-models.sh"; then printf '%s\n' 'dbt build/test failed; report will preserve evidence.'; fi
if ! bash "$RM5_DIR/test-cube.sh"; then echo "Cube checks failed; preserving evidence."; fi
if ! bash "$RM5_DIR/verify-catalog.sh"; then echo "Governance checks failed; preserving evidence."; fi
om_catalog=not_tested; om_owner=not_tested; om_glossary=not_tested; om_lineage=not_tested; om_metric=not_tested; om_quality=not_tested; om_product=not_tested
mapfile -t gov_states < <(k -n "$RM5_NAMESPACE" exec rm5-artifacts -- cat /artifacts/governance-status.txt 2>/dev/null || true)
if [[ "${#gov_states[@]}" -eq 7 ]]; then
  valid=1; for state in "${gov_states[@]}"; do [[ "$state" =~ ^(passed|failed|not_tested)$ ]] || valid=0; done
  if [[ "$valid" -eq 1 ]]; then om_catalog="${gov_states[0]}"; om_owner="${gov_states[1]}"; om_glossary="${gov_states[2]}"; om_lineage="${gov_states[3]}"; om_metric="${gov_states[4]}"; om_quality="${gov_states[5]}"; om_product="${gov_states[6]}"; fi
fi
cube_api=not_tested; cube_sql=not_tested; cube_match=not_tested; two_consumers=not_tested; api_auth=not_tested
mapfile -t cube_states < <(k -n "$RM5_NAMESPACE" exec rm5-artifacts -- cat /artifacts/cube-status.txt 2>/dev/null || true)
if [[ "${#cube_states[@]}" -eq 5 ]]; then
  valid=1; for state in "${cube_states[@]}"; do [[ "$state" =~ ^(passed|failed|not_tested)$ ]] || valid=0; done
  if [[ "$valid" -eq 1 ]]; then cube_api="${cube_states[0]}"; cube_sql="${cube_states[1]}"; cube_match="${cube_states[2]}"; two_consumers="${cube_states[3]}"; api_auth="${cube_states[4]}"; fi
fi
models=not_tested; tests=not_tested; docs=not_tested
status_text="$(k -n "$RM5_NAMESPACE" exec rm5-artifacts -- cat /artifacts/dbt-status.txt 2>/dev/null || true)"
mapfile -t tool_states <<< "$status_text"
if [[ "${#tool_states[@]}" -eq 3 ]]; then
  if [[ "${tool_states[0]}" =~ ^(passed|failed|not_tested)$ && "${tool_states[1]}" =~ ^(passed|failed|not_tested)$ && "${tool_states[2]}" =~ ^(passed|failed|not_tested)$ ]]; then
    models="${tool_states[0]}"; tests="${tool_states[1]}"; docs="${tool_states[2]}"
  fi
fi
for artifact in manifest.json build_results.json catalog.json static_index.html dbt-checks.json cube-checks.json cube-results.json cube-sql.json python-results.json dashboard-results.json governance-checks.json catalog-lineage-map.json; do
  k -n "$RM5_NAMESPACE" cp "rm5-artifacts:/artifacts/$artifact" "$report_dir/kanitlar/$artifact" 2>/dev/null || true
done
report_sql="$(cat "$RM5_DIR/sql/report.sql")"
report_sql="${report_sql//__DBT_MODELS__/$models}"
report_sql="${report_sql//__DBT_TESTS__/$tests}"
report_sql="${report_sql//__DBT_DOCS__/$docs}"
report_sql="${report_sql//__CUBE_API__/$cube_api}"
report_sql="${report_sql//__CUBE_SQL__/$cube_sql}"
report_sql="${report_sql//__CUBE_MATCH__/$cube_match}"
report_sql="${report_sql//__TWO_CONSUMERS__/$two_consumers}"
report_sql="${report_sql//__API_AUTH__/$api_auth}"
report_sql="${report_sql//__OM_CATALOG__/$om_catalog}"
report_sql="${report_sql//__OM_OWNER__/$om_owner}"
report_sql="${report_sql//__OM_GLOSSARY__/$om_glossary}"
report_sql="${report_sql//__OM_LINEAGE__/$om_lineage}"
report_sql="${report_sql//__OM_METRIC__/$om_metric}"
report_sql="${report_sql//__OM_QUALITY__/$om_quality}"
report_sql="${report_sql//__OM_PRODUCT__/$om_product}"
executions='' 
failed=0
for sql in 01-kanal-geliri.sql 02-horeca-degisim.sql 03-distributor-urun.sql verify.sql; do
  printf 'Running: %s\n' "$sql"
  cp "$RM5_DIR/sql/$sql" "$report_dir/kanitlar/$sql"
  if { printf 'SET ROLE rm5_bi;\n'; cat "$RM5_DIR/sql/$sql"; } | k -n "$RM5_NAMESPACE" exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -h 127.0.0.1 -U rm5_admin -d komtas_rm5 -v ON_ERROR_STOP=1' > "$report_dir/kanitlar/$sql.txt" 2>&1; then
    status='passed'
  else
    status='failed'; failed=1
  fi
  cat "$report_dir/kanitlar/$sql.txt"
  executions+="${executions:+,}{\"file\":\"$sql\",\"status\":\"$status\"}"
done
observation='null'
if { printf 'SET ROLE rm5_bi;\n'; printf '%s\n' "$report_sql"; } | k -n "$RM5_NAMESPACE" exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -Atq -h 127.0.0.1 -U rm5_admin -d komtas_rm5 -v ON_ERROR_STOP=1' > "$report_dir/kanitlar/observation.json" 2> "$report_dir/kanitlar/report-error.txt"; then
  observation="$(cat "$report_dir/kanitlar/observation.json")"
  if [[ -z "$observation" ]]; then observation='null'; failed=1; fi
  if [[ "$observation" == *'"failed"'* ]]; then failed=1; fi
else
  failed=1
fi
if [[ "$observation" == null ]]; then
  observation='{"checks":[{"id":"schemas","status":"not_tested"},{"id":"rows","status":"not_tested"},{"id":"months","status":"not_tested"},{"id":"horeca","status":"not_tested"},{"id":"volume","status":"not_tested"},{"id":"price","status":"not_tested"},{"id":"bi_role","status":"not_tested"},{"id":"no_insert","status":"not_tested"},{"id":"dbt_models","status":"'"$models"'"},{"id":"dbt_tests","status":"'"$tests"'"},{"id":"dbt_docs","status":"'"$docs"'"},{"id":"cube_api","status":"'"$cube_api"'"},{"id":"cube_sql","status":"'"$cube_sql"'"},{"id":"cube_match","status":"'"$cube_match"'"},{"id":"two_consumers","status":"'"$two_consumers"'"},{"id":"api_auth","status":"'"$api_auth"'"},{"id":"om_catalog","status":"'"$om_catalog"'"},{"id":"om_owner","status":"'"$om_owner"'"},{"id":"om_glossary","status":"'"$om_glossary"'"},{"id":"om_lineage","status":"'"$om_lineage"'"},{"id":"om_metric","status":"'"$om_metric"'"},{"id":"om_quality","status":"'"$om_quality"'"},{"id":"om_product","status":"'"$om_product"'"}],"metrics":{"janRevenue":null,"febRevenue":null,"janLiters":null,"febLiters":null,"change":null}}'
fi
printf '{"schemaVersion":1,"architecture":"rm-5","architectureVersion":"1.0","scenario":"beverage-revenue-v1","generatedAt":"%s","namespace":"%s","executions":[%s],"observation":%s}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$RM5_NAMESPACE" "$executions" "$observation" > "$report_dir/sonuc.json"
encoded="$(base64 < "$report_dir/sonuc.json" | tr -d '\r\n')"
while IFS= read -r line || [[ -n "$line" ]]; do
  printf '%s\n' "${line//__RESULT_BASE64__/$encoded}"
done < "$RM5_DIR/report-template.html" > "$report_dir/rapor.html"
printf 'Rapor: %s/rapor.html\nUygulamaya yukle: %s/sonuc.json\n' "$report_dir" "$report_dir"
if [[ "$failed" -ne 0 ]]; then printf '%s\n' 'Deney tam dogrulanmadi. Raporu ve kanitlari inceleyin.' >&2; exit 1; fi
