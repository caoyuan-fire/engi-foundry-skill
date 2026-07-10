#!/bin/sh

set -eu

usage() {
  echo "Usage: state.sh status|advance|cancel [--project-root PATH]" >&2
}

action="${1:-}"
if [ "$#" -gt 0 ]; then shift; fi
project_root="."

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-root)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      project_root="$2"
      shift 2
      ;;
    *) usage; exit 2 ;;
  esac
done

case "$action" in
  status|advance|cancel) ;;
  *) usage; exit 2 ;;
esac

if [ ! -d "$project_root" ]; then
  printf '%s\n' '{"status":"error","reason":"invalid-project-root"}'
  exit 2
fi

project_root="$(cd "$project_root" && pwd -P)"
data_root="$project_root/.engifoundry"
state_file="$data_root/initialization.json"

if [ ! -s "$state_file" ]; then
  printf '%s\n' '{"status":"error","reason":"missing-initialization-state"}'
  exit 2
fi

read_string() {
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$state_file" | sed -n '1p'
}

status="$(read_string status)"
current_step="$(read_string currentStep)"

case "$status" in
  in_progress)
    case "$current_step" in
      executor|workflow) ;;
      *)
        printf '%s\n' '{"status":"error","reason":"invalid-initialization-state"}'
        exit 2
        ;;
    esac
    ;;
  complete|cancelled)
    if [ -n "$current_step" ]; then
      printf '%s\n' '{"status":"error","reason":"invalid-initialization-state"}'
      exit 2
    fi
    ;;
  *)
    printf '%s\n' '{"status":"error","reason":"invalid-initialization-state"}'
    exit 2
    ;;
esac

completed_for() {
  case "$1" in
    executor) printf '[]' ;;
    workflow) printf '["executor"]' ;;
    complete|cancelled) printf '["executor","workflow"]' ;;
  esac
}

write_state() {
  new_status="$1"
  new_step="$2"
  completed_key="$3"
  temporary="$data_root/.initialization.json.tmp.$$"
  if [ -n "$new_step" ]; then
    step_json="\"$new_step\""
  else
    step_json="null"
  fi
  cat > "$temporary" <<EOF
{
  "schemaVersion": 1,
  "status": "$new_status",
  "currentStep": $step_json,
  "completedSteps": $(completed_for "$completed_key")
}
EOF
  mv "$temporary" "$state_file"
  cat "$state_file"
}

is_configured() {
  config="$data_root/$1.json"
  [ -s "$config" ] && grep -Eq '"configured"[[:space:]]*:[[:space:]]*true' "$config"
}

final_validation() {
  for name in executors workflows; do
    is_configured "$name" || return 1
  done
  for path in \
    "$project_root/engifoundry.config.json" \
    "$data_root/workspace.md" \
    "$data_root/initialization.json" \
    "$data_root/artifacts/plans" \
    "$data_root/artifacts/records" \
    "$data_root/artifacts/reviews" \
    "$data_root/artifacts/verification" \
    "$data_root/artifacts/delivery" \
    "$data_root/packages"
  do
    [ -e "$path" ] || return 1
  done
  [ -f "$project_root/.gitignore" ] && grep -Fqx '.engifoundry/packages/' "$project_root/.gitignore"
}

if [ "$action" = "status" ]; then
  cat "$state_file"
  exit 0
fi

if [ "$status" != "in_progress" ]; then
  printf '{"status":"invalid","reason":"terminal-state","state":"%s"}\n' "$status"
  exit 1
fi

if [ "$action" = "cancel" ]; then
  write_state cancelled "" "$current_step"
  exit 0
fi

case "$current_step" in
  executor)
    is_configured executors || { printf '%s\n' '{"status":"invalid","reason":"executor-not-configured"}'; exit 1; }
    next_step="workflow"
    ;;
  workflow)
    is_configured workflows || { printf '%s\n' '{"status":"invalid","reason":"workflow-not-configured"}'; exit 1; }
    final_validation || { printf '%s\n' '{"status":"invalid","reason":"final-validation-failed"}'; exit 1; }
    write_state complete "" complete
    exit 0
    ;;
esac

write_state in_progress "$next_step" "$next_step"
