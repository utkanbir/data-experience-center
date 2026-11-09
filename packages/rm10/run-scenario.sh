#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
mkdir -p "$RM10_DIR/reports"
report_dir="$(mktemp -d "$RM10_DIR/reports/run-$(date -u +%Y%m%d-%H%M%S)-XXXXXX")"
run_id="${report_dir##*/}"
k -n "$RM10_NAMESPACE" exec rm10-artifacts -- rm -f /artifacts/dbt-status.txt /artifacts/cube-status.txt /artifacts/governance-status.txt /artifacts/manifest.json /artifacts/build_results.json /artifacts/catalog.json /artifacts/static_index.html /artifacts/dbt-checks.json /artifacts/cube-checks.json /artifacts/cube-results.json /artifacts/cube-sql.json /artifacts/python-results.json /artifacts/dashboard-results.json /artifacts/governance-checks.json /artifacts/catalog-lineage-map.json /artifacts/graph-status.txt /artifacts/graph-checks.json /artifacts/graph-results.json
dbt=true; cube=true; catalog=true; graph=true
if bash "$RM10_DIR/build-models.sh"; then dbt=true; fi
if bash "$RM10_DIR/test-cube.sh"; then cube=true; fi
if bash "$RM10_DIR/verify-catalog.sh"; then catalog=true; fi
if bash "$RM10_DIR/verify-graph.sh"; then graph=true; fi
run_file="$(mktemp)"
trap 'rm -f -- "$run_file"' EXIT
printf '{"runId":"%s","stages":{"dbt":%s,"cube":%s,"catalog":%s,"graph":%s}}' "$run_id" "$dbt" "$cube" "$catalog" "$graph" > "$run_file"
k -n "$RM10_NAMESPACE" create configmap rm10-experience --from-file="run.json=$run_file" --from-file="$RM10_DIR/experience/scenario.py" --from-file="$RM10_DIR/graph/ontology.json" --from-file="$RM10_DIR/report-profile.json" --from-file="$RM10_DIR/sql/01-kanal-geliri.sql" --from-file="$RM10_DIR/sql/02-horeca-degisim.sql" --from-file="$RM10_DIR/sql/03-distributor-urun.sql" --from-file="$RM10_DIR/sql/verify.sql" --dry-run=client -o yaml | k apply -f -
run_job rm10-scenario "$RM10_DIR/k8s/scenario-job.yaml"
k -n "$RM10_NAMESPACE" cp "rm10-artifacts:/artifacts/runs/$run_id/." "$report_dir"
encoded="$(base64 < "$report_dir/sonuc.json" | tr -d '\r\n')"
graph_encoded="$(printf '{}' | base64 | tr -d '\r\n')"
if [[ -f "$report_dir/kanitlar/graph-results.json" ]]; then graph_encoded="$(base64 < "$report_dir/kanitlar/graph-results.json" | tr -d '\r\n')"; fi
while IFS= read -r line || [[ -n "$line" ]]; do line="${line//__RESULT_BASE64__/$encoded}"; printf '%s\n' "${line//__GRAPH_RESULTS_BASE64__/$graph_encoded}"; done < "$RM10_DIR/report-template.html" > "$report_dir/rapor.html"
printf 'Rapor: %s/rapor.html\nUygulamaya yukle: %s/sonuc.json\n' "$report_dir" "$report_dir"
if grep -Eq '"status"[[:space:]]*:[[:space:]]*"(failed|not_tested)"' "$report_dir/sonuc.json"; then echo 'Graph deneyi tam dogrulanmadi; raporu inceleyin.' >&2; exit 1; fi
