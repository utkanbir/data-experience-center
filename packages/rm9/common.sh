set -euo pipefail
RM9_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RM9_NAMESPACE='komtas-rm9'
RM9_CONTEXT='docker-desktop'
k() { kubectl --context "$RM9_CONTEXT" "$@"; }
run_job() {
  local name="$1" manifest="$2" deadline=$((SECONDS+1200)) status success failed
  k -n "$RM9_NAMESPACE" delete job "$name" --ignore-not-found=true --wait=true
  k apply -f "$manifest"
  while (( SECONDS < deadline )); do
    status="$(k -n "$RM9_NAMESPACE" get job "$name" -o 'jsonpath={.status.succeeded}{" "}{.status.failed}')"
    success="${status%% *}"; failed="${status#* }"
    if [[ "$success" == 1 ]]; then k -n "$RM9_NAMESPACE" logs "job/$name"; return 0; fi
    if [[ -n "$failed" && "$failed" != 0 ]]; then k -n "$RM9_NAMESPACE" logs "job/$name" --all-containers=true || true; return 1; fi
    sleep 2
  done
  k -n "$RM9_NAMESPACE" describe job "$name" || true
  return 1
}
