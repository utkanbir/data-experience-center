#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
command -v kubectl >/dev/null || { echo 'kubectl gerekli.' >&2; exit 1; }
command -v openssl >/dev/null || { echo 'openssl gerekli.' >&2; exit 1; }
k get nodes --request-timeout=10s
if ! k get storageclass -o 'jsonpath={range .items[*]}{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{.metadata.annotations.storageclass\.beta\.kubernetes\.io/is-default-class}{"\n"}{end}' | grep -qx true; then
  echo 'Varsayilan StorageClass gerekli.' >&2; exit 1
fi
k apply -f "$RM7_DIR/k8s/namespace.yaml"
existing="$(k -n "$RM7_NAMESPACE" get secret rm7-credentials --ignore-not-found=true -o name)"
if [[ -z "$existing" ]]; then
  pvc="$(k -n "$RM7_NAMESPACE" get pvc data-postgres-0 --ignore-not-found=true -o name)"
  if [[ -n "$pvc" ]]; then echo 'PVC var ancak Secret kayip. Mevcut Secret yedegini geri yukleyin.' >&2; exit 1; fi
  umask 077
  secret_dir="$(mktemp -d)"
  trap 'rm -f -- "$secret_dir/admin-password" "$secret_dir/bi-password" "$secret_dir/dbt-password"; rmdir -- "$secret_dir"' EXIT
  printf '%s' "$(openssl rand -hex 24)" > "$secret_dir/admin-password"
  printf '%s' "$(openssl rand -hex 24)" > "$secret_dir/bi-password"
  printf '%s' "$(openssl rand -hex 24)" > "$secret_dir/dbt-password"
  k -n "$RM7_NAMESPACE" create secret generic rm7-credentials --from-file="admin-password=$secret_dir/admin-password" --from-file="bi-password=$secret_dir/bi-password" --from-file="dbt-password=$secret_dir/dbt-password"
fi
k -n "$RM7_NAMESPACE" create configmap rm7-sql --from-file="$RM7_DIR/sql" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM7_DIR/k8s/postgres.yaml"
k -n "$RM7_NAMESPACE" rollout status statefulset/postgres --timeout=330s
k -n "$RM7_NAMESPACE" create configmap rm7-dbt --from-file="project.json=$RM7_DIR/dbt-project.json" --from-file="runner.py=$RM7_DIR/runner.py" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM7_DIR/k8s/dbt-artifacts.yaml"
k -n "$RM7_NAMESPACE" wait --for=condition=Ready pod/rm7-artifacts --timeout=330s
run_job rm7-seed "$RM7_DIR/k8s/seed-job.yaml"
bash "$RM7_DIR/build-models.sh"
run_job rm7-verify "$RM7_DIR/k8s/verify-job.yaml"
k -n "$RM7_NAMESPACE" get pods,svc,pvc,jobs
printf '%s\n' 'Kurulum tamamlandi. Deney: bash run-scenario.sh'

k apply -f "$RM7_DIR/k8s/dbt-docs.yaml"
k -n "$RM7_NAMESPACE" rollout status deployment/dbt-docs --timeout=180s

if [[ -z "$(k -n "$RM7_NAMESPACE" get secret rm7-api --ignore-not-found=true -o name)" ]]; then
  umask 077
  api_file="$(mktemp)"
  printf '%s' "$(openssl rand -hex 24)" > "$api_file"
  if ! k -n "$RM7_NAMESPACE" create secret generic rm7-api --from-file="api-secret=$api_file"; then rm -f -- "$api_file"; exit 1; fi
  rm -f -- "$api_file"
fi
k -n "$RM7_NAMESPACE" create configmap rm7-cube-model --from-file="$RM7_DIR/cube/schema" --dry-run=client -o yaml | k apply -f -
k -n "$RM7_NAMESPACE" create configmap rm7-cube-config --from-file="$RM7_DIR/cube/cube.js" --dry-run=client -o yaml | k apply -f -
k -n "$RM7_NAMESPACE" create configmap rm7-consumers --from-file="$RM7_DIR/consumers" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM7_DIR/k8s/cube.yaml"
k -n "$RM7_NAMESPACE" rollout status deployment/cubestore --timeout=600s
k -n "$RM7_NAMESPACE" rollout status deployment/cube --timeout=600s
k apply -f "$RM7_DIR/k8s/dashboard.yaml"
k -n "$RM7_NAMESPACE" rollout status deployment/dashboard --timeout=900s
bash "$RM7_DIR/test-cube.sh"

bash "$RM7_DIR/run-governance.sh"
bash "$RM7_DIR/show-access.sh"
