#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
require_complete=0
if [[ "${1:-}" == --require-complete ]]; then require_complete=1; elif [[ $# -gt 0 ]]; then echo 'Bilinmeyen parametre' >&2; exit 1; fi
build_ok=1; cube_ok=1; governance_ok=1
mkdir -p "$RM8_DIR/reports"
report_dir="$(mktemp -d "$RM8_DIR/reports/run-$(date -u +%Y%m%d-%H%M%S)-XXXXXX")"
mkdir "$report_dir/kanitlar"
if ! bash "$RM8_DIR/build-models.sh"; then build_ok=0; printf '%s\n' 'dbt build/test failed; report will preserve evidence.'; fi
if ! bash "$RM8_DIR/test-cube.sh"; then cube_ok=0; echo "Cube checks failed; preserving evidence."; fi
if ! bash "$RM8_DIR/run-cdgc.sh"; then governance_ok=0; echo "CDGC check job failed; preserving evidence."; fi
cdgc_assets=not_tested; cdgc_definition=not_tested; cdgc_owner=not_tested; cdgc_published=not_tested; cdgc_binding=not_tested; cdgc_product=not_tested; cdgc_approval=not_tested
mapfile -t governance_states < <(k -n "$RM8_NAMESPACE" exec rm8-artifacts -- cat /artifacts/cdgc-status.txt 2>/dev/null || true)
if [[ "$governance_ok" -eq 1 && "${#governance_states[@]}" -eq 7 ]]; then
 valid=1; for state in "${governance_states[@]}"; do [[ "$state" =~ ^(passed|failed|not_tested)$ ]] || valid=0; done
 if [[ "$valid" -eq 1 ]]; then cdgc_assets="${governance_states[0]}"; cdgc_definition="${governance_states[1]}"; cdgc_owner="${governance_states[2]}"; cdgc_published="${governance_states[3]}"; cdgc_binding="${governance_states[4]}"; cdgc_product="${governance_states[5]}"; cdgc_approval="${governance_states[6]}"; fi
fi
catalog_ok=1
if ! bash "$RM8_DIR/verify-catalog.sh"; then catalog_ok=0; fi
om_catalog=not_tested; om_owner=not_tested; om_glossary=not_tested; om_lineage=not_tested; om_metric=not_tested; om_quality=not_tested; om_product=not_tested
mapfile -t catalog_states < <(k -n "$RM8_NAMESPACE" exec rm8-artifacts -- cat /artifacts/governance-status.txt 2>/dev/null || true)
if [[ "$catalog_ok" -eq 1 && "${#catalog_states[@]}" -eq 7 ]]; then
 valid=1; for state in "${catalog_states[@]}"; do [[ "$state" =~ ^(passed|failed|not_tested)$ ]] || valid=0; done
 if [[ "$valid" -eq 1 ]]; then om_catalog="${catalog_states[0]}"; om_owner="${catalog_states[1]}"; om_glossary="${catalog_states[2]}"; om_lineage="${catalog_states[3]}"; om_metric="${catalog_states[4]}"; om_quality="${catalog_states[5]}"; om_product="${catalog_states[6]}"; fi
fi
dual_ok=1
if ! bash "$RM8_DIR/verify-dual-catalog.sh"; then dual_ok=0; fi
dual_identity=not_tested; dual_definition=not_tested; dual_owner=not_tested; dual_revision=not_tested
mapfile -t dual_states < <(k -n "$RM8_NAMESPACE" exec rm8-artifacts -- cat /artifacts/dual-status.txt 2>/dev/null || true)
if [[ "$dual_ok" -eq 1 && "${#dual_states[@]}" -eq 4 ]]; then
 valid=1; for state in "${dual_states[@]}"; do [[ "$state" =~ ^(passed|failed|not_tested)$ ]] || valid=0; done
 if [[ "$valid" -eq 1 ]]; then dual_identity="${dual_states[0]}"; dual_definition="${dual_states[1]}"; dual_owner="${dual_states[2]}"; dual_revision="${dual_states[3]}"; fi
fi
cube_api=not_tested; cube_sql=not_tested; cube_match=not_tested; two_consumers=not_tested; api_auth=not_tested
mapfile -t cube_states < <(k -n "$RM8_NAMESPACE" exec rm8-artifacts -- cat /artifacts/cube-status.txt 2>/dev/null || true)
if [[ "$cube_ok" -eq 1 && "${#cube_states[@]}" -eq 5 ]]; then
  valid=1; for state in "${cube_states[@]}"; do [[ "$state" =~ ^(passed|failed|not_tested)$ ]] || valid=0; done
  if [[ "$valid" -eq 1 ]]; then cube_api="${cube_states[0]}"; cube_sql="${cube_states[1]}"; cube_match="${cube_states[2]}"; two_consumers="${cube_states[3]}"; api_auth="${cube_states[4]}"; fi
fi
models=not_tested; tests=not_tested; docs=not_tested
status_text="$(k -n "$RM8_NAMESPACE" exec rm8-artifacts -- cat /artifacts/dbt-status.txt 2>/dev/null || true)"
mapfile -t tool_states <<< "$status_text"
if [[ "$build_ok" -eq 1 && "${#tool_states[@]}" -eq 3 ]]; then
  if [[ "${tool_states[0]}" =~ ^(passed|failed|not_tested)$ && "${tool_states[1]}" =~ ^(passed|failed|not_tested)$ && "${tool_states[2]}" =~ ^(passed|failed|not_tested)$ ]]; then
    models="${tool_states[0]}"; tests="${tool_states[1]}"; docs="${tool_states[2]}"
  fi
fi
for artifact in manifest.json build_results.json catalog.json static_index.html dbt-checks.json cube-checks.json cube-results.json cube-sql.json python-results.json dashboard-results.json cdgc-checks.json cdgc-approval-template.json governance-checks.json catalog-lineage-map.json dual-checks.json business-sync.json; do
  k -n "$RM8_NAMESPACE" cp "rm8-artifacts:/artifacts/$artifact" "$report_dir/kanitlar/$artifact" 2>/dev/null || true
done
report_sql="$(cat "$RM8_DIR/sql/report.sql")"
report_sql="${report_sql//__DBT_MODELS__/$models}"
report_sql="${report_sql//__DBT_TESTS__/$tests}"
report_sql="${report_sql//__DBT_DOCS__/$docs}"
report_sql="${report_sql//__CUBE_API__/$cube_api}"
report_sql="${report_sql//__CUBE_SQL__/$cube_sql}"
report_sql="${report_sql//__CUBE_MATCH__/$cube_match}"
report_sql="${report_sql//__TWO_CONSUMERS__/$two_consumers}"
report_sql="${report_sql//__API_AUTH__/$api_auth}"
report_sql="${report_sql//__CDGC_ASSETS__/$cdgc_assets}"
report_sql="${report_sql//__CDGC_DEFINITION__/$cdgc_definition}"
report_sql="${report_sql//__CDGC_OWNER__/$cdgc_owner}"
report_sql="${report_sql//__CDGC_PUBLISHED__/$cdgc_published}"
report_sql="${report_sql//__CDGC_BINDING__/$cdgc_binding}"
report_sql="${report_sql//__CDGC_PRODUCT__/$cdgc_product}"
report_sql="${report_sql//__CDGC_APPROVAL__/$cdgc_approval}"
report_sql="${report_sql//__OM_CATALOG__/$om_catalog}"
report_sql="${report_sql//__OM_OWNER__/$om_owner}"
report_sql="${report_sql//__OM_GLOSSARY__/$om_glossary}"
report_sql="${report_sql//__OM_LINEAGE__/$om_lineage}"
report_sql="${report_sql//__OM_METRIC__/$om_metric}"
report_sql="${report_sql//__OM_QUALITY__/$om_quality}"
report_sql="${report_sql//__OM_PRODUCT__/$om_product}"
report_sql="${report_sql//__DUAL_IDENTITY__/$dual_identity}"
report_sql="${report_sql//__DUAL_DEFINITION__/$dual_definition}"
report_sql="${report_sql//__DUAL_OWNER__/$dual_owner}"
report_sql="${report_sql//__DUAL_REVISION__/$dual_revision}"
executions=''
failed=0
for sql in 01-kanal-geliri.sql 02-horeca-degisim.sql 03-distributor-urun.sql verify.sql; do
  printf 'Running: %s\n' "$sql"
  cp "$RM8_DIR/sql/$sql" "$report_dir/kanitlar/$sql"
  if { printf 'SET ROLE rm8_bi;\n'; cat "$RM8_DIR/sql/$sql"; } | k -n "$RM8_NAMESPACE" exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -h 127.0.0.1 -U rm8_admin -d komtas_rm8 -v ON_ERROR_STOP=1' > "$report_dir/kanitlar/$sql.txt" 2>&1; then
    status='passed'
  else
    status='failed'; failed=1
  fi
  cat "$report_dir/kanitlar/$sql.txt"
  executions+="${executions:+,}{\"file\":\"$sql\",\"status\":\"$status\"}"
done
observation='null'
if { printf 'SET ROLE rm8_bi;\n'; printf '%s\n' "$report_sql"; } | k -n "$RM8_NAMESPACE" exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -Atq -h 127.0.0.1 -U rm8_admin -d komtas_rm8 -v ON_ERROR_STOP=1' > "$report_dir/kanitlar/observation.json" 2> "$report_dir/kanitlar/report-error.txt"; then
  observation="$(cat "$report_dir/kanitlar/observation.json")"
  if [[ -z "$observation" ]]; then observation='null'; failed=1; fi
  if [[ "$observation" == *'"failed"'* ]]; then failed=1; fi
else
  failed=1
fi
if [[ "$observation" == null ]]; then
  observation='{"checks":[{"id":"schemas","status":"not_tested"},{"id":"rows","status":"not_tested"},{"id":"months","status":"not_tested"},{"id":"horeca","status":"not_tested"},{"id":"volume","status":"not_tested"},{"id":"price","status":"not_tested"},{"id":"bi_role","status":"not_tested"},{"id":"no_insert","status":"not_tested"},{"id":"dbt_models","status":"'"$models"'"},{"id":"dbt_tests","status":"'"$tests"'"},{"id":"dbt_docs","status":"'"$docs"'"},{"id":"cube_api","status":"'"$cube_api"'"},{"id":"cube_sql","status":"'"$cube_sql"'"},{"id":"cube_match","status":"'"$cube_match"'"},{"id":"two_consumers","status":"'"$two_consumers"'"},{"id":"api_auth","status":"'"$api_auth"'"},{"id":"cdgc_assets","status":"'"$cdgc_assets"'"},{"id":"cdgc_definition","status":"'"$cdgc_definition"'"},{"id":"cdgc_owner","status":"'"$cdgc_owner"'"},{"id":"cdgc_published","status":"'"$cdgc_published"'"},{"id":"cdgc_binding","status":"'"$cdgc_binding"'"},{"id":"cdgc_product","status":"'"$cdgc_product"'"},{"id":"cdgc_approval","status":"'"$cdgc_approval"'"},{"id":"om_catalog","status":"'"$om_catalog"'"},{"id":"om_owner","status":"'"$om_owner"'"},{"id":"om_glossary","status":"'"$om_glossary"'"},{"id":"om_lineage","status":"'"$om_lineage"'"},{"id":"om_metric","status":"'"$om_metric"'"},{"id":"om_quality","status":"'"$om_quality"'"},{"id":"om_product","status":"'"$om_product"'"},{"id":"dual_identity","status":"'"$dual_identity"'"},{"id":"dual_definition","status":"'"$dual_definition"'"},{"id":"dual_owner","status":"'"$dual_owner"'"},{"id":"dual_revision","status":"'"$dual_revision"'"}],"metrics":{"janRevenue":null,"febRevenue":null,"janLiters":null,"febLiters":null,"change":null}}'
fi
printf '{"schemaVersion":1,"architecture":"rm-8","architectureVersion":"1.0","scenario":"beverage-revenue-v1","generatedAt":"%s","namespace":"%s","executions":[%s],"observation":%s}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$RM8_NAMESPACE" "$executions" "$observation" > "$report_dir/sonuc.json"
encoded="$(base64 < "$report_dir/sonuc.json" | tr -d '\r\n')"
while IFS= read -r line || [[ -n "$line" ]]; do
  printf '%s\n' "${line//__RESULT_BASE64__/$encoded}"
done < "$RM8_DIR/report-template.html" > "$report_dir/rapor.html"
printf 'Rapor: %s/rapor.html\nUygulamaya yukle: %s/sonuc.json\n' "$report_dir" "$report_dir"
if [[ "$catalog_ok" -ne 1 || "$dual_ok" -ne 1 || "$build_ok" -ne 1 || "$cube_ok" -ne 1 || "$governance_ok" -ne 1 || "$models" != passed || "$tests" != passed || "$docs" != passed || "$cube_api" != passed || "$cube_sql" != passed || "$cube_match" != passed || "$two_consumers" != passed || "$api_auth" != passed ]]; then echo "Guncel yerel/governance denemesi tamamlanmadi." >&2; exit 1; fi
if [[ "$failed" -ne 0 ]]; then printf '%s\n' 'Deney tam dogrulanmadi. Raporu ve kanitlari inceleyin.' >&2; exit 1; fi

if [[ "$observation" == *'"not_tested"'* ]]; then echo "Kismi deney: harici CDGC kanitlari eksik."; [[ "$require_complete" -eq 0 ]] || exit 1; fi
