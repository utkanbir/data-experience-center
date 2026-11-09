#!/usr/bin/env bash
set -euo pipefail
task_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
task_namespace='komtas-rm3'
task_context='docker-desktop'
task_service="${1:-all}"
mkdir -p "$task_dir/.connections"
command -v flock >/dev/null || { echo 'flock gerekli (util-linux).' >&2; exit 1; }
exec 9>"$task_dir/.connections/session.lock"
flock -n 9 || { echo 'Bu paket icin Connect zaten acik; ayni terminali kullanin.' >&2; exit 1; }
task_pids=()
task_status="$task_dir/.connections/runtime.tsv"
: > "$task_status"
cleanup(){
 trap - EXIT INT TERM
 for task_pid in "${task_pids[@]}"; do if jobs -pr | grep -qx "$task_pid"; then kill "$task_pid" 2>/dev/null || true; fi; done
 for task_pid in "${task_pids[@]}"; do wait "$task_pid" 2>/dev/null || true; done
 if [[ -f "$task_status" ]]; then sed 's/|ready$/|closed/' "$task_status" > "$task_status.tmp"; mv "$task_status.tmp" "$task_status"; fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM
task_count=0
while IFS='|' read -r task_id task_name task_remote task_base task_target task_kind task_path task_db task_user; do
 [[ "$task_service" == all || "$task_service" == "$task_id" ]] || continue
 task_count=$((task_count+1))
 task_port="$task_base"
 task_log="$task_dir/.connections/$task_id-$$.log"
 task_ready=false
 for task_attempt in $(seq 0 30); do
  task_port=$((task_base+task_attempt)); (( task_port <= 65535 )) || break
  kubectl --context "$task_context" -n "$task_namespace" port-forward --address=127.0.0.1 "service/$task_remote" "$task_port:$task_target" > "$task_log" 2>&1 &
  task_pid=$!;task_pids+=("$task_pid")
  for task_tick in $(seq 1 150); do
   if grep -q 'Forwarding from 127.0.0.1:' "$task_log"; then task_ready=true; break; fi
   kill -0 "$task_pid" 2>/dev/null || break
   sleep .2
  done
  if [[ "$task_ready" == true ]]; then break; fi
  if jobs -pr | grep -qx "$task_pid"; then kill "$task_pid" 2>/dev/null || true; fi
  wait "$task_pid" 2>/dev/null || true
  unset 'task_pids[${#task_pids[@]}-1]'
  task_pids=("${task_pids[@]}")
  grep -Eq 'address already in use|Only one usage|Unable to listen on port' "$task_log" || { cat "$task_log" >&2; exit 1; }
 done
 [[ "$task_ready" == true ]] || { echo "Baglanamadi: $task_name" >&2; exit 1; }
 printf '%s|%s|ready\n' "$task_id" "$task_port" >> "$task_status"
done < "$task_dir/connections.tsv"
(( task_count > 0 )) || { echo 'Bilinmeyen servis.' >&2; exit 1; }
bash "$task_dir/get-connections.sh" --no-secrets
echo 'Tum yerel servisler baglandi. Bu tek terminal acik kalsin. Giris bilgileri: bash get-connections.sh'
echo 'Durdurmak icin Ctrl+C; yalniz bu komutun actigi tuneller kapanir.'
while true; do
 for task_pid in "${task_pids[@]}"; do kill -0 "$task_pid" 2>/dev/null || { echo 'Bir tunel kapandi; Connect komutunu yeniden calistirin.' >&2; exit 1; }; done
 sleep 1
done
