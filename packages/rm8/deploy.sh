#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
command -v kubectl >/dev/null || { echo 'kubectl gerekli.' >&2; exit 1; }
command -v openssl >/dev/null || { echo 'openssl gerekli.' >&2; exit 1; }
k get nodes --request-timeout=10s
if ! k get storageclass -o 'jsonpath={range .items[*]}{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{.metadata.annotations.storageclass\.beta\.kubernetes\.io/is-default-class}{"\n"}{end}' | grep -qx true; then
  echo 'Varsayilan StorageClass gerekli.' >&2; exit 1
fi
k apply -f "$RM8_DIR/k8s/namespace.yaml"
existing="$(k -n "$RM8_NAMESPACE" get secret rm8-credentials --ignore-not-found=true -o name)"
if [[ -z "$existing" ]]; then
  pvc="$(k -n "$RM8_NAMESPACE" get pvc data-postgres-0 --ignore-not-found=true -o name)"
  if [[ -n "$pvc" ]]; then echo 'PVC var ancak Secret kayip. Mevcut Secret yedegini geri yukleyin.' >&2; exit 1; fi
  umask 077
  secret_dir="$(mktemp -d)"
  trap 'rm -f -- "$secret_dir/admin-password" "$secret_dir/bi-password" "$secret_dir/dbt-password"; rmdir -- "$secret_dir"' EXIT
  printf '%s' "$(openssl rand -hex 24)" > "$secret_dir/admin-password"
  printf '%s' "$(openssl rand -hex 24)" > "$secret_dir/bi-password"
  printf '%s' "$(openssl rand -hex 24)" > "$secret_dir/dbt-password"
  k -n "$RM8_NAMESPACE" create secret generic rm8-credentials --from-file="admin-password=$secret_dir/admin-password" --from-file="bi-password=$secret_dir/bi-password" --from-file="dbt-password=$secret_dir/dbt-password"
fi
k -n "$RM8_NAMESPACE" create configmap rm8-sql --from-file="$RM8_DIR/sql" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM8_DIR/k8s/postgres.yaml"
k -n "$RM8_NAMESPACE" rollout status statefulset/postgres --timeout=330s
k -n "$RM8_NAMESPACE" create configmap rm8-dbt --from-file="project.json=$RM8_DIR/dbt-project.json" --from-file="runner.py=$RM8_DIR/runner.py" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM8_DIR/k8s/dbt-artifacts.yaml"
k -n "$RM8_NAMESPACE" wait --for=condition=Ready pod/rm8-artifacts --timeout=330s
run_job rm8-seed "$RM8_DIR/k8s/seed-job.yaml"
bash "$RM8_DIR/build-models.sh"
run_job rm8-verify "$RM8_DIR/k8s/verify-job.yaml"
k -n "$RM8_NAMESPACE" get pods,svc,pvc,jobs
printf '%s\n' 'Kurulum tamamlandi. Deney: bash run-scenario.sh'

k apply -f "$RM8_DIR/k8s/dbt-docs.yaml"
k -n "$RM8_NAMESPACE" rollout status deployment/dbt-docs --timeout=180s

if [[ -z "$(k -n "$RM8_NAMESPACE" get secret rm8-api --ignore-not-found=true -o name)" ]]; then
  umask 077
  api_file="$(mktemp)"
  printf '%s' "$(openssl rand -hex 24)" > "$api_file"
  if ! k -n "$RM8_NAMESPACE" create secret generic rm8-api --from-file="api-secret=$api_file"; then rm -f -- "$api_file"; exit 1; fi
  rm -f -- "$api_file"
fi
k -n "$RM8_NAMESPACE" create configmap rm8-cube-model --from-file="$RM8_DIR/cube/schema" --dry-run=client -o yaml | k apply -f -
k -n "$RM8_NAMESPACE" create configmap rm8-cube-config --from-file="$RM8_DIR/cube/cube.js" --dry-run=client -o yaml | k apply -f -
k -n "$RM8_NAMESPACE" create configmap rm8-consumers --from-file="$RM8_DIR/consumers" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM8_DIR/k8s/cube.yaml"
k -n "$RM8_NAMESPACE" rollout status deployment/cubestore --timeout=600s
k -n "$RM8_NAMESPACE" rollout status deployment/cube --timeout=600s
k apply -f "$RM8_DIR/k8s/dashboard.yaml"
k -n "$RM8_NAMESPACE" rollout status deployment/dashboard --timeout=900s
bash "$RM8_DIR/test-cube.sh"


if [[ -z "$(k -n "$RM8_NAMESPACE" get secret rm8-governance --ignore-not-found=true -o name)" ]]; then
  umask 077
  gov_dir="$(mktemp -d)"
  printf '%s' "$(openssl rand -hex 24)" > "$gov_dir/database-password"
  printf 'Aa1!%s' "$(openssl rand -hex 24)" > "$gov_dir/admin-password"
  if ! k -n "$RM8_NAMESPACE" create secret generic rm8-governance --from-file="database-password=$gov_dir/database-password" --from-file="admin-password=$gov_dir/admin-password"; then rm -f -- "$gov_dir/database-password" "$gov_dir/admin-password"; rmdir -- "$gov_dir"; exit 1; fi
  rm -f -- "$gov_dir/database-password" "$gov_dir/admin-password"; rmdir -- "$gov_dir"
fi
k -n "$RM8_NAMESPACE" create configmap rm8-catalog --from-file="$RM8_DIR/governance" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM8_DIR/k8s/governance-config.yaml"
k apply -f "$RM8_DIR/k8s/governance-dependencies.yaml"
k -n "$RM8_NAMESPACE" rollout status statefulset/metadata-postgres --timeout=600s
k -n "$RM8_NAMESPACE" rollout status statefulset/elasticsearch --timeout=600s
run_job rm8-om-migrate "$RM8_DIR/k8s/governance-migrate.yaml"
k apply -f "$RM8_DIR/k8s/governance-server.yaml"
k -n "$RM8_NAMESPACE" rollout status deployment/openmetadata --timeout=900s
bash "$RM8_DIR/sync-catalog.sh"

bash "$RM8_DIR/run-cdgc.sh"
bash "$RM8_DIR/verify-dual-catalog.sh"
bash "$RM8_DIR/show-access.sh"
