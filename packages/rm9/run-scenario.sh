#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
mkdir -p "$RM9_DIR/reports"
report_dir="$(mktemp -d "$RM9_DIR/reports/run-$(date -u +%Y%m%d-%H%M%S)-XXXXXX")"
run_id="${report_dir##*/}"
k -n "$RM9_NAMESPACE" exec rm9-artifacts -- rm -f /artifacts/dbt-status.txt /artifacts/cube-status.txt /artifacts/governance-status.txt /artifacts/manifest.json /artifacts/build_results.json /artifacts/catalog.json /artifacts/static_index.html /artifacts/dbt-checks.json /artifacts/cube-checks.json /artifacts/cube-results.json /artifacts/cube-sql.json /artifacts/python-results.json /artifacts/dashboard-results.json /artifacts/governance-checks.json /artifacts/catalog-lineage-map.json
dbt=true; cube=true; catalog=true
if bash "$RM9_DIR/build-models.sh"; then dbt=true; fi
if bash "$RM9_DIR/test-cube.sh"; then cube=true; fi
if bash "$RM9_DIR/verify-catalog.sh"; then catalog=true; fi
run_file="$(mktemp)"
trap 'rm -f -- "$run_file"' EXIT
printf '{"runId":"%s","stages":{"dbt":%s,"cube":%s,"catalog":%s}}' "$run_id" "$dbt" "$cube" "$catalog" > "$run_file"
k -n "$RM9_NAMESPACE" create configmap rm9-experience --from-file="run.json=$run_file" --from-file="$RM9_DIR/experience/scenario.py" --from-file="$RM9_DIR/report-profile.json" --from-file="$RM9_DIR/sql/01-kanal-geliri.sql" --from-file="$RM9_DIR/sql/02-horeca-degisim.sql" --from-file="$RM9_DIR/sql/03-distributor-urun.sql" --from-file="$RM9_DIR/sql/verify.sql" --dry-run=client -o yaml | k apply -f -
run_job rm9-scenario "$RM9_DIR/k8s/scenario-job.yaml"
k -n "$RM9_NAMESPACE" cp "rm9-artifacts:/artifacts/runs/$run_id/." "$report_dir"
encoded="$(base64 < "$report_dir/sonuc.json" | tr -d '\r\n')"
while IFS= read -r line || [[ -n "$line" ]]; do printf '%s\n' "${line//__RESULT_BASE64__/$encoded}"; done < "$RM9_DIR/report-template.html" > "$report_dir/rapor.html"
printf 'Rapor: %s/rapor.html\nUygulamaya yukle: %s/sonuc.json\n' "$report_dir" "$report_dir"
if grep -Eq '"status"[[:space:]]*:[[:space:]]*"(failed|not_tested)"' "$report_dir/sonuc.json"; then echo 'Federasyon deneyi tam dogrulanmadi; raporu inceleyin.' >&2; exit 1; fi
