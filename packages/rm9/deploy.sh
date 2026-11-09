#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
command -v kubectl >/dev/null || { echo 'kubectl gerekli.' >&2; exit 1; }
command -v openssl >/dev/null || { echo 'openssl gerekli.' >&2; exit 1; }
k get nodes --request-timeout=10s
if ! k get storageclass -o 'jsonpath={range .items[*]}{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{.metadata.annotations.storageclass\.beta\.kubernetes\.io/is-default-class}{"\n"}{end}' | grep -qx true; then
  echo 'Varsayilan StorageClass gerekli.' >&2; exit 1
fi
k apply -f "$RM9_DIR/k8s/namespace.yaml"
existing="$(k -n "$RM9_NAMESPACE" get secret rm9-credentials --ignore-not-found=true -o name)"
if [[ -z "$existing" ]]; then
  pvc="$(k -n "$RM9_NAMESPACE" get pvc data-postgres-0 --ignore-not-found=true -o name)"
  if [[ -n "$pvc" ]]; then echo 'PVC var ancak Secret kayip. Mevcut Secret yedegini geri yukleyin.' >&2; exit 1; fi
  umask 077
  secret_dir="$(mktemp -d)"
  trap 'rm -f -- "$secret_dir/admin-password" "$secret_dir/bi-password" "$secret_dir/dbt-password"; rmdir -- "$secret_dir"' EXIT
  printf '%s' "$(openssl rand -hex 24)" > "$secret_dir/admin-password"
  printf '%s' "$(openssl rand -hex 24)" > "$secret_dir/bi-password"
  printf '%s' "$(openssl rand -hex 24)" > "$secret_dir/dbt-password"
  k -n "$RM9_NAMESPACE" create secret generic rm9-credentials --from-file="admin-password=$secret_dir/admin-password" --from-file="bi-password=$secret_dir/bi-password" --from-file="dbt-password=$secret_dir/dbt-password"
fi
k -n "$RM9_NAMESPACE" create configmap rm9-sql --from-file="$RM9_DIR/sql" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM9_DIR/k8s/postgres.yaml"
k -n "$RM9_NAMESPACE" rollout status statefulset/postgres --timeout=330s
k apply -f "$RM9_DIR/k8s/postgres-reference.yaml"
k -n "$RM9_NAMESPACE" rollout status statefulset/postgres-reference --timeout=330s
k -n "$RM9_NAMESPACE" create configmap rm9-dbt --from-file="project.json=$RM9_DIR/dbt-project.json" --from-file="runner.py=$RM9_DIR/runner.py" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM9_DIR/k8s/dbt-artifacts.yaml"
k -n "$RM9_NAMESPACE" wait --for=condition=Ready pod/rm9-artifacts --timeout=330s
run_job rm9-seed "$RM9_DIR/k8s/seed-job.yaml"
run_job rm9-seed-reference "$RM9_DIR/k8s/seed-reference-job.yaml"
k -n "$RM9_NAMESPACE" create configmap rm9-trino --from-file="$RM9_DIR/trino/properties" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM9_DIR/k8s/trino.yaml"
k -n "$RM9_NAMESPACE" rollout status deployment/trino --timeout=600s
bash "$RM9_DIR/build-models.sh"

k -n "$RM9_NAMESPACE" get pods,svc,pvc,jobs
printf '%s\n' 'Kurulum tamamlandi. Deney: bash run-scenario.sh'

k apply -f "$RM9_DIR/k8s/dbt-docs.yaml"
k -n "$RM9_NAMESPACE" rollout status deployment/dbt-docs --timeout=180s

if [[ -z "$(k -n "$RM9_NAMESPACE" get secret rm9-api --ignore-not-found=true -o name)" ]]; then
  umask 077
  api_file="$(mktemp)"
  printf '%s' "$(openssl rand -hex 24)" > "$api_file"
  if ! k -n "$RM9_NAMESPACE" create secret generic rm9-api --from-file="api-secret=$api_file"; then rm -f -- "$api_file"; exit 1; fi
  rm -f -- "$api_file"
fi
k -n "$RM9_NAMESPACE" create configmap rm9-cube-model --from-file="$RM9_DIR/cube/schema" --dry-run=client -o yaml | k apply -f -
k -n "$RM9_NAMESPACE" create configmap rm9-cube-config --from-file="$RM9_DIR/cube/cube.js" --dry-run=client -o yaml | k apply -f -
k -n "$RM9_NAMESPACE" create configmap rm9-consumers --from-file="$RM9_DIR/consumers" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM9_DIR/k8s/cube.yaml"
k -n "$RM9_NAMESPACE" rollout status deployment/cubestore --timeout=600s
k -n "$RM9_NAMESPACE" rollout status deployment/cube --timeout=600s
k apply -f "$RM9_DIR/k8s/dashboard.yaml"
k -n "$RM9_NAMESPACE" rollout status deployment/dashboard --timeout=900s
bash "$RM9_DIR/test-cube.sh"


if [[ -z "$(k -n "$RM9_NAMESPACE" get secret rm9-governance --ignore-not-found=true -o name)" ]]; then
  umask 077
  gov_dir="$(mktemp -d)"
  printf '%s' "$(openssl rand -hex 24)" > "$gov_dir/database-password"
  printf 'Aa1!%s' "$(openssl rand -hex 24)" > "$gov_dir/admin-password"
  if ! k -n "$RM9_NAMESPACE" create secret generic rm9-governance --from-file="database-password=$gov_dir/database-password" --from-file="admin-password=$gov_dir/admin-password"; then rm -f -- "$gov_dir/database-password" "$gov_dir/admin-password"; rmdir -- "$gov_dir"; exit 1; fi
  rm -f -- "$gov_dir/database-password" "$gov_dir/admin-password"; rmdir -- "$gov_dir"
fi
k -n "$RM9_NAMESPACE" create configmap rm9-catalog --from-file="$RM9_DIR/governance" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM9_DIR/k8s/governance-config.yaml"
k apply -f "$RM9_DIR/k8s/governance-dependencies.yaml"
k -n "$RM9_NAMESPACE" rollout status statefulset/metadata-postgres --timeout=600s
k -n "$RM9_NAMESPACE" rollout status statefulset/elasticsearch --timeout=600s
run_job rm9-om-migrate "$RM9_DIR/k8s/governance-migrate.yaml"
k apply -f "$RM9_DIR/k8s/governance-server.yaml"
k -n "$RM9_NAMESPACE" rollout status deployment/openmetadata --timeout=900s
bash "$RM9_DIR/sync-catalog.sh"

bash "$RM9_DIR/show-access.sh"
