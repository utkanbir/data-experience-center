#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
command -v kubectl >/dev/null || { echo 'kubectl gerekli.' >&2; exit 1; }
command -v openssl >/dev/null || { echo 'openssl gerekli.' >&2; exit 1; }
k get nodes --request-timeout=10s
if ! k get storageclass -o 'jsonpath={range .items[*]}{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{.metadata.annotations.storageclass\.beta\.kubernetes\.io/is-default-class}{"\n"}{end}' | grep -qx true; then
  echo 'Varsayilan StorageClass gerekli.' >&2; exit 1
fi
k apply -f "$RM6_DIR/k8s/namespace.yaml"
bash "$RM6_DIR/initialize-external-connection.sh"
existing="$(k -n "$RM6_NAMESPACE" get secret rm6-credentials --ignore-not-found=true -o name)"
if [[ -z "$existing" ]]; then
  pvc="$(k -n "$RM6_NAMESPACE" get pvc data-postgres-0 --ignore-not-found=true -o name)"
  if [[ -n "$pvc" ]]; then echo 'PVC var ancak Secret kayip. Mevcut Secret yedegini geri yukleyin.' >&2; exit 1; fi
  umask 077
  secret_dir="$(mktemp -d)"
  trap 'rm -f -- "$secret_dir/admin-password" "$secret_dir/bi-password" "$secret_dir/dbt-password"; rmdir -- "$secret_dir"' EXIT
  printf '%s' "$(openssl rand -hex 24)" > "$secret_dir/admin-password"
  printf '%s' "$(openssl rand -hex 24)" > "$secret_dir/bi-password"
  printf '%s' "$(openssl rand -hex 24)" > "$secret_dir/dbt-password"
  k -n "$RM6_NAMESPACE" create secret generic rm6-credentials --from-file="admin-password=$secret_dir/admin-password" --from-file="bi-password=$secret_dir/bi-password" --from-file="dbt-password=$secret_dir/dbt-password"
fi
k -n "$RM6_NAMESPACE" create configmap rm6-sql --from-file="$RM6_DIR/sql" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM6_DIR/k8s/postgres.yaml"
k -n "$RM6_NAMESPACE" rollout status statefulset/postgres --timeout=330s
k -n "$RM6_NAMESPACE" create configmap rm6-dbt --from-file="project.json=$RM6_DIR/dbt-project.json" --from-file="runner.py=$RM6_DIR/runner.py" --dry-run=client -o yaml | k apply -f -
k apply -f "$RM6_DIR/k8s/dbt-artifacts.yaml"
k -n "$RM6_NAMESPACE" wait --for=condition=Ready pod/rm6-artifacts --timeout=330s
run_job rm6-seed "$RM6_DIR/k8s/seed-job.yaml"
bash "$RM6_DIR/build-models.sh"
run_job rm6-verify "$RM6_DIR/k8s/verify-job.yaml"
k -n "$RM6_NAMESPACE" get pods,svc,pvc,jobs
printf '%s\n' 'Kurulum tamamlandi. Deney: bash run-scenario.sh'

k apply -f "$RM6_DIR/k8s/dbt-docs.yaml"
k -n "$RM6_NAMESPACE" rollout status deployment/dbt-docs --timeout=180s
k -n "$RM6_NAMESPACE" create configmap rm6-managed --from-file="$RM6_DIR/managed" --dry-run=client -o yaml | k apply -f -
bash "$RM6_DIR/run-remote-checks.sh"
bash "$RM6_DIR/show-access.sh"
