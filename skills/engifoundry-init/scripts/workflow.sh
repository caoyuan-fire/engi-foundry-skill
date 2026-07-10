#!/bin/sh

set -eu

usage() {
  echo "Usage: workflow.sh begin|status|select|commit|cancel [--project-root PATH] [--user-input TEXT]" >&2
}

action="${1:-}"
if [ "$#" -gt 0 ]; then shift; fi
project_root="."
user_input=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-root)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      project_root="$2"
      shift 2
      ;;
    --user-input)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      user_input="$2"
      shift 2
      ;;
    *) usage; exit 2 ;;
  esac
done

case "$action" in
  begin|status|select|commit|cancel) ;;
  *) usage; exit 2 ;;
esac

if [ ! -d "$project_root" ]; then
  printf '%s\n' '{"status":"error","reason":"invalid-project-root"}'
  exit 2
fi

project_root="$(cd "$project_root" && pwd -P)"
data_root="$project_root/.engifoundry"
config_file="$data_root/workflows.json"
setup_root="$data_root/.workflow-setup"
phase_file="$setup_root/phase"
mode_file="$setup_root/automation-mode"
preference_file="$setup_root/action-preference"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
verifier="$script_dir/verify.sh"

if [ ! -d "$data_root" ] || [ ! -s "$config_file" ]; then
  printf '%s\n' '{"status":"error","reason":"missing-workflow-config"}'
  exit 2
fi

automation_options='[{"optionId":1,"automationMode":"job-approval"},{"optionId":2,"automationMode":"package-approval","recommended":true},{"optionId":3,"automationMode":"full-auto"}]'
action_options='[{"optionId":1,"actionPreference":"package-first"},{"optionId":2,"actionPreference":"balanced","recommended":true},{"optionId":3,"actionPreference":"direct-first"}]'

emit_state() {
  if [ ! -s "$phase_file" ]; then
    printf '%s\n' '{"status":"idle"}'
    return
  fi
  phase="$(sed -n '1p' "$phase_file")"
  case "$phase" in
    automation)
      printf '{"status":"in_progress","phase":"automation","selection":"single","options":%s}\n' "$automation_options"
      ;;
    action-preference)
      mode="$(sed -n '1p' "$mode_file")"
      printf '{"status":"in_progress","phase":"action-preference","selection":"single","automationMode":"%s","options":%s}\n' "$mode" "$action_options"
      ;;
    ready)
      mode="$(sed -n '1p' "$mode_file")"
      preference="$(sed -n '1p' "$preference_file")"
      printf '{"status":"ready","automationMode":"%s","actionPreference":"%s"}\n' "$mode" "$preference"
      ;;
    *)
      printf '%s\n' '{"status":"error","reason":"invalid-workflow-setup"}'
      exit 2
      ;;
  esac
}

if [ "$action" = "begin" ]; then
  if [ -s "$phase_file" ]; then
    emit_state
    exit 0
  fi
  temporary="$data_root/.workflow-setup.tmp.$$"
  rm -rf "$temporary"
  mkdir -p "$temporary"
  printf '%s\n' automation > "$temporary/phase"
  rm -rf "$setup_root"
  mv "$temporary" "$setup_root"
  emit_state
  exit 0
fi

if [ "$action" = "status" ]; then
  emit_state
  exit 0
fi

if [ "$action" = "cancel" ]; then
  rm -rf "$setup_root"
  printf '%s\n' '{"status":"cancelled"}'
  exit 0
fi

if [ ! -s "$phase_file" ]; then
  printf '%s\n' '{"status":"invalid","reason":"workflow-setup-not-started"}'
  exit 1
fi
phase="$(sed -n '1p' "$phase_file")"

if [ "$action" = "select" ]; then
  if [ "$phase" != "automation" ] && [ "$phase" != "action-preference" ]; then
    printf '%s\n' '{"status":"invalid","reason":"wrong-workflow-phase"}'
    exit 1
  fi
  set +e
  verified="$(sh "$verifier" --source 1,2,3 --selection single --user-input "$user_input")"
  verified_status=$?
  set -e
  if [ "$verified_status" -ne 0 ]; then
    printf '%s\n' "$verified"
    exit "$verified_status"
  fi
  selected="$(printf '%s\n' "$verified" | sed -n 's/.*"normalizedInput":"\([0-9]*\)".*/\1/p')"
  if [ "$phase" = "automation" ]; then
    case "$selected" in
      1) mode="job-approval" ;;
      2) mode="package-approval" ;;
      3) mode="full-auto" ;;
      *)
        printf '%s\n' '{"status":"error","reason":"invalid-workflow-selection"}'
        exit 2
        ;;
    esac
    printf '%s\n' "$mode" > "$mode_file"
    printf '%s\n' action-preference > "$phase_file"
  else
    case "$selected" in
      1) preference="package-first" ;;
      2) preference="balanced" ;;
      3) preference="direct-first" ;;
      *)
        printf '%s\n' '{"status":"error","reason":"invalid-workflow-selection"}'
        exit 2
        ;;
    esac
    printf '%s\n' "$preference" > "$preference_file"
    printf '%s\n' ready > "$phase_file"
  fi
  emit_state
  exit 0
fi

if [ "$action" = "commit" ]; then
  if [ "$phase" != "ready" ] || [ ! -s "$mode_file" ] || [ ! -s "$preference_file" ]; then
    printf '%s\n' '{"status":"invalid","reason":"wrong-workflow-phase"}'
    exit 1
  fi
  mode="$(sed -n '1p' "$mode_file")"
  preference="$(sed -n '1p' "$preference_file")"
  temporary="$data_root/.workflows.json.tmp.$$"
  cat > "$temporary" <<EOF
{
  "schemaVersion": 1,
  "configured": true,
  "actionPreference": "$preference",
  "automationMode": "$mode"
}
EOF
  mv "$temporary" "$config_file"
  rm -rf "$setup_root"
  cat "$config_file"
  exit 0
fi

usage
exit 2
